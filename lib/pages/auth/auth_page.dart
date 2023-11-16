import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:goltens_core/constants/constants.dart';
import 'package:goltens_core/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:goltens_mobile/utils/functions.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lottie/lottie.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    Key? key,
  }) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLoginForm = true;
  bool isLoading = false;
  bool showPassword = false;
  final nameTextController = TextEditingController();
  final emailTextController = TextEditingController();
  final phoneTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final departmentController = SingleValueDropDownController();
  final employeeNumberTextController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!isLoginForm) {
          setState(() => isLoginForm = !isLoginForm);
          return false;
        }

        return true;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: buildHeader() + buildInputs() + buildButtons(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildHeader() {
    return [
      const SizedBox(height: 80.0),
      Image.asset('assets/images/logo.png', width: 80.0, height: 80.0),
      const SizedBox(height: 20.0),
      if (isLoginForm)
        Lottie.asset('assets/json/register.json', height: 300.0)
      else
        Lottie.asset('assets/json/login-ready.json', height: 300.0),
      const SizedBox(height: 20.0)
    ];
  }

  List<Widget> buildInputs() {
    return [
      if (!isLoginForm)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            controller: nameTextController,
            validator: (value) {
              if (value != null && value.isEmpty) {
                return 'Please enter your name';
              }

              return null;
            },
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          controller: emailTextController,
          validator: (value) {
            if (value != null && value.isEmpty) {
              return 'Please enter your email address';
            }

            if (!EmailValidator.validate(value ?? '')) {
              return 'Please enter a valid email address';
            }

            return null;
          },
        ),
      ),
      if (!isLoginForm)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: IntlPhoneField(
            decoration: InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            initialCountryCode: singaporeCountryCode,
            onChanged: (phone) {
              phoneTextController.text = phone.completeNumber;
            },
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.completeNumber.isEmpty) {
                return 'Please enter your phone number';
              }

              try {
                value?.isValidNumber();
                return null;
              } on Exception {
                return 'Invalid Number';
              }
            },
          ),
        ),
      if (!isLoginForm)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: DropDownTextField(
            clearOption: false,
            controller: departmentController,
            validator: (value) {
              if (value != null && value.isEmpty) {
                return 'Please select your department';
              }
              return null;
            },
            textFieldDecoration: InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            dropDownItemCount: departmentList.length,
            dropDownList: departmentList.map((department) {
              return DropDownValueModel(name: department, value: department);
            }).toList(),
          ),
        ),
      if (!isLoginForm)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Employee Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            controller: employeeNumberTextController,
            validator: (value) {
              if (value != null && value.isEmpty) {
                return 'Please enter your employee number';
              }
              return null;
            },
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Password',
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
              return 'Please enter a password';
            }

            if (value != null && value.length < 6) {
              return 'Password must be at least 6 characters long';
            }

            return null;
          },
        ),
      ),
    ];
  }

  Future<void> forgotPassword() async {
    try {
      if (emailTextController.text.isEmpty) {
        if (mounted) {
          const snackBar = SnackBar(content: Text('Enter your email'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        return;
      }

      await AuthService.forgotPassword(emailTextController.text);

      if (mounted) {
        Navigator.pushNamed(context, '/reset-password');
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  List<Widget> buildButtons() {
    if (isLoginForm) {
      return [
        // ElevatedButton(
        //   onPressed: !isLoading
        //       ? () async {
        //           if (formKey.currentState?.validate() == true) {
        //             formKey.currentState?.save();
        //             setState(() => isLoading = true);
        //
        //             try {
        //               final fcmToken = await getFcmToken();
        //
        //
        //               await AuthService.login(
        //                 email: emailTextController.text,
        //                 password: passwordTextController.text,
        //                 fcmToken: fcmToken,
        //               );
        //
        //               if (mounted) authNavigate(context);
        //             } catch (e) {
        //               if (mounted) {
        //                 final snackBar = SnackBar(content: Text(e.toString()));
        //                 ScaffoldMessenger.of(context).showSnackBar(snackBar);
        //               }
        //             } finally {
        //               setState(() => isLoading = false);
        //             }
        //           }
        //         }
        //       : null,

        ElevatedButton(
          onPressed: !isLoading
              ? () async {
                  if (formKey.currentState?.validate() == true) {
                    formKey.currentState?.save();
                    setState(() => isLoading = true);

                    try {
                      final fcmToken = await getFcmToken();

                      // Check if the provided email and password match the predefined values
                      if (emailTextController.text == 'user@gmail.com' &&
                          passwordTextController.text == 'user123') {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/admin-choose-app',
                          (r) => false,
                        );

                        // Perform login with predefined values
                        // You can replace this block with your actual login logic
                        // For example, AuthService.login(email: email, password: password, fcmToken: fcmToken);
                        // authNavigate(context);

                        // For now, let's print a message indicating successful login
                        print('Logged in successfully as user@gmail.com');
                      } else {
                        // Handle invalid email or password
                        final snackBar = SnackBar(
                            content: Text('Invalid email or password'));
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    } catch (e) {
                      if (mounted) {
                        final snackBar = SnackBar(content: Text(e.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    } finally {
                      setState(() => isLoading = false);
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            minimumSize: const Size(
              double.infinity,
              40.0,
            ),
          ),
          child: !isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 5),
                    Text('Login'),
                  ],
                )
              : const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
        ),
        const SizedBox(height: 10.0),
        SizedBox(
          height: 40,
          child: TextButton(
            onPressed: forgotPassword,
            child: const Text('Forgot Password'),
          ),
        ),
        SizedBox(
          height: 40,
          child: TextButton(
            child: const Text('Don\'t have an account? Register'),
            onPressed: () => setState(() => isLoginForm = false),
          ),
        ),
      ];
    } else {
      return [
        ElevatedButton(
          onPressed: !isLoading
              ? () async {
                  if (formKey.currentState?.validate() == true) {
                    formKey.currentState?.save();
                    setState(() => isLoading = true);

                    final fcmToken = await getFcmToken();

                    try {
                      await AuthService.register(
                        name: nameTextController.text,
                        email: emailTextController.text,
                        phone: phoneTextController.text,
                        password: passwordTextController.text,
                        department: departmentController.dropDownValue?.value,
                        employeeNumber: employeeNumberTextController.text,
                        fcmToken: fcmToken,
                      );

                      if (mounted) authNavigate(context);
                    } catch (e) {
                      if (mounted) {
                        final snackBar = SnackBar(content: Text(e.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    } finally {
                      setState(() => isLoading = false);
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          child: !isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle),
                    SizedBox(width: 5),
                    Text('Register'),
                  ],
                )
              : const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
        ),
        TextButton(
          child: const Text('Already have an account? Login'),
          onPressed: () => setState(() => isLoginForm = true),
        ),
      ];
    }
  }
}
