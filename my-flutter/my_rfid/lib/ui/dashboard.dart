import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history/history_page.dart';
import 'settings/settings_page.dart';
import 'history/history_back_handler.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;

  // ✅ Use GlobalKey to access HistoryPage state
  final GlobalKey<HistoryPageState> _historyPageKey = GlobalKey();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HomePage(),
      HistoryPage(key: _historyPageKey),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex == 1) {
      // ✅ If we're in HistoryPage, delegate back press
      final handler = _historyPageKey.currentState;
      if (handler != null) {
        final handled = await handler.handleWillPop();
        if (!handled) return false; // stay inside History
      }
    }

    if (_selectedIndex == 0) {
      // ✅ Double press to exit only in Home
      final now = DateTime.now();
      if (_lastBackPressTime == null ||
          now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
        _lastBackPressTime = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Press again to exit"),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
      return true;
    }

    // ✅ If in Settings, just go back to Home
    setState(() => _selectedIndex = 0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF4fb094),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
