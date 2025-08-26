// lib/screens/tap_history_screen.dart
import 'package:flutter/material.dart';

import '../services/rfid_service.dart';

class TapHistoryScreen extends StatefulWidget {
  final String cardId;

  TapHistoryScreen({required this.cardId});

  @override
  _TapHistoryScreenState createState() => _TapHistoryScreenState();
}

class _TapHistoryScreenState extends State<TapHistoryScreen> {
  final RFIDService _rfidService = RFIDService();
  List<Map<String, dynamic>> _tapHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTapHistory();
  }

  Future<void> _loadTapHistory() async {
    try {
      final history = await _rfidService.getTapHistory(widget.cardId);
      setState(() {
        _tapHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading tap history';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tap History')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _tapHistory.isEmpty
                  ? Center(child: Text('No tap history found'))
                  : ListView.builder(
                      itemCount: _tapHistory.length,
                      itemBuilder: (context, index) {
                        final tap = _tapHistory[index];
                        return ListTile(
                          title: Text('Tapped at: ${tap['tapped_at']}'),
                          subtitle: Text('MAC: ${tap['mac_address']}'),
                        );
                      },
                    ),
    );
  }
}
