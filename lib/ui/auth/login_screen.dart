import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_nest/core/theme/app_colors.dart';
import 'package:stock_nest/core/theme/app_text_styles.dart';
import 'package:stock_nest/core/theme/app_spacing.dart';
import 'package:stock_nest/core/widgets/widgets.dart';
import 'package:stock_nest/domain/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePass   = true;
  bool _rememberMe    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Validates input criteria and dispatches authentication credentials.
  /// Passes the active state of [_rememberMe] flag to handle session persistence.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      rememberMe: _rememberMe,
    );
    if (success && mounted) context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxl),

                // Header icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.inputRadius,
                  ),
                  child: const Icon(Icons.warehouse_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Welcome back',
                    style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('Sign in to your account',
                    style: AppTextStyles.bodyLarge),

                const SizedBox(height: AppSpacing.xl),

                // Error banner
                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    if (auth.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    return ErrorBanner(
                      message:  auth.errorMessage!,
                      onDismiss: auth.clearError,
                    );
                  },
                ),

                // Email Input
                AppTextField(
                  label:           'Email',
                  hint:            'you@example.com',
                  controller:      _emailCtrl,
                  keyboardType:    TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon:      const Icon(Icons.mail_outline_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    if (!v.contains('@'))
                      return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Password Input
                AppTextField(
                  label:           'Password',
                  controller:      _passwordCtrl,
                  obscureText:     _obscurePass,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Password is required';
                    if (v.length < 6)
                      return 'Minimum 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                // Remember Me Configuration Row
                CheckboxListTile(
                  title: Text('Remember Me', style: AppTextStyles.bodyMedium),
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primaryLight,
                ),

                const SizedBox(height: AppSpacing.md),

                // Login Action Dispatcher
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => PrimaryButton(
                    label:     'Sign In',
                    isLoading: auth.status == AuthStatus.loading,
                    onPressed: _submit,
                    icon:      Icons.login_rounded,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Register Navigation Route Trigger
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.goNamed('register'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}