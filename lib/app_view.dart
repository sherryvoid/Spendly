// import 'package:expense_tracker/auth/screens/onboarding_screen.dart';
// import 'package:expense_tracker/auth/screens/splash_screen.dart';
// import 'package:expense_tracker/home/screens/dashboard_screen.dart';
// import 'package:expense_tracker/home/screens/profile_screen.dart';
// import 'package:flutter/material.dart';

// class MyAppView extends StatefulWidget {
//   const MyAppView({super.key});

//   @override
//   State<MyAppView> createState() => _MyAppViewState();
// }

// class _MyAppViewState extends State<MyAppView> {
//   int _selectedIndex = 0;

//   final List<Widget> _pages = [const DashboardScreen(), const ProfileScreen()];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Expense Tracker',
//       theme: ThemeData(
//         scaffoldBackgroundColor: Colors.grey[100],
//         colorScheme: ColorScheme.light(
//           primary: const Color(0xFF5BA29C),
//           secondary: const Color(0xFFE064F7),
//           tertiary: const Color(0xFFFF8D6C),
//           outline: Colors.blueGrey,
//         ),
//       ),
//       home: Scaffold(
//         body: _pages[_selectedIndex],
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//           selectedItemColor: const Color(0xFF5BA29C),
//           unselectedItemColor: Colors.grey,
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//             BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//           ],
//         ),
//       ),
//       routes: {
//         '/onboarding': (context) => const OnboardingScreen(),
//         '/splash': (context) => const SplashScreen(),
//       },
//     );
//   }
// }



// home
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:expense_tracker/home/screens/profile_screen.dart';
// import 'package:expense_tracker/home/screens/stats_screen.dart';
// import 'package:expense_tracker/home/screens/wallet_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int index = 0;

//   final List<Map<String, dynamic>> dummyTransactions = [
//     {'name': 'Upwork', 'date': 'Today', 'amount': 850.00, 'isIncome': true},
//     {
//       'name': 'Transfer',
//       'date': 'Yesterday',
//       'amount': 85.00,
//       'isIncome': false,
//     },
//     {
//       'name': 'Paypal',
//       'date': 'Jan 30, 2022',
//       'amount': 1406.00,
//       'isIncome': true,
//     },
//     {
//       'name': 'Youtube',
//       'date': 'Jan 16, 2022',
//       'amount': 11.99,
//       'isIncome': false,
//     },
//     {
//       'name': 'Netflix',
//       'date': 'Jan 14, 2022',
//       'amount': 13.99,
//       'isIncome': false,
//     },
//   ];

//   final List<Color> _avatarColors = [
//     Color(0xFF5BA29C),
//     Color(0xFF42A5F5),
//     Color(0xFFEF5350),
//     Color(0xFFFFCA28),
//   ];

//   final List<Widget> _screens = [
//     const Placeholder(), // Home content will go here
//     const StatsScreen(),
//     const WalletScreen(),
//     const ProfileScreen(),
//   ];

//   String _getGreeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Good morning,';
//     if (hour < 17) return 'Good afternoon,';
//     return 'Good evening,';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     final isHome = index == 0;

//     return Scaffold(
//       body:
//           index == 0
//               ? Stack(
//                 children: [
//                   ClipPath(
//                     clipper: _CurvedBottomClipper(),
//                     child: Container(
//                       height: size.height * 0.25,
//                       color: const Color(0xFF2E6D6A),
//                       child: Stack(
//                         children: [
//                           Positioned(
//                             top: -size.height * 0.15,
//                             left: -size.width * 0.25,
//                             child: Container(
//                               width: size.width * 0.9,
//                               height: size.width * 0.9,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: Colors.white.withOpacity(0.1),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             top: size.height * 0.05,
//                             right: -size.width * 0.35,
//                             child: Container(
//                               width: size.width * 0.7,
//                               height: size.width * 0.7,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: Colors.white.withOpacity(0.1),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SafeArea(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 25.0,
//                         vertical: 10,
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Header
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     _getGreeting(),
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   const Text(
//                                     'Shaheryar Ghous',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.notifications,
//                                   color: Colors.white,
//                                 ),
//                                 onPressed: () {},
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 15),

//                           // Balance card
//                           Container(
//                             padding: const EdgeInsets.all(20),
//                             width: double.infinity,
//                             height: 200,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF2E6D6A),
//                               borderRadius: BorderRadius.circular(25),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.15),
//                                   offset: const Offset(0, 8),
//                                   blurRadius: 10,
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     const Text(
//                                       'Total Balance',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                     Image.asset(
//                                       'assets/images/card_chip.png',
//                                       width: 35,
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 const Text(
//                                   r'$ 2,548.00',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const Spacer(),
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: const [
//                                     Text(
//                                       'Spendly',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Text(
//                                       'LAST UPDATED\n05/10/2024',
//                                       textAlign: TextAlign.right,
//                                       style: TextStyle(
//                                         color: Colors.white54,
//                                         fontSize: 10,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 30),
//                           const Text(
//                             'Transactions History',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 15),

//                           // Transactions list
//                           Expanded(
//                             child: ListView.builder(
//                               padding: EdgeInsets.zero,
//                               itemCount: dummyTransactions.length,
//                               itemBuilder: (context, i) {
//                                 final tx = dummyTransactions[i];
//                                 return Container(
//                                   margin: const EdgeInsets.only(bottom: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[100],
//                                     borderRadius: BorderRadius.circular(15),
//                                   ),
//                                   child: ListTile(
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 15,
//                                       vertical: 5,
//                                     ),
//                                     leading: CircleAvatar(
//                                       radius: 20,
//                                       backgroundColor:
//                                           _avatarColors[i %
//                                               _avatarColors.length],
//                                       child: Text(
//                                         tx['name'][0],
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 18,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                     title: Text(
//                                       tx['name'],
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                                     subtitle: Text(tx['date']),
//                                     trailing: Text(
//                                       "${tx['isIncome'] ? '+' : '-'} \$${tx['amount'].toStringAsFixed(2)}",
//                                       style: TextStyle(
//                                         color:
//                                             tx['isIncome']
//                                                 ? Colors.green
//                                                 : Colors.red,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//               : _screens[index],

//       floatingActionButton:
//           isHome
//               ? FloatingActionButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/expense');
//                 },
//                 shape: const CircleBorder(),
//                 backgroundColor: const Color(0xFF5BA29C),
//                 child: const Icon(
//                   CupertinoIcons.add,
//                   size: 30,
//                   color: Colors.white,
//                 ),
//               )
//               : null,

//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

//       bottomNavigationBar: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//         child: BottomNavigationBar(
//           currentIndex: index,
//           onTap: (value) => setState(() => index = value),
//           backgroundColor: Colors.white,
//           showSelectedLabels: false,
//           showUnselectedLabels: false,
//           type: BottomNavigationBarType.fixed,
//           selectedItemColor: const Color(0xFF5BA29C),
//           unselectedItemColor: const Color(0xFFB7B7B7),
//           elevation: 8,
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.home),
//               label: 'home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.chart_bar),
//               label: 'stats',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.creditcard),
//               label: 'wallet',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(CupertinoIcons.person),
//               label: 'profile',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Curved background clipper
// class _CurvedBottomClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//     path.lineTo(0, size.height - 30);
//     path.quadraticBezierTo(
//       size.width / 2,
//       size.height,
//       size.width,
//       size.height - 30,
//     );
//     path.lineTo(size.width, 0);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
// }