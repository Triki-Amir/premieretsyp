class EnergyData {
  final DateTime timestamp;
  final double generation;
  final double consumption;
  final double solar;
  final double wind;
  final double battery;

  EnergyData({
    required this.timestamp,
    required this.generation,
    required this.consumption,
    required this.solar,
    required this.wind,
    required this.battery,
  });
}

class CurrentEnergyData {
  final double generation;
  final double consumption;
  final double balance;
  final double todayGenerated;
  final double todayConsumed;
  final double todayTraded;
  final double costSavings;
  final double batteryLevel;

  CurrentEnergyData({
    required this.generation,
    required this.consumption,
    required this.balance,
    required this.todayGenerated,
    required this.todayConsumed,
    required this.todayTraded,
    required this.costSavings,
    required this.batteryLevel,
  });
}
