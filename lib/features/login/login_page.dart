import 'package:flutter/material.dart';
import 'package:gplx/core/constants/app_styles.dart';
import 'package:gplx/core/services/firebase/auth_services.dart';
import 'package:gplx/features/forgot_password/forgot_password_page.dart';
import 'package:gplx/features/login/widgets/auth_text_field.dart';
import 'package:gplx/features/register/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String errorMessage = '';
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Vui lòng nhập email hợp lệ';
    }
    // Không cho phép email có đuôi gmail.co (ví dụ: gmail.co, gmail.com.vn, ...)
    final gmailCoRegex = RegExp(r'@gmail\.co(\.|$)');
    if (gmailCoRegex.hasMatch(value)) {
      return 'Email không đúng định dạng';
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

  void signIn() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        errorMessage = '';
      });

      try {
        await authServices.value.signIn(
            email: emailController.text, password: passwordController.text);
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
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

  void clearLoginData() {
    emailController.clear();
    passwordController.clear();
    setState(() {
      errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLoginColors.background,
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
                      child: Column(
                        children: [
                          const Image(
                            image: AssetImage('assets/images/logo_vx.jpg'),
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Đăng nhập',
                            style: AppLoginTextStyles.title,
                          ),
                          const SizedBox(height: 30),
                          Form(
                            key: formKey,
                            child: Column(
                              children: [
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
                                  obscureText: _obscureText,
                                  validator: _validatePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppLoginColors.inputIcon,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ),
                                if (errorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 15, bottom: 5),
                                    child: Text(
                                      errorMessage,
                                      style: AppLoginTextStyles.error,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : signIn,
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
                                            'Đăng nhập',
                                            style: AppLoginTextStyles.button,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordPage(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppLoginColors.primary,
                                  ),
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: AppLoginTextStyles.label,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final shouldClear = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                              if (shouldClear == true) {
                                clearLoginData();
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppLoginColors.primary,
                            ),
                            child: const Text(
                              'Đăng ký',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
