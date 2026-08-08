import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/authService.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final UserStorageService _storage = UserStorageService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  User? get currentUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) {
        _setLoading(false);
        return false;
      }
      final user = credential.user!;
      await _handleSocialAuth(
        uid: user.uid,
        email: user.email ?? '',
        logType: 'google',
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authService.signInWithApple();
      if (credential == null) {
        _setLoading(false);
        return false;
      }
      final user = credential.user!;
      await _handleSocialAuth(
        uid: user.uid,
        email: user.email ?? '',
        logType: 'apple',
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Checks whether the email already exists in the backend.
  /// If yes  → loads the existing customer profile and saves it to SharedPrefs.
  /// If no   → creates a minimal social account, then saves the profile.
  Future<void> _handleSocialAuth({
    required String uid,
    required String email,
    required String logType,
  }) async {
    final checkResult = await _apiService.checkEmail(email);
    final Map<String, dynamic> customerData;

    if (checkResult['exists'] == true) {
      customerData = checkResult['customer'] as Map<String, dynamic>;
    } else {
      final createResult = await _apiService.createSocialAccount(
        uid: uid,
        email: email,
        logType: logType,
      );
      customerData =
          (createResult['customer'] as Map<String, dynamic>?) ?? createResult;
    }

    if (customerData['isActive'] == false) {
      throw Exception('your account has been suspended contact admin team');
    }

    await _storage.saveUser(customerData);
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      await _storage.clearUser();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
