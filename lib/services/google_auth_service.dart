import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String webClientId =
      '452364672232-he1uv7fl474l54nde1bfgub8m0sr4fq2.apps.googleusercontent.com'; // TODO: Replace with actual Web Client ID from Firebase Console

  static GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? webClientId : null,
    );
  }

  static Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = _createGoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // debugPrint("Firebase Auth error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      // debugPrint("Google Sign in error: $e");
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      final googleSignIn = _createGoogleSignIn();
      try {
        await googleSignIn.signOut();
      } catch (e) {
        // Plugin may not be available on all platforms; log and continue
        // debugPrint("Google Sign out plugin error: $e");
      }
      await _auth.signOut();
    } catch (e) {
      // debugPrint("Google Sign out error: $e");
    }
  }
}
