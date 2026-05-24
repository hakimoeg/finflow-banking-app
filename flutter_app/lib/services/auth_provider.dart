// lib/services/auth_provider.dart — Gestion d'état d'authentification
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User?   get user         => _user;
  String? get token        => _token;
  bool    get isLoading    => _isLoading;
  bool    get isLoggedIn   => _token != null && _user != null;
  String? get errorMessage => _errorMessage;

  // Charger la session depuis le stockage local
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userId  = prefs.getInt('userId');
    final nom     = prefs.getString('userName');
    final email   = prefs.getString('userEmail');

    if (_token != null && userId != null && nom != null && email != null) {
      _user = User(id: userId, nom: nom, email: email);
      notifyListeners();
    }
  }

  // Connexion
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.login(email, password);
      _token = result['token'] as String;
      _user  = result['user'] as User;

      // Sauvegarder en local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setInt('userId', _user!.id);
      await prefs.setString('userName', _user!.nom);
      await prefs.setString('userEmail', _user!.email);

      _isLoading = false;
      notifyListeners();
      return true;

    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    _user  = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}