import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onBack;

  const ProfileScreen({
    super.key,
    required this.onSignOut,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Factory 1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Energy Manager',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
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
                    'Solar Panels',
                    '500 kW',
                  ),
                  const Divider(color: Colors.grey, height: 24),
                  _buildInfrastructureRow(
                    Icons.air,
                    Colors.blue,
                    'Wind Turbines',
                    '300 kW',
                  ),
                  const Divider(color: Colors.grey, height: 24),
                  _buildInfrastructureRow(
                    Icons.battery_charging_full,
                    Colors.purple,
                    'Battery Storage',
                    '200 kWh',
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

          // Notification Preferences
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Notification Preferences',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    'Energy Alerts',
                    'Low energy and surplus notifications',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Trade Offers',
                    'New trading opportunities',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Price Alerts',
                    'Below/above threshold notifications',
                    false,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Contract Executions',
                    'Smart contract activity',
                    true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-Trading Rules
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings, color: Colors.purple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Auto-Trading Rules',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      Switch(
                        value: true,
                        onChanged: (val) {},
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Sell Surplus',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Automatically sell when surplus exceeds 50 kWh at min \$0.10/kWh',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Buy Deficit',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Automatically buy when deficit exceeds 20 kWh at max \$0.15/kWh',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
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
                        'Configure Rules',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security Settings
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Security Settings',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    'Two-Factor Authentication',
                    'Extra security for your account',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Biometric Login',
                    'Use fingerprint or face ID',
                    true,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Text(
                        'Change Password',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Statistics
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Statistics',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Member Since',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              'Jan 2024',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Trades',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              '342',
                              style: TextStyle(color: Colors.white),
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
                              'Energy Traded',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              '12,847 kWh',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Savings',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              '\$4,283',
                              style: TextStyle(color: Colors.greenAccent),
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
            onPressed: onSignOut,
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

  Widget _buildSwitchRow(String title, String subtitle, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (val) {},
          activeColor: Colors.blue,
        ),
      ],
    );
  }
}
