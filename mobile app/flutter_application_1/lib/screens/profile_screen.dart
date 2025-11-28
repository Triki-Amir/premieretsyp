import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/energy_data_provider.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  final VoidCallback onBack;

  const ProfileScreen({
    super.key,
    required this.onSignOut,
    required this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSeeding = false;

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
    });

    try {
      final provider = context.read<EnergyDataProvider>();
      final result = await provider.seedDatabase();
      
      if (!mounted) return;
      
      Fluttertoast.showToast(
        msg: "✅ Database seeded successfully! ${result['factoriesCreated']} factories created.",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      if (!mounted) return;
      
      Fluttertoast.showToast(
        msg: "❌ Error seeding database: ${e.toString().replaceAll('Exception: ', '')}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        final factory = energyData.currentUserFactory;
        final factoryName = factory?['factory_name'] ?? 'My Factory';
        final email = factory?['email'] ?? 'Not logged in';
        final energyCapacity = factory?['energy_capacity'] ?? 500;
        final energySource = factory?['energy_source'] ?? 'Mixed';
        final localisation = factory?['localisation'] ?? 'Unknown';
        
        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          appBar: AppBar(
            backgroundColor: Colors.grey.shade900.withOpacity(0.5),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
            title: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Gen Power',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        'Account Settings',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Header
              Card(
                color: Colors.grey.shade900.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.purple.shade600,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factoryName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              localisation,
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Seed Database Button - NEW
              Card(
                color: Colors.orange.shade900.withOpacity(0.3),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600.withOpacity(0.2),
                        Colors.orange.shade800.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade600.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dataset, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Database Management',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Populate the database with sample factories, offers, and trades for testing.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSeeding ? null : _seedDatabase,
                          icon: _isSeeding 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.add_circle),
                          label: Text(_isSeeding ? 'Seeding...' : 'Seed Database'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Infrastructure Overview
              Card(
                color: Colors.grey.shade900.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.factory, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Infrastructure Capacity',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfrastructureRow(
                        Icons.wb_sunny,
                        Colors.yellow,
                        'Energy Source',
                        energySource,
                      ),
                      const Divider(color: Colors.grey, height: 24),
                      _buildInfrastructureRow(
                        Icons.battery_charging_full,
                        Colors.purple,
                        'Total Capacity',
                        '$energyCapacity kW',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Connection Status
              Card(
                color: Colors.grey.shade900.withOpacity(0.5),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (energyData.isConnectedToBackend 
                            ? Colors.green.shade600 
                            : Colors.red.shade600).withOpacity(0.2),
                        (energyData.isConnectedToBackend 
                            ? Colors.green.shade800 
                            : Colors.red.shade800).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (energyData.isConnectedToBackend 
                          ? Colors.green.shade600 
                          : Colors.red.shade600).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        energyData.isConnectedToBackend 
                            ? Icons.cloud_done 
                            : Icons.cloud_off,
                        color: energyData.isConnectedToBackend 
                            ? Colors.green 
                            : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              energyData.isConnectedToBackend 
                                  ? 'Connected to Backend' 
                                  : 'Disconnected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              energyData.isConnectedToBackend 
                                  ? 'All data is synced with the server' 
                                  : 'Using offline mode',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Validator Status
              Card(
                color: Colors.grey.shade900.withOpacity(0.5),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade600.withOpacity(0.2),
                        Colors.green.shade800.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade600.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.emoji_events, color: Colors.greenAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Validator Tier',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Gold',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Rewards',
                                  style: TextStyle(
                                    color: Colors.green.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  '1,247 ECT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staked Amount',
                                  style: TextStyle(
                                    color: Colors.green.shade300,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  '5,000 ECT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(height: 16),

              // Action Buttons
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    'Export Report',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    'Help & Support',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Clear session and sign out
                  context.read<EnergyDataProvider>().clearSession();
                  widget.onSignOut();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfrastructureRow(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
