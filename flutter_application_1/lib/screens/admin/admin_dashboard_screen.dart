import 'package:flutter/material.dart';

import '../login_screen.dart';
import 'admin_bug_reports_screen.dart';
import 'admin_home_screen.dart';
import 'admin_riders_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color darkMaroon = Color(0xFF62191C);
  static const Color cream = Color(0xFFE0CFC2);
  static const Color background = Color(0xFFF7F3F1);

  int _selectedIndex = 0;

  // =========================
  // PAGE TITLES
  // =========================
  final List<String> _titles = const [
    'Admin Dashboard',
    'Bug Reports',
    'Rider Monitoring',
  ];

  // =========================
  // ADMIN PAGES
  // =========================
  final List<Widget> _pages = const [
    AdminHomeScreen(),
    AdminBugReportsScreen(),
    AdminRidersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: darkMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Lumear Administration',
              style: TextStyle(fontSize: 10, color: cream),
            ),
          ],
        ),

        actions: [
          // =========================
          // NOTIFICATIONS
          // =========================
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Admin notifications will be connected later.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),

          // =========================
          // ADMIN MENU
          // =========================
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _showAdminProfile();
              }

              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: darkMaroon,
                    ),
                    SizedBox(width: 10),
                    Text('Admin Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: darkMaroon),
                    SizedBox(width: 10),
                    Text('Log Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // =========================
      // ADMIN PAGES
      // =========================
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: cream,
        height: 68,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        destinations: const [
          // =========================
          // HOME
          // =========================
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: darkMaroon),
            label: 'Home',
          ),

          // =========================
          // BUG REPORTS
          // =========================
          NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report_rounded, color: darkMaroon),
            label: 'Bugs',
          ),

          // =========================
          // RIDER MONITORING
          // =========================
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security_rounded, color: darkMaroon),
            label: 'Riders',
          ),
        ],
      ),
    );
  }

  // =========================
  // ADMIN PROFILE
  // =========================
  void _showAdminProfile() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                backgroundColor: cream,
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: darkMaroon,
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Lumear Admin')),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email', style: TextStyle(fontSize: 11, color: Colors.grey)),
              SizedBox(height: 3),
              Text(
                'lumear@gmail.com',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 14),
              Text('Role', style: TextStyle(fontSize: 11, color: Colors.grey)),
              SizedBox(height: 3),
              Text(
                'System Administrator',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close', style: TextStyle(color: darkMaroon)),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> _showLogoutDialog() async {
    final bool? logout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out of the admin account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkMaroon,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (logout != true || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
