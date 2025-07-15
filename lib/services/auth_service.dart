// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/environment.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint("Phát hiện người dùng ẩn danh. Đang thử liên kết...");
        final result = await currentUser.linkWithCredential(credential);
        debugPrint("Liên kết tài khoản ẩn danh thành công!");
        return result.user;
      }

      debugPrint("Đăng nhập Google bình thường...");
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint(
          'Tài khoản Google đã tồn tại, đang thực hiện đăng nhập trực tiếp...',
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
              "Lỗi khi cố gắng đăng nhập lại bằng credential đã có: $e",
            );
            return null;
          }
        }
      }
      debugPrint('Lỗi FirebaseAuthException khác: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('Đã xảy ra lỗi không xác định: $e');
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
