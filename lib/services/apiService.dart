import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '/utils/navigator_key.dart';

const String _baseUrl = 'https://uzivajlife.online';

String get _devBaseUrl {
  if (kIsWeb) return 'http://localhost:3001';
  if (Platform.isAndroid) return 'http://10.0.2.2:3001';
  return 'http://localhost:3001';
}

class ApiService {
  Future<List<dynamic>> getCategories() async {
    final response = await _Http.get(Uri.parse('$_baseUrl/api/categories'));
    if (response.statusCode == 200) return jsonDecode(response.body) as List<dynamic>;
    throw const ApiException('Failed to load categories');
  }

  Future<Map<String, dynamic>> getMerchants({int? customerId}) async {
    final uri = customerId != null
        ? Uri.parse('$_baseUrl/api/merchants?customerId=$customerId')
        : Uri.parse('$_baseUrl/api/merchants');
    final response = await _Http.get(uri);
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw const ApiException('Failed to load merchants');
  }

  Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
    required String phoneNumber,
    required String nationality,
    required String dateOfBirth,
    required String gender,
    required String uid,
    String imageUrl = '',
    String logType = 'email',
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullname': fullname,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'nationality': nationality,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'imageUrl': imageUrl,
        'uid': uid,
        'logType': logType,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['message']?.toString() ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> getTermsAndConditions() async {
    final response = await _Http.get(Uri.parse('$_baseUrl/api/terms'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw const ApiException('Failed to load terms and conditions');
  }

  Future<Map<String, dynamic>> getRedeemHistory({
    required int customerId,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/redemptions/history'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data;
    throw ApiException(
        data['message']?.toString() ?? 'Failed to load redeem history');
  }

  Future<Map<String, dynamic>> checkEmail(String email) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/check-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data;
    throw ApiException(data['message']?.toString() ?? 'Failed to check email');
  }

  Future<Map<String, dynamic>> createSocialAccount({
    required String uid,
    required String email,
    required String logType,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'email': email, 'logType': logType}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['message']?.toString() ?? 'Failed to create account');
  }

  Future<Map<String, dynamic>> socialLogin({
    required String uid,
    required String email,
    required String fullname,
    required String logType,
    String imageUrl = '',
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/social-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'email': email,
        'fullname': fullname,
        'imageUrl': imageUrl,
        'logType': logType,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['error']?.toString() ?? 'Social login failed');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data;
    throw ApiException(data['error']?.toString() ?? data['message']?.toString() ?? 'Login failed');
  }

  Future<Map<String, dynamic>> getSubscriptionStatus({
    required int customerId,
  }) async {
    http.Response response;
    try {
      response = await _Http.post(
        Uri.parse('$_baseUrl/api/subscriptions/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customerId': customerId}),
        checkInternet: false,
      );
      if (response.statusCode == 404) {
        response = await _Http.post(
          Uri.parse('$_devBaseUrl/api/subscriptions/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'customerId': customerId}),
        );
      }
    } catch (_) {
      response = await _Http.post(
        Uri.parse('$_devBaseUrl/api/subscriptions/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customerId': customerId}),
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data;
    throw ApiException(data['message']?.toString() ?? 'Failed to load subscription status');
  }

  Future<Map<String, dynamic>> createSubscription({
    required int customerId,
    required int subscriptionPackageId,
    required String plan,
    required String paymentRef,
    required String platform,
    String? promoCode,
  }) async {
    final bodyMap = <String, dynamic>{
      'customerId': customerId,
      'subscriptionPackageId': subscriptionPackageId,
      'plan': plan,
      'paymentRef': paymentRef,
      'platform': platform,
    };
    if (promoCode != null && promoCode.trim().isNotEmpty) {
      bodyMap['promoCode'] = promoCode.trim();
      bodyMap['coupon'] = promoCode.trim();
    }

    http.Response response;
    try {
      response = await _Http.post(
        Uri.parse('$_baseUrl/api/subscriptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
        checkInternet: false,
      );
      if (response.statusCode == 404) {
        response = await _Http.post(
          Uri.parse('$_devBaseUrl/api/subscriptions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyMap),
        );
      }
    } catch (_) {
      response = await _Http.post(
        Uri.parse('$_devBaseUrl/api/subscriptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['message']?.toString() ?? 'Subscription failed');
  }

  Future<Map<String, dynamic>> createStripePaymentIntent({
    required int customerId,
    required String plan,
    int? subscriptionPackageId,
    String? promoCode,
  }) async {
    final bodyMap = <String, dynamic>{
      'customerId': customerId,
      'plan': plan,
      if (subscriptionPackageId != null) 'subscriptionPackageId': subscriptionPackageId,
      if (promoCode != null && promoCode.trim().isNotEmpty) 'promoCode': promoCode.trim(),
    };

    http.Response response;
    try {
      response = await _Http.post(
        Uri.parse('$_baseUrl/api/stripe/payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
        checkInternet: false,
      );
      if (response.statusCode == 404) {
        response = await _Http.post(
          Uri.parse('$_devBaseUrl/api/stripe/payment-intent'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyMap),
        );
      }
    } catch (_) {
      response = await _Http.post(
        Uri.parse('$_devBaseUrl/api/stripe/payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ApiException(data['error']?.toString() ?? data['message']?.toString() ?? 'Failed to initialize payment');
  }

  Future<Map<String, dynamic>> createStripeCheckoutSession({
    required int customerId,
    required String plan,
    int? subscriptionPackageId,
    String? promoCode,
    String? customerEmail,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final bodyMap = <String, dynamic>{
      'customerId': customerId,
      'plan': plan,
      if (customerEmail != null && customerEmail.isNotEmpty) 'customerEmail': customerEmail,
      if (subscriptionPackageId != null) 'subscriptionPackageId': subscriptionPackageId,
      if (promoCode != null && promoCode.trim().isNotEmpty) 'promoCode': promoCode.trim(),
      if (successUrl != null) 'successUrl': successUrl,
      if (cancelUrl != null) 'cancelUrl': cancelUrl,
    };

    http.Response response;
    try {
      response = await _Http.post(
        Uri.parse('$_baseUrl/api/stripe/checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
        checkInternet: false,
      );
      if (response.statusCode == 404) {
        response = await _Http.post(
          Uri.parse('$_devBaseUrl/api/stripe/checkout-session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(bodyMap),
        );
      }
    } catch (_) {
      response = await _Http.post(
        Uri.parse('$_devBaseUrl/api/stripe/checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw ApiException(data['error']?.toString() ?? data['message']?.toString() ?? 'Failed to initialize checkout session');
  }

  Future<Map<String, dynamic>> updateProfile({
    required int id,
    required String fullname,
    required String phoneNumber,
    required String nationality,
    required String dateOfBirth,
    required String gender,
    String imageUrl = '',
  }) async {
    final response = await _Http.put(
      Uri.parse('$_baseUrl/api/customers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'fullname': fullname,
        'phoneNumber': phoneNumber,
        'nationality': nationality,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'imageUrl': imageUrl,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['message']?.toString() ?? 'Failed to update profile');
  }

  Future<String> verifyMerchantCode({
    required int merchantId,
    required String merchantCode,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/merchants/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'merchantId': merchantId, 'merchantCode': merchantCode}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data['status']?.toString() ?? 'invalid';
    throw ApiException(data['message']?.toString() ?? 'Failed to verify code');
  }

  Future<Map<String, dynamic>> redeemOffer({
    required int customerId,
    required int offerId,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/redemptions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId, 'offerId': offerId}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['message']?.toString() ?? 'Failed to redeem offer');
  }

  Future<Map<String, dynamic>> rateMerchant({
    required int customerId,
    required int merchantId,
    required int rating,
    required String review,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/merchants/rate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'merchantId': merchantId,
        'rating': rating,
        'review': review,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['message']?.toString() ?? 'Failed to submit rating');
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['error']?.toString() ?? data['message']?.toString() ?? 'Failed to send reset link');
  }

  Future<Map<String, dynamic>> verifyCode({required String email, required String code}) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['error']?.toString() ?? data['message']?.toString() ?? 'Invalid or expired verification link/code');
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/customers/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(data['error']?.toString() ?? data['message']?.toString() ?? 'Failed to reset password');
  }

  Future<Map<String, dynamic>> validatePromoCode({
    required String code,
    required double amount,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/promocodes/validate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'amount': amount}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return data;
    throw ApiException(
        data['message']?.toString() ?? 'Failed to validate promo code');
  }

  Future<Map<String, dynamic>> sendSupportMessage({
    required int customerId,
    required String name,
    required String email,
    required String phone,
    required String subject,
    required String message,
  }) async {
    final response = await _Http.post(
      Uri.parse('$_baseUrl/api/support'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'name': name,
        'email': email,
        'phone': phone,
        'subject': subject,
        'message': message,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) return data;
    throw ApiException(
        data['message']?.toString() ?? 'Failed to send support message');
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class _Http {
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      return await http.get(url, headers: headers);
    } catch (e) {
      _checkInternet(e);
      rethrow;
    }
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool checkInternet = true,
  }) async {
    try {
      return await http.post(url, headers: headers, body: body, encoding: encoding);
    } catch (e) {
      if (checkInternet) _checkInternet(e);
      rethrow;
    }
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    try {
      return await http.put(url, headers: headers, body: body, encoding: encoding);
    } catch (e) {
      _checkInternet(e);
      rethrow;
    }
  }

  static void _checkInternet(Object e) {
    final errStr = e.toString();
    // Do not show "No Internet" if connection was refused or trying dev/local endpoints
    if (errStr.contains('10.0.2.2') ||
        errStr.contains('localhost') ||
        errStr.contains('Connection refused')) {
      return;
    }
    if (errStr.contains('Failed host lookup') ||
        errStr.contains('Network is unreachable')) {
      showNoInternetDialog();
    }
  }
}
