import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for communicating with the backend API
class BackendApiService {
  // Base URL for the blockchain backend (Node.js app on port 3000)
  // For physical devices, use the actual server IP address
  // For Android emulator, use 10.0.2.2 to access host machine's localhost
  // For iOS simulator, localhost works
  // For web or physical device, replace localhost with your server IP
  static String _baseUrl = 'http://localhost:3000';
  
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
          .get(Uri.parse('$_baseUrl/api/factories'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both success formats
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get factories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting factories: $e');
    }
  }

  /// Get a single factory by ID
  Future<Map<String, dynamic>> getFactory(String factoryId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/factory/$factoryId'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        return data;
      } else {
        throw Exception('Failed to get factory: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting factory: $e');
    }
  }

  /// Update factory energy data
  Future<void> updateFactoryEnergy({
    required String factoryId,
    required double energyBalance,
    required double currentGeneration,
    required double currentConsumption,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/factory/$factoryId/energy'),
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
      // Use mobile app format endpoint (without /api prefix)
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
    required String factoryId,
    required String offerType, // 'buy' or 'sell'
    required double energyAmount,
    required double pricePerKwh,
  }) async {
    try {
      // Use mobile app format endpoint (without /api prefix)
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
      // Use mobile app format endpoint (without /api prefix)
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
  Future<List<Map<String, dynamic>>> getTrades({String? factoryId}) async {
    try {
      // Use mobile app format endpoint (without /api prefix)
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

  /// Create a new trade using blockchain endpoint
  /// This creates a trade on the blockchain via /api/trade/create
  Future<Map<String, dynamic>> createTrade({
    required String sellerFactoryId,
    required String buyerFactoryId,
    required double energyAmount,
    required double pricePerKwh,
  }) async {
    try {
      // Generate a unique trade ID
      final tradeId = 'Trade_${DateTime.now().millisecondsSinceEpoch}_${energyAmount.toInt()}';
      
      // Use blockchain endpoint for creating trades
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/trade/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tradeId': tradeId,
              'sellerId': sellerFactoryId,
              'buyerId': buyerFactoryId,
              'amount': energyAmount,
              'pricePerUnit': pricePerKwh,
            }),
          )
          .timeout(timeout);

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to create trade');
      }
    } catch (e) {
      throw Exception('Error creating trade: $e');
    }
  }

  /// Execute a trade using blockchain endpoint
  /// This executes a pending trade on the blockchain via /api/trade/execute
  Future<Map<String, dynamic>> executeTrade(String tradeId) async {
    try {
      // Use blockchain endpoint for executing trades
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/trade/execute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tradeId': tradeId}),
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
      // Use mobile app format endpoint (without /api prefix)
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
