import 'package:flutter/material.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:goltens_mobile/utils/functions.dart';

class AdminRejectedPage extends StatefulWidget {
  const AdminRejectedPage({Key? key}) : super(key: key);

  @override
  State<AdminRejectedPage> createState() => _AdminRejectedPageState();
}

class _AdminRejectedPageState extends State<AdminRejectedPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: FractionalOffset(0, 0),
          end: FractionalOffset(1.0, 0.0),
          stops: [0.0, 1.0],
          tileMode: TileMode.clamp,
        ),
      ),
      child: Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 80.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 100.0,
                  height: 100.0,
                ),
                const SizedBox(height: 20.0),
                Image.asset('assets/images/rejected.jpg', height: 380),
                const SizedBox(height: 35.0),
                const Text(
                  'Unfortunately, your account request has been rejected by'
                  ' the admin. Please contact the admin for more info.',
                  style: TextStyle(fontSize: 20.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    minimumSize: const Size(
                      double.infinity,
                      40.0,
                    ),
                  ),
                  onPressed: () async {
                    await AuthService.logout();

                    if (mounted) {
                      authNavigate(context);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done),
                      SizedBox(width: 5.0),
                      Text('OK'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
