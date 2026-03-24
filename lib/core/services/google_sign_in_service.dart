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
      // Sign out first to always show the account picker for a clean UX.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker.
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Get a fresh ID token to send to our backend.
      return await userCredential.user?.getIdToken();
    } catch (e) {
      return null;
    }
  }
}
