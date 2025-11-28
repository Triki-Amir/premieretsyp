class EnergyOffer {
  final String id;
  final String factoryId;
  final String factoryName;
  final OfferType type;
  final double kWh;
  final double pricePerKWh;
  final double distance;
  final DateTime timestamp;

  EnergyOffer({
    required this.id,
    required this.factoryId,
    required this.factoryName,
    required this.type,
    required this.kWh,
    required this.pricePerKWh,
    required this.distance,
    required this.timestamp,
  });

  double get totalPrice => kWh * pricePerKWh;
}

enum OfferType { buy, sell }
