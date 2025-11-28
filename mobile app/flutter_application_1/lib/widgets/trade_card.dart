import 'package:flutter/material.dart';
import '../models/trade.dart';

class TradeCardWidget extends StatelessWidget {
  final Trade trade;

  const TradeCardWidget({
    super.key,
    required this.trade,
  });

  Color _getStatusColor() {
    switch (trade.status) {
      case TradeStatus.pending:
        return Colors.yellow;
      case TradeStatus.active:
        return Colors.blue;
      case TradeStatus.completed:
        return Colors.green;
      case TradeStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (trade.status) {
      case TradeStatus.pending:
      case TradeStatus.active:
        return Icons.schedule;
      case TradeStatus.completed:
        return Icons.check_circle;
      case TradeStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusLabel() {
    return trade.status.name[0].toUpperCase() + trade.status.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == TradeType.buy;

    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isBuy ? Colors.blue : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.factoryName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${trade.timestamp.hour.toString().padLeft(2, '0')}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 12,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Energy',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${trade.kWh} kWh',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '\$${trade.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (trade.profitLoss != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'P/L',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          '${trade.profitLoss! >= 0 ? '+' : ''}${trade.profitLoss!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: trade.profitLoss! >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
