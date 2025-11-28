import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/energy_data_provider.dart';
import '../models/factory.dart';

class DashboardScreenNew extends StatefulWidget {
  final Function(String) onNavigate;

  const DashboardScreenNew({super.key, required this.onNavigate});

  @override
  State<DashboardScreenNew> createState() => _DashboardScreenNewState();
}

class _DashboardScreenNewState extends State<DashboardScreenNew> {
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load blockchain data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EnergyDataProvider>();
      if (!provider.isConnectedToBlockchain) {
        provider.loadFactoriesFromBlockchain();
      }
    });
  }

  Future<void> _handleBuyEnergy(BuildContext context, EnergyFactory factory) async {
    final provider = context.read<EnergyDataProvider>();
    
    // Show dialog to enter amount
    final amount = await _showAmountDialog(
      context,
      'Buy Energy from ${factory.name}',
      'How much energy (kWh) do you want to buy?',
      factory.availableEnergy ?? factory.currentGeneration,
    );
    
    if (amount == null || amount <= 0) return;
    
    setState(() => _isLoading = true);
    
    try {
      await provider.buyEnergy(
        sellerFactoryId: factory.id,
        amount: amount,
        pricePerUnit: factory.pricePerUnit ?? 0.10,
      );
      
      Fluttertoast.showToast(
        msg: "✅ Trade created successfully! Total: \$${(amount * (factory.pricePerUnit ?? 0.10)).toStringAsFixed(2)}",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error: ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSellEnergy(BuildContext context, EnergyFactory factory) async {
    final provider = context.read<EnergyDataProvider>();
    
    // Show dialog to enter amount
    final amount = await _showAmountDialog(
      context,
      'Sell Energy to ${factory.name}',
      'How much energy (kWh) do you want to sell?',
      100.0, // Max sellable from your factory
    );
    
    if (amount == null || amount <= 0) return;
    
    setState(() => _isLoading = true);
    
    try {
      await provider.sellEnergy(
        buyerFactoryId: factory.id,
        amount: amount,
        pricePerUnit: factory.pricePerUnit ?? 0.10,
      );
      
      Fluttertoast.showToast(
        msg: "✅ Sell offer created! You'll receive \$${(amount * (factory.pricePerUnit ?? 0.10)).toStringAsFixed(2)}",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error: ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<double?> _showAmountDialog(
    BuildContext context,
    String title,
    String subtitle,
    double maxAmount,
  ) async {
    final controller = TextEditingController();
    
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (kWh)',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'Max: ${maxAmount.toStringAsFixed(0)}',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              Navigator.pop(context, amount);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        // Filter factories based on search query and exclude storage
        final factories = energyData.factories
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                f.status != FactoryStatus.storage)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar with connection status
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.grey.shade900.withOpacity(0.8),
                    title: Row(
                      children: [
                        // Logo placeholder
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bolt, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Gen Power',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            Text(
                              'Energy Marketplace',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      // Blockchain connection indicator
                      Icon(
                        energyData.isConnectedToBlockchain
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: energyData.isConnectedToBlockchain
                            ? Colors.green
                            : Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: energyData.isLoadingFactories
                            ? null
                            : () => energyData.loadFactoriesFromBlockchain(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.blur_on),
                        onPressed: () => widget.onNavigate('blockchain'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person),
                        onPressed: () => widget.onNavigate('profile'),
                      ),
                    ],
                  ),

                  // Connection Status Banner
                  if (!energyData.isConnectedToBlockchain)
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.orange.shade900,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Not connected to blockchain. Using demo data.',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search factories by name...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                  // Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Factories',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${factories.length} factories',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Loading indicator
                  if (energyData.isLoadingFactories)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),

                  // Factory List
                  if (!energyData.isLoadingFactories)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final factory = factories[index];
                          final statusColor = factory.status == FactoryStatus.surplus
                              ? Colors.green
                              : Colors.red;
                          final statusText = factory.status == FactoryStatus.surplus
                              ? 'SURPLUS'
                              : 'DEFICIT';
                          
                          final totalCapacity = (factory.capacity.solar +
                              factory.capacity.wind +
                              factory.capacity.battery);
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Card(
                              color: Colors.grey.shade900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: statusColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Factory Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                factory.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                factory.energyType?.toUpperCase() ?? 'MIXED',
                                                style: TextStyle(
                                                  color: Colors.blue.shade300,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: statusColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Energy Stats
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatColumn(
                                          'Available',
                                          '${(factory.availableEnergy ?? factory.currentGeneration).toStringAsFixed(0)} kWh',
                                          Icons.energy_savings_leaf,
                                          Colors.green,
                                        ),
                                        _buildStatColumn(
                                          'Consumption',
                                          '${(factory.dailyConsumption ?? factory.currentConsumption).toStringAsFixed(0)} kWh/day',
                                          Icons.trending_down,
                                          Colors.orange,
                                        ),
                                        _buildStatColumn(
                                          'Price',
                                          '\$${(factory.pricePerUnit ?? 0.10).toStringAsFixed(2)}/kWh',
                                          Icons.attach_money,
                                          Colors.blue,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Total Capacity
                                    Row(
                                      children: [
                                        const Icon(Icons.battery_full,
                                            color: Colors.grey, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Total Capacity: ${totalCapacity.toStringAsFixed(0)} kWh',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Action Buttons
                                    Row(
                                      children: [
                                        if (factory.status == FactoryStatus.surplus)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => _handleBuyEnergy(context, factory),
                                              icon: const Icon(Icons.shopping_cart),
                                              label: const Text('Buy Energy'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (factory.status == FactoryStatus.deficit) ...[
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => _handleSellEnergy(context, factory),
                                              icon: const Icon(Icons.sell),
                                              label: const Text('Sell Energy'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            // Show factory details
                                            _showFactoryDetails(context, factory);
                                          },
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text('Details'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.grey),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: factories.length,
                      ),
                    ),

                  // Empty state
                  if (factories.isEmpty && !energyData.isLoadingFactories)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.factory_outlined,
                                  size: 64, color: Colors.grey.shade700),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No factories available'
                                    : 'No factories match your search',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showFactoryDetails(BuildContext context, EnergyFactory factory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              factory.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Factory ID', factory.id),
            _buildDetailRow('Energy Type', factory.energyType ?? 'Mixed'),
            _buildDetailRow('Available Energy',
                '${(factory.availableEnergy ?? factory.currentGeneration).toStringAsFixed(2)} kWh'),
            _buildDetailRow('Daily Consumption',
                '${(factory.dailyConsumption ?? factory.currentConsumption).toStringAsFixed(2)} kWh'),
            _buildDetailRow('Energy Balance',
                '${factory.balance.toStringAsFixed(2)} kWh'),
            _buildDetailRow('Price per kWh',
                '\$${(factory.pricePerUnit ?? 0.10).toStringAsFixed(2)}'),
            _buildDetailRow('Currency Balance',
                '\$${(factory.currencyBalance ?? 0.0).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
