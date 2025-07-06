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
                              onPressed: () async {
                                final wasAdded = await _inviteUser(
                                  searchedUser!['uid'],
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        wasAdded
                                            ? 'Friend added!'
                                            : 'Friend is already added.',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );

                                  if (wasAdded) {
                                    Navigator.pop(
                                      context,
                                    ); // Only close if newly added
                                  }
                                }
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

  Future<bool> _inviteUser(String friendUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;
    if (currentUid == null || currentUid == friendUid) return false;

    final firestore = FirebaseFirestore.instance;

    final currentUserDoc = firestore.collection('users').doc(currentUid);
    final friendUserDoc = firestore.collection('users').doc(friendUid);

    final currentUserFriendsRef = currentUserDoc.collection('friends');
    final friendUserFriendsRef = friendUserDoc.collection('friends');

    final existingCurrentFriendQuery =
        await currentUserFriendsRef
            .where('friendId', isEqualTo: friendUid)
            .limit(1)
            .get();

    final alreadyAdded = existingCurrentFriendQuery.docs.isNotEmpty;

    if (!alreadyAdded) {
      // Add friend entry to both users
      await currentUserFriendsRef.add({
        'friendId': friendUid,
        'addedAt': FieldValue.serverTimestamp(),
      });

      await friendUserFriendsRef.add({
        'friendId': currentUid,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Get current user's name
      final currentUserSnapshot = await currentUserDoc.get();
      final currentUserName = currentUserSnapshot.data()?['name'] ?? 'Unknown';

      // Add notification to friend's notifications subcollection
      await friendUserDoc.collection('notifications').add({
        'type': 'friend added',
        'name': currentUserName,
        'time': FieldValue.serverTimestamp(),
        'description':
            "You've been added as a friend by $currentUserName, you can now split expenses together!",
        'read': false,
      });
    }

    return !alreadyAdded;
  }
}
