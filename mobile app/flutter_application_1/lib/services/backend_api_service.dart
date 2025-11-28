import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for communicating with the backend API
class BackendApiService {
  // Base URL for the backend - configurable for different environments
  // For physical devices, use the actual server IP address
  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  // For iOS simulator, localhost works
  static String _baseUrl = 'http://localhost:5000/';
  static String _baseUrl_blockchain = 'http://localhost:3000/api';
  
  /// Configure the base URL for different environments
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }
  
  /// Get the current base URL
  static String get baseUrl => _baseUrl;
  
  static const Duration timeout = Duration(seconds: 15);

  /// Health check / test endpoint
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/test'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backend test failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cannot connect to backend server: $e');
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Sign up a new factory
  Future<Map<String, dynamic>> signup({
    required String factoryName,
    required String email,
    required String password,
    required String fiscalMatricule,
    String? localisation,
    int? energyCapacity,
    String? contactInfo,
    String? energySource,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'factory_name': factoryName,
              'email': email,
              'password': password,
              'fiscal_matricule': fiscalMatricule,
              'localisation': localisation,
              'energy_capacity': energyCapacity,
              'contact_info': contactInfo,
              'energy_source': energySource,
            }),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Signup failed');
      }
    } catch (e) {
      throw Exception('Signup error: $e');
    }
  }

  // ==================== FACTORIES ====================

  /// Get all factories
  Future<List<Map<String, dynamic>>> getAllFactories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl_blockchain/factories'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get factories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting factories: $e');
    }
  }

  /// Get a single factory by ID
  Future<Map<String, dynamic>> getFactory(int factoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl_blockchain/factory/$factoryId'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to get factory: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting factory: $e');
    }
  }

  /// Update factory energy data
  Future<void> updateFactoryEnergy({
    required int factoryId,
    required double energyBalance,
    required double currentGeneration,
    required double currentConsumption,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl_blockchain/factory/$factoryId/energy'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'energy_balance': energyBalance,
              'current_generation': currentGeneration,
              'current_consumption': currentConsumption,
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to update factory energy: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating factory energy: $e');
    }
  }

  // ==================== OFFERS ====================

  /// Get all active offers
  Future<List<Map<String, dynamic>>> getAllOffers() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/offers'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get offers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting offers: $e');
    }
  }

  /// Create a new offer
  Future<Map<String, dynamic>> createOffer({
    required int factoryId,
    required String offerType, // 'buy' or 'sell'
    required double energyAmount,
    required double pricePerKwh,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/offers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'factory_id': factoryId,
              'offer_type': offerType,
              'energy_amount': energyAmount,
              'price_per_kwh': pricePerKwh,
            }),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create offer');
      }
    } catch (e) {
      throw Exception('Error creating offer: $e');
    }
  }

  /// Update offer status
  Future<void> updateOfferStatus(int offerId, String status) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/offers/$offerId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to update offer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating offer: $e');
    }
  }

  // ==================== TRADES ====================

  /// Get trades (optionally filter by factory ID)
  Future<List<Map<String, dynamic>>> getTrades({int? factoryId}) async {
    try {
      String url = '$_baseUrl/trades';
      if (factoryId != null) {
        url += '?factory_id=$factoryId';
      }
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get trades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting trades: $e');
    }
  }

  /// Create a new trade
  Future<Map<String, dynamic>> createTrade({
    required int sellerFactoryId,
    required int buyerFactoryId,
    required double energyAmount,
    required double pricePerKwh,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/trades'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'seller_factory_id': sellerFactoryId,
              'buyer_factory_id': buyerFactoryId,
              'energy_amount': energyAmount,
              'price_per_kwh': pricePerKwh,
            }),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create trade');
      }
    } catch (e) {
      throw Exception('Error creating trade: $e');
    }
  }

  /// Execute a trade
  Future<Map<String, dynamic>> executeTrade(int tradeId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/trades/$tradeId/execute'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to execute trade');
      }
    } catch (e) {
      throw Exception('Error executing trade: $e');
    }
  }

  // ==================== SEED ====================

  /// Seed the database with sample data
  Future<Map<String, dynamic>> seedDatabase() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/seed'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30)); // Longer timeout for seeding

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to seed database');
      }
    } catch (e) {
      throw Exception('Error seeding database: $e');
    }
  }
}
