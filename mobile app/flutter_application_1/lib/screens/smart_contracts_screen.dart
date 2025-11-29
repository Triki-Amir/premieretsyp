import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/energy_data_provider.dart';
import '../widgets/offer_card.dart';
import '../widgets/trade_card.dart';
import '../models/energy_offer.dart';
import '../models/trade.dart';

class SmartContractsScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const SmartContractsScreen({super.key, required this.onNavigate});

  @override
  State<SmartContractsScreen> createState() => _SmartContractsScreenState();
}

class _SmartContractsScreenState extends State<SmartContractsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExecutingTrade = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load offers and trades when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EnergyDataProvider>();
      provider.loadOffers();
      provider.loadTrades();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _executeTrade(String tradeId) async {
    setState(() => _isExecutingTrade = true);
    
    try {
      final provider = context.read<EnergyDataProvider>();
      await provider.executeTrade(tradeId);
      
      Fluttertoast.showToast(
        msg: "✅ Trade executed successfully!",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ ${e.toString().replaceAll('Exception: ', '')}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() => _isExecutingTrade = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        final offers = energyData.offers;
        final trades = energyData.trades;
        final sellOffers = offers.where((o) => o.type == OfferType.sell).length;
        final buyOffers = offers.where((o) => o.type == OfferType.buy).length;
        final pendingTrades = trades.where((t) => t.status == TradeStatus.pending).length;
        final completedTrades = trades.where((t) => t.status == TradeStatus.completed).length;

        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: Colors.grey.shade900.withOpacity(0.9),
                title: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trading Hub',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        Text(
                          'Offers & Trades',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: (energyData.isLoadingOffers || energyData.isLoadingTrades)
                        ? null
                        : () {
                            energyData.loadOffers();
                            energyData.loadTrades();
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                      _showCreateTradeDialog(context);
                    },
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_offer, size: 18),
                          const SizedBox(width: 4),
                          Text('Offers ($sellOffers/$buyOffers)'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, size: 18),
                          const SizedBox(width: 4),
                          Text('Trades ($pendingTrades/$completedTrades)'),
                        ],
                      ),
                    ),
                  ],
                ),
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
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Offers Tab
                _buildOffersTab(energyData, offers, sellOffers, buyOffers),
                
                // Trades Tab
                _buildTradesTab(energyData, trades, pendingTrades, completedTrades),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffersTab(EnergyDataProvider energyData, List<EnergyOffer> offers, int sellOffers, int buyOffers) {
    return CustomScrollView(
      slivers: [
        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Sell Offers', '$sellOffers', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Buy Offers', '$buyOffers', Colors.blue),
                ),
              ],
            ),
          ),
        ),
        
        // Create offer button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateOfferDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create New Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade700),
                    const SizedBox(height: 16),
                    const Text(
                      'No offers available',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a new offer to get started',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Offers list
        if (!energyData.isLoadingOffers)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final offer = offers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OfferCardWidget(
                    offer: offer,
                    onAction: () => _showTradeFromOfferDialog(context, offer),
                  ),
                );
              },
              childCount: offers.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildTradesTab(EnergyDataProvider energyData, List<Trade> trades, int pendingTrades, int completedTrades) {
    return CustomScrollView(
      slivers: [
        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Pending', '$pendingTrades', Colors.yellow),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Completed', '$completedTrades', Colors.green),
                ),
              ],
            ),
          ),
        ),
        
        // Create trade button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateTradeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create New Trade on Blockchain'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
        
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your Trades',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Loading indicator
        if (energyData.isLoadingTrades)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        
        // Empty state
        if (!energyData.isLoadingTrades && trades.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade700),
                    const SizedBox(height: 16),
                    const Text(
                      'No trades yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a trade from the dashboard or here',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Trades list with execute button for pending trades
        if (!energyData.isLoadingTrades)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final trade = trades[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: Colors.grey.shade900,
                    child: Column(
                      children: [
                        TradeCardWidget(trade: trade),
                        if (trade.status == TradeStatus.pending)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isExecutingTrade ? null : () => _executeTrade(trade.id),
                                icon: _isExecutingTrade 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_arrow),
                                label: Text(_isExecutingTrade ? 'Executing...' : 'Execute Trade on Blockchain'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: trades.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: Colors.grey.shade900.withOpacity(0.5),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTradeFromOfferDialog(BuildContext context, EnergyOffer offer) {
    final provider = context.read<EnergyDataProvider>();
    final amountController = TextEditingController(text: offer.kWh.toString());
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          offer.type == OfferType.sell 
            ? 'Buy Energy from ${offer.factoryName}'
            : 'Sell Energy to ${offer.factoryName}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (kWh)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'Price: \$${offer.pricePerKWh.toStringAsFixed(2)}/kWh',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Fluttertoast.showToast(msg: "Please enter a valid amount", backgroundColor: Colors.red);
                return;
              }
              
              Navigator.pop(dialogContext);
              
              try {
                if (offer.type == OfferType.sell) {
                  // Offer is a sell offer, so we buy energy
                  await provider.buyEnergy(
                    sellerFactoryId: offer.factoryId,
                    amount: amount,
                    pricePerUnit: offer.pricePerKWh,
                  );
                } else {
                  // Offer is a buy offer, so we sell energy
                  await provider.sellEnergy(
                    buyerFactoryId: offer.factoryId,
                    amount: amount,
                    pricePerUnit: offer.pricePerKWh,
                  );
                }
                
                Fluttertoast.showToast(
                  msg: "✅ Trade created on blockchain!",
                  backgroundColor: Colors.green,
                );
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "❌ ${e.toString().replaceAll('Exception: ', '')}",
                  backgroundColor: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: offer.type == OfferType.sell ? Colors.blue.shade600 : Colors.green.shade600,
            ),
            child: Text(
              offer.type == OfferType.sell ? 'Buy' : 'Sell',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTradeDialog(BuildContext context) {
    final provider = context.read<EnergyDataProvider>();
    final factories = provider.factories;
    
    if (factories.isEmpty) {
      Fluttertoast.showToast(
        msg: "No other factories available for trading",
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    String? selectedFactoryId = factories.first.id;
    String tradeType = 'buy';
    final amountController = TextEditingController();
    final priceController = TextEditingController(text: '0.10');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text(
              'Create Trade on Blockchain',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trade Type', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tradeType,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey.shade800,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'buy', child: Text('Buy Energy')),
                      DropdownMenuItem(value: 'sell', child: Text('Sell Energy')),
                    ],
                    onChanged: (value) => setDialogState(() => tradeType = value!),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tradeType == 'buy' ? 'Buy From Factory' : 'Sell To Factory',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedFactoryId,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey.shade800,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: factories.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.name, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) => setDialogState(() => selectedFactoryId = value),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  if (amountController.text.isEmpty || priceController.text.isEmpty || selectedFactoryId == null) {
                    Fluttertoast.showToast(msg: "Please fill all fields", backgroundColor: Colors.red);
                    return;
                  }
                  
                  final amount = double.tryParse(amountController.text);
                  final price = double.tryParse(priceController.text);
                  
                  if (amount == null || price == null) {
                    Fluttertoast.showToast(msg: "Please enter valid numbers", backgroundColor: Colors.red);
                    return;
                  }
                  
                  Navigator.pop(dialogContext);
                  
                  try {
                    if (tradeType == 'buy') {
                      await provider.buyEnergy(
                        sellerFactoryId: selectedFactoryId!,
                        amount: amount,
                        pricePerUnit: price,
                      );
                    } else {
                      await provider.sellEnergy(
                        buyerFactoryId: selectedFactoryId!,
                        amount: amount,
                        pricePerUnit: price,
                      );
                    }
                    
                    Fluttertoast.showToast(
                      msg: "✅ Trade created on blockchain!",
                      backgroundColor: Colors.green,
                    );
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: "❌ ${e.toString().replaceAll('Exception: ', '')}",
                      backgroundColor: Colors.red,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600),
                child: const Text('Create Trade', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
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
                    final amount = double.tryParse(amountController.text);
                    final price = double.tryParse(priceController.text);
                    
                    if (amount == null || price == null) {
                      Fluttertoast.showToast(
                        msg: "Please enter valid numbers",
                        backgroundColor: Colors.red,
                      );
                      return;
                    }
                    
                    final provider = context.read<EnergyDataProvider>();
                    await provider.createOffer(
                      offerType: selectedOfferType,
                      energyAmount: amount,
                      pricePerKwh: price,
                    );
                    
                    Navigator.pop(dialogContext);
                    
                    Fluttertoast.showToast(
                      msg: "✅ Offer created successfully!",
                      backgroundColor: Colors.green,
                    );
                  } catch (e) {
                    String errorMessage = e.toString();
                    // Clean up common exception prefixes
                    const prefixes = ['Exception: ', 'Error: '];
                    for (final prefix in prefixes) {
                      if (errorMessage.startsWith(prefix)) {
                        errorMessage = errorMessage.substring(prefix.length);
                      }
                    }
                    Fluttertoast.showToast(
                      msg: "❌ $errorMessage",
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
