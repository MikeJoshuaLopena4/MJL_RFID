// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/rfid_service.dart';
import 'add_card_screen.dart'; // Add this import
import 'tap_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RFIDService _rfidService = RFIDService();
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _rfidService.getUserCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading cards';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My RFID Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _cards.isEmpty
                  ? Center(
                      child: Text('No RFID cards added yet'),
                    )
                  : ListView.builder(
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return ListTile(
                          title: Text(card['name'] ?? 'Unnamed Card'),
                          subtitle: Text(card['uid']),
                          trailing: IconButton(
                            icon: Icon(Icons.history),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TapHistoryScreen(cardId: card['uid']),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCardScreen()),
          ).then((_) => _loadCards());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
