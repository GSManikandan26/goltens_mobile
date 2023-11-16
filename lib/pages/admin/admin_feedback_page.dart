import 'package:flutter/material.dart';
import 'package:goltens_mobile/components/admin/feedback/feedback_dashboard.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: FeedbackAdminDashboard(),
    );
  }
}
