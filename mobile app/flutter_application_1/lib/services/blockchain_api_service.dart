import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockchainApiService {
  // Use localhost for Windows/Desktop/Web, 10.0.2.2 for Android emulator
  static String get baseUrl {
    // Web and desktop always use localhost
    return 'http://localhost:3000/api';
  }

  static const Duration timeout = Duration(seconds: 30);

  /// Check if the API server is running
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cannot connect to blockchain server: $e');
    }
  }

  /// Get all registered factories
  Future<List<dynamic>> getAllFactories() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/factories'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] as List<dynamic>;
      } else {
        throw Exception('Failed to get factories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting factories: $e');
    }
  }

  /// Get factory energy status (surplus/deficit)
  Future<Map<String, dynamic>> getEnergyStatus(String factoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/factory/$factoryId/energy-status'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      } else {
        throw Exception('Failed to get energy status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting energy status: $e');
    }
  }

  /// Create an energy trade
  Future<Map<String, dynamic>> createTrade({
    required String tradeId,
    required String sellerId,
    required String buyerId,
    required double amount,
    required double pricePerUnit,
  }) async {
    try {
      final body = jsonEncode({
        'tradeId': tradeId,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'amount': amount,
        'pricePerUnit': pricePerUnit,
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/trade/create'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create trade');
      }
    } catch (e) {
      throw Exception('Error creating trade: $e');
    }
  }

  /// Execute a pending trade
  Future<Map<String, dynamic>> executeTrade(String tradeId) async {
    try {
      final body = jsonEncode({'tradeId': tradeId});

      final response = await http
          .post(
            Uri.parse('$baseUrl/trade/execute'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to execute trade');
      }
    } catch (e) {
      throw Exception('Error executing trade: $e');
    }
  }

  /// Get factory details
  Future<Map<String, dynamic>> getFactory(String factoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/factory/$factoryId'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'];
      } else {
        throw Exception('Failed to get factory: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting factory: $e');
    }
  }
}
