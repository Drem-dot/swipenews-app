// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/environment.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String webClientId = String.fromEnvironment(
    'WEB_CLIENT_ID',
    defaultValue: '128128649313-8uurnl9tq7kkr11ek9j76t70fr0n8p43.apps.googleusercontent.com',
  );

  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      debugPrint("Đăng nhập ẩn danh thành công: ${result.user?.uid}");
      return result.user;
    } catch (e) {
      debugPrint("Lỗi đăng nhập ẩn danh: $e");
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Email/Password Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Đăng nhập email thành công: ${credential.user?.uid}");
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi đăng nhập email: ${e.code}");
      rethrow;
    }
  }

  // Email/Password Registration
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      debugPrint("Đăng ký email thành công: ${credential.user?.uid}");
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi đăng ký email: ${e.code}");
      rethrow;
    }
  }

  // Existing Google Sign In method
  Future<User?> signInWithGoogle() async {

    final String webClientId = Environment.webClientId;
    if (webClientId.isEmpty) {
      throw 'Web Client ID not configured';
    }

    try {
      debugPrint("AuthService: Initializing GoogleSignIn with serverClientId: $webClientId");
      await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      debugPrint("AuthService: GoogleSignIn initialized. Attempting to authenticate...");
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      debugPrint("AuthService: GoogleSignIn authentication successful for user: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      debugPrint("AuthService: Got GoogleSignInAuthentication. ID Token available: ${googleAuth.idToken != null}");
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      debugPrint("AuthService: Created AuthCredential.");

      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint("AuthService: Current Firebase user: ${currentUser?.uid ?? 'None'}");

      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint("AuthService: Anonymous user detected. Attempting to link with Google credential...");
        final result = await currentUser.linkWithCredential(credential);
        debugPrint("AuthService: Anonymous account linking successful!");
        return result.user;
      }

      debugPrint("AuthService: Performing normal Google sign-in...");
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      debugPrint("AuthService: Normal Google sign-in successful for user: ${result.user?.uid}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService: FirebaseAuthException during Google Sign-In: ${e.code}");
      if (e.code == 'credential-already-in-use') {
        debugPrint(
          'AuthService: Google account already exists, attempting direct sign-in...',
        );

        final AuthCredential? credential = e.credential;
        if (credential != null) {
          try {
            final result = await FirebaseAuth.instance.signInWithCredential(
              credential,
            );
            debugPrint(
              "Đăng nhập lại bằng tài khoản Google đã tồn tại thành công.",
            );
            return result.user;
          } catch (e) {
            debugPrint(
              "AuthService: Error attempting to sign in again with existing credential: $e",
            );
            return null;
          }
        }
      }
      debugPrint('AuthService: Other FirebaseAuthException: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('AuthService: An unknown error occurred: $e');
      return null;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("Email reset password đã được gửi");
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi reset password: ${e.code}");
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'Không tìm thấy người dùng';
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      debugPrint("Đổi mật khẩu thành công");
    } on FirebaseAuthException catch (e) {
      debugPrint("Lỗi đổi mật khẩu: ${e.code}");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
    debugPrint("Đã đăng xuất người dùng.");
  }
}
