import 'dart:math';
import 'package:flutter/material.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';

class SignupProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final UserStorageService _storage = UserStorageService();

  String _selectedGender = '';
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _error;

  String get selectedGender => _selectedGender;
  bool get agreedToTerms => _agreedToTerms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void toggleTerms(bool? value) {
    if (value != null) {
      _agreedToTerms = value;
      notifyListeners();
    }
  }

  String _generateUid() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final rnd = Random.secure();
    return List.generate(28, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<bool> register({
    required String fullname,
    required String email,
    required String password,
    required String phoneNumber,
    required String nationality,
    required String dateOfBirth,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _generateUid();

      await _apiService.register(
        fullname: fullname,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        gender: _selectedGender.toLowerCase(),
        uid: uid,
      );

      // Clear any cached session; user needs to verify email or log in
      await _storage.clearUser();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      if (err.contains('Failed to fetch') ||
          err.contains('ClientException') ||
          err.contains('HandshakeException')) {
        _error =
            'Unable to connect to server. Please check your network connection.';
      } else {
        _error = err;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
