import 'package:flutter/material.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:goltens_mobile/utils/functions.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final formKey = GlobalKey<FormState>();
  bool showPassword = false;
  final tokenTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: buildBody(),
        ),
      ),
    );
  }

  Future<void> resetPassword() async {
    try {
      if (formKey.currentState?.validate() == true) {
        formKey.currentState?.save();

        await AuthService.resetPassword(
          tokenTextController.text,
          passwordTextController.text,
        );

        if (mounted) authNavigate(context);
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Widget buildBody() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16.0),
          const Text(
            'A token has been sent to your email enter it here within 10 '
            'minutes to reset your password (It may take few minutes)',
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Token',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            controller: tokenTextController,
            validator: (value) {
              if (value != null && value.isEmpty) {
                return 'Please enter the token sent to your mail';
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
                  !showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
            ),
            controller: passwordTextController,
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
              labelText: 'Confirm New Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  !showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => showPassword = !showPassword),
              ),
            ),
            controller: confirmPasswordTextController,
            obscureText: !showPassword,
            validator: (value) {
              if (value != null && value.isEmpty) {
                return 'Please enter confirm new password';
              }

              if (value != null && value.length < 6) {
                return 'Password must be at least 6 characters long';
              }

              if (value != null && value != passwordTextController.text) {
                return 'Password and confirm password must be same';
              }

              return null;
            },
          ),
          const SizedBox(height: 16.0),
          ElevatedButton.icon(
            onPressed: resetPassword,
            icon: const Icon(Icons.done),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          )
        ],
      ),
    );
  }
}
