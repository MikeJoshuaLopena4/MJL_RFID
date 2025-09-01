import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/id_input_form.dart';

class AddIdPage extends StatefulWidget {
  const AddIdPage({super.key});

  @override
  State<AddIdPage> createState() => _AddIdPageState();
}

class _AddIdPageState extends State<AddIdPage> {
  String _mode = 'manual'; // 'manual' or 'auto'

  Future<void> _onSaved(Map<String, String> entry) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not logged in")),
        );
        return;
      }

      // Reference to the user's document
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Create/update the user document (optional: store username/email)
      await userDoc.set({
        "uid": user.uid,
        "email": user.email,
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge so it doesn't overwrite subcollections

      // Add the ID to the 'ids' subcollection
      await userDoc.collection('ids').add({
        "id": entry["id"],        // your ID from IdInputForm
        "label": entry["label"],  // optional label/name
        "mode": _mode,            // manual/auto
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Return entry to previous screen (optional)
      Navigator.of(context).pop(entry);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving ID: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add ID')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Manual'),
                selected: _mode == 'manual',
                onSelected: (_) => setState(() => _mode = 'manual'),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Auto (NFC)'),
                selected: _mode == 'auto',
                onSelected: (_) => setState(() => _mode = 'auto'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: IdInputForm(mode: _mode, onSave: _onSaved),
          ),
        ],
      ),
    );
  }
}
