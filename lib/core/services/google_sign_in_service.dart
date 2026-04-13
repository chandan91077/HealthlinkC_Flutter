import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles the Google Sign-In flow and returns a Firebase ID token.
/// The token is then sent to our backend for verification and JWT issuance.
class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Triggers the Google account picker, authenticates with Firebase,
  /// and returns a fresh Firebase ID token.
  ///
  /// Returns `null` if the user cancels the flow or an error occurs.
  Future<String?> getIdToken() async {
    try {
      // Clear stale sessions first so a fresh Firebase token is produced.
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker.
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if ((googleAuth.idToken ?? '').isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Google did not return an ID token. Check Firebase/Google Sign-In configuration.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Always force-refresh to avoid sending an expired cached token.
      final firebaseIdToken = await userCredential.user?.getIdToken(true);
      if ((firebaseIdToken ?? '').isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-firebase-id-token',
          message:
              'Could not create a Firebase session token. Please try again.',
        );
      }

      return firebaseIdToken;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In failed. Please try again.',
      );
    }
  }
}
