import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/theme/app_theme.dart';
import '/providers/app_provider.dart';
import '/providers/login_provider.dart';
import '/providers/locale_provider.dart';
import '/services/userStorageService.dart';
import '/services/apiService.dart';
import '/screens/login.dart';
import '/screens/profile_screen.dart';
import '/screens/merchant_detail_screen.dart';
import '/screens/terms_screen.dart';
import '/screens/redeem_history_screen.dart';
import '/screens/subscription_screen.dart';
import '/l10n/app_strings.dart';
import '/utils/image_url.dart';
import '/widgets/support_sheet.dart';

// ── Local models ──────────────────────────────────────────────────────────────

class _Category {
  final int id;
  final String nameEn;
  final String nameHr;
  final String slug;
  final String emoji;
  final String? image;

  _Category({
    required this.id,
    required this.nameEn,
    required this.nameHr,
    required this.slug,
    required this.emoji,
    this.image,
  });
  factory _Category.fromJson(Map<String, dynamic> j) => _Category(
    id: j['id'] as int,
    nameEn: j['nameEn'] as String? ?? j['name'] as String? ?? '',
    nameHr: j['nameHr'] as String? ?? j['name'] as String? ?? '',
    slug: j['slug'] as String,
    emoji: j['emoji'] as String,
    image: j['image'] as String?,
  );

  String name(bool isEn) => isEn ? nameEn : nameHr;
}

class _Offer {
  final String titleEn;
  final String titleHr;
  final String discountEn;
  final String discountHr;
  const _Offer({
    required this.titleEn,
    required this.titleHr,
    required this.discountEn,
    required this.discountHr,
  });
  factory _Offer.fromJson(Map<String, dynamic> j) => _Offer(
    titleEn: j['titleEn'] as String? ?? j['title'] as String? ?? '',
    titleHr: j['titleHr'] as String? ?? j['title'] as String? ?? '',
    discountEn: j['discountEn'] as String? ?? j['discount'] as String? ?? '',
    discountHr: j['discountHr'] as String? ?? j['discount'] as String? ?? '',
  );

  String title(bool isEn) => isEn ? titleEn : titleHr;
  String discount(bool isEn) => isEn ? discountEn : discountHr;
}

class _Merchant {
  final int id;
  final String nameEn;
  final String nameHr;
  final String category;
  final String addressEn;
  final String addressHr;
  final String cityEn;
  final String cityHr;
  final List<String> images;
  final int savingsEstimate;
  final List<_Offer> offers;
  final Map<String, dynamic> rawJson;
  final double? lat;
  final double? lon;
  final double? avgRating;
  final int? ratingCount;

  const _Merchant({
    required this.id,
    required this.nameEn,
    required this.nameHr,
    required this.category,
    required this.addressEn,
    required this.addressHr,
    required this.cityEn,
    required this.cityHr,
    required this.images,
    required this.savingsEstimate,
    required this.offers,
    required this.rawJson,
    this.lat,
    this.lon,
    this.avgRating,
    this.ratingCount,
  });

  String name(bool isEn) => isEn ? nameEn : nameHr;
  String address(bool isEn) => isEn ? addressEn : addressHr;
  String city(bool isEn) => isEn ? cityEn : cityHr;

  static const String _baseImageUrl =
      'https://uzivaj.rizwancars.com/data/uploads/';

