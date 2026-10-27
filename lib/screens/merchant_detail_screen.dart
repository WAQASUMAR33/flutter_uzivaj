import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/theme/app_theme.dart';
import '/l10n/app_strings.dart';
import '/screens/offer_redemption_screens.dart';
import '/utils/image_url.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';
import '/screens/subscription_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '/providers/locale_provider.dart';

class MerchantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> merchantData;
  final Function(Map<String, dynamic>)? onMerchantUpdated;
  const MerchantDetailScreen({
    super.key,
    required this.merchantData,
    this.onMerchantUpdated,
  });

  @override
  State<MerchantDetailScreen> createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int? _selectedOfferId;
  late Map<String, dynamic> _merchantData;
  final ApiService _api = ApiService();
  bool _isRedeeming = false;

  // Offers are locked (grey + not clickable) for guests and non-subscribers.
  // Default locked until we confirm an active subscription.
  bool _offersLocked = true;
  bool _loadingAccess = true;
  Set<int> _redeemedOfferIds = {};

  static const _transitionDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _merchantData = Map.from(widget.merchantData);
    WidgetsBinding.instance.addObserver(this);
    _loadAccessState();
  }

  /// Unlocks offers only for a logged-in user with an ACTIVE subscription.
  /// Also loads the user's redemption history so used offers are disabled.
  Future<void> _loadAccessState() async {
    bool subscribed = false;
    final Set<int> redeemed = {};
    try {
      final user = await UserStorageService().getUser();
      if (user != null) {
        // Stored user snapshot
        final sub = user['subscription'] as Map<String, dynamic>?;
        if (sub?['status']?.toString().toUpperCase() == 'ACTIVE') {
          subscribed = true;
        }
        // Authoritative check via API (matches profile screen)
        final id = user['id'] as int?;
        if (id != null) {
          try {
            final status = await _api.getSubscriptionStatus(customerId: id);
            if (status['subscribed'] == true) subscribed = true;
          } catch (_) {}

          try {
            final historyData = await _api.getRedeemHistory(customerId: id);
            final redemptions = (historyData['redemptions'] as List?) ?? [];
            for (final item in redemptions) {
              final offId = (item['offerId'] as num?)?.toInt() ??
                            (item['offer']?['id'] as num?)?.toInt();
              if (offId != null) {
                redeemed.add(offId);
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Also pick up any offers explicitly tagged as isRedeemed in merchantData
    for (final offer in _offers) {
      if (offer['isRedeemed'] == true) {
        final offId = (offer['id'] as num?)?.toInt();
        if (offId != null) redeemed.add(offId);
      }
    }

    if (mounted) {
      setState(() {
        _offersLocked = !subscribed;
        _redeemedOfferIds = redeemed;
        _loadingAccess = false;
        if (_selectedOfferId != null && _redeemedOfferIds.contains(_selectedOfferId)) {
          _selectedOfferId = null;
        }
      });
    }
  }

  void _updateMerchantData(Map<String, dynamic> newData) {
    setState(() {
      _merchantData.addAll(newData);
    });
    widget.onMerchantUpdated?.call(_merchantData);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op since we removed auto-play
  }

  void _navigateToPreviousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: _transitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToNextImage() {
    if (_currentImageIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: _transitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPinEntry() {
    if (_selectedOfferId == null) return;
    Map<String, dynamic>? selectedOffer;
    for (final o in _offers) {
      if ((o['id'] as int?) == _selectedOfferId) {
        selectedOffer = o;
        break;
      }
    }
    if (selectedOffer != null) {
      final offer = selectedOffer;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            final isEn = Provider.of<LocaleProvider>(context, listen: false).isEnglish;
            return PinEntryScreen(
              merchantName: _merchantData[isEn ? 'nameEn' : 'nameHr'] as String? ?? _merchantData['name'] as String? ?? '',
              offerTitle: offer[isEn ? 'titleEn' : 'titleHr'] as String? ?? offer['title'] as String? ?? '',
              merchantId: _merchantData['id'] as int? ?? 0,
              offerId: offer['id'] as int? ?? 0,
              onReviewSubmitted: _updateMerchantData,
            );
          },
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _selectedOfferId = null;
          });
          _loadAccessState();
          _refresh();
        }
      });
    }
  }

  Future<void> _handleRedeemClick() async {
    if (_selectedOfferId == null) return;
    setState(() => _isRedeeming = true);
    try {
      final storage = UserStorageService();
      final user = await storage.getUser();
      if (user == null) {
        setState(() => _isRedeeming = false);
        return;
      }

      // Check subscription from stored user data first
      final subscription = user['subscription'] as Map<String, dynamic>?;
      final subStatus = subscription?['status']?.toString().toUpperCase();
      var hasActiveSubscription = subStatus == 'ACTIVE';

      // Stored snapshot can be stale (e.g. user subscribed after login),
      // so confirm with the server before showing the paywall.
      if (!hasActiveSubscription) {
        final id = (user['id'] as num?)?.toInt();
        if (id != null) {
          try {
            final status = await _api.getSubscriptionStatus(customerId: id);
            if (status['subscribed'] == true) {
              hasActiveSubscription = true;
              user['subscription'] = {
                'status': status['status']?.toString() ?? 'ACTIVE',
                'plan': status['plan'],
                'endDate': status['endDate'],
              };
              await storage.saveUser(user);
            }
          } catch (_) {}
        }
      }

      if (!hasActiveSubscription) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
        setState(() => _isRedeeming = false);
        return;
      }
    } catch (e) {
      // On error, show a snackbar instead of wrongly redirecting
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking subscription: $e')),
      );
      setState(() => _isRedeeming = false);
      return;
    }
    setState(() => _isRedeeming = false);
    _navigateToPinEntry();
  }

  Future<void> _refresh() async {
    try {
      final user = await UserStorageService().getUser();
      final id = user?['id'] as int?;
      final data = await _api.getMerchants(customerId: id);
      final merchants = data['merchants'] as List?;
      if (merchants != null) {
        final updated = merchants.firstWhere(
          (m) => m['id'] == _merchantData['id'],
          orElse: () => null,
        );
        if (updated != null) {
          _updateMerchantData(updated as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    await _loadAccessState();
  }

  List<Map<String, dynamic>> get _offers =>
      ((_merchantData['offers'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

  static const String _baseImageUrl =
      'https://uzivaj.rizwancars.com/data/uploads';

  String _resolveImage(String img) =>
      webSafeImageUrl(joinImageUrl(_baseImageUrl, img));

  List<String> get _images {
    final raw = _merchantData['images'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final parsed = List<String>.from(jsonDecode(raw));
        return parsed.map(_resolveImage).toList();
      } catch (_) {}
    } else if (raw is List) {
      try {
        final parsed = List<String>.from(raw);
        return parsed.map(_resolveImage).toList();
      } catch (_) {}
    }
    return [];
  }

  String get _categoryDisplay {
    final cat = _merchantData['category'] as String? ?? '';
    return cat
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  double get _avgRating =>
      (_merchantData['avgRating'] as num?)?.toDouble() ?? 4.8;
  int get _ratingCount =>
      _merchantData['ratingCount'] as int? ?? (_offers.length * 47);

  bool get _isOpen {
    final now = DateTime.now();
    return _offers.any((o) {
      try {
        final from = DateTime.parse(o['validFrom'] as String);
        final until = DateTime.parse(o['validUntil'] as String);
        return now.isAfter(from) &&
            now.isBefore(until) &&
            (o['isActive'] == true);
      } catch (_) {
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final name = _merchantData[isEn ? 'nameEn' : 'nameHr'] as String? ?? _merchantData['name'] as String? ?? '';
    final description = _merchantData[isEn ? 'descriptionEn' : 'descriptionHr'] as String? ?? _merchantData['description'] as String? ?? '';
    final city = _merchantData[isEn ? 'cityEn' : 'cityHr'] as String? ?? _merchantData['city'] as String? ?? '';
    final phone = _merchantData['phone'] as String?;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final images = _images;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              // Image slider — plain SliverToBoxAdapter avoids SliverAppBar
              // gesture conflicts that prevent PageView from working
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280 + topPadding,
                  child: Stack(
                    children: [
                      // PageView with fully bounded constraints (no swipe, no auto-scroll)
                      Positioned.fill(
                        child: images.isNotEmpty
                            ? PageView.builder(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: images.length,
                                onPageChanged: (i) {
                                  setState(() => _currentImageIndex = i);
                                },
                                itemBuilder: (_, i) => CachedNetworkImage(
                                  imageUrl: images[i],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (_, __) => Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Apptheme.bluecolor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.grey.shade500,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image unavailable',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: Center(
                                  child: Icon(
                                    Icons.storefront_outlined,
                                    color: Colors.grey.shade500,
                                    size: 48,
                                  ),
                                ),
                              ),
                      ),
                      // Dark gradient (painted before the arrows/dots so it
                      // doesn't intercept taps meant for them)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Navigation arrows
                      if (images.length > 1) ...[
                        Positioned(
                          top: topPadding + 40,
                          left: 8,
                          child: Opacity(
                            opacity: _currentImageIndex > 0 ? 1.0 : 0.3,
                            child: GestureDetector(
                              onTap: _currentImageIndex > 0
                                  ? _navigateToPreviousImage
                                  : null,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: topPadding + 40,
                          right: 8,
                          child: Opacity(
                            opacity: _currentImageIndex < images.length - 1
                                ? 1.0
                                : 0.3,
                            child: GestureDetector(
                              onTap: _currentImageIndex < images.length - 1
                                  ? _navigateToNextImage
                                  : null,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Dot indicators
                      if (images.length > 1)
                        Positioned(
                          bottom: 72,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Dot indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) {
                                  final active = i == _currentImageIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: active ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: active
                                          ? [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 4,
                                                spreadRadius: 0.5,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      // Category badge + rating
                      Positioned(
                        bottom: 44,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _categoryDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  if (i < _avgRating.floor()) {
                                    return const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    );
                                  } else if (i < _avgRating) {
                                    return const Icon(
                                      Icons.star_half,
                                      color: Colors.amber,
                                      size: 14,
                                    );
                                  } else {
                                    return const Icon(
                                      Icons.star_border,
                                      color: Colors.amber,
                                      size: 14,
                                    );
                                  }
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  _avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($_ratingCount)',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // White card body
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Info row
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                _InfoItem(
                                  icon: Icons.location_on,
                                  label: city.isEmpty ? l.locationLabel : city,
                                  color: Colors.redAccent,
                                  onTap: () async {
                                    final lat = _merchantData['lat'];
                                    final lon = _merchantData['lon'];
                                    if (lat != null && lon != null) {
                                      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      } else {
                                        final uriApple = Uri.parse('http://maps.apple.com/?daddr=$lat,$lon');
                                        if (await canLaunchUrl(uriApple)) {
                                          await launchUrl(uriApple, mode: LaunchMode.externalApplication);
                                        }
                                      }
                                    }
                                  },
                                ),
                                _VerticalDivider(),
                                _InfoItem(
                                  icon: Icons.access_time_outlined,
                                  label: _isOpen ? l.openLabel : l.closedLabel,
                                  color: _isOpen
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                                _VerticalDivider(),
                                _InfoItem(
                                  icon: Icons.phone_outlined,
                                  label: l.callLabel,
                                  color: Colors.blueAccent,
                                  disabled: phone == null,
                                  onTap: phone == null ? null : () async {
                                    final uri = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Offers header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.availableOffers,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              l.offersUseEach(_offers.length),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Apptheme.bluecolor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Offer cards
                        if (_loadingAccess)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Apptheme.bluecolor,
                              ),
                            ),
                          )
                        else
                          ..._offers.map((offer) {
                            final offerId = offer['id'] as int? ?? 0;
                            final isRedeemed = _redeemedOfferIds.contains(offerId) || offer['isRedeemed'] == true;
                            final isSelected = _selectedOfferId == offerId;
                            return _OfferCard(
                              title: offer[isEn ? 'titleEn' : 'titleHr'] as String? ?? offer['title'] as String? ?? '',
                              subtitle: offer[isEn ? 'descriptionEn' : 'descriptionHr'] as String? ?? offer['description'] as String? ?? '',
                              discount: offer[isEn ? 'discountEn' : 'discountHr'] as String? ?? offer['discount'] as String? ?? '',
                              offerAmount: offer['offerAmount'] as num?,
                              discountValue: offer['discountValue'] as num?,
                              isSelected: isSelected,
                              locked: _offersLocked,
                              isRedeemed: isRedeemed,
                              onSelect: () {
                                if (_offersLocked || isRedeemed) return;
                                setState(() {
                                  _selectedOfferId = offerId;
                                });
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),

          // ── Back button overlay (always visible) ────────────────────────
          Positioned(
            top: topPadding + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Fixed bottom button ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                     color: Colors.black.withValues(alpha: 0.08),
                     blurRadius: 12,
                     offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _loadingAccess || _selectedOfferId == null || _isRedeeming
                    ? null
                    : _handleRedeemClick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Apptheme.bluecolor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isRedeeming 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _loadingAccess
                            ? 'Verifying access...'
                            : _selectedOfferId != null
                                ? 'Redeem Offer'
                                : _offers.isNotEmpty && !_offersLocked
                                    ? l.chooseAnOffer
                                    : l.noOffersAvailableBtn,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: !_loadingAccess && _selectedOfferId != null
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback? onTap;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.color,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = disabled ? Colors.grey.shade400 : color;
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: Colors.grey.shade200);
  }
}

class _OfferCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String discount;
  final num? offerAmount;
  final num? discountValue;
  final bool isSelected;
  final bool locked;
  final bool isRedeemed;
  final VoidCallback? onSelect;

  const _OfferCard({
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.isSelected,
    this.locked = false,
    this.isRedeemed = false,
    this.offerAmount,
    this.discountValue,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final textColor = isRedeemed
        ? Colors.grey.shade500
        : (isSelected ? Apptheme.bluecolor : Apptheme.blackcolor);
    final subColor = isRedeemed ? Colors.grey.shade400 : Colors.grey.shade600;

    // Locked or already redeemed: block taps
    final card = GestureDetector(
      onTap: (locked || isRedeemed) ? null : onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isRedeemed ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Apptheme.bluecolor
                : (isRedeemed ? Colors.grey.shade300 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isRedeemed ? 0.01 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: discount badge + title + description + savings
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount badge row (+ offer amount chip if present)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isRedeemed
                              ? Colors.grey.shade200
                              : Apptheme.bluecolor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isRedeemed ? Colors.grey.shade600 : Apptheme.bluecolor,
                          ),
                        ),
                      ),
                      if (isRedeemed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            l.usedLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ] else if (offerAmount != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '€${offerAmount!.toStringAsFixed(offerAmount! % 1 == 0 ? 0 : 2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      decoration: isRedeemed ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Description
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                  // Savings line
                  if (discountValue != null && !isRedeemed) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 13,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Save €${discountValue!.toStringAsFixed(discountValue! % 1 == 0 ? 0 : 2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: lock icon when locked, or used badge, else selection indicator
            if (isRedeemed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      l.usedLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (locked)
              Icon(Icons.lock_outline, size: 22, color: Colors.grey.shade400)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Apptheme.bluecolor : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Apptheme.bluecolor
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: isRedeemed ? 0.65 : (locked ? 0.5 : 1.0),
      child: card,
    );
  }
}
