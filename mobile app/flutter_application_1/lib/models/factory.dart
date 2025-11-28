class EnergyFactory {
  final String id;
  final String name;
  final Location location;
  final double distance;
  final FactoryStatus status;
  final Capacity capacity;
  final double currentGeneration;
  final double currentConsumption;
  final double balance;
  final String? energyType;
  final double? dailyConsumption;
  final double? availableEnergy;
  final double? currencyBalance;
  final double? pricePerUnit; // For trading

  EnergyFactory({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    required this.status,
    required this.capacity,
    required this.currentGeneration,
    required this.currentConsumption,
    required this.balance,
    this.energyType,
    this.dailyConsumption,
    this.availableEnergy,
    this.currencyBalance,
    this.pricePerUnit,
  });

  /// Create factory from blockchain API response
  factory EnergyFactory.fromBlockchain(Map<String, dynamic> json) {
    final energyBalance = (json['energyBalance'] as num?)?.toDouble() ?? 0.0;
    final dailyConsumption = (json['dailyConsumption'] as num?)?.toDouble() ?? 0.0;
    final availableEnergy = (json['availableEnergy'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate status based on available energy vs consumption
    FactoryStatus status;
    if (availableEnergy > dailyConsumption) {
      status = FactoryStatus.surplus;
    } else if (availableEnergy < dailyConsumption) {
      status = FactoryStatus.deficit;
    } else {
      status = FactoryStatus.storage;
    }

    // Calculate total capacity from available energy
    final totalCapacity = availableEnergy * 1.5;
    
    return EnergyFactory(
      id: json['id'] ?? json['ID'] ?? '',
      name: json['name'] ?? json['Name'] ?? 'Unknown Factory',
      location: Location(lat: 40.7128, lng: -74.0060), // Default location
      distance: 0.0,
      status: status,
      capacity: Capacity(
        solar: totalCapacity * 0.5,
        wind: totalCapacity * 0.3,
        battery: totalCapacity * 0.2,
      ),
      currentGeneration: availableEnergy,
      currentConsumption: dailyConsumption,
      balance: energyBalance,
      energyType: json['energyType'] ?? json['EnergyType'],
      dailyConsumption: dailyConsumption,
      availableEnergy: availableEnergy,
      currencyBalance: (json['currencyBalance'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: 0.10, // Default price, can be customized
    );
  }
  
  /// Create factory from backend API response
  factory EnergyFactory.fromBackend(Map<String, dynamic> json) {
    final currentGeneration = (json['current_generation'] as num?)?.toDouble() ?? 0.0;
    final currentConsumption = (json['current_consumption'] as num?)?.toDouble() ?? 0.0;
    final energyBalance = (json['energy_balance'] as num?)?.toDouble() ?? 0.0;
    final energyCapacity = (json['energy_capacity'] as num?)?.toDouble() ?? 100.0;
    
    // Calculate status based on energy balance
    FactoryStatus status;
    if (energyBalance > 0) {
      status = FactoryStatus.surplus;
    } else if (energyBalance < 0) {
      status = FactoryStatus.deficit;
    } else {
      status = FactoryStatus.storage;
    }
    
    return EnergyFactory(
      id: json['id'].toString(),
      name: json['factory_name'] ?? 'Unknown Factory',
      location: Location(lat: 40.7128, lng: -74.0060), // Default location
      distance: 0.0,
      status: status,
      capacity: Capacity(
        solar: energyCapacity * 0.5,
        wind: energyCapacity * 0.3,
        battery: energyCapacity * 0.2,
      ),
      currentGeneration: currentGeneration,
      currentConsumption: currentConsumption,
      balance: energyBalance,
      energyType: json['energy_source'],
      dailyConsumption: currentConsumption,
      availableEnergy: currentGeneration,
      currencyBalance: 0.0,
      pricePerUnit: 0.10, // Default price
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});
}

class Capacity {
  final double solar;
  final double wind;
  final double battery;

  Capacity({
    required this.solar,
    required this.wind,
    required this.battery,
  });
}

enum FactoryStatus { surplus, deficit, storage }
