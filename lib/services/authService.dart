import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web sign-in using a popup
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile sign-in using google_sign_in 7.x API
        if (!_initialized) {
          const String webClientId =
              '995140505639-oca8sdulbhvsdlj78qitg4hvq41efcvl.apps.googleusercontent.com';
          await GoogleSignIn.instance.initialize(serverClientId: webClientId);
          _initialized = true;
        }

        // authenticate() throws GoogleSignInException on cancel/failure
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();

        // In google_sign_in 7.x, .authentication is a sync getter
        // that only provides idToken (auth and authz are separated)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // For Firebase Auth, idToken alone is sufficient
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on GoogleSignInException catch (e) {
      // User cancelled the sign-in flow
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        debugPrint('Google sign in cancelled by user');
        return null;
      }
      debugPrint('Google sign in error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only sends name on first sign-in; persist it if available
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      if ((givenName != null || familyName != null) &&
          userCredential.user?.displayName == null) {
        final displayName =
            [givenName, familyName].whereType<String>().join(' ').trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      debugPrint('Apple sign in error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    // disconnect() is only valid on mobile after initialize() was called
    if (!kIsWeb && _initialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
