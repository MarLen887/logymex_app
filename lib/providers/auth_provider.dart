import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> authenticate(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final bool success = await _authService.login(username, password);
    
    _isAuthenticated = success;
    _isLoading = false;
    notifyListeners();

    return success;
  }

  Future<void> signSignOut() async {
    await _authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}