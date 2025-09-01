import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/auth_gate.dart';
import 'services/notification_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'theme/theme_config.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize notifications
  await NotificationService.init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth UI',
      theme: _buildThemeData(),
      home: const AuthGate(),
    );
  }
  
  // Helper method to build the theme data
ThemeData _buildThemeData() {
  final baseTheme = AppTheme.lightTheme;
  
  return baseTheme.copyWith(
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
  );
}
}