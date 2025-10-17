import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthSevices> authServices = ValueNotifier(AuthSevices());

class AuthSevices {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email không đúng.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không đúng.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Email hoặc mật khẩu không hợp lệ.');
      } else {
        throw Exception('Đăng nhập thất bại (${e.code}): ${e.message}');
      }
    }
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: currentPassword);
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw Exception('Không tìm thấy người dùng');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'Vui lòng đăng nhập lại trước khi xóa tài khoản để xác nhận.');
      } else {
        throw Exception('Không thể xóa tài khoản (${e.code}): ${e.message}');
      }
    }
  }
}
