enum TradeType { buy, sell }

enum TradeStatus { pending, active, completed, cancelled }

class Trade {
  final String id;
  final TradeType type;
  final String factoryName;
  final double kWh;
  final double pricePerKWh;
  final double totalPrice;
  final TradeStatus status;
  final DateTime timestamp;
  final double? profitLoss;

  Trade({
    required this.id,
    required this.type,
    required this.factoryName,
    required this.kWh,
    required this.pricePerKWh,
    required this.totalPrice,
    required this.status,
    required this.timestamp,
    this.profitLoss,
  });
}
