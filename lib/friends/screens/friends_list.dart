import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in.");
      return;
    }

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    print("Current user UID: ${user.uid}");
    final friendsCollection = await userDocRef.collection('friends').get();

    print("Fetched ${friendsCollection.docs.length} friend(s).");

    List<Map<String, dynamic>> fetchedFriends = [];

    for (var doc in friendsCollection.docs) {
      final friendId = doc.data()['friendId'];
      if (friendId != null) {
        final friendDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendId)
                .get();
        if (friendDoc.exists) {
          fetchedFriends.add(friendDoc.data()!);
        }
      }
    }

    setState(() {
      _friends = fetchedFriends;
      _isLoading = false;
    });
  }

  void _removeFriend(int index) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final firestore = FirebaseFirestore.instance;
    final friend = _friends[index];
    final friendUid = friend['uid'];

    try {
      final currentUserFriendsRef = firestore
          .collection('users')
          .doc(currentUid)
          .collection('friends');

      final currentQuery =
          await currentUserFriendsRef
              .where('friendId', isEqualTo: friendUid)
              .limit(1)
              .get();

      if (currentQuery.docs.isNotEmpty) {
        await currentUserFriendsRef.doc(currentQuery.docs.first.id).delete();
      }

      final friendUserFriendsRef = firestore
          .collection('users')
          .doc(friendUid)
          .collection('friends');

      final friendQuery =
          await friendUserFriendsRef
              .where('friendId', isEqualTo: currentUid)
              .limit(1)
              .get();

      if (friendQuery.docs.isNotEmpty) {
        await friendUserFriendsRef.doc(friendQuery.docs.first.id).delete();
      }

      setState(() {
        _friends.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Friend removed"),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing friend: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Friends'),
        backgroundColor: const Color(0xFF2E6D6A),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
              ? const Center(child: Text('No friends added yet.'))
              : ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          friend['profileImage'] != null
                              ? NetworkImage(friend['profileImage'])
                              : null,
                      child:
                          friend['profileImage'] == null
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(friend['name'] ?? 'Unknown'),
                    subtitle: Text(friend['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeFriend(index),
                    ),
                  );
                },
              ),
    );
  }
}
