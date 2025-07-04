import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteFriendsTile extends StatelessWidget {
  final Widget leadingIcon;

  const InviteFriendsTile({super.key, required this.leadingIcon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leadingIcon,
      title: const Text("Invite Friends"),
      onTap: () => _showInvitePopup(context),
    );
  }

  void _showInvitePopup(BuildContext context) {
    final TextEditingController _emailController = TextEditingController();
    Map<String, dynamic>? searchedUser;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final mediaQuery = MediaQuery.of(context);
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      mediaQuery
                          .viewInsets
                          .bottom, // pushes dialog above keyboard
                ),
                child: AlertDialog(
                  contentPadding: const EdgeInsets.all(16),
                  title: const Text("Invite a Friend"),
                  content: SizedBox(
                    width: mediaQuery.size.width * 0.80,
                    height: mediaQuery.size.height * 0.3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: "Enter friend's email",
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result =
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .where(
                                        'email',
                                        isEqualTo: _emailController.text,
                                      )
                                      .limit(1)
                                      .get();
                              if (result.docs.isNotEmpty) {
                                final doc = result.docs.first;
                                setState(() {
                                  searchedUser = {'uid': doc.id, ...doc.data()};
                                });
                              } else {
                                setState(() {
                                  searchedUser = null;
                                });
                                print('No user found');
                              }
                            },
                            child: const Text("Search"),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (searchedUser != null)
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(searchedUser!['name'] ?? 'Unnamed'),
                            subtitle: Text(
                              searchedUser!['email'] ?? 'No Email',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                _inviteUser(searchedUser!['uid']);
                                Navigator.pop(context);
                              },
                              child: const Text("Invite"),
                            ),
                          )
                        else if (_emailController.text.isNotEmpty)
                          const Text("No user found"),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _inviteUser(String friendUid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid == friendUid) return;

    final firestore = FirebaseFirestore.instance;

    final currentUserFriendsRef = firestore
        .collection('users')
        .doc(currentUid)
        .collection('friends');

    final friendUserFriendsRef = firestore
        .collection('users')
        .doc(friendUid)
        .collection('friends');

    // Check if already exists in current user's friend list
    final existingCurrentFriendQuery =
        await currentUserFriendsRef
            .where('friendId', isEqualTo: friendUid)
            .limit(1)
            .get();

    if (existingCurrentFriendQuery.docs.isEmpty) {
      await currentUserFriendsRef.add({
        'friendId': friendUid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    // Check if already exists in invited user's friend list
    final existingFriendFriendQuery =
        await friendUserFriendsRef
            .where('friendId', isEqualTo: currentUid)
            .limit(1)
            .get();

    if (existingFriendFriendQuery.docs.isEmpty) {
      await friendUserFriendsRef.add({
        'friendId': currentUid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
