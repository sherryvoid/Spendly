// lib/components/add_category_dialog.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(String) onCategoryAdded;

  const AddCategoryDialog({super.key, required this.onCategoryAdded});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveCategory() async {
    final String newCategory = _controller.text.trim();
    if (newCategory.isEmpty) return;

    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('categories')
            .doc();

    await docRef.set({'name': newCategory});

    widget.onCategoryAdded(newCategory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Category"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: "Enter category name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveCategory,
          child: const Text("Done"),
        ),
      ],
    );
  }
}