  factory _Merchant.fromJson(Map<String, dynamic> j) {
    List<String> imgs = [];
    final raw = j['images'];

    if (raw is String && raw.isNotEmpty) {
      try {
        final parsed = List<String>.from(jsonDecode(raw));
        imgs = parsed
            .map((img) => webSafeImageUrl(joinImageUrl(_baseImageUrl, img)))
            .toList();
      } catch (_) {}
    } else if (raw is List) {
      try {
        final parsed = List<String>.from(raw);
        imgs = parsed
            .map((img) => webSafeImageUrl(joinImageUrl(_baseImageUrl, img)))
            .toList();
      } catch (_) {}
    }

    return _Merchant(
      id: j['id'] as int,
      nameEn: j['nameEn'] as String? ?? j['name'] as String? ?? '',
      nameHr: j['nameHr'] as String? ?? j['name'] as String? ?? '',
      category: j['category'] as String? ?? '',
      addressEn: j['addressEn'] as String? ?? j['address'] as String? ?? '',
      addressHr: j['addressHr'] as String? ?? j['address'] as String? ?? '',
      cityEn: j['cityEn'] as String? ?? j['city'] as String? ?? '',
      cityHr: j['cityHr'] as String? ?? j['city'] as String? ?? '',
      images: imgs,
      savingsEstimate: (j['savingsEstimate'] as num?)?.toInt() ?? 0,
      offers: ((j['offers'] as List?) ?? [])
          .map((o) => _Offer.fromJson(o as Map<String, dynamic>))
          .toList(),
      rawJson: j,
      lat:
          (j['lat'] as num?)?.toDouble() ?? (j['latitude'] as num?)?.toDouble(),
      lon:
          (j['lon'] as num?)?.toDouble() ??
          (j['lng'] as num?)?.toDouble() ??
          (j['longitude'] as num?)?.toDouble(),
      avgRating: (j['avgRating'] as num?)?.toDouble(),
      ratingCount: j['ratingCount'] as int?,
    );
  }

  String get categoryDisplay => category
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');

  String? get firstImage => images.isNotEmpty ? images[0] : null;
  String? firstDiscount(bool isEn) =>
      offers.isNotEmpty ? offers[0].discount(isEn) : null;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  int _bottomIndex = 0;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  int _prevBottomIndex = 0;

  Map<String, dynamic>? _userData;
  bool _isLoggedIn = false;

  List<_Category> _categories = [];
  List<_Merchant> _merchants = [];
  bool _loadingData = true;

  Position? _userPosition;

  final _api = ApiService();

