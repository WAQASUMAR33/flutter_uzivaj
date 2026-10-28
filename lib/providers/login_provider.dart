import 'package:flutter/material.dart';
import '/services/authService.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';

class LoginProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final UserStorageService _storage = UserStorageService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Email/password uses the custom API only — not Firebase
      final userData = await _apiService.login(email: email, password: password);

      if (userData['isActive'] == false) {
        _error = 'your account has been suspended contact admin team';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _storage.saveUser(userData);
      _user = userData;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      if (err.contains('Failed to fetch') || err.contains('ClientException')) {
        _error = 'Unable to connect to server. Please check network connection or SSL certificate.';
      } else {
        _error = err;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (_) {}
    await _storage.clearUser();
    _user = null;
    notifyListeners();
  }
}
