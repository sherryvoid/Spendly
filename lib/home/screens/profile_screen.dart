import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Spendly/friends/screens/friends_list.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Handles logout logic using Firebase Auth
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Navigates back to Home Screen
  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Teal curved background with decorative circles
          ClipPath(
            clipper: _CurvedBottomClipper(),
            child: Container(
              height: size.height * 0.4,
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
          ),

          SafeArea(
            child: Column(
              children: [
                /// Top AppBar row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => _navigateToHome(context),
                      ),
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                /// Avatar and user info from Firestore
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF42A5F5),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                /// Fetch full name and email using Firestore stream
                if (user != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          'User data not found',
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          Text(
                            userData['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            userData['email'] ?? 'No Email',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 15),

                /// List of profile options
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: size.height * 0.08),
                    child: ListView(
                      children: [
                        _buildListTile(
                          leadingIcon: _circleIcon(Icons.diamond),
                          title: "Invite Friends",
                          onTap: () {},
                        ),
                        _buildListTile(
                          leadingIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.black54,
                          ),
                          title: "Personal profile",
                          onTap: () {},
                        ),
                        _buildListTile(
                          leadingIcon: const Icon(
                            Icons.group_outlined,
                            color: Colors.black54,
                          ),
                          title: "Friends",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FriendsListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildListTile(
                          leadingIcon: const Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          title: "Logout",
                          onTap: () => _logout(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Utility method to build a list tile row
  Widget _buildListTile({
    required Widget leadingIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: leadingIcon,
      title: Text(title),
      onTap: onTap,
      splashColor: Colors.grey.withOpacity(0.3),
      hoverColor: Colors.grey.withOpacity(0.1),
      horizontalTitleGap: 12,
    );
  }

  /// Rounded icon container
  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF5BA29C),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

/// Custom clipper for top curved background
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
