import 'package:flutter/material.dart';
import 'package:goltens_mobile/components/admin/feedback/feedback_dashboard.dart';
import 'package:goltens_mobile/components/admin/feedback/feedbacks.dart';
import 'package:goltens_mobile/pages/auth/auth_page.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:provider/provider.dart';

class AdminFeedbackDrawer extends StatefulWidget {
  final int currentIndex;

  const AdminFeedbackDrawer({
    super.key,
    required this.currentIndex,
  });

  @override
  State<AdminFeedbackDrawer> createState() => _AdminFeedbackDrawerState();
}

class _AdminFeedbackDrawerState extends State<AdminFeedbackDrawer> {
  void setDrawerSelectedIndex(int index) {
    var selectedIndex = widget.currentIndex;
    if (selectedIndex == index) return;

    Navigator.pop(context);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedbackAdminDashboard(),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Feedbacks(),
          ),
        );
        break;
      default:
    }
  }

  void logout() {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure you want to logout ?"),
          actions: [
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                await AuthService.logout();

                // ignore: use_build_context_synchronously
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return const AuthPage();
                  }),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var selectedItemIndex = widget.currentIndex;
    var user = context.read<GlobalState>().user?.data;

    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Goltens Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '---',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    user?.email ?? '---',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_sharp),
              title: const Text('Dashboard'),
              onTap: () => setDrawerSelectedIndex(0),
              selected: selectedItemIndex == 0,
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Feedbacks'),
              onTap: () => setDrawerSelectedIndex(1),
              selected: selectedItemIndex == 1,
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_outlined),
              title: const Text('Go To Communication'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/admin-communication');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }
}
