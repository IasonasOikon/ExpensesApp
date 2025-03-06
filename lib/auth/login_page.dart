import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensesappflutter/auth/signup_page.dart';
import 'package:expensesappflutter/common/colors.dart';
import 'package:expensesappflutter/main_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    getSavedCredentials();
  }

  // Uses the last saved login credentials to auto signin
  void getSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('savedEmail') && prefs.containsKey('savedPassword')) {
      setState(() {
        emailController.text = prefs.getString('savedEmail') ?? '';
        passwordController.text = prefs.getString('savedPassword') ?? '';
      });
    } else {
      emailController.text = '';
      passwordController.text = '';
    }
  }

  // Save login credentials to automatically signin next time
  void saveCredentialsLocally(
      String userId, String userName, String userEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedEmail', emailController.text.trim());
    await prefs.setString('savedPassword', passwordController.text.trim());
    await prefs.setString('savedUserId', userId);
    await prefs.setString('savedUserName', userName);
    await prefs.setString('savedUserEmail', userEmail);
  }

  void login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Invalid username or password.';
      });
      return;
    }

    try {
      final UserCredential userCredential =
          await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Fetch user data from Firestore using the userId
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData = userDoc.data();
        if (userData != null) {
          final String userName = userData['name'] ?? '';
          final String userEmail = userData['email'] ?? '';

          saveCredentialsLocally(user.uid, userName, userEmail);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainView(userId: user.uid),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String customErrorMessage;

      // Custom error messages...
      if (e.code == 'invalid-credential') {
        customErrorMessage = 'Incorrect username or password.';
      } else {
        customErrorMessage = 'An unknown error occurred. Please try again.';
      }

      if (mounted) {
        setState(() {
          errorMessage = customErrorMessage;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter your email address to reset your password.'),
        ),
      );
      return;
    }

    try {
      // Send reset password through email (firebase)
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Password Reset'),
              content: const Text(
                  'A password reset email has been sent to your email address.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      // Specific error handling for FirebaseAuth exceptions
      String errorMessage;
      if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else {
        errorMessage = 'Error sending reset email: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Expenses App',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 60.0),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: AppColors.primaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.secondaryText),
                      ),
                      filled: true,
                      fillColor: AppColors.darkBase,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.secondaryText),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.mediumAccent),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 20.0),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppColors.primaryText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.secondaryText),
                      ),
                      filled: true,
                      fillColor: AppColors.darkBase,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.secondaryText),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: AppColors.mediumAccent),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.primaryText),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 20.0),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                            color: AppColors.errorRed, fontSize: 12.0),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _resetPassword,
                        child: const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40.0),
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.lightAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18.0, color: AppColors.darkBase),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
