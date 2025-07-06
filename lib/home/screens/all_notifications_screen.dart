import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Spendly/utils/timeFormatter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Icon _getNotificationIcon(String? type, Color themeColor) {
    switch (type) {
      case 'message':
        return Icon(Icons.chat_bubble, color: themeColor);
      case 'order':
        return Icon(Icons.local_shipping, color: themeColor);
      case 'reminder':
        return Icon(Icons.calendar_today, color: themeColor);
      case 'update':
        return Icon(Icons.update, color: themeColor);
      case 'friend added':
        return Icon(Icons.person_add, color: themeColor);
      case 'split':
        return Icon(Icons.attach_money, color: themeColor);
      case 'password':
        return Icon(Icons.lock, color: themeColor);
      default:
        return Icon(Icons.notifications, color: themeColor); // Default icon
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);
    final notificationsRef = userRef.collection('notifications');

    final snapshot =
        await notificationsRef.orderBy('time', descending: true).get();

    // Mark all unread notifications as read
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      if (doc['read'] == false) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E6D6A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final icon = _getNotificationIcon(
                notification['type'],
                themeColor,
              );

              return ListTile(
                leading: icon,
                title: Text(
                  notification['description'] ?? '',

                  // notification['name'] + " added you as a friend" ?? '',
                  style: const TextStyle(fontSize: 16),
                ),

                subtitle: Text(
                  formatTimestamp(notification['time']),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                // subtitle: Text(
                //   notification['time']?.toString() ?? '',
                //   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                // ),
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Exportable button in the same file
class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .where('read', isEqualTo: false);

    return StreamBuilder<QuerySnapshot>(
      stream: notificationsRef.snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
