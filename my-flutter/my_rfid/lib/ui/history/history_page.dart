import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/color_palette.dart';
import 'history_back_handler.dart';
import 'models/card_item.dart';
import 'models/access_log.dart';
import 'views/card_grid_view.dart';
import 'views/calendar_view.dart';
import 'views/day_logs_views.dart'; // Fixed typo: day_logs_views.dart → day_logs_view.dart

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  HistoryPageState createState() => HistoryPageState(); // ✅ expose state
}

class HistoryPageState extends State<HistoryPage>
    implements HistoryPageBackHandler {
  final user = FirebaseAuth.instance.currentUser;
  String _selectedView = 'grid'; // 'grid', 'calendar', 'day_logs'
  CardItem? _selectedCard;
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarViewDate = DateTime.now();

  // Get the user's linked IDs from Firestore
  Stream<QuerySnapshot> get _linkedIdsStream {
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('ids')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get sessions for a specific date and card
  Stream<DocumentSnapshot> _getSessionsForDate(DateTime date, String cardId) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return FirebaseFirestore.instance
        .collection('rfidSessions')
        .doc(dateStr)
        .collection('cards')
        .doc(cardId)
        .snapshots();
  }

  // Get all sessions for a date (for "All Cards" view)
  Stream<QuerySnapshot> _getAllSessionsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return FirebaseFirestore.instance
        .collection('rfidSessions')
        .doc(dateStr)
        .collection('cards')
        .snapshots();
  }

  // Convert Firestore docs to CardItems
  List<CardItem> _buildCardItems(QuerySnapshot snapshot) {
    final cards = <CardItem>[
      CardItem(
        id: 'all',
        name: 'All Cards',
        icon: Icons.all_inclusive,
        color: ColorPalette.primary500,
      ),
    ];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cardId = data['id']?.toString() ?? doc.id;
      final cardLabel = data['label']?.toString() ?? 'Unnamed Card';

      // Determine icon based on label or type
      IconData icon = Icons.credit_card;
      if (cardLabel.toLowerCase().contains('student')) {
        icon = Icons.school;
      } else if (cardLabel.toLowerCase().contains('faculty') ||
          cardLabel.toLowerCase().contains('teacher')) {
        icon = Icons.person;
      } else if (cardLabel.toLowerCase().contains('staff')) {
        icon = Icons.badge;
      }

      cards.add(CardItem(
        id: cardId,
        name: cardLabel,
        subtitle: cardId,
        icon: icon,
        color: _getColorForCard(cards.length),
      ));
    }

    return cards;
  }

  Color _getColorForCard(int index) {
    final colors = [
      ColorPalette.accent500,
      ColorPalette.secondary500,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.blue,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  // Check if a date has logs for a specific card
  Future<bool> _hasLogsForDate(DateTime date, String cardId) async {
    if (cardId == 'all') {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('rfidSessions')
          .doc(dateStr)
          .collection('cards')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } else {
      final session = await _getSessionsForDate(date, cardId).first;
      return session.exists;
    }
  }

  // Convert session data to AccessLog list
  List<AccessLog> _convertSessionToLogs(
      Map<String, dynamic> sessionData, String cardId, String cardName) {
    final logs = <AccessLog>[];
    final dateFormat = DateFormat('hh:mm a');

    void addLogIfExists(String field, String type) {
      final timestamp = sessionData[field];
      if (timestamp != null) {
        final time = dateFormat.format((timestamp as Timestamp).toDate());
        logs.add(AccessLog(
          cardId: cardId,
          cardName: cardName,
          time: time,
          type: type,
          location: 'School',
        ));
      }
    }

    addLogIfExists('AMIn', 'Entry');
    addLogIfExists('AMOut', 'Exit');
    addLogIfExists('PMIn', 'Entry');
    addLogIfExists('PMOut', 'Exit');

    logs.sort((a, b) {
      final timeFormat = DateFormat('hh:mm a');
      final timeA = timeFormat.parse(a.time);
      final timeB = timeFormat.parse(b.time);
      return timeA.compareTo(timeB);
    });

    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // internal back handling for nested views
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildCurrentView(),
      ),
    );
  }

  /// ✅ Expose to Dashboard via the public interface
  @override
  Future<bool> handleWillPop() async {
    return await _onWillPop();
  }

  /// ✅ Handle back button depending on which view we're in
  Future<bool> _onWillPop() async {
    if (_selectedView == 'day_logs') {
      if (_selectedCard?.id == 'all') {
        setState(() {
          _selectedView = 'grid';
          _selectedCard = null;
        });
      } else {
        setState(() {
          _selectedView = 'calendar';
        });
      }
      return false; // prevent leaving HistoryPage
    } else if (_selectedView == 'calendar') {
      setState(() {
        _selectedView = 'grid';
        _selectedCard = null;
      });
      return false;
    }
    return true; // ✅ Already in grid → let Dashboard handle it
  }

  AppBar _buildAppBar() {
    String title = 'Access History';
    if (_selectedView == 'calendar') {
      title =
          '${_selectedCard?.name ?? ''} - ${_formatMonthYear(_calendarViewDate)}';
    } else if (_selectedView == 'day_logs') {
      title = '${_selectedCard?.name ?? ''} - ${_formatDate(_selectedDate)}';
    }

    List<Widget> actions = [];
    if (_selectedView == 'calendar') {
      actions = [
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            setState(() {
              _calendarViewDate = DateTime.now();
            });
          },
        ),
      ];
    }

    return AppBar(
      title: Text(title),
      backgroundColor: ColorPalette.primary500,
      centerTitle: true,
      elevation: 0,
      leading: _selectedView != 'grid'
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackButton,
            )
          : null,
      actions: actions,
    );
  }

  void _handleBackButton() {
    if (_selectedView == 'day_logs') {
      if (_selectedCard?.id == 'all') {
        setState(() {
          _selectedView = 'grid';
          _selectedCard = null;
        });
      } else {
        setState(() {
          _selectedView = 'calendar';
        });
      }
    } else if (_selectedView == 'calendar') {
      setState(() {
        _selectedView = 'grid';
        _selectedCard = null;
      });
    }
  }

  Widget _buildCurrentView() {
    switch (_selectedView) {
      case 'grid':
        return CardGridView(
          linkedIdsStream: _linkedIdsStream,
          buildCardItems: _buildCardItems,
          onCardTap: _handleCardTap,
        );
      case 'calendar':
        return CalendarView(
          selectedCard: _selectedCard!,
          calendarViewDate: _calendarViewDate,
          hasLogsForDate: _hasLogsForDate,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
              _selectedView = 'day_logs';
            });
          },
          onMonthChanged: (date) {
            setState(() {
              _calendarViewDate = date;
            });
          },
        );
      case 'day_logs':
        return DayLogsView(
          selectedCard: _selectedCard!,
          selectedDate: _selectedDate,
          linkedIdsStream: _linkedIdsStream,
          getSessionsForDate: _getSessionsForDate,
          getAllSessionsForDate: _getAllSessionsForDate,
          convertSessionToLogs: _convertSessionToLogs,
        );
      default:
        return CardGridView(
          linkedIdsStream: _linkedIdsStream,
          buildCardItems: _buildCardItems,
          onCardTap: _handleCardTap,
        );
    }
  }

  void _handleCardTap(CardItem card) {
    setState(() {
      _selectedCard = card;
      if (card.id == 'all') {
        _selectedDate = DateTime.now();
        _selectedView = 'day_logs';
      } else {
        _calendarViewDate = DateTime.now();
        _selectedView = 'calendar';
      }
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  String _formatMonthYear(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
