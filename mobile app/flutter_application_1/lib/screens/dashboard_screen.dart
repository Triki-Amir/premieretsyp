import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/energy_data_provider.dart';
import '../models/factory.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        final factories = energyData.factories
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                f.status != FactoryStatus.storage)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.grey.shade900.withOpacity(0.5),
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'lib/screens/assets/logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
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
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    color: Colors.grey,
                    onPressed: () {
                      _showNotificationPanel(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.blur_on),
                    color: Colors.grey,
                    onPressed: () => widget.onNavigate('blockchain'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    color: Colors.grey,
                    onPressed: () => widget.onNavigate('profile'),
                  ),
                ],
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for factories...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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

              // Today's Energy Balance Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.grey.shade900.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Energy Balance",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Factory 1 (My Factory)',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => widget.onNavigate('myFactory'),
                                child: const Text(
                                  'View My Factory',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Green = Surplus | Red = Deficit',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          const SizedBox(height: 16),
                          // Simplified chart representation
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Energy Chart\n(Surplus/Deficit over time)',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Available Factories',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Factory List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final factory = factories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        color: Colors.grey.shade900.withOpacity(0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          factory.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.wb_sunny,
                                              size: 16,
                                              color: Colors.yellow,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Solar Energy',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${factory.distance} km away',
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(factory.status)
                                          .withOpacity(0.2),
                                      border: Border.all(
                                        color: _getStatusColor(factory.status),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(factory.status),
                                      style: TextStyle(
                                        color: _getStatusColor(factory.status),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Available',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${factory.balance.abs()} kWh',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Price/kWh',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '\$${(0.08 + (index * 0.02)).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Capacity',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${factory.capacity.solar} kW',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (factory.status == FactoryStatus.surplus)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showBuyEnergyDialog(context, factory);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                    ),
                                    icon: const Icon(Icons.shopping_cart,
                                        color: Colors.white),
                                    label: const Text(
                                      'Buy Energy',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              if (factory.status == FactoryStatus.deficit)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showSellEnergyDialog(context, factory);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                    ),
                                    icon: const Icon(Icons.sell,
                                        color: Colors.white),
                                    label: const Text(
                                      'Sell Energy',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
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
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(FactoryStatus status) {
    switch (status) {
      case FactoryStatus.surplus:
        return Colors.green;
      case FactoryStatus.deficit:
        return Colors.red;
      case FactoryStatus.storage:
        return Colors.purple;
    }
  }

  String _getStatusLabel(FactoryStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            _buildNotificationItem(
              Icons.bolt,
              Colors.green,
              'Low Energy Alert',
              'Your surplus has dropped below 50 kWh',
              '5 min ago',
            ),
            _buildNotificationItem(
              Icons.local_offer,
              Colors.blue,
              'New Trade Offer',
              'Factory 3 wants to buy 100 kWh at \$0.12/kWh',
              '15 min ago',
            ),
            _buildNotificationItem(
              Icons.check_circle,
              Colors.purple,
              'Contract Executed',
              'Successfully sold 150 kWh to Factory 2',
              '1 hour ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    IconData icon,
    Color color,
    String title,
    String message,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSellEnergyDialog(BuildContext context, EnergyFactory factory) {
    final factoryNameController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController(text: '0.10');
    String selectedEnergyType = 'Solar';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double amount = double.tryParse(amountController.text) ?? 0;
          double price = double.tryParse(priceController.text) ?? 0;
          double total = amount * price;

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Sell Energy to ${factory.name}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: factoryNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Factory Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => setDialogState(() {}),
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
                      items: ['Solar', 'Wind', 'Hydro', 'Biomass']
                          .map((String value) {
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
                      onChanged: (value) => setDialogState(() {}),
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
                      onChanged: (value) => setDialogState(() {}),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Sell order created: ${amount.toStringAsFixed(0)} kWh of $selectedEnergyType at \$${price.toStringAsFixed(2)}/kWh to ${factory.name}'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                child:
                    const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBuyEnergyDialog(BuildContext context, EnergyFactory factory) {
    final amountController = TextEditingController();
    final priceController = TextEditingController(text: '0.10');
    String selectedDelivery = 'Immediate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double amount = double.tryParse(amountController.text) ?? 0;
          double price = double.tryParse(priceController.text) ?? 0;
          double total = amount * price;

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Buy Energy from ${factory.name}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      onChanged: (value) => setDialogState(() {}),
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
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Delivery Time',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedDelivery,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey.shade800,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Immediate', 'Within an hour', 'Tomorrow']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedDelivery = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Buy order created: ${amount.toStringAsFixed(0)} kWh at \$${price.toStringAsFixed(2)}/kWh'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
                child:
                    const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
