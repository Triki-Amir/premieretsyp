import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/energy_data.dart';
import '../models/factory.dart';
import '../models/energy_offer.dart';
import '../models/trade.dart';
import '../services/blockchain_api_service.dart';

class EnergyDataProvider extends ChangeNotifier {
  final BlockchainApiService _blockchainApi = BlockchainApiService();
  
  // Connection status
  bool _isConnectedToBlockchain = false;
  String? _connectionError;
  bool _isLoadingFactories = false;
  
  // Current user's factory ID (you can set this based on login)
  String _myFactoryId = 'Factory01'; // Default to Factory01
  
  CurrentEnergyData _currentData = CurrentEnergyData(
    generation: 245,
    consumption: 198,
    balance: 47,
    todayGenerated: 1834,
    todayConsumed: 1567,
    todayTraded: 423,
    costSavings: 1247,
    batteryLevel: 78,
  );

  List<EnergyData> _history = [];
  List<EnergyFactory> _factories = [];
  List<EnergyOffer> _offers = [];
  List<Trade> _trades = [];

  Timer? _timer;

  EnergyDataProvider() {
    _initializeData();
    _startUpdates();
    _checkBlockchainConnection();
  }

  // Getters
  CurrentEnergyData get currentData => _currentData;
  List<EnergyData> get history => _history;
  List<EnergyFactory> get factories => _factories;
  List<EnergyOffer> get offers => _offers;
  List<Trade> get trades => _trades;
  bool get isConnectedToBlockchain => _isConnectedToBlockchain;
  bool get isLoadingFactories => _isLoadingFactories;
  String? get connectionError => _connectionError;
  String get myFactoryId => _myFactoryId;
  
  /// Set the current user's factory ID
  void setMyFactoryId(String factoryId) {
    _myFactoryId = factoryId;
    notifyListeners();
  }
  
  /// Check blockchain connection
  Future<void> _checkBlockchainConnection() async {
    try {
      await _blockchainApi.checkHealth();
      _isConnectedToBlockchain = true;
      _connectionError = null;
      
      // Load factories from blockchain
      await loadFactoriesFromBlockchain();
      
      notifyListeners();
    } catch (e) {
      _isConnectedToBlockchain = false;
      _connectionError = e.toString();
      debugPrint('Blockchain connection error: $e');
      // Fall back to demo data
      _initializeData();
      notifyListeners();
    }
  }
  
  /// Load factories from blockchain
  Future<void> loadFactoriesFromBlockchain() async {
    _isLoadingFactories = true;
    notifyListeners();
    
    try {
      final factoriesData = await _blockchainApi.getAllFactories();
      
      if (factoriesData.isNotEmpty) {
        _factories = factoriesData
            .map((json) => EnergyFactory.fromBlockchain(json))
            .toList();
        _isConnectedToBlockchain = true;
        _connectionError = null;
      }
    } catch (e) {
      _connectionError = e.toString();
      debugPrint('Error loading factories from blockchain: $e');
      // Keep using demo data if blockchain fails
    } finally {
      _isLoadingFactories = false;
      notifyListeners();
    }
  }
  
