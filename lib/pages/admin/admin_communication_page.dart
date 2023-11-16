import 'package:flutter/material.dart';
import 'package:goltens_mobile/components/admin/dashboard.dart';

class AdminCommunicationPage extends StatelessWidget {
  const AdminCommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CommunicationDashboard(),
    );
  }
}
