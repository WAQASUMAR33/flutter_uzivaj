import 'package:flutter/material.dart';
import '/theme/app_theme.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';
import '/l10n/app_strings.dart';

class PinEntryScreen extends StatefulWidget {
  final String merchantName;
  final String offerTitle;
  final int merchantId;
  final int offerId;
  final Function(Map<String, dynamic>)? onReviewSubmitted;

  const PinEntryScreen({
    super.key,
    required this.merchantName,
    required this.offerTitle,
    required this.merchantId,
    required this.offerId,
    this.onReviewSubmitted,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final ApiService _apiService = ApiService();
  final UserStorageService _storage = UserStorageService();

  String _pin = '';
  bool _isVerifying = false;
  String? _errorMessage;
  static const int _pinLength = 4;

  void _onKeyPressed(String value) {
    if (_isVerifying) return;
    if (value == 'backspace') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _errorMessage = null;
        });
      }
    } else if (_pin.length < _pinLength) {
      setState(() {
        _pin += value;
        _errorMessage = null;
      });
      if (_pin.length == _pinLength) {
        _verifyAndRedeem();
      }
    }
  }

  Future<void> _verifyAndRedeem() async {
    setState(() => _isVerifying = true);
    try {
      final status = await _apiService.verifyMerchantCode(
        merchantId: widget.merchantId,
        merchantCode: _pin,
      );
      if (status != 'valid') {
        _showInvalidCode();
        return;
      }

      final customer = await _storage.getUser();
      final customerId = customer?['id'] as int?;
      if (customerId == null) {
        _showInvalidCode();
        return;
      }

      await _apiService.redeemOffer(
        customerId: customerId,
        offerId: widget.offerId,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OfferRedeemedScreen(
            merchantName: widget.merchantName,
            offerTitle: widget.offerTitle,
            merchantId: widget.merchantId,
            onReviewSubmitted: widget.onReviewSubmitted,
          ),
        ),
      );
    } catch (_) {
      _showInvalidCode();
    }
  }

  void _showInvalidCode() {
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _pin = '';
      _errorMessage = AppStrings.of(context).codeIsInvalid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(color: Apptheme.bluecolor),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(context).redeemingAt,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.merchantName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.offerTitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.of(context).waiterEntersPin,
                      style: TextStyle(
                        color: Apptheme.blackcolor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.of(context).handPhoneToWaiter,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Apptheme.blackcolor.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pinLength, (index) {
                        final isFilled = index < _pin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isFilled
                                ? Colors.white
                                : Apptheme.offwhitecolor,
                            border: Border.all(
                              color: isFilled
                                  ? Apptheme.bluecolor
                                  : Apptheme.blackcolor.withValues(alpha: 0.15),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isFilled
                              ? Center(
                                  child: Icon(
                                    Icons.circle,
                                    color: Apptheme.bluecolor,
                                    size: 12,
                                  ),
                                )
                              : null,
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 24,
                      child: _isVerifying
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Apptheme.bluecolor,
                              ),
                            )
                          : _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _buildKeypadRow(['1', '2', '3']),
                          const SizedBox(height: 12),
                          _buildKeypadRow(['4', '5', '6']),
                          const SizedBox(height: 12),
                          _buildKeypadRow(['7', '8', '9']),
                          const SizedBox(height: 12),
                          _buildKeypadRow(['', '0', 'backspace']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          if (key.isEmpty) {
            return const SizedBox(width: 80, height: 80);
          }
          return _buildKey(key);
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String value) {
    final isBackspace = value == 'backspace';
    return GestureDetector(
      onTap: () => _onKeyPressed(value),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Apptheme.offwhitecolor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: Apptheme.blackcolor,
                  size: 24,
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: Apptheme.blackcolor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }
}

class OfferRedeemedScreen extends StatefulWidget {
  final String merchantName;
  final String offerTitle;
  final int merchantId;
  final Function(Map<String, dynamic>)? onReviewSubmitted;

  const OfferRedeemedScreen({
    super.key,
    required this.merchantName,
    required this.offerTitle,
    required this.merchantId,
    this.onReviewSubmitted,
  });

  @override
  State<OfferRedeemedScreen> createState() => _OfferRedeemedScreenState();
}

class _OfferRedeemedScreenState extends State<OfferRedeemedScreen> {
  final ApiService _apiService = ApiService();
  final UserStorageService _storage = UserStorageService();
  bool _showRatingModal = true;
  int _selectedRating = 5;
  String? _selectedReview;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  double? _updatedAvgRating;
  int? _updatedRatingCount;

  static const List<String> _validReviews = [
    'Amazing!',
    'Great!',
    'Good',
    'Okay',
    'Not great',
  ];

  Future<void> _submitRating() async {
    if (_selectedReview == null) return;

    final customer = await _storage.getUser();
    if (customer == null) return;

    final customerId = customer['id'] as int?;
    if (customerId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _apiService.rateMerchant(
        customerId: customerId,
        merchantId: widget.merchantId,
        rating: _selectedRating,
        review: _selectedReview!,
      );
      setState(() {
        _hasSubmitted = true;
        _updatedAvgRating = (response['avgRating'] as num?)?.toDouble();
        _updatedRatingCount = response['ratingCount'] as int?;
      });
      if (_updatedAvgRating != null && _updatedRatingCount != null) {
        widget.onReviewSubmitted?.call({
          'avgRating': _updatedAvgRating,
          'ratingCount': _updatedRatingCount,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      4,
      (index) => chars[(index * 11) % chars.length],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: const BoxDecoration(color: Apptheme.bluecolor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(context).redeemedAt,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.merchantName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F9E6),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              color: Color(0xFF4CAF50),
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.of(context).offerRedeemed,
                          style: TextStyle(
                            color: Apptheme.blackcolor,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.offerTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Apptheme.blackcolor.withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.merchantName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Apptheme.blackcolor.withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Apptheme.offwhitecolor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppStrings.of(context).merchantRecordCode,
                                style: TextStyle(
                                  color: Apptheme.blackcolor.withValues(
                                    alpha: 0.35,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _generateRandomCode(),
                                style: TextStyle(
                                  color: Apptheme.bluecolor,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.of(context).waiterWritesThis,
                                style: TextStyle(
                                  color: Apptheme.blackcolor.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Apptheme.bluecolor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppStrings.of(context).doneBtn,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showRatingModal) _buildRatingModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingModal() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_hasSubmitted) ...[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.of(context).rateYourExperience,
                style: TextStyle(
                  color: Apptheme.blackcolor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.star,
                        size: 36,
                        color: starIndex <= _selectedRating
                            ? Colors.amber
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 120,
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: _validReviews.map((review) {
                    final isSelected = _selectedReview == review;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReview = review),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Apptheme.bluecolor.withValues(alpha: 0.1)
                              : Apptheme.offwhitecolor,
                          border: Border.all(
                            color: isSelected
                                ? Apptheme.bluecolor
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            review,
                            style: TextStyle(
                              color: isSelected
                                  ? Apptheme.bluecolor
                                  : Apptheme.blackcolor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showRatingModal = false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppStrings.of(context).skipBtn,
                        style: TextStyle(
                          color: Apptheme.blackcolor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReview == null || _isSubmitting
                          ? null
                          : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Apptheme.bluecolor,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppStrings.of(context).submitBtn,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text(
                'Thank you for your feedback!',
                style: TextStyle(
                  color: Apptheme.blackcolor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              if (_updatedAvgRating != null && _updatedRatingCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Apptheme.offwhitecolor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _updatedAvgRating!.toStringAsFixed(1),
                        style: TextStyle(
                          color: Apptheme.blackcolor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($_updatedRatingCount reviews)',
                        style: TextStyle(
                          color: Apptheme.blackcolor.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _showRatingModal = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Apptheme.bluecolor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
