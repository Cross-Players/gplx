import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/features/login/widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Vui lòng nhập email hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu';
    }
    if (value != passwordController.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  Future<void> _register() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        errorMessage = '';
      });

      try {
        // Tạo tài khoản mới
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        if (mounted && credential.user != null) {
          // Đăng xuất ngay lập tức để người dùng phải đăng nhập lại
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            // Hiển thị thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng ký thành công! Vui lòng đăng nhập'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Quay về màn hình đăng nhập và yêu cầu xóa dữ liệu
            Navigator.pop(context, true);
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'weak-password') {
            errorMessage = 'Mật khẩu quá yếu';
          } else if (e.code == 'email-already-in-use') {
            errorMessage = 'Email này đã được sử dụng';
          } else {
            errorMessage = e.message ?? 'Đã xảy ra lỗi khi đăng ký';
          }
        });
      } catch (e) {
        setState(() {
          errorMessage = 'Đã xảy ra lỗi không xác định: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void popPage() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppLoginColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppLoginColors.primary),
                onPressed: popPage,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              AppLoginColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppLoginPaddings.screen,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: AppLoginPaddings.card,
                      decoration: AppLoginDecorations.card,
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            const Image(
                              image: AssetImage('assets/images/logo_vx.jpg'),
                              width: 120,
                              height: 120,
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              'Đăng ký tài khoản',
                              style: AppLoginTextStyles.title,
                            ),
                            const SizedBox(height: 30),
                            AuthTextField(
                              controller: emailController,
                              labelText: 'Email',
                              hintText: 'Nhập email của bạn',
                              icon: Icons.email_outlined,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            AuthTextField(
                              controller: passwordController,
                              labelText: 'Mật khẩu',
                              hintText: 'Nhập mật khẩu của bạn',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppLoginColors.inputIcon,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            AuthTextField(
                              controller: confirmPasswordController,
                              labelText: 'Xác nhận mật khẩu',
                              hintText: 'Nhập lại mật khẩu của bạn',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              validator: _validateConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppLoginColors.inputIcon,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            if (errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  errorMessage,
                                  style: AppLoginTextStyles.error,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppLoginColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Đăng ký',
                                        style: AppLoginTextStyles.button,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