  /// Create a trade to buy energy from another factory
  Future<Map<String, dynamic>> buyEnergy({
    required String sellerFactoryId,
    required double amount,
    required double pricePerUnit,
  }) async {
    try {
      final tradeId = 'trade_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _blockchainApi.createTrade(
        tradeId: tradeId,
        sellerId: sellerFactoryId,
        buyerId: _myFactoryId,
        amount: amount,
        pricePerUnit: pricePerUnit,
      );
      
      // Reload factories to update balances
      await loadFactoriesFromBlockchain();
      
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
    try {
      final tradeId = 'trade_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _blockchainApi.createTrade(
        tradeId: tradeId,
        sellerId: _myFactoryId,
        buyerId: buyerFactoryId,
        amount: amount,
        pricePerUnit: pricePerUnit,
      );
      
      // Reload factories to update balances
      await loadFactoriesFromBlockchain();
      
      return result;
    } catch (e) {
      throw Exception('Failed to sell energy: $e');
    }
  }
  
  /// Get energy status for a specific factory
  Future<Map<String, dynamic>> getEnergyStatus(String factoryId) async {
    try {
      return await _blockchainApi.getEnergyStatus(factoryId);
    } catch (e) {
      throw Exception('Failed to get energy status: $e');
    }
  }

  void _initializeData() {
    // Initialize history data (keep real-time simulation)
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

    // Initialize demo factories (will be replaced by blockchain data if available)
    if (_factories.isEmpty) {
      _factories = [
        EnergyFactory(
          id: 'f1',
          name: 'Factory 2',
          location: Location(lat: 40.7128, lng: -74.0060),
          distance: 2.3,
          status: FactoryStatus.surplus,
          capacity: Capacity(solar: 500, wind: 300, battery: 200),
          currentGeneration: 320,
          currentConsumption: 250,
          balance: 70,
          pricePerUnit: 0.09,
        ),
        EnergyFactory(
          id: 'f2',
          name: 'Factory 3',
          location: Location(lat: 40.7580, lng: -73.9855),
          distance: 5.7,
          status: FactoryStatus.deficit,
          capacity: Capacity(solar: 400, wind: 200, battery: 150),
          currentGeneration: 180,
          currentConsumption: 230,
          balance: -50,
          pricePerUnit: 0.13,
        ),
        EnergyFactory(
          id: 'f3',
          name: 'Factory 4',
          location: Location(lat: 40.7489, lng: -73.9680),
          distance: 8.1,
          status: FactoryStatus.storage,
          capacity: Capacity(solar: 600, wind: 400, battery: 300),
          currentGeneration: 280,
          currentConsumption: 270,
          balance: 10,
          pricePerUnit: 0.11,
        ),
        EnergyFactory(
          id: 'f4',
          name: 'Factory 5',
          location: Location(lat: 40.7614, lng: -73.9776),
          distance: 12.4,
          status: FactoryStatus.surplus,
          capacity: Capacity(solar: 450, wind: 250, battery: 180),
          currentGeneration: 380,
          currentConsumption: 290,
          balance: 90,
          pricePerUnit: 0.08,
        ),
      ];
    }

    // Initialize offers
    _offers = [
      EnergyOffer(
        id: 'o1',
        factoryId: 'f1',
        factoryName: 'Factory 2',
        type: OfferType.sell,
        kWh: 70,
        pricePerKWh: 0.09,
        distance: 2.3,
        timestamp: DateTime.now(),
      ),
      EnergyOffer(
        id: 'o2',
        factoryId: 'f2',
        factoryName: 'Factory 3',
        type: OfferType.buy,
        kWh: 50,
        pricePerKWh: 0.13,
        distance: 5.7,
        timestamp: DateTime.now(),
      ),
      EnergyOffer(
        id: 'o3',
        factoryId: 'f4',
        factoryName: 'Factory 5',
        type: OfferType.sell,
        kWh: 90,
        pricePerKWh: 0.08,
        distance: 12.4,
        timestamp: DateTime.now(),
      ),
    ];

    // Initialize trades
    _trades = [
      Trade(
        id: 't1',
        type: TradeType.buy,
        factoryName: 'Factory 2',
        kWh: 30,
        pricePerKWh: 0.09,
        totalPrice: 2.7,
        status: TradeStatus.active,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Trade(
        id: 't2',
        type: TradeType.sell,
        factoryName: 'Factory 5',
        kWh: 45,
        pricePerKWh: 0.12,
        totalPrice: 5.4,
        status: TradeStatus.completed,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        profitLoss: 1.2,
      ),
      Trade(
        id: 't3',
        type: TradeType.buy,
        factoryName: 'Factory 3',
        kWh: 25,
        pricePerKWh: 0.11,
        totalPrice: 2.75,
        status: TradeStatus.completed,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        profitLoss: -0.5,
      ),
    ];
  }

  void _startUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
