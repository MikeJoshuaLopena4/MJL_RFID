import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'link_id_page.dart';
import 'profile_page.dart';
import '../../theme/color_palette.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService authService = AuthService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    await NotificationService.setNotificationsEnabled(value);

    if (value) {
      debugPrint("🔔 Notifications enabled");
    } else {
      debugPrint("🔔 Notifications disabled");
    }
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ColorPalette.background50,
          title: Text(
            'About RFID Access Tracker',
            style: TextStyle(
              color: ColorPalette.text800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'RFID Access Tracker is a comprehensive security management app that monitors and records '
              'time-in and time-out activities using RFID technology. The app provides real-time notifications '
              'for access events, maintains detailed history logs, and offers secure card management. '
              'Designed for organizations requiring controlled access to facilities, it ensures security '
              'personnel receive instant alerts for unauthorized access attempts. '
              'The app features an intuitive interface, robust security protocols, and detailed reporting '
              'capabilities for effective access control management.\n\n'
              'Version 1.0.0\n'
              '© 2025 MJL Community',
              style: TextStyle(
                color: ColorPalette.text600,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: ColorPalette.primary500),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: ColorPalette.primary500,
          centerTitle: true,
          elevation: 0,
        ),
        body: Container(
          color: ColorPalette.background50,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text(
                  'General Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.text800,
                  ),
                ),
              ),

              // Profile
              _buildSettingItem(
                context,
                icon: Icons.person_outline,
                title: 'Profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),

              // Notification 
              _buildSettingItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                hasToggle: true,
                value: _notificationsEnabled,
                onTap: () {
                  _toggleNotifications(!_notificationsEnabled);
                },
              ),

              // Link my ID
              _buildSettingItem(
                context,
                icon: Icons.link_outlined,
                title: 'Link my ID',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LinkIdPage()),
                  );
                },
              ),

              // Help & Support
              _buildSettingItem(
                context,
                icon: Icons.help_outline,
                title: 'About',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: 24),

              // App Version
              Center(
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    color: ColorPalette.text500,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Logout button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[700]),
                  title: Text('Logout', style: TextStyle(color: Colors.red[700])),
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: ColorPalette.background50,
                        title: Text('Logout', style: TextStyle(color: ColorPalette.text800)),
                        content: Text('Are you sure you want to logout?', style: TextStyle(color: ColorPalette.text600)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('Cancel', style: TextStyle(color: ColorPalette.text500)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      await authService.signOut();
                      // AuthGate will redirect back to login
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Back button handling for nested Settings pages
  Future<bool> _onWillPop() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // go back inside Settings sub-page
      return false; // don’t exit SettingsPage
    }
    return true; // at Settings root → allow leaving to Dashboard
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasToggle = false,
    bool value = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: ColorPalette.primary500),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: ColorPalette.text800,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: ColorPalette.text500),
              )
            : null,
        trailing: hasToggle
            ? Switch(
                value: value,
                onChanged: (bool newValue) {
                  onTap();
                },
                activeThumbColor: ColorPalette.accent500,
                activeTrackColor: ColorPalette.accent300,
              )
            : Icon(Icons.arrow_forward_ios, size: 16, color: ColorPalette.text400),
        onTap: hasToggle ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
