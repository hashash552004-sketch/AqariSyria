import 'package:firebase_core/firebase_core.dart';

class FirebaseSetupService {
  static Future<FirebaseApp> initialize() async {
    return Firebase.initializeApp();
  }
}
