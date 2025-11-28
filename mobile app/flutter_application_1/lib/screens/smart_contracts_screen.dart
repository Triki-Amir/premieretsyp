import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/energy_data_provider.dart';
import '../widgets/offer_card.dart';
import '../models/energy_offer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SmartContractsScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const SmartContractsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        final offers = energyData.offers;
        final sellOffers = offers.where((o) => o.type == OfferType.sell).length;
        final buyOffers = offers.where((o) => o.type == OfferType.buy).length;

        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.grey.shade900.withOpacity(0.5),
                title: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trading Offers',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        Text(
                          'Buy and sell energy',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                      _showCreateOfferDialog(context);
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.grey.shade900.withOpacity(0.5),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.3),
                                  Colors.green.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Sell Offers',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$sellOffers',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          color: Colors.grey.shade900.withOpacity(0.5),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.3),
                                  Colors.blue.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Buy Offers',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$buyOffers',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Available Offers',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final offer = offers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OfferCardWidget(
                      offer: offer,
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Trade initiated with ${offer.factoryName}',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                }, childCount: offers.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  void _showCreateOfferDialog(BuildContext context) {
    final factoryNameController = TextEditingController(text: 'Factory 1');
    final factoryIdController = TextEditingController(text: 'F-001');
    final amountController = TextEditingController();
    final priceController = TextEditingController();
    String selectedEnergyType = 'Solar';
    String selectedOfferType = 'Sell';

    Future<void> createOffer() async {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/factory/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'factoryId': factoryIdController.text,
            'name': factoryNameController.text,
            'initialBalance': double.parse(priceController.text),
            'energyType': selectedEnergyType.toLowerCase(),
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            print('Offer created successfully');
          }
        } else {
          print('Failed to create offer');
        }
      } catch (e) {
        print('Error: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text(
              'Create Trading Offer',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: factoryNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Factory Name',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: factoryIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Factory ID',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Offer Type',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedOfferType,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey.shade800,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Sell', 'Buy'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedOfferType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Energy Type',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedEnergyType,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey.shade800,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Solar', 'Wind', 'Footstep', 'Mixed'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedEnergyType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Price per kWh (\$)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount (kWh)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Energy Balance:',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '+125 kWh',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  createOffer();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
