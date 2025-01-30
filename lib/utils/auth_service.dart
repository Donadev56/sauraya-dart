import 'package:google_sign_in/google_sign_in.dart';
import 'package:sauraya/logger/logger.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "594191550662-nlaeqrvm0slr15vmroo1ahodd77kr8mm.apps.googleusercontent.com",
    
    scopes: ['email', 'profile'], 
  );

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      log("User connected: ${googleUser.displayName}");
      log("Email : ${googleUser.email}");
      log("Goofle user : $googleUser");
      return googleUser;
    } catch (e) {
      log("Error Google Sign-In : $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    log("User signed out");
  }
}
