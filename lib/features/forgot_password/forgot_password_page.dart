import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/services/firebase/auth_services.dart';
import 'package:gplx/features/login/widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';
  bool _isLoading = false;
  String? successMessage;

  @override
  void dispose() {
    emailController.dispose();
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

  void resetPassword() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        errorMessage = '';
        successMessage = null;
      });

      try {
        await authServices.value.resetPassword(email: emailController.text);
        if (mounted) {
          setState(() {
            successMessage =
                'Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra hộp thư của bạn.';
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage =
              e.message ?? 'Đã xảy ra lỗi khi gửi email khôi phục mật khẩu';
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Đã xảy ra lỗi không xác định: $e';
          });
        }
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
                              'Quên mật khẩu',
                              style: AppLoginTextStyles.title,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Nhập email của bạn\n để nhận hướng dẫn đặt lại mật khẩu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                height: 1.5,
                              ),
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
                            if (errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  errorMessage,
                                  style: AppLoginTextStyles.error,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (successMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  successMessage!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : resetPassword,
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
                                        'Gửi yêu cầu',
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
