import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/services/userStorageService.dart';
import '/services/apiService.dart';
import '/screens/subscription_screen.dart';
import '/screens/payment_success_screen.dart';
import 'package:provider/provider.dart';
import '/providers/locale_provider.dart';
import '/l10n/app_strings.dart';

class OrderSummaryScreen extends StatefulWidget {
  final SubscriptionPackage package;

  const OrderSummaryScreen({super.key, required this.package});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  Map<String, dynamic>? _user;
  bool _isProcessing = false;

  // ── Promo code state ─────────────────────────────────────────────────────
  final _promoController = TextEditingController();
  Map<String, dynamic>? _promoData;
  String? _promoError;
  bool _isValidatingPromo = false;
  bool _isPromoExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserStorageService().getUser();
    if (mounted) setState(() => _user = user);
  }

  // ── Promo code helpers ───────────────────────────────────────────────────

  double get _basePrice => widget.package.priceYearly;

  double get _effectiveBase =>
      _promoData != null
          ? (_promoData!['finalAmount'] as num).toDouble()
          : _basePrice;

  double get _discountAmount =>
      _promoData != null
          ? (_promoData!['discountAmount'] as num).toDouble()
          : 0.0;

  double get _vat => _effectiveBase * 0.25;

  double get _total => _effectiveBase + _vat;

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final result = await ApiService().validatePromoCode(
        code: code,
        amount: _basePrice,
      );

      if (!mounted) return;

      if (result['valid'] == true) {
        setState(() {
          _promoData = result;
          _promoError = null;
          _isValidatingPromo = false;
        });
      } else {
        setState(() {
          _promoData = null;
          _promoError =
              result['message']?.toString() ??
              AppStrings.of(context).invalidPromoCode;
          _isValidatingPromo = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _promoData = null;
        _promoError = e.toString().replaceAll('Exception: ', '');
        _isValidatingPromo = false;
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _promoData = null;
      _promoError = null;
      _promoController.clear();
    });
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final pkg = widget.package;
      final total = _total;
      final isEn = Provider.of<LocaleProvider>(context, listen: false).isEnglish;
      final customerId =
          ((_user?['id'] ?? _user?['customerId'] ?? 0) as num).toInt();

      // Block buying a package the account already holds (before charging).
      try {
        final status =
            await ApiService().getSubscriptionStatus(customerId: customerId);
        final ownedPkgId =
            ((status['subscriptionPackage'] as Map<String, dynamic>?)?['id']
                    as num?)
                ?.toInt();
        if (status['subscribed'] == true && ownedPkgId == pkg.id) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'You already have an active subscription for this plan.'),
              backgroundColor: Colors.red.shade600,
            ),
          );
          return;
        }
      } catch (_) {
        // Status check failed — the server remains the final gate.
      }

      // Simulate Stripe payment processing delay
      await Future.delayed(const Duration(milliseconds: 1800));

      final paymentRef = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
      final platform = _detectPlatform();

      final subscription = await ApiService().createSubscription(
        customerId: customerId,
        subscriptionPackageId: pkg.id,
        plan: 'ANNUAL',
        paymentRef: paymentRef,
        platform: platform,
        promoCode: _promoData?['code']?.toString() ?? _promoController.text.trim(),
      );

      // Persist the new subscription into the stored user so local
      // ACTIVE checks (e.g. redeem flow) pass without a re-login.
      final storage = UserStorageService();
      final storedUser = await storage.getUser();
      if (storedUser != null) {
        final subData = subscription['subscription'] is Map<String, dynamic>
            ? subscription['subscription'] as Map<String, dynamic>
            : subscription;
        storedUser['subscription'] = {
          ...subData,
          'status': subData['status']?.toString() ?? 'ACTIVE',
        };
        await storage.saveUser(storedUser);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            subscription: subscription,
            packageTitle: pkg.title(isEn),
            totalPaid: total,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LocaleProvider>().isEnglish;
    final l = AppStrings.of(context);
    final pkg = widget.package;

    final fullname = _user?['fullname'] as String? ?? '';
    final email = _user?['email'] as String? ?? '';
    final initials = _buildInitials(fullname);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ── Blue header ────────────────────────────────────────────────
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
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Review before payment',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── YOUR PLAN ──────────────────────────────────────────
                  const _SectionLabel('YOUR PLAN'),
                  const SizedBox(height: 8),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                pkg.title(isEn),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '€${_fmt(_basePrice)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Apptheme.bluecolor,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Apptheme.ambercolor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Price locked forever',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '€${_fmtDec(_basePrice / 12)}/month',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (pkg.features(isEn).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...pkg.features(isEn).map((f) => _FeatureRow(f)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── PROMO CODE ──────────────────────────────────────────
                  _buildPromoCodeSection(l),
                  const SizedBox(height: 16),

                  // ── BILLING ────────────────────────────────────────────
                  const _SectionLabel('BILLING'),
                  const SizedBox(height: 8),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BillingRow(
                          label: '${pkg.title(isEn)} membership',
                          amount: '€${_fmtDec(_basePrice)}',
                        ),

                        // ── Discount row (when promo applied) ──────────
                        if (_promoData != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 14, color: Colors.green.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.promoDiscount,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '-€${_fmtDec(_discountAmount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),
                        _BillingRow(
                          label: 'VAT (25%)',
                          amount: '€${_fmtDec(_vat)}',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Colors.grey.shade200, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total due today',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Show strikethrough original if discounted
                                if (_promoData != null)
                                  Text(
                                    '€${_fmtDec(_basePrice * 1.25)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  '€${_fmtDec(_total)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Apptheme.bluecolor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Auto-renews on the same date next year. You'll receive a reminder 30 days before. Cancel anytime in Profile → Subscription.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ACCOUNT ────────────────────────────────────────────
                  const _SectionLabel('ACCOUNT'),
                  const SizedBox(height: 8),
                  _Card(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Apptheme.ambercolor,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullname.isEmpty ? 'Account' : fullname,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Renewal reminder box ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications_outlined,
                            size: 18, color: Color(0xFFFF8F00)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                  height: 1.55),
                              children: [
                                TextSpan(
                                    text:
                                        "Your membership renews automatically each year. We'll email you "),
                                TextSpan(
                                  text: '30 days before',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                    text:
                                        ' as a reminder. You can opt out anytime in '),
                                TextSpan(
                                  text: 'Profile → Subscription',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Continue to payment button ─────────────────────────
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Apptheme.bluecolor,
                      disabledBackgroundColor:
                          Apptheme.bluecolor.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Continue to payment →',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ── Stripe trust line ──────────────────────────────────
                  const Center(
                    child: Text(
                      'Secured by Stripe · We never store your card details',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Payment method badges ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _PaymentBadge('VISA'),
                      _PaymentBadge('MC'),
                      _PaymentBadge('AMEX'),
                      _PaymentBadge('Apple Pay'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Footer label ───────────────────────────────────────
                  const Center(
                    child: Text(
                      'CHECKOUT — ORDER SUMMARY',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Promo code section builder ───────────────────────────────────────────

  Widget _buildPromoCodeSection(AppStrings l) {
    // Successfully applied → show green confirmation chip
    if (_promoData != null) {
      final discountLabel = _promoData!['discountType'] == 'PERCENTAGE'
          ? '${(_promoData!['discountValue'] as num).toInt()}% off'
          : '-€${_fmtDec((_promoData!['discountAmount'] as num).toDouble())}';
      return _Card(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.check_circle,
                  color: Colors.green.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.promoApplied,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_promoData!['code']} · $discountLabel',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _removePromoCode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l.removePromo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Not expanded → show tappable label
    if (!_isPromoExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isPromoExpanded = true),
        child: Text(
          l.havePromoCode,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Apptheme.bluecolor,
          ),
        ),
      );
    }

    // Expanded → show input field with Apply button
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: l.enterPromoCode,
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Apptheme.bluecolor, width: 1.5),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyPromoCode(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _isValidatingPromo ? null : _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Apptheme.bluecolor,
                    disabledBackgroundColor:
                        Apptheme.bluecolor.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  child: _isValidatingPromo
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l.applyPromo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Error message
          if (_promoError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _promoError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _fmtDec(double v) => v.toStringAsFixed(2);
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final String amount;

  const _BillingRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        Text(amount,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 12.5, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String label;
  const _PaymentBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}
