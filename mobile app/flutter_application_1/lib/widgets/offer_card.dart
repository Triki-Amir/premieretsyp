import 'package:flutter/material.dart';
import '../models/energy_offer.dart';

class OfferCardWidget extends StatelessWidget {
  final EnergyOffer offer;
  final VoidCallback onAction;

  const OfferCardWidget({
    super.key,
    required this.offer,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isSell = offer.type == OfferType.sell;
    final totalPrice = offer.totalPrice.toStringAsFixed(2);

    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSell
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSell ? Icons.factory : Icons.factory_outlined,
                    color: isSell ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.factoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.navigation, size: 10, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.distance} km',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSell
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSell ? 'Selling' : 'Buying',
                    style: TextStyle(
                      color: isSell ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
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
                        '${offer.kWh} kWh',
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
                        'Price/kWh',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '\$${offer.pricePerKWh.toStringAsFixed(2)}',
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
                        'Total',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '\$$totalPrice',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSell ? Colors.green : Colors.blue.shade600,
                ),
                child: Text(
                  isSell ? 'Buy Now' : 'Sell Now',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
