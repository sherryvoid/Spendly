// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Spendly/home/widgets/split_expense.dart';
import 'package:Spendly/home/widgets/add_category_dialog.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> defaultCategories = [
    'Food',
    'Traveling',
    'Shopping',
    'Entertainment',
    'Grocery',
    'Health',
    'Bills',
    'Transport',
  ];

  List<String> customCategories = [];

  List<String> categories = [];

  List<Map<String, dynamic>> selectedFriends = [];
  Map<String, double> friendSplits = {};

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Entertainment';
  bool _isSubmitting = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _amountController.addListener(_onAmountChanged);
  }

  Future<void> _loadCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('categories')
            .get();

    customCategories =
        snapshot.docs
            .map((doc) => doc.data()['name'] as String?)
            .whereType<String>()
            .where((cat) => !defaultCategories.contains(cat))
            .toList();

    setState(() {
      categories = [...defaultCategories, ...customCategories];
    });
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearAmount() {
    _amountController.clear();
  }

  Future<void> _submitExpense() async {
    final currentUser = _auth.currentUser;
    final currentUid = currentUser?.uid;

    if (currentUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    final description = _descriptionController.text.trim();
    final amountStr = _amountController.text.trim();

    if (description.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // If no split, just add for current user
      if (selectedFriends.isEmpty) {
        final userExpenseRef = _firestore
            .collection('users')
            .doc(currentUid)
            .collection('expenses');

        await userExpenseRef.add({
          'description': description,
          'amount': amount,
          'category': _selectedCategory,
          'date': _selectedDate,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final balanceRef = _firestore
            .collection('users')
            .doc(currentUid)
            .collection('balances')
            .doc('current');

        final balanceSnapshot = await balanceRef.get();
        final currentBalance =
            (balanceSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;

        final newBalance = currentBalance - amount;

        await balanceRef.set({
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // For split: loop over selectedFriends and add expense to each
        for (var friend in selectedFriends) {
          // Replace 'me' with actual current user's UID
          final rawUid = friend['uid'];
          final uid = rawUid == 'me' ? currentUid : rawUid;

          final friendAmount = (friend['amount'] as num).toDouble();

          final friendExpenseRef = _firestore
              .collection('users')
              .doc(uid)
              .collection('expenses');

          await friendExpenseRef.add({
            'description': description,
            'amount': friendAmount,
            'category': _selectedCategory,
            'date': _selectedDate,
            'createdAt': FieldValue.serverTimestamp(),
            'addedBy': currentUid,
          });

          final friendBalanceRef = _firestore
              .collection('users')
              .doc(uid)
              .collection('balances')
              .doc('current');

          final friendBalanceSnap = await friendBalanceRef.get();
          final currentBalance =
              (friendBalanceSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

          final updatedBalance = currentBalance - friendAmount;

          await friendBalanceRef.set({
            'balance': updatedBalance,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (uid != currentUid) {
            final friendUserDoc = _firestore.collection('users').doc(uid);

            await friendUserDoc.collection('notifications').add({
              'type': 'split',
              'splitter': FirebaseAuth.instance.currentUser?.displayName ?? '',
              'splitterId': FirebaseAuth.instance.currentUser?.uid ?? '',
              'time': FieldValue.serverTimestamp(),
              'description':
                  '${FirebaseAuth.instance.currentUser?.displayName} split an expense of $friendAmount with you: "$description".',
              'read': false,
            });
          }
        }
      }

      // Reset UI
      _descriptionController.clear();
      _amountController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Expense(s) added and balance(s) updated"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E6D6A);
    final lightGray = Colors.grey.shade400;

    return Scaffold(
      body: Stack(
        children: [
          // Background with curves and circles
          ClipPath(
            clipper: _CurvedBottomClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.25,
              color: themeColor,
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    left: -100,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: -90,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // App Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        BackButton(color: Colors.white),
                        Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.ellipsis_vertical,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Card Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(top: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          const Text(
                            "Description",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              hintText: 'e.g. Mcdonalds Lunch',
                              hintStyle: TextStyle(color: lightGray),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Amount",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),

                          // Amount + Clear
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: themeColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '\$ 48.00',
                                      hintStyle: TextStyle(color: lightGray),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _clearAmount,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Clear",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Date",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),

                          // Date Picker
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade100,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEE, dd MMM yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.calendar,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Text(
                            "Category",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),

                          // Category Selection
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              // Default categories
                              ...defaultCategories.map((cat) {
                                final isSelected = cat == _selectedCategory;
                                return GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => _selectedCategory = cat,
                                      ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? themeColor
                                                : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      color:
                                          isSelected
                                              ? themeColor.withOpacity(0.05)
                                              : Colors.white,
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isSelected
                                                ? themeColor
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              // Custom categories with delete button (no divider)
                              ...customCategories.map((cat) {
                                final isSelected = cat == _selectedCategory;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? themeColor
                                              : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    color:
                                        isSelected
                                            ? themeColor.withOpacity(0.05)
                                            : Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            () => setState(
                                              () => _selectedCategory = cat,
                                            ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isSelected
                                                    ? themeColor
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ), // small spacing before X button
                                      Container(
                                        height: 20,
                                        width: 1,
                                        color: Colors.grey.shade300,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                      ), // subtle vertical divider between text and X
                                      GestureDetector(
                                        onTap: () async {
                                          final uid =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid;
                                          if (uid == null) return;

                                          final snapshot =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(uid)
                                                  .collection('categories')
                                                  .where('name', isEqualTo: cat)
                                                  .get();

                                          for (var doc in snapshot.docs) {
                                            await doc.reference.delete();
                                          }

                                          setState(() {
                                            customCategories.remove(cat);
                                            categories.remove(cat);
                                            if (_selectedCategory == cat) {
                                              _selectedCategory = "";
                                            }
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // Add category button
                              GestureDetector(
                                onTap:
                                    () => showDialog(
                                      context: context,
                                      builder:
                                          (context) => AddCategoryDialog(
                                            onCategoryAdded: (newCat) {
                                              setState(() {
                                                if (!defaultCategories.contains(
                                                      newCat,
                                                    ) &&
                                                    !customCategories.contains(
                                                      newCat,
                                                    )) {
                                                  customCategories.add(newCat);
                                                  categories.add(newCat);
                                                }
                                                _selectedCategory = newCat;
                                              });
                                            },
                                          ),
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: const Icon(Icons.add),
                                ),
                              ),
                            ],
                          ),
                          // Splitting Expense
                          SplitExpenseButton(
                            isSubmitting: _isSubmitting,
                            onPressed: _submitExpense,
                            amount: _amountController.text.trim(),
                            isAmountEntered:
                                _amountController.text.trim().isNotEmpty,
                            onSplitUpdated: (selectedFriends) {
                              setState(() {
                                this.selectedFriends = selectedFriends;

                                // Optionally: If you still need friendSplits map for other logic:
                                this.friendSplits = {
                                  for (var friend in selectedFriends)
                                    friend['name']: friend['amount'],
                                };
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BA29C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  "Add Expense",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
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
