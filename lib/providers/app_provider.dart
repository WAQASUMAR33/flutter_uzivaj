import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  // A simple dummy state to demonstrate Provider
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    // notifyListeners() tells all listening widgets to rebuild
    notifyListeners();
  }

  // Simulating dynamic user data for the city
  String _userCity = "Zagreb";
  String get userCity => _userCity;

  void setUserCity(String city) {
    _userCity = city;
    notifyListeners();
  }

  // Example of another state you might want to manage globally:
  // User? _currentUser;
  // User? get currentUser => _currentUser;
  // void setUser(User user) { _currentUser = user; notifyListeners(); }
}
