import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/theme/app_theme.dart';
import '/l10n/app_strings.dart';
import '/screens/order_summary_screen.dart';
import '/screens/login.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';
import 'package:provider/provider.dart';
import '/providers/locale_provider.dart';
import '/utils/image_url.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<SubscriptionPackage> _packages = [];
  bool _loading = true;
  String? _error;
  int? _ownedPackageId;
  Map<String, dynamic>? _subStatus;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchPackages(),
        _fetchOwnedPackage(),
      ]);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  /// Loads the package the account already holds so it can't be bought twice.
  Future<void> _fetchOwnedPackage() async {
    try {
      final user = await UserStorageService().getUser();
      final id = (user?['id'] as num?)?.toInt();
      if (id == null) return;
      final status = await ApiService().getSubscriptionStatus(customerId: id);
      if (mounted) {
        setState(() {
          _subStatus = status;
          if (status['subscribed'] == true) {
            final pkg = status['subscriptionPackage'] as Map<String, dynamic>?;
            final pkgId = (pkg?['id'] as num?)?.toInt();
            if (pkgId != null) {
              _ownedPackageId = pkgId;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPackages() async {
    try {
      final res = await http.get(
        Uri.parse('$appBaseUrl/api/subscription-packages'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _packages = data
                .where((e) => e['isActive'] == true)
                .map((e) => SubscriptionPackage.fromJson(e as Map<String, dynamic>))
                .toList();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load plans';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load plans';
        });
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final isSubscribed = _subStatus?['subscribed'] == true;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ── Blue header ───────────────────────────────────────────────
          Container(
            color: Apptheme.bluecolor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 20,
              bottom: 20,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isSubscribed ? l.mySubscriptions : l.chooseYourPlan,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    if (!isSubscribed)
                      Text(l.annualOnly,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _loading = true;
                                  _error = null;
                                });
                                _fetchPackages();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Apptheme.bluecolor),
                              child: const Text('Retry',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : isSubscribed
                        ? _buildActiveSubscriptionView(isEn, l)
                        : _buildChoosePlanView(isEn, l),
          ),
        ],
      ),
    );
  }

  /// Read-only view for users who already have an active subscription.
  Widget _buildActiveSubscriptionView(bool isEn, AppStrings l) {
    final subPlan = _subStatus?['plan'] as String?;
    final subStatusLabel = _subStatus?['status'] as String?;
    final subEndDate = _formatDate(_subStatus?['endDate'] as String?);
    final subPrice = _subStatus?['price'];
    final subCurrency = _subStatus?['currency'] as String? ?? 'EUR';
    final daysRemaining = _subStatus?['daysRemaining'] as int? ?? 0;
    final subPackage =
        _subStatus?['subscriptionPackage'] as Map<String, dynamic>?;
    final packageTitle = subPackage?['title'] as String? ??
        subPackage?['titleEn'] as String? ??
        '';

    // Try to find the matching package from the fetched list for features
    SubscriptionPackage? matchedPkg;
    if (_ownedPackageId != null) {
      for (final p in _packages) {
        if (p.id == _ownedPackageId) {
          matchedPkg = p;
          break;
        }
      }
    }

    final currencySymbol = subCurrency == 'EUR' ? '€' : subCurrency;

    final subPromoCode = _subStatus?['promoCode'] as String? ?? _subStatus?['coupon'] as String?;
    final subDiscount = _subStatus?['discountAmount'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          // ── Active plan card ────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.green.shade400, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Green "Active" banner ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isEn ? 'ACTIVE PLAN' : 'AKTIVAN PLAN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Package name & price ─────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  packageTitle,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (subPlan != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Apptheme.bluecolor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      subPlan.replaceAll('_', ' '),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Apptheme.bluecolor,
                                      ),
                                    ),
                                  ),
                                ],
                                if (subPromoCode != null && subPromoCode.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_offer, size: 12, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          subDiscount != null ? '$subPromoCode (-$currencySymbol$subDiscount)' : subPromoCode,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (subPrice != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currencySymbol$subPrice',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Apptheme.bluecolor,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  isEn ? 'per year' : 'godišnje',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // ── Features (from matched package) ──────────────
                      if (matchedPkg != null &&
                          matchedPkg.features(isEn).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...matchedPkg.features(isEn).map((f) => _Feature(f)),
                      ],

                      // ── Subscription details ─────────────────────────
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 14),

                      // Expiry + Days remaining + Status row
                      Row(
                        children: [
                          if (subEndDate.isNotEmpty)
                            Expanded(
                              child: _DetailChip(
                                icon: Icons.calendar_today,
                                label: isEn ? 'Expires' : 'Istječe',
                                value: subEndDate,
                              ),
                            ),
                          if (daysRemaining > 0)
                            Expanded(
                              child: _DetailChip(
                                icon: Icons.timer_outlined,
                                label: isEn ? 'Days left' : 'Preostalo dana',
                                value: '$daysRemaining',
                                valueColor: daysRemaining < 30
                                    ? Colors.orange
                                    : Colors.green.shade600,
                              ),
                            ),
                          if (subStatusLabel != null)
                            Expanded(
                              child: _DetailChip(
                                icon: Icons.verified_outlined,
                                label: isEn ? 'Status' : 'Status',
                                value: subStatusLabel,
                                valueColor: Colors.green.shade600,
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

          const SizedBox(height: 20),

          Text(
            l.annualNoAutoRenewal,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// Purchase flow for users who don't yet have a subscription.
  Widget _buildChoosePlanView(bool isEn, AppStrings l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          // ── Plan cards (yearly only) ───────────────
          ..._packages.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PlanCard(
                package: entry.value,
                featured: entry.key == 0,
                isEn: isEn,
                alreadyOwned:
                    entry.value.id == _ownedPackageId,
              ),
            );
          }),

          Text(
            l.annualNoAutoRenewal,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class SubscriptionPackage {
  final int id;
  final String titleEn;
  final String titleHr;
  final double priceMonthly;
  final double priceYearly;
  final List<String> featuresEn;
  final List<String> featuresHr;

  SubscriptionPackage({
    required this.id,
    required this.titleEn,
    required this.titleHr,
    required this.priceMonthly,
    required this.priceYearly,
    required this.featuresEn,
    required this.featuresHr,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    final descEn = json['descriptionEn'] as String? ?? json['description'] as String? ?? '';
    final descHr = json['descriptionHr'] as String? ?? json['description'] as String? ?? '';
    return SubscriptionPackage(
      id: json['id'] as int,
      titleEn: (json['titleEn'] as String? ?? json['title'] as String? ?? '').trim(),
      titleHr: (json['titleHr'] as String? ?? json['title'] as String? ?? '').trim(),
      priceMonthly: (json['priceMonthly'] as num).toDouble(),
      priceYearly: (json['priceYearly'] as num).toDouble(),
      featuresEn: _parseFeatures(descEn),
      featuresHr: _parseFeatures(descHr),
    );
  }

  String title(bool isEn) => isEn ? titleEn : titleHr;
  List<String> features(bool isEn) => isEn ? featuresEn : featuresHr;

  static List<String> _parseFeatures(String html) {
    final liPattern =
        RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true);
    final matches = liPattern.allMatches(html);
    if (matches.isNotEmpty) {
      return matches
          .map((m) => _stripHtml(m.group(1) ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final plain = _stripHtml(html);
    return plain.isNotEmpty ? [plain] : [];
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SubscriptionPackage package;
  final bool featured;
  final bool isEn;
  final bool alreadyOwned;

  const _PlanCard({
    required this.package,
    required this.featured,
    required this.isEn,
    this.alreadyOwned = false,
  });

  String _formatPrice(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final price = package.priceYearly;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: featured ? Border.all(color: Colors.orange.shade400, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: featured
                ? Colors.orange.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: featured ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  package.title(isEn).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(18, featured ? 16 : 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.title(isEn),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '€${_formatPrice(package.priceYearly / 12)}/mo billed yearly',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${_formatPrice(price)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: featured ? Apptheme.bluecolor : Colors.black87,
                            height: 1,
                          ),
                        ),
                        const Text(
                          'per year',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),

                if (package.features(isEn).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...package.features(isEn).map((f) => _Feature(f)),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: alreadyOwned
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: Colors.green.shade50,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Current plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : featured
                      ? ElevatedButton(
                          onPressed: () => _goToSummary(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get ${package.title(isEn)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () => _goToSummary(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Select ${package.title(isEn)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToSummary(BuildContext context) async {
    // Guests must log in with their own credentials before subscribing.
    final loggedIn = await UserStorageService().isLoggedIn();
    if (!context.mounted) return;
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).loginToSubscribe)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(package: package),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String text;
  const _Feature(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
