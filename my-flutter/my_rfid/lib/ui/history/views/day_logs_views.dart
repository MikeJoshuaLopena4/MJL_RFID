import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/card_item.dart';
import '../models/access_log.dart';
import '../widgets/log_item.dart';
import '../../../theme/color_palette.dart';

class DayLogsView extends StatelessWidget {
  final CardItem selectedCard;
  final DateTime selectedDate;
  final Stream<QuerySnapshot> linkedIdsStream;
  final Stream<DocumentSnapshot> Function(DateTime, String) getSessionsForDate;
  final Stream<QuerySnapshot> Function(DateTime) getAllSessionsForDate;
  final List<AccessLog> Function(Map<String, dynamic>, String, String) convertSessionToLogs;

  const DayLogsView({
    super.key,
    required this.selectedCard,
    required this.selectedDate,
    required this.linkedIdsStream,
    required this.getSessionsForDate,
    required this.getAllSessionsForDate,
    required this.convertSessionToLogs,
  });

  @override
  Widget build(BuildContext context) {
    final cardId = selectedCard.id;
    final cardName = selectedCard.name;

    if (cardId == 'all') {
      return StreamBuilder<QuerySnapshot>(
        stream: getAllSessionsForDate(selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoLogsView();
          }

          // ✅ Only use logs for card IDs in user's linked IDs
          return StreamBuilder<QuerySnapshot>(
            stream: linkedIdsStream,
            builder: (context, linkedIdsSnapshot) {
              if (linkedIdsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userCardIds = <String, String>{};
              if (linkedIdsSnapshot.hasData) {
                for (final doc in linkedIdsSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data['id']?.toString() ?? doc.id;
                  final name =
                      data['label']?.toString() ?? 'Unnamed Card';
                  userCardIds[id] = name;
                }
              }

              // ✅ Only show logs for cards the user has added
              final allLogs = <AccessLog>[];
              for (final doc in snapshot.data!.docs) {
                if (!userCardIds.containsKey(doc.id)) continue; // skip others
                final cardName = userCardIds[doc.id]!;
                final logs = convertSessionToLogs(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                  cardName,
                );
                allLogs.addAll(logs);
              }

              allLogs.sort((a, b) {
                final timeFormat = DateFormat('hh:mm a');
                final timeA = timeFormat.parse(a.time);
                final timeB = timeFormat.parse(b.time);
                return timeA.compareTo(timeB);
              });

              return _buildLogsListView(allLogs, showCardName: true);
            },
          );
        },
      );
    } else {
      return StreamBuilder<DocumentSnapshot>(
        stream: getSessionsForDate(selectedDate, cardId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNoLogsView();
          }

          final logs = convertSessionToLogs(
            snapshot.data!.data() as Map<String, dynamic>,
            cardId,
            cardName,
          );

          return _buildLogsListView(logs, showCardName: false);
        },
      );
    }
  }

  Widget _buildLogsListView(List<AccessLog> logs, {bool showCardName = false}) {
    if (logs.isEmpty) {
      return _buildNoLogsView();
    }

    return Container(
      color: ColorPalette.background50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return LogItem(
            log: log,
            showCardName: showCardName,
          );
        },
      ),
    );
  }

  Widget _buildNoLogsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: ColorPalette.text300,
          ),
          const SizedBox(height: 16),
          Text(
            'No logs for ${_formatDate(selectedDate)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: ColorPalette.text600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }
}