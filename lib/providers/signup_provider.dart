import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
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
      String? uid;
      try {
        final credential = await _authService.signUpWithEmail(email, password);
        uid = credential.user?.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If already in Firebase Auth from a previous interrupted registration attempt, fetch existing UID
          try {
            final credential = await _authService.signInWithEmail(email, password);
            uid = credential.user?.uid;
          } catch (_) {}
        } else {
          debugPrint('Firebase signUpWithEmail notice: $e');
        }
      } catch (e) {
        debugPrint('Firebase signUpWithEmail non-fatal: $e');
      }

      await _apiService.register(
        fullname: fullname,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        gender: _selectedGender.toLowerCase(),
        uid: uid ?? '',
      );

      // Do not save user session as logged in yet; email verification is required
      try {
        await _authService.signOut();
      } catch (_) {}
      await _storage.clearUser();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      if (err.contains('Failed to fetch') || err.contains('ClientException') || err.contains('HandshakeException')) {
        _error = 'Unable to connect to server. Please check your network connection.';
      } else {
        _error = err;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
