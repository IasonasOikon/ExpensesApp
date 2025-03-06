import 'package:expensesappflutter/auth/login_page.dart';
import 'package:expensesappflutter/main_view.dart';
import 'package:expensesappflutter/services/firebase_options.dart';
import 'package:expensesappflutter/services/notif_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: MyFirebaseOptions.options,
  );

  // Initialize notification handling

  NotificationService.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Loads user credentials from local storage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedUserId = prefs.getString('savedUserId');
  String? savedUserName = prefs.getString('savedUserName');
  String? savedUserEmail = prefs.getString('savedUserEmail');

  runApp(ExpensesApp(
      savedUserId: savedUserId,
      savedUserName: savedUserName,
      savedUserEmail: savedUserEmail));
}

class ExpensesApp extends StatelessWidget {
  final String? savedUserId;
  final String? savedUserName;
  final String? savedUserEmail;

  const ExpensesApp(
      {super.key,
      required this.savedUserId,
      required this.savedUserName,
      required this.savedUserEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 67, 126, 199),
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),

      // Routes to MainView if user credentials are saved for auto login
      initialRoute: savedUserId != null ? 'main' : 'login',
      routes: {
        'login': (context) => const LoginPage(),
        'main': (context) => MainView(userId: savedUserId ?? ''),
      },
    );
  }
}
