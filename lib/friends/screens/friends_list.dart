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

  void _removeFriend(int index) {
    setState(() {
      _friends.removeAt(index);
    });
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
