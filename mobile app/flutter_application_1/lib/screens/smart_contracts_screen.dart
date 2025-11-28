import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/energy_data_provider.dart';
import '../widgets/offer_card.dart';
import '../models/energy_offer.dart';

class SmartContractsScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const SmartContractsScreen({super.key, required this.onNavigate});

  @override
  State<SmartContractsScreen> createState() => _SmartContractsScreenState();
}

class _SmartContractsScreenState extends State<SmartContractsScreen> {
  @override
  void initState() {
    super.initState();
    // Load offers when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnergyDataProvider>().loadOffers();
    });
  }

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
                    icon: const Icon(Icons.refresh),
                    onPressed: energyData.isLoadingOffers
                        ? null
                        : () => energyData.loadOffers(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                      _showCreateOfferDialog(context);
                    },
                  ),
                ],
              ),
              
              // Connection status banner
              if (!energyData.isConnectedToBackend)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.orange.shade900,
                    padding: const EdgeInsets.all(12),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Not connected to backend. Showing cached data.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              
              // Loading indicator
              if (energyData.isLoadingOffers)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              
              // Empty state
              if (!energyData.isLoadingOffers && offers.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 64, color: Colors.grey.shade700),
                          const SizedBox(height: 16),
                          const Text(
                            'No offers available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a new offer to get started',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              if (!energyData.isLoadingOffers)
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
    final amountController = TextEditingController();
    final priceController = TextEditingController();
    String selectedOfferType = 'sell';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
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
                    items: [
                      const DropdownMenuItem(value: 'sell', child: Text('Sell Energy')),
                      const DropdownMenuItem(value: 'buy', child: Text('Buy Energy')),
                    ],
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedOfferType = newValue!;
                      });
                    },
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty || priceController.text.isEmpty) {
                    Fluttertoast.showToast(
                      msg: "Please fill all fields",
                      backgroundColor: Colors.red,
                    );
                    return;
                  }
                  
                  try {
                    final provider = context.read<EnergyDataProvider>();
                    await provider.createOffer(
                      offerType: selectedOfferType,
                      energyAmount: double.parse(amountController.text),
                      pricePerKwh: double.parse(priceController.text),
                    );
                    
                    Navigator.pop(dialogContext);
                    
                    Fluttertoast.showToast(
                      msg: "✅ Offer created successfully!",
                      backgroundColor: Colors.green,
                    );
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: "❌ Error: ${e.toString().replaceAll('Exception: ', '')}",
                      backgroundColor: Colors.red,
                    );
                  }
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
