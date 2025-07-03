// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Spendly/home/widgets/notifications_popup.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _balanceController = TextEditingController();

  bool _isLoading = false;
  String _cardName = 'NameXXX';
  double _cardBalance = 0.0;
  String _lastUpdated = '---';

  @override
  void initState() {
    super.initState();
    _fetchCardData();
  }

  Future<void> _fetchCardData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get card name from /users/{uid}
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _cardName = userDoc.data()?['name'] ?? 'NameXXX';
      }

      // Get balance from /users/{uid}/balances/current
      final cardDoc =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('balances')
              .doc('current')
              .get();
      if (cardDoc.exists) {
        setState(() {
          _cardBalance = (cardDoc.data()?['balance'] ?? 0).toDouble();
          final ts = cardDoc.data()?['lastUpdated'];
          if (ts != null) {
            _lastUpdated = DateFormat(
              'MM/dd/yyyy',
            ).format((ts as Timestamp).toDate());
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching card info: $e');
    }
  }

  Future<void> _updateCard() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final entered = _balanceController.text.trim();
    if (entered.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter balance')));
      return;
    }

    final addAmount = double.tryParse(entered);
    if (addAmount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cardRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('balances')
          .doc('current');

      final doc = await cardRef.get();
      final current = (doc.data()?['balance'] ?? 0).toDouble();
      final updatedBalance = current + addAmount;

      await cardRef.set({
        'balance': updatedBalance,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Add to balance_logs
      await _firestore.collection('users').doc(uid).collection('expenses').add({
        'category': 'Money Added',
        'description': '🤑🤑🤑',
        'amount': -addAmount, // negative to represent income visually
        'date': FieldValue.serverTimestamp(),
      });

      _balanceController.clear();
      await _fetchCardData();
      Navigator.pushReplacementNamed(context, '/home');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Balance updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goBack() => Navigator.pushReplacementNamed(context, '/home');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _BackgroundCurve(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: _goBack,
                        ),
                        const Text(
                          "Update Balance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        NotificationButton(),
                        // const Icon(Icons.notifications, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Card
                    _BalanceCard(name: _cardName, lastUpdated: _lastUpdated),

                    const SizedBox(height: 30),

                    // TextField(
                    //   readOnly: true,
                    //   controller: TextEditingController(
                    //     text: "\$${_cardBalance.toStringAsFixed(2)}",
                    //   ),
                    //   decoration: const InputDecoration(
                    //     labelText: "Current Balance",
                    //     border: OutlineInputBorder(),
                    //   ),
                    // ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Current Balance",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "\$${_cardBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    TextField(
                      controller: _balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Add Balance",
                        hintText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BA29C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Update',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Decorative background
class _BackgroundCurve extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ClipPath(
      clipper: _CurvedBottomClipper(),
      child: Container(
        height: size.height * 0.3,
        color: const Color(0xFF2E6D6A),
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: size.height * 0.05,
              right: -size.width * 0.35,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card Widget
class _BalanceCard extends StatelessWidget {
  final String name;
  final String lastUpdated;

  const _BalanceCard({required this.name, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E6D6A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 8),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget\nCard',
                style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
              ),
              Text(
                'Spendly',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0000  0000  0000  0000',
                style: TextStyle(color: Colors.white, letterSpacing: 3),
              ),
              Image.asset('assets/images/card_chip.png', width: 35),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'LAST UPDATED',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    lastUpdated,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
