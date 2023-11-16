import 'package:flutter/material.dart';
import 'package:goltens_core/models/feedback.dart';
import 'package:goltens_mobile/pages/auth/auth_page.dart';
import 'package:goltens_mobile/pages/feedback/feedback_assigned_page.dart';
import 'package:goltens_mobile/pages/feedback/feedback_dashboard_page.dart';
import 'package:goltens_mobile/pages/feedback/feedback_page.dart';
import 'package:goltens_mobile/provider/global_state.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:goltens_core/services/feedback.dart';
import 'package:provider/provider.dart';

class FeedbackDrawer extends StatefulWidget {
  final int currentIndex;

  const FeedbackDrawer({
    super.key,
    required this.currentIndex,
  });

  @override
  State<FeedbackDrawer> createState() => _FeedbackDrawerState();
}

class _FeedbackDrawerState extends State<FeedbackDrawer> {
  FeedbackDrawerData? drawerData;

  @override
  void initState() {
    super.initState();
    fetchDrawerData();
  }

  Future<void> fetchDrawerData() async {
    try {
      var res = await FeedbackService.getFeedbackDrawerData();

      setState(() {
        drawerData = res.data;
      });
    } catch (err) {
      // Empty
    }
  }

  void setDrawerSelectedIndex(int index) {
    var selectedIndex = widget.currentIndex;
    if (selectedIndex == index) return;

    Navigator.pop(context);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedbackPage(),
          ),
        );

        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedbackDashboardPage(),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FeedbackAssignedPage(),
          ),
        );
        break;
      default:
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    BuildContext context,
  ) async {
    try {
      await AuthService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      var userResponse = await AuthService.getMe();

      if (mounted) {
        const snackBar = SnackBar(
          content: Text('Password Changed Successfully'),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        context.read<GlobalState>().setUserResponse(userResponse);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void showChangePasswordDialog(BuildContext context) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) {
        var formKey = GlobalKey<FormState>();
        final currentPasswordTextController = TextEditingController();
        final newPasswordTextController = TextEditingController();
        bool showPassword = false;

        return AlertDialog(
          title: const Center(child: Text("Change Password")),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
          ),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              StateSetter setState,
            ) {
              return SizedBox(
                height: 215,
                width: 410,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 16.0),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    !showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => showPassword = !showPassword,
                                  ),
                                ),
                              ),
                              controller: currentPasswordTextController,
                              obscureText: !showPassword,
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter new password';
                                }

                                if (value != null && value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    !showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => showPassword = !showPassword,
                                  ),
                                ),
                              ),
                              controller: newPasswordTextController,
                              obscureText: !showPassword,
                              validator: (value) {
                                if (value != null && value.isEmpty) {
                                  return 'Please enter new password';
                                }

                                if (value != null && value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.done),
                        label: const Text('Change Password'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: () async {
                          if (formKey.currentState?.validate() == true) {
                            formKey.currentState?.save();

                            await changePassword(
                              currentPasswordTextController.text,
                              newPasswordTextController.text,
                              context,
                            );

                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
                  MaterialPageRoute(builder: (context) => const AuthPage()),
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
                    'Feedback',
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
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () => setDrawerSelectedIndex(0),
              selected: selectedItemIndex == 0,
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_sharp),
              title: const Text('Dashboard'),
              onTap: () => setDrawerSelectedIndex(1),
              selected: selectedItemIndex == 1,
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(
                'Assigned Feedbacks (${drawerData?.assignedFeedbacks ?? "-"})',
              ),
              onTap: () => setDrawerSelectedIndex(2),
              selected: selectedItemIndex == 2,
            ),
            ListTile(
              leading: const Icon(Icons.change_circle),
              title: const Text('Change Password'),
              onTap: () => showChangePasswordDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_outlined),
              title: const Text('Go To Communication'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
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