  void _updateMerchant(int merchantId, Map<String, dynamic> newData) {
    setState(() {
      _merchants = _merchants.map((m) {
        if (m.id == merchantId) {
          final updatedRawJson = {...m.rawJson}..addAll(newData);
          return _Merchant.fromJson(updatedRawJson);
        }
        return m;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadData();
    _loadLocation();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser({bool refreshApi = false}) async {
    final storage = UserStorageService();
    Map<String, dynamic>? user = await storage.getUser();
    final loggedIn = await storage.isLoggedIn();

    if (loggedIn && user != null) {
      try {
        final email = user['email'];
        if (email != null) {
          final check = await _api.checkEmail(email);
          if (check['exists'] == true) {
            final customer = check['customer'] as Map<String, dynamic>;
            if (customer['isActive'] == false) {
              await _logout();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Account Suspended'),
                    content: const Text(
                      'your account has been suspended contact admin team',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
              return;
            } else {
              await storage.saveUser(customer);
              user = customer;
            }
          }
        }
      } catch (e) {}
    }

    if (mounted) {
      setState(() {
        _userData = user;
        _isLoggedIn = loggedIn;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final cats = await _api.getCategories();
      final mchData = await _api.getMerchants();
      if (!mounted) return;
      setState(() {
        _categories = cats
            .map((c) => _Category.fromJson(c as Map<String, dynamic>))
            .toList();
        _merchants = (mchData['merchants'] as List)
            .map((m) => _Merchant.fromJson(m as Map<String, dynamic>))
            .toList();
        _loadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _loadLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {
      // Silently ignore — distance just won't be shown.
    }
  }

  String? _distanceFor(_Merchant m) {
    if (_userPosition == null || m.lat == null || m.lon == null) return null;
    final meters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      m.lat!,
      m.lon!,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  List<_Merchant> get _filteredMerchants {
    var list = _merchants;

    if (_selectedCategoryIndex != 0) {
      final slug = _categories[_selectedCategoryIndex - 1].slug;
      final catKey = slug.replaceAll('-', '_').toUpperCase();
      list = list.where((m) => m.category == catKey).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (m) =>
                m.nameEn.toLowerCase().contains(_searchQuery) ||
                m.nameHr.toLowerCase().contains(_searchQuery) ||
                m.cityEn.toLowerCase().contains(_searchQuery) ||
                m.cityHr.toLowerCase().contains(_searchQuery) ||
                m.addressEn.toLowerCase().contains(_searchQuery) ||
                m.addressHr.toLowerCase().contains(_searchQuery) ||
                m.offers.any(
                  (o) =>
                      o.titleEn.toLowerCase().contains(_searchQuery) ||
                      o.titleHr.toLowerCase().contains(_searchQuery),
                ),
          )
          .toList();
    }

    return list;
  }

  Future<void> _logout() async {
    await context.read<LoginProvider>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _initials() {
    final name = _userData?['fullname'] as String? ?? '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty)
      return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final userCity = context.watch<AppProvider>().userCity;
    final l = AppStrings.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade100,
      onDrawerChanged: (isOpen) {
        if (isOpen) {
          _loadUser(refreshApi: true);
        }
      },
      drawer: _buildDrawer(l),
      body: IndexedStack(
        index: _bottomIndex,
        children: [
          // Tab 0 — Home
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(userCity, l),
                Expanded(
                  child: _loadingData
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBody(l),
                ),
              ],
            ),
          ),
          // Tab 1 — Search
          _SearchTab(
            key: ValueKey(
              _bottomIndex == 1 ? DateTime.now().millisecondsSinceEpoch : 0,
            ),
          ),
          // Tab 2 — Nearby
          const _NearbyTab(),
          // Tab 3 — Profile
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(l),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(String userCity, AppStrings l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Apptheme.bluecolor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hamburger + location
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState!.openDrawer(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              // Bell + language + auth
              Row(
                children: [
                  // Language toggle — same 44×44 circle as logout
                  Consumer<LocaleProvider>(
                    builder: (_, lp, __) => GestureDetector(
                      onTap: lp.toggleLocale,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          lp.isEnglish ? 'EN' : 'HR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logout — same 44×44 circle as language toggle
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(
                        _isLoggedIn ? Icons.logout : Icons.login,
                        color: Colors.white,
                      ),
                      onPressed: _isLoggedIn
                          ? _logout
                          : () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l.discoverZagreb,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l.searchHint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.7),
                          size: 18,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Scrollable body ─────────────────────────────────────────────────────────

  Widget _buildBody(AppStrings l) {
    final filtered = _filteredMerchants;
    final isEn = context.watch<LocaleProvider>().isEnglish;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CATEGORIES label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.categoriesLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final selectedIndex = await Navigator.push<int>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoriesScreen(
                            categories: _categories,
                            merchants: _merchants,
                          ),
                        ),
                      );
                      if (selectedIndex != null) {
                        setState(() => _selectedCategoryIndex = selectedIndex);
                      }
                    },
                    child: Text(
                      l.viewAll,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Apptheme.bluecolor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                itemBuilder: (context, i) {
                  final isSelected = i == _selectedCategoryIndex;
                  final label = i == 0
                      ? l.allCategory
                      : '${_categories[i - 1].emoji} ${_categories[i - 1].name(isEn)}';
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Apptheme.bluecolor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Apptheme.bluecolor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.nearbyOffers,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      l.viewAll,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Apptheme.bluecolor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Merchant cards
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    l.noOffersInCategory,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ...filtered.map(
                (m) => _MerchantCard(
                  merchant: m,
                  distance: _distanceFor(m),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MerchantDetailScreen(
                        merchantData: m.rawJson,
                        onMerchantUpdated: (newData) {
                          _updateMerchant(m.id, newData);
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav(AppStrings l) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() {
            _prevBottomIndex = _bottomIndex;
            _bottomIndex = i;
          });
          // If entering search tab, refresh data
          if (i == 1 && _prevBottomIndex != 1) {
            _loadData();
          }
        },
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Apptheme.bluecolor,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l.homeTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: l.searchTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.near_me_outlined),
            activeIcon: const Icon(Icons.near_me),
            label: l.nearbyTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l.profileTab,
          ),
        ],
      ),
    );
  }

  // ── Drawer ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer(AppStrings l) {
    final imageUrl = _userData?['imageUrl'] as String?;
    final fullname = _userData?['fullname'] as String? ?? l.guest;
    final email = _userData?['email'] as String? ?? '';

    void close() => Navigator.pop(context);
    void push(Widget screen) {
      close();
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              color: Apptheme.bluecolor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: _isLoggedIn
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                            ? NetworkImage(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? Text(
                                _initials(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0x40FFFFFF),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.welcome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => push(const LoginScreen()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.signIn,
                            style: const TextStyle(
                              color: Apptheme.bluecolor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Menu items ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: l.homeTab,
                  onTap: close,
                ),
                _DrawerItem(
                  icon: Icons.receipt_long_outlined,
                  label: l.redeemHistory,
                  onTap: () => push(const RedeemHistoryScreen()),
                ),
                _DrawerItem(
                  icon: Icons.card_membership_outlined,
                  label: l.mySubscriptions,
                  onTap: () => push(const SubscriptionScreen()),
                ),
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: l.myProfile,
                  onTap: () {
                    close();
                    setState(() {
                      _bottomIndex = 3;
                    });
                  },
                ),
                _DrawerItem(
                  icon: Icons.description_outlined,
                  label: l.termsAndConditions,
                  onTap: () => push(const TermsScreen()),
                ),
                _DrawerItem(
                  icon: Icons.support_agent_outlined,
                  label: l.contactSupport,
                  onTap: () {
                    close();
                    showSupportSheet(context, userData: _userData);
                  },
                ),
              ],
            ),
          ),

          // ── Logout / Login ───────────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          if (_isLoggedIn)
            _DrawerItem(
              icon: Icons.logout,
              label: l.logout,
              color: Colors.red.shade600,
              onTap: () {
                close();
                _logout();
              },
            )
          else
            _DrawerItem(
              icon: Icons.login,
              label: l.signIn,
              color: Apptheme.bluecolor,
              onTap: () => push(const LoginScreen()),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Merchant card ─────────────────────────────────────────────────────────────

class _MerchantCard extends StatelessWidget {
  final _Merchant merchant;
  final String? distance;
  final VoidCallback? onTap;
  const _MerchantCard({required this.merchant, this.distance, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final offerCount = merchant.offers.length;
    final baseSubtitle =
        '${merchant.categoryDisplay} · $offerCount offer${offerCount != 1 ? 's' : ''} available';
    final subtitle = distance != null
        ? '$baseSubtitle · $distance'
        : baseSubtitle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badge
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: merchant.firstImage != null
                        ? CachedNetworkImage(
                            imageUrl: merchant.firstImage!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _imagePlaceholder(),
                            errorWidget: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  if (merchant.firstDiscount(isEn) != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          merchant.firstDiscount(isEn)!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.name(isEn),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ...List.generate(5, (i) {
                          final rating = merchant.avgRating ?? 4.5;
                          if (i < rating.floor()) {
                            return const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 13,
                            );
                          } else if (i < rating) {
                            return const Icon(
                              Icons.star_half,
                              color: Colors.amber,
                              size: 13,
                            );
                          } else {
                            return const Icon(
                              Icons.star_border,
                              color: Colors.amber,
                              size: 13,
                            );
                          }
                        }),
                        const SizedBox(width: 4),
                        Text(
                          merchant.avgRating != null
                              ? merchant.avgRating!.toStringAsFixed(1)
                              : '4.5',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (merchant.ratingCount != null)
                          Text(
                            ' (${merchant.ratingCount})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
    ),
  );
}

// ── search tab ───────────────────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  const _SearchTab({super.key});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _searchController = TextEditingController();
  String _query = '';
  int _selectedCategoryIndex = 0;

  List<_Category> _categories = [];
  List<_Merchant> _merchants = [];
  bool _loading = true;

  final _api = ApiService();

  void _updateMerchant(int merchantId, Map<String, dynamic> newData) {
    setState(() {
      _merchants = _merchants.map((m) {
        if (m.id == merchantId) {
          final updatedRawJson = {...m.rawJson}..addAll(newData);
          return _Merchant.fromJson(updatedRawJson);
        }
        return m;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(
      () =>
          setState(() => _query = _searchController.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final cats = await _api.getCategories();
      final mchData = await _api.getMerchants();
      if (!mounted) return;
      setState(() {
        _categories = cats
            .map((c) => _Category.fromJson(c as Map<String, dynamic>))
            .toList();
        _merchants = (mchData['merchants'] as List)
            .map((m) => _Merchant.fromJson(m as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Merchant> get _filtered {
    var list = _merchants;
    if (_selectedCategoryIndex != 0) {
      final slug = _categories[_selectedCategoryIndex - 1].slug;
      final catKey = slug.replaceAll('-', '_').toUpperCase();
      list = list.where((m) => m.category == catKey).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
            (m) =>
                m.nameEn.toLowerCase().contains(_query) ||
                m.nameHr.toLowerCase().contains(_query) ||
                m.categoryDisplay.toLowerCase().contains(_query) ||
                m.cityEn.toLowerCase().contains(_query) ||
                m.cityHr.toLowerCase().contains(_query) ||
                m.offers.any(
                  (o) =>
                      o.titleEn.toLowerCase().contains(_query) ||
                      o.titleHr.toLowerCase().contains(_query),
                ),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final filtered = _filtered;
    final hasQuery = _query.isNotEmpty;
    final isEn = context.watch<LocaleProvider>().isEnglish;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Blue header ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            color: Apptheme.bluecolor,
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, i) {
                      final isSelected = i == _selectedCategoryIndex;
                      final label = i == 0
                          ? l.allCategory
                          : _categories[i - 1].name(isEn);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryIndex = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Apptheme.bluecolor
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          hasQuery
                              ? l.searchResultsLabel(filtered.length)
                              : l.allVenuesLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  l.noResultsFound,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) => _SearchCard(
                                    merchant: filtered[i],
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MerchantDetailScreen(
                                          merchantData: filtered[i].rawJson,
                                          onMerchantUpdated: (newData) {
                                            _updateMerchant(
                                              filtered[i].id,
                                              newData,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
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
}

// ── Search result card ────────────────────────────────────────────────────────

class _SearchCard extends StatefulWidget {
  final _Merchant merchant;
  final VoidCallback onTap;

  const _SearchCard({required this.merchant, required this.onTap});

  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard> {
  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final offerCount = widget.merchant.offers.length;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + overlays
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: widget.merchant.firstImage != null
                        ? CachedNetworkImage(
                            imageUrl: widget.merchant.firstImage!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _placeholder(),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  // Offer badge — top left
                  if (widget.merchant.firstDiscount(isEn) != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.merchant.firstDiscount(isEn)!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  // City badge — top right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.merchant.city(isEn),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.merchant.name(isEn),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.merchant.categoryDisplay} · $offerCount offer${offerCount != 1 ? 's' : ''} available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Star rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ...List.generate(5, (i) {
                          final rating = widget.merchant.avgRating ?? 4.5;
                          if (i < rating.floor()) {
                            return const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 13,
                            );
                          } else if (i < rating) {
                            return const Icon(
                              Icons.star_half,
                              color: Colors.amber,
                              size: 13,
                            );
                          } else {
                            return const Icon(
                              Icons.star_border,
                              color: Colors.amber,
                              size: 13,
                            );
                          }
                        }),
                        const SizedBox(width: 4),
                        Text(
                          widget.merchant.avgRating != null
                              ? widget.merchant.avgRating!.toStringAsFixed(1)
                              : '4.5',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (widget.merchant.ratingCount != null)
                          Text(
                            ' (${widget.merchant.ratingCount})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.restaurant, size: 40, color: Colors.grey),
    ),
  );
}

// ── Nearby tab ────────────────────────────────────────────────────────────────

enum _LocationStatus { loading, denied, serviceDisabled, ready }

class _NearbyTab extends StatefulWidget {
  const _NearbyTab();

  @override
  State<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<_NearbyTab> {
  _LocationStatus _status = _LocationStatus.loading;
  Position? _position;
  List<_Merchant> _merchants = [];
  bool _loadingMerchants = true;

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadMerchants(), _requestLocation()]);
  }

  Future<void> _loadMerchants() async {
    try {
      final data = await _api.getMerchants();
      if (!mounted) return;
      setState(() {
        _merchants = (data['merchants'] as List)
            .map((m) => _Merchant.fromJson(m as Map<String, dynamic>))
            .toList();
        _loadingMerchants = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMerchants = false);
    }
  }

  Future<void> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _status = _LocationStatus.serviceDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _status = _LocationStatus.denied);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted)
        setState(() {
          _position = pos;
          _status = _LocationStatus.ready;
        });
    } catch (_) {
      if (mounted) setState(() => _status = _LocationStatus.denied);
    }
  }

  List<({_Merchant merchant, double distanceM})> get _sortedMerchants {
    if (_position == null) return [];
    final withDist =
        _merchants
            .where((m) => m.lat != null && m.lon != null)
            .map(
              (m) => (
                merchant: m,
                distanceM: Geolocator.distanceBetween(
                  _position!.latitude,
                  _position!.longitude,
                  m.lat!,
                  m.lon!,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return withDist;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final sorted = _sortedMerchants;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Apptheme.bluecolor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.near_me, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  l.nearbyTab,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (_status == _LocationStatus.ready)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l.nearbyCount(sorted.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Expanded(child: _buildNearbyBody(sorted, l)),
        ],
      ),
    );
  }

  Widget _buildNearbyBody(
    List<({_Merchant merchant, double distanceM})> sorted,
    AppStrings l,
  ) {
    if (_status == _LocationStatus.loading || _loadingMerchants) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == _LocationStatus.serviceDisabled) {
      return _PermissionPrompt(
        icon: Icons.location_off_outlined,
        title: l.locationServicesOff,
        subtitle: l.enableLocationServices,
        buttonLabel: l.openSettings,
        onTap: () => Geolocator.openLocationSettings(),
      );
    }

    if (_status == _LocationStatus.denied) {
      return _PermissionPrompt(
        icon: Icons.location_disabled_outlined,
        title: l.locationAccessNeeded,
        subtitle: l.allowLocationAccess,
        buttonLabel: l.grantPermission,
        onTap: () async {
          final perm = await Geolocator.requestPermission();
          if (perm == LocationPermission.deniedForever) {
            await Geolocator.openAppSettings();
          } else {
            await _requestLocation();
          }
        },
      );
    }

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _merchants.isEmpty
                ? l.noVenuesAvailable
                : l.venueLocationsUnavailable,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _init,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final item = sorted[i];
          return _NearbyCard(
            merchant: item.merchant,
            distance: _formatDistance(item.distanceM),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MerchantDetailScreen(merchantData: item.merchant.rawJson),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Permission prompt ─────────────────────────────────────────────────────────

class _PermissionPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _PermissionPrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Apptheme.bluecolor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Apptheme.bluecolor, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Apptheme.bluecolor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby card ───────────────────────────────────────────────────────────────

class _NearbyCard extends StatelessWidget {
  final _Merchant merchant;
  final String distance;
  final VoidCallback onTap;

  const _NearbyCard({
    required this.merchant,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LocaleProvider>().isEnglish;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: merchant.firstImage != null
                    ? CachedNetworkImage(
                        imageUrl: merchant.firstImage!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name(isEn),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${merchant.categoryDisplay} · ${merchant.address(isEn)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Badge(
                          icon: Icons.near_me,
                          label: distance,
                          bgColor: Apptheme.bluecolor.withOpacity(0.1),
                          textColor: Apptheme.bluecolor,
                        ),
                        if (merchant.firstDiscount(isEn) != null) ...[
                          const SizedBox(width: 6),
                          _Badge(
                            label: merchant.firstDiscount(isEn)!,
                            bgColor: Colors.orange.shade50,
                            textColor: Colors.orange.shade700,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.restaurant, size: 32, color: Colors.grey),
    ),
  );
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Badge({
    this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer item ───────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black87;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  final List<_Category> categories;
  final List<_Merchant> merchants;
  const CategoriesScreen({
    super.key,
    required this.categories,
    required this.merchants,
  });

  // Pastel background colors for emoji icons
  static const List<Color> _emojiBackgrounds = [
    Color(0xFFFFF3E0), // light orange
    Color(0xFFFCE4EC), // light pink
    Color(0xFFE8EAF6), // light indigo
    Color(0xFFE0F2F1), // light teal
    Color(0xFFF3E5F5), // light purple
    Color(0xFFE8F5E9), // light green
    Color(0xFFFFF9C4), // light yellow
    Color(0xFFE1F5FE), // light blue
  ];

  int _countForCategory(_Category cat) {
    final catKey = cat.slug.replaceAll('-', '_').toUpperCase();
    return merchants.where((m) => m.category == catKey).length;
  }

  @override
  Widget build(BuildContext context) {
    // Featured category is the first one
    final featured = categories.isNotEmpty ? categories[0] : null;
    final featuredCount = featured != null ? _countForCategory(featured) : 0;
    final isEn = context.watch<LocaleProvider>().isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Blue header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Apptheme.bluecolor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Browse by type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  // ── Featured banner ─────────────────────────────
                  if (featured != null)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, 1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF5A623), Color(0xFFFFBB47)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF5A623,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    featured.name(isEn),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$featuredCount places available',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (featured.image != null &&
                                featured.image!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: featured.image!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, error, stackTrace) =>
                                      Text(
                                        featured.emoji,
                                        style: const TextStyle(fontSize: 48),
                                      ),
                                ),
                              )
                            else
                              Text(
                                featured.emoji,
                                style: const TextStyle(fontSize: 48),
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Category grid ───────────────────────────────
                  _buildCategoryGrid(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    // Skip the first category (it's the featured one)
    final gridCategories = categories.length > 1
        ? categories.sublist(1)
        : <_Category>[];
    final isOdd = gridCategories.length.isOdd;
    final pairedCount = isOdd
        ? gridCategories.length - 1
        : gridCategories.length;

    final List<Widget> rows = [];

    // Build paired rows (2 cards per row)
    for (int i = 0; i < pairedCount; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildCategoryCard(context, gridCategories[i], i + 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  context,
                  gridCategories[i + 1],
                  i + 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build full-width last card if odd
    if (isOdd) {
      final lastCat = gridCategories.last;
      final lastIndex =
          gridCategories.length; // already offset by 1 for featured
      final count = _countForCategory(lastCat);
      final isEn = context.watch<LocaleProvider>().isEnglish;

      rows.add(
        GestureDetector(
          onTap: () => Navigator.pop(context, lastIndex + 1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (lastCat.image != null && lastCat.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: lastCat.image!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              _emojiBackgrounds[lastIndex %
                                  _emojiBackgrounds.length],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          lastCat.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          _emojiBackgrounds[lastIndex %
                              _emojiBackgrounds.length],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      lastCat.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastCat.name(isEn),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count places',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildCategoryCard(
    BuildContext context,
    _Category cat,
    int gridIndex,
  ) {
    final count = _countForCategory(cat);
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final bgColor = _emojiBackgrounds[gridIndex % _emojiBackgrounds.length];

    return GestureDetector(
      onTap: () =>
          Navigator.pop(context, gridIndex + 1), // +1 because 0 is "All"
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cat.image != null && cat.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: cat.image!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
              ),
            const SizedBox(height: 12),
            Text(
              cat.name(isEn),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count places',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
