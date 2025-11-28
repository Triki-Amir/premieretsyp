import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlockchainScreen extends StatefulWidget {
  final VoidCallback onBack;

  const BlockchainScreen({super.key, required this.onBack});

  @override
  State<BlockchainScreen> createState() => _BlockchainScreenState();
}

class _BlockchainScreenState extends State<BlockchainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _truncateHash(String hash) {
    return '${hash.substring(0, 10)}...${hash.substring(hash.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
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
                    'Blockchain Explorer',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    'Live transaction feed',
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
          // Wallet Summary Card
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600.withOpacity(0.2),
                    Colors.purple.shade600.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade600.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Token Balance',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '2,847 ECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Energy Credit Tokens',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.qr_code, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Send', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Receive', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Block Height
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Block Height',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1,234,567',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Transactions Feed
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Transactions',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Row(
                        children: [
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Live',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTransactionItem(
                    icon: Icons.bolt,
                    iconColor: Colors.yellow,
                    title: 'Solar generation',
                    type: 'generation',
                    typeColor: Colors.yellow,
                    amount: '45.3 kWh',
                    time: DateTime.now().subtract(const Duration(minutes: 5)),
                    hash: '0x7f9fade1c0d57a7af66ab4ead79fade1c0d57a7af66ab4ead7c2c2eb7b11a91385',
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionItem(
                    icon: Icons.swap_horiz,
                    iconColor: Colors.blue,
                    title: 'P2P Trade with Factory 2',
                    type: 'trade',
                    typeColor: Colors.blue,
                    amount: '30 kWh',
                    time: DateTime.now().subtract(const Duration(minutes: 15)),
                    hash: '0x9f2fade1c0d57a7af66ab4ead79fade1c0d57a7af66ab4ead7c2c2eb7b11a91456',
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionItem(
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                    title: 'Payment received',
                    type: 'payment',
                    typeColor: Colors.green,
                    amount: '\$5.4',
                    time: DateTime.now().subtract(const Duration(hours: 2)),
                    hash: '0x3f8fade1c0d57a7af66ab4ead79fade1c0d57a7af66ab4ead7c2c2eb7b11a91789',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Latest Block
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Block',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Block Number', '1,234,567'),
                  _buildStatRow('Timestamp', TimeOfDay.now().format(context)),
                  _buildStatRow('Transactions', '23'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Block Hash',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Text(
                            '0x7f9fade...91385',
                            style: TextStyle(
                              color: Colors.purple.shade400,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.open_in_new, size: 12, color: Colors.grey),
                        ],
                      ),
                    ],
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Validator Status',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rewards Earned',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 10,
                            ),
                          ),
                          const Text(
                            '147 ECT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                              'Uptime',
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 12,
                              ),
                            ),
                            const Text(
                              '99.8%',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blocks Validated',
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 12,
                              ),
                            ),
                            const Text(
                              '1,247',
                              style: TextStyle(color: Colors.white, fontSize: 16),
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

          // QR Code Scanner Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
              ),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String type,
    required Color typeColor,
    required String amount,
    required DateTime time,
    required String hash,
  }) {
    return Card(
      color: Colors.grey.shade800.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade700.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _truncateHash(hash),
                              style: TextStyle(
                                color: Colors.purple.shade400,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(hash),
                            child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        amount,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
