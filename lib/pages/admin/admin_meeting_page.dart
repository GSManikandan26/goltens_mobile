import 'package:flutter/material.dart';

class AdminMeetingPage extends StatelessWidget {
  const AdminMeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toolbox Meeting'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Toolbox Meeting',
              style: TextStyle(
                fontSize: 32.0,
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              'Coming Soon...',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
