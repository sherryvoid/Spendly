import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplitExpenseButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;
  final String amount;
  final bool isAmountEntered;
  final Function(List<Map<String, dynamic>>) onSplitUpdated;

  const SplitExpenseButton({
    super.key,
    required this.onPressed,
    required this.isSubmitting,
    required this.amount,
    required this.isAmountEntered,
    required this.onSplitUpdated,
  });

  @override
  State<SplitExpenseButton> createState() => _SplitExpenseButtonState();
}

class _SplitExpenseButtonState extends State<SplitExpenseButton> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> selectedFriends = [];
  Map<String, double> friendSplits = {};
  List<Map<String, dynamic>> splitFriends = [];
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

    final friendsCollection = await userDocRef.collection('friends').get();

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
          fetchedFriends.add({
            ...friendDoc.data()!,
            'uid': friendDoc.id, // ensure we store the UID for comparison
          });
        }
      }
    }

    setState(() {
      _friends = fetchedFriends;
      _isLoading = false;
    });
  }

  void _calculateSplit() {
    final double totalAmount = double.tryParse(widget.amount) ?? 0;

    if (selectedFriends.isEmpty) return;

    List<Map<String, dynamic>> tempSplit = List.from(selectedFriends);
    tempSplit.add({'name': 'Me', 'uid': 'me'}); // Include self

    final double splitAmount = totalAmount / tempSplit.length;

    splitFriends =
        tempSplit.map((friend) {
          return {
            ...friend,
            'amount': double.parse(splitAmount.toStringAsFixed(2)),
          };
        }).toList();
  }

  void _showFriendSelectionDialog() {
    List<Map<String, dynamic>> tempSelected = List.from(selectedFriends);
    List<Map<String, dynamic>> filteredFriends = List.from(_friends);

    showDialog(
      context: context,
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Friends"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search friends",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        search = value.toLowerCase();
                        setDialogState(() {
                          filteredFriends =
                              _friends
                                  .where(
                                    (friend) => (friend['name'] as String)
                                        .toLowerCase()
                                        .contains(search),
                                  )
                                  .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = filteredFriends[index];
                          final isSelected = tempSelected.any(
                            (f) => f['uid'] == friend['uid'],
                          );
                          return CheckboxListTile(
                            title: Text(friend['name'] ?? 'Unknown'),
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelected.add(friend);
                                } else {
                                  tempSelected.removeWhere(
                                    (f) => f['uid'] == friend['uid'],
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFriends = List.from(tempSelected);
                      _calculateSplit();
                    });
                    // Notify the parent widget with updated data
                    widget.onSplitUpdated(splitFriends);

                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedFriendsList() {
    if (splitFriends.isEmpty) return const SizedBox.shrink();

    List<Widget> chips =
        splitFriends.map((friend) {
          final name = friend['name'] ?? 'Unknown';
          final amount = friend['amount']?.toStringAsFixed(2) ?? '0.00';

          return Chip(
            label: Text("$name: \$$amount"),
            deleteIcon: friend['uid'] != 'me' ? const Icon(Icons.close) : null,
            onDeleted:
                friend['uid'] != 'me'
                    ? () {
                      setState(() {
                        selectedFriends.removeWhere(
                          (f) => f['uid'] == friend['uid'],
                        );
                        _calculateSplit();
                      });
                    }
                    : null,
          );
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Split With:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF5BA29C)),
              onPressed: _showFriendSelectionDialog,
              tooltip: "Edit Friends",
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: chips),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled =
        widget.isSubmitting || !widget.isAmountEntered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: isButtonDisabled ? null : _showFriendSelectionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BA29C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Split Expense",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        _buildSelectedFriendsList(),
      ],
    );
  }
}
