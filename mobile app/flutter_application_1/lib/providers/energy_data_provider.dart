import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/energy_data.dart';
import '../models/factory.dart';
import '../models/energy_offer.dart';
import '../models/trade.dart';
import '../services/backend_api_service.dart';

class EnergyDataProvider extends ChangeNotifier {
  final BackendApiService _backendApi = BackendApiService();
  
  // Connection status
  bool _isConnectedToBackend = false;
  String? _connectionError;
  bool _isLoadingFactories = false;
  bool _isLoadingOffers = false;
  bool _isLoadingTrades = false;
  bool _isSeeding = false;
  
  // Current user's factory data from login
  Map<String, dynamic>? _currentUserFactory;
  int? _myFactoryId;
  
  CurrentEnergyData _currentData = CurrentEnergyData(
    generation: 0,
    consumption: 0,
    balance: 0,
    todayGenerated: 0,
    todayConsumed: 0,
    todayTraded: 0,
    costSavings: 0,
    batteryLevel: 0,
  );

  List<EnergyData> _history = [];
  List<EnergyFactory> _factories = [];
  List<EnergyOffer> _offers = [];
  List<Trade> _trades = [];

  Timer? _timer;

  EnergyDataProvider() {
    _initializeHistory();
    _startUpdates();
    _checkBackendConnection();
  }

  // Getters
  CurrentEnergyData get currentData => _currentData;
  List<EnergyData> get history => _history;
  List<EnergyFactory> get factories => _factories;
  List<EnergyOffer> get offers => _offers;
  List<Trade> get trades => _trades;
  bool get isConnectedToBlockchain => _isConnectedToBackend;
  bool get isConnectedToBackend => _isConnectedToBackend;
  bool get isLoadingFactories => _isLoadingFactories;
  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoadingTrades => _isLoadingTrades;
  bool get isSeeding => _isSeeding;
  String? get connectionError => _connectionError;
  int? get myFactoryId => _myFactoryId;
  Map<String, dynamic>? get currentUserFactory => _currentUserFactory;
  
  /// Set the current user's factory from login response
  void setCurrentUserFactory(Map<String, dynamic> factory) {
    _currentUserFactory = factory;
    _myFactoryId = factory['id'] as int?;
    
    // Update current data based on logged-in user's factory
    final generation = (factory['current_generation'] as num?)?.toDouble() ?? 0;
    final consumption = (factory['current_consumption'] as num?)?.toDouble() ?? 0;
    final balance = (factory['energy_balance'] as num?)?.toDouble() ?? 0;
    
    _currentData = CurrentEnergyData(
      generation: generation,
      consumption: consumption,
      balance: balance,
      todayGenerated: (generation * 8).round(), // Simulated daily values
      todayConsumed: (consumption * 8).round(),
      todayTraded: 0,
      costSavings: (balance * 0.10 * 8).round(),
      batteryLevel: ((factory['energy_capacity'] as num?)?.toDouble() ?? 100) * 0.78,
    );
    
    notifyListeners();
  }
  
  /// Clear user session on logout
  void clearSession() {
    _currentUserFactory = null;
    _myFactoryId = null;
    _factories = [];
    _offers = [];
    _trades = [];
    _isConnectedToBackend = false;
    notifyListeners();
  }
  
  /// Check backend connection
  Future<void> _checkBackendConnection() async {
    try {
      await _backendApi.testConnection();
      _isConnectedToBackend = true;
      _connectionError = null;
      notifyListeners();
    } catch (e) {
      _isConnectedToBackend = false;
      _connectionError = e.toString();
      debugPrint('Backend connection error: $e');
      notifyListeners();
    }
  }
  
  /// Load factories from backend
  Future<void> loadFactoriesFromBlockchain() async {
    return loadFactoriesFromBackend();
  }
  
  Future<void> loadFactoriesFromBackend() async {
    _isLoadingFactories = true;
    notifyListeners();
    
    try {
      final factoriesData = await _backendApi.getAllFactories();
      
      if (factoriesData.isNotEmpty) {
        _factories = factoriesData
            .where((json) => json['id'] != _myFactoryId) // Exclude current user's factory
            .map((json) => EnergyFactory.fromBackend(json))
            .toList();
        _isConnectedToBackend = true;
        _connectionError = null;
      } else {
        _factories = [];
      }
    } catch (e) {
      _connectionError = e.toString();
      debugPrint('Error loading factories from backend: $e');
    } finally {
      _isLoadingFactories = false;
      notifyListeners();
    }
  }
  
