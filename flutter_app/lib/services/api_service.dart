// lib/services/api_service.dart — Service HTTP vers l'API REST
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compte.dart';
import '../models/transaction.dart';
import '../models/user.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000';
  // Remplacez par l'URL de votre serveur en production
  //static const String _baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String _baseUrl = 'http://localhost:3000'; // iOS simulator
  // static const String _baseUrl = 'https://api.finflow.io'; // Production

  static const Duration _timeout = Duration(seconds: 15);

  // ============================================================
  //  Authentification — POST /api/auth/login
  // ============================================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'token': data['token'] as String,
          'user': User.fromJson(data['user'] as Map<String, dynamic>),
        };
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: data['error'] as String? ?? 'Erreur de connexion',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de joindre le serveur. Vérifiez votre connexion.',
      );
    }
  }

  // ============================================================
  //  Comptes — GET /api/accounts/:userId
  // ============================================================
  Future<List<Compte>> fetchComptes(String userId, String token) async {
    final uri = Uri.parse('$_baseUrl/api/accounts/$userId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final comptesList = data['comptes'] as List<dynamic>;
        return comptesList
            .map((j) => Compte.fromJson(j as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw ApiException(statusCode: 401, message: 'Session expirée. Reconnectez-vous.');
      } else {
        throw ApiException(statusCode: response.statusCode, message: 'Erreur serveur (500).');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Erreur réseau. Réessayez.');
    }
  }

  // ============================================================
  //  Transactions — GET /api/accounts/:userId/transactions
  // ============================================================
  Future<List<Transaction>> fetchTransactions(
      String userId, String token, {int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/api/accounts/$userId/transactions?limit=$limit');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final txList = data['transactions'] as List<dynamic>;
        return txList
            .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw ApiException(statusCode: 401, message: 'Session expirée.');
      } else {
        throw ApiException(statusCode: response.statusCode, message: 'Erreur serveur.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Erreur réseau.');
    }
  }

  // ============================================================
  //  Virement — POST /api/accounts/transfer
  // ============================================================
  Future<void> effectuerVirement({
    required int compteSourceId,
    required int compteDestId,
    required double montant,
    required String token,
    String? motif,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/accounts/transfer');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'compteSourceId': compteSourceId,
        'compteDestId': compteDestId,
        'montant': montant,
        'motif': motif ?? 'Virement',
      }),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: response.statusCode,
        message: data['error'] as String? ?? 'Erreur lors du virement',
      );
    }
  }
}

// ============================================================
//  Exception personnalisée
// ============================================================
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isServerError   => statusCode >= 500;
  bool get isNetworkError  => statusCode == 0;
}