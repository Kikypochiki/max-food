import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/auth/presentation/providers/auth_providers.dart';
import 'package:max_food/features/auth/presentation/utils/auth_feedback.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      context.go('/home');
      return;
    }

    await showAuthErrorDialog(
      context,
      title: 'Login failed',
      message: friendlyAuthErrorMessage(
        ref.read(authControllerProvider).error,
        fallback: 'Unable to sign in. Please check your details and try again.',
      ),
    );
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      await showAuthErrorDialog(
        context,
        title: 'Enter your email',
        message: 'Type the email you used for UbayHarvest, then try again.',
      );
      return;
    }

    final sent = await ref
        .read(authControllerProvider.notifier)
        .resetPasswordForEmail(email: email);

    if (!mounted) return;

    await showAuthErrorDialog(
      context,
      title: sent ? 'Reset link sent' : 'Could not send reset link',
      message: sent
          ? 'If an account exists for $email, you will receive a password reset link shortly.'
          : friendlyAuthErrorMessage(
              ref.read(authControllerProvider).error,
              fallback: 'Unable to send a reset link. Please try again.',
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7EA), Color(0xFFFDFEF9)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.75),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: const Color(0xFF163A22),
                      onPressed: () => context.go('/'),
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFE2EEE4)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF29A300,
                                ).withOpacity(0.10),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4FBF3),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo_ubayharvest1.png',
                                    height: 88,
                                    width: 88,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'Welcome back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF163A22),
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sign in to access listings, chats, and alerts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Color(0xFF5F6F64),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildLabel('Email'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  hint: 'Enter your email',
                                  prefixIcon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  );
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _inputDecoration(
                                  hint: 'Enter your password',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF757575),
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : _onForgotPassword,
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Color(0xFF257533),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F8C32),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: isLoading ? null : _onSubmit,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF607067),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/sign-up'),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F8C32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B1B1B),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF757575)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF29A300), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
