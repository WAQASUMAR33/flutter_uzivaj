import 'package:flutter/material.dart';
import '/services/authService.dart';
import '/services/apiService.dart';
import '/services/userStorageService.dart';

class SignupProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
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
      final credential = await _authService.signUpWithEmail(email, password);
      final uid = credential.user!.uid;

      final userData = await _apiService.register(
        fullname: fullname,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        gender: _selectedGender.toLowerCase(),
        uid: uid,
      );

      await _storage.saveUser(userData);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
