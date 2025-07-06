import 'package:Spendly/home/screens/profile_screen.dart';
import 'package:Spendly/home/screens/stats_screen.dart';
import 'package:Spendly/home/screens/wallet_screen.dart';
import 'package:Spendly/home/screens/all_notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  String selectedCategory = 'All';
  final themeColor = const Color(0xFF2E6D6A);

  List<String> _getAvailableCategories(List<QueryDocumentSnapshot> logs) {
    final categories =
        logs
            .map(
              (doc) =>
                  (doc.data() as Map<String, dynamic>)['category'] ?? 'Unknown',
            )
            .toSet()
            .toList();
    categories.sort();
    return ['All', ...categories];
  }

  // Assigns different colors to each transaction avatar
  Color _getRandomColor(int index) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }

  // Returns greeting based on current hour
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isHome = index == 0;

    return Scaffold(
      body:
          isHome
              ? _buildHomeScreen(size)
              : _screens[index], // navigate to other tabs
      // FAB to add new expense
      floatingActionButton:
          isHome
              ? FloatingActionButton(
                onPressed: () => Navigator.pushNamed(context, '/expense'),
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFF5BA29C),
                child: const Icon(
                  CupertinoIcons.add,
                  size: 30,
                  color: Colors.white,
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5BA29C),
        unselectedItemColor: const Color(0xFFB7B7B7),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: 'stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard),
            label: 'wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(Size size) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final name = userData['name'] ?? 'User';

        return StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('balances')
                  .doc('current')
                  .snapshots(),
          builder: (context, balanceSnapshot) {
            if (!balanceSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final balanceData =
                balanceSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final balance = (balanceData['balance'] as num?)?.toDouble() ?? 0.0;
            final lastUpdated =
                (balanceData['lastUpdated'] as Timestamp?)?.toDate();

            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('expenses')
                      .orderBy('date', descending: true)
                      .snapshots(),
              builder: (context, logsSnapshot) {
                if (!logsSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final logs = logsSnapshot.data!.docs;
                final categories = _getAvailableCategories(logs);

                // Filter logs based on selected category
                final filteredLogs =
                    selectedCategory == 'All'
                        ? logs
                        : logs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['category'] == selectedCategory;
                        }).toList();

                return Stack(
                  children: [
                    _buildCurvedBackground(size),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25.0,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting & Notifications
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                NotificationButton(),
                              ],
                            ),

                            const SizedBox(height: 15),
                            _buildBalanceCard(balance, lastUpdated),
                            const SizedBox(height: 30),

                            // Transactions Header + Filter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Transactions History",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: themeColor,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedCategory,
                                      items:
                                          categories.map((category) {
                                            return DropdownMenuItem<String>(
                                              value: category,
                                              child: Text(category),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedCategory = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // Transaction List
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredLogs.length,
                                itemBuilder: (context, i) {
                                  final log =
                                      filteredLogs[i].data()
                                          as Map<String, dynamic>;
                                  final category = log['category'] ?? 'Unknown';
                                  final desc = log['description'] ?? '';
                                  final amount =
                                      (log['amount'] as num).toDouble();
                                  final date =
                                      (log['date'] as Timestamp?)?.toDate();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      elevation: 0,
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.white,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 8,
                                            ),
                                        leading: CircleAvatar(
                                          radius: 20,
                                          backgroundColor: _getRandomColor(i),
                                          child: Text(
                                            category.isNotEmpty
                                                ? category[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          desc.length > 40
                                              ? '${desc.substring(0, 40)}...'
                                              : desc,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${amount >= 0 ? '-' : '+'} \$${amount.abs().toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color:
                                                    amount >= 0
                                                        ? Colors.red
                                                        : Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              date != null
                                                  ? DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(date)
                                                  : 'Unknown Date',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap:
                                            () => _showFullDescription(
                                              context,
                                              category,
                                              desc,
                                              date != null
                                                  ? DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(date)
                                                  : '',
                                              amount,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Top green background design
  Widget _buildCurvedBackground(Size size) {
    return ClipPath(
      clipper: _CurvedBottomClipper(),
      child: Container(
        height: size.height * 0.25,
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

  // Balance card widget
  Widget _buildBalanceCard(double balance, DateTime? lastUpdated) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2E6D6A),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              Image.asset('assets/images/card_chip.png', width: 35),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spendly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LAST UPDATED\n${lastUpdated != null ? DateFormat('MMM dd, yyyy').format(lastUpdated).toUpperCase() : 'UNKNOWN'}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modern centered modal to show full transaction info
  void _showFullDescription(
    BuildContext context,
    String category,
    String description,
    String date,
    double amount,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxWidth: 350,
                minHeight: 200,
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E6D6A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 24,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount
                    Row(
                      children: [
                        Icon(
                          amount >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: amount >= 0 ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: amount >= 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Close button
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BA29C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Screens for navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const WalletScreen(), // can replace with a separate transaction screen
    const ProfileScreen(),
  ];
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
