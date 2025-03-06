import 'package:firebase_core/firebase_core.dart';

// Firebase options from google-services.json
class MyFirebaseOptions {
  static FirebaseOptions get options {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAMaChVwOWS7aYCea3jzrYb8hlnkkwotp0',
      appId: '1:1052149973377:android:9bcbf9aa695836622a2880',
      messagingSenderId: '1052149973377',
      projectId: 'expenses-3fca1',
      authDomain: 'expenses-3fca1.firebaseapp.com',
      storageBucket: 'expenses-3fca1.appspot.com',
    );
  }
}
