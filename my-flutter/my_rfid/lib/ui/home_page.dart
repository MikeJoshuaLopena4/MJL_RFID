import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/color_palette.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _timeString;
  late String _dateString;
  late Timer _timer;
  String username = "Parent";
  final AuthService _authService = AuthService();

  // Linked IDs and sessions
  List<Map<String, dynamic>> linkedIds = [];
  Map<String, Map<String, DateTime?>> idSessions = {};

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());

    _loadUsername();
    _loadLinkedIds();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  Future<void> _loadUsername() async {
    final name = await _authService.getUsername();
    setState(() => username = name);
  }

  Future<void> _loadLinkedIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ids')
        .orderBy('createdAt', descending: true);

    idsCollection.snapshots().listen((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        idSessions[data['id']] ??= {};
        return data;
      }).toList();

      setState(() => linkedIds = docs);

      // 🔹 After IDs are loaded, bind sessions from Firestore
      _bindSessions();
    });
  }

  void _bindSessions() {
    if (linkedIds.isEmpty) return;

    final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final firestore = FirebaseFirestore.instance;

    for (var idData in linkedIds) {
      final cardId = idData['id'];
      final docRef = firestore
          .collection('rfidSessions')
          .doc(today)
          .collection('cards')
          .doc(cardId);

      docRef.snapshots().listen((docSnap) {
        if (!docSnap.exists) return;

        final data = docSnap.data() as Map<String, dynamic>;
        setState(() {
          idSessions[cardId] = {
            "AMIn": _parseTimestamp(data['AMIn']),
            "AMOut": _parseTimestamp(data['AMOut']),
            "PMIn": _parseTimestamp(data['PMIn']),
            "PMOut": _parseTimestamp(data['PMOut']),
          };
        });
      });
    }
  }

  DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  void _updateTime() {
    setState(() {
      _timeString = _formatTime(DateTime.now());
      _dateString = _formatDate(DateTime.now());
    });
  }

  String _formatTime(DateTime dt) {
    return DateFormat('hh : mm : ss a').format(dt.toLocal());
  }

  String _formatDate(DateTime dt) {
    return DateFormat('EEE, d MMMM yyyy').format(dt.toLocal());
  }

  String _calculateDuration(DateTime timeIn, DateTime? timeOut) {
    final end = timeOut ?? DateTime.now();
    final diff = end.difference(timeIn);

    final seconds = diff.inSeconds.remainder(60);
    final minutes = diff.inMinutes.remainder(60);
    final hours = diff.inHours;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Check if a card has any logs for today
  bool _hasLogsForToday(String cardId) {
    final session = idSessions[cardId] ?? {};
    return session.values.any((time) => time != null);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter out cards that have no logs for today
    final cardsWithLogs = linkedIds.where((idData) {
      final cardId = idData['id'];
      return _hasLogsForToday(cardId);
    }).toList();

    return Scaffold(
      backgroundColor: ColorPalette.background50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                color: ColorPalette.primary500,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $username',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Today's Attendance",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _timeString,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateString,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Show cards with logs or empty state
            if (cardsWithLogs.isEmpty)
              _buildEmptyState()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: cardsWithLogs.map((idData) {
                    final cardId = idData['id'];
                    final label = idData['label'] ?? cardId;
                    final session = idSessions[cardId] ?? {};

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // --- Card Header ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ColorPalette.primary100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: ColorPalette.primary800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // --- AM Session (only show if there are logs) ---
                          if (session["AMIn"] != null || session["AMOut"] != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    "MORNING SESSION",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: ColorPalette.text600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _timeBox("IN", session["AMIn"], Colors.green),
                                      if (session["AMIn"] != null)
                                        _durationBox(
                                          "DURATION",
                                          _calculateDuration(
                                              session["AMIn"]!, session["AMOut"]),
                                        )
                                      else
                                        _durationBox("DURATION", "--"),
                                      _timeBox("OUT", session["AMOut"], Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          if ((session["AMIn"] != null || session["AMOut"] != null) &&
                              (session["PMIn"] != null || session["PMOut"] != null))
                            const Divider(height: 1, color: ColorPalette.background200),

                          // --- PM Session (only show if there are logs) ---
                          if (session["PMIn"] != null || session["PMOut"] != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    "AFTERNOON SESSION",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: ColorPalette.text600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _timeBox("IN", session["PMIn"], Colors.green),
                                      if (session["PMIn"] != null)
                                        _durationBox(
                                          "DURATION",
                                          _calculateDuration(
                                              session["PMIn"]!, session["PMOut"]),
                                        )
                                      else
                                        _durationBox("DURATION", "--"),
                                      _timeBox("OUT", session["PMOut"], Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // You can Add notes here (like in the image)
            
            if (cardsWithLogs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Note",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primary500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Please check the history tab for full logs.",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.text600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            
          ],          
        ),
      ),
    );
  }

  Widget _timeBox(String label, DateTime? time, Color color) {
    final isEmpty = time == null;
    final text = isEmpty ? "--:--" : DateFormat("hh:mm a").format(time);

    return Column(
      children: [
        Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: isEmpty ? ColorPalette.background100 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEmpty ? ColorPalette.text400 : color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: ColorPalette.text500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _durationBox(String label, String value) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: ColorPalette.primary50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ColorPalette.primary600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: ColorPalette.text500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nfc_rounded,
            size: 64,
            color: ColorPalette.text300,
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records today',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.text600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for today\'s access logs',
            style: GoogleFonts.inter(
              color: ColorPalette.text400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}