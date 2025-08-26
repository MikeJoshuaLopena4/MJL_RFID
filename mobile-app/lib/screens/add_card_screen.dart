// lib/screens/add_card_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/rfid_service.dart';

class AddCardScreen extends StatefulWidget {
  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uidController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final rfidService = RFIDService();
    final error = await rfidService.addCard(
      _uidController.text.trim(),
      _nameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (error != null) {
        _errorMessage = error;
      } else {
        _successMessage = 'Card added successfully!';
        _uidController.clear();
        _nameController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add RFID Card')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _uidController,
                decoration: InputDecoration(labelText: 'RFID UID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the RFID UID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Card Name (optional)'),
              ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              if (_successMessage != null)
                Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green),
                ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Add Card'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