  /// Load offers from backend
  Future<void> loadOffers() async {
    _isLoadingOffers = true;
    notifyListeners();
    
    try {
      final offersData = await _backendApi.getAllOffers();
      
      _offers = offersData.map((json) {
        return EnergyOffer(
          id: json['id'].toString(),
          factoryId: json['factory_id'].toString(),
          factoryName: json['factory_name'] ?? 'Unknown Factory',
          type: json['offer_type'] == 'sell' ? OfferType.sell : OfferType.buy,
          kWh: (json['energy_amount'] as num).toDouble(),
          pricePerKWh: (json['price_per_kwh'] as num).toDouble(),
          distance: 0.0, // Distance not stored in backend
          timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        );
      }).toList();
      
      _isConnectedToBackend = true;
    } catch (e) {
      debugPrint('Error loading offers from backend: $e');
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }
  
  /// Load trades from backend
  Future<void> loadTrades() async {
    _isLoadingTrades = true;
    notifyListeners();
    
    try {
      final tradesData = await _backendApi.getTrades(factoryId: _myFactoryId);
      
      _trades = tradesData.map((json) {
        final isSeller = json['seller_factory_id'] == _myFactoryId;
        return Trade(
          id: json['id'].toString(),
          type: isSeller ? TradeType.sell : TradeType.buy,
          factoryName: isSeller ? json['buyer_name'] : json['seller_name'],
          kWh: (json['energy_amount'] as num).toDouble(),
          pricePerKWh: (json['price_per_kwh'] as num).toDouble(),
          totalPrice: (json['total_price'] as num).toDouble(),
          status: _mapTradeStatus(json['status']),
          timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
          profitLoss: isSeller ? (json['total_price'] as num).toDouble() : -(json['total_price'] as num).toDouble(),
        );
      }).toList();
      
      _isConnectedToBackend = true;
    } catch (e) {
      debugPrint('Error loading trades from backend: $e');
    } finally {
      _isLoadingTrades = false;
      notifyListeners();
    }
  }
  
  TradeStatus _mapTradeStatus(String? status) {
    switch (status) {
      case 'pending':
        return TradeStatus.pending;
      case 'active':
        return TradeStatus.active;
      case 'completed':
        return TradeStatus.completed;
      case 'cancelled':
        return TradeStatus.cancelled;
      default:
        return TradeStatus.pending;
    }
  }
  
  /// Create a trade to buy energy from another factory
  Future<Map<String, dynamic>> buyEnergy({
    required String sellerFactoryId,
    required double amount,
    required double pricePerUnit,
  }) async {
    if (_myFactoryId == null) {
      throw Exception('User not logged in');
    }
    
    try {
      final result = await _backendApi.createTrade(
        sellerFactoryId: int.parse(sellerFactoryId),
        buyerFactoryId: _myFactoryId!,
        energyAmount: amount,
        pricePerKwh: pricePerUnit,
      );
      
      // Reload data to update balances
      await loadFactoriesFromBackend();
      await loadTrades();
      
      return result;
    } catch (e) {
      throw Exception('Failed to buy energy: $e');
    }
  }
  
  /// Create a trade to sell energy to another factory
  Future<Map<String, dynamic>> sellEnergy({
    required String buyerFactoryId,
    required double amount,
    required double pricePerUnit,
  }) async {
    if (_myFactoryId == null) {
      throw Exception('User not logged in');
    }
    
    try {
      final result = await _backendApi.createTrade(
        sellerFactoryId: _myFactoryId!,
        buyerFactoryId: int.parse(buyerFactoryId),
        energyAmount: amount,
        pricePerKwh: pricePerUnit,
      );
      
      // Reload data to update balances
      await loadFactoriesFromBackend();
      await loadTrades();
      
      return result;
    } catch (e) {
      throw Exception('Failed to sell energy: $e');
    }
  }
  
  /// Create a new offer
  Future<void> createOffer({
    required String offerType,
    required double energyAmount,
    required double pricePerKwh,
  }) async {
    if (_myFactoryId == null) {
      throw Exception('User not logged in');
    }
    
    try {
      await _backendApi.createOffer(
        factoryId: _myFactoryId!,
        offerType: offerType,
        energyAmount: energyAmount,
        pricePerKwh: pricePerKwh,
      );
      
      // Reload offers
      await loadOffers();
    } catch (e) {
      throw Exception('Failed to create offer: $e');
    }
  }
  
  /// Seed the database with sample data
  Future<Map<String, dynamic>> seedDatabase() async {
    _isSeeding = true;
    notifyListeners();
    
    try {
      final result = await _backendApi.seedDatabase();
      
      // Reload all data after seeding
      await loadFactoriesFromBackend();
      await loadOffers();
      await loadTrades();
      
      return result;
    } catch (e) {
      throw Exception('Failed to seed database: $e');
    } finally {
      _isSeeding = false;
      notifyListeners();
    }
  }

  void _initializeHistory() {
    // Initialize history data for charts
    final now = DateTime.now();
    for (int i = 23; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i));
      final baseGen = 150 + sin(i / 24 * 2 * pi) * 100;
      _history.add(EnergyData(
        timestamp: hour,
        generation: baseGen + Random().nextDouble() * 50,
        consumption: 120 + Random().nextDouble() * 80,
        solar: baseGen * 0.6,
        wind: baseGen * 0.3,
        battery: baseGen * 0.1,
      ));
    }
  }

  void _startUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentUserFactory != null) {
        final random = Random();
        _currentData = CurrentEnergyData(
          generation: max(0, _currentData.generation + (random.nextDouble() - 0.5) * 20),
          consumption: max(0, _currentData.consumption + (random.nextDouble() - 0.5) * 15),
          balance: _currentData.generation - _currentData.consumption,
          todayGenerated: _currentData.todayGenerated,
          todayConsumed: _currentData.todayConsumed,
          todayTraded: _currentData.todayTraded,
          costSavings: _currentData.costSavings,
          batteryLevel: min(100, max(0, _currentData.batteryLevel + (random.nextDouble() - 0.5) * 5)),
        );
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
