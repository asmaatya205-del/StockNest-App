import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_nest/core/theme/app_text_styles.dart';
import 'package:stock_nest/core/theme/app_spacing.dart';
import 'package:stock_nest/core/widgets/widgets.dart';
import 'package:stock_nest/domain/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass   = true;
  bool _obscureConf   = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
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
                const SizedBox(height: AppSpacing.xl),

                // Back button
                IconButton(
                  onPressed: () => context.goNamed('login'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),

                // Header
                Text('Create account',
                    style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('Start managing your warehouses',
                    style: AppTextStyles.bodyLarge),

                const SizedBox(height: AppSpacing.xl),

                // Error banner
                Consumer<AuthProvider>(
                  builder: (_, auth, __) {
                    if (auth.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    return ErrorBanner(
                      message:   auth.errorMessage!,
                      onDismiss: auth.clearError,
                    );
                  },
                ),

                // Name
                AppTextField(
                  label:           'Full Name',
                  hint:            'John Smith',
                  controller:      _nameCtrl,
                  textInputAction: TextInputAction.next,
                  prefixIcon:
                  const Icon(Icons.person_outline_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Name is required';
                    if (v.trim().length < 2)
                      return 'Name is too short';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Email
                AppTextField(
                  label:           'Email',
                  hint:            'you@example.com',
                  controller:      _emailCtrl,
                  keyboardType:    TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon:
                  const Icon(Icons.mail_outline_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Email is required';
                    if (!v.contains('@'))
                      return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Password
                AppTextField(
                  label:           'Password',
                  controller:      _passwordCtrl,
                  obscureText:     _obscurePass,
                  textInputAction: TextInputAction.next,
                  prefixIcon:
                  const Icon(Icons.lock_outline_rounded),
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
                const SizedBox(height: AppSpacing.md),

                // Confirm password
                AppTextField(
                  label:           'Confirm Password',
                  controller:      _confirmCtrl,
                  obscureText:     _obscureConf,
                  textInputAction: TextInputAction.done,
                  prefixIcon:
                  const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConf
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConf = !_obscureConf),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please confirm password';
                    if (v != _passwordCtrl.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Register button
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => PrimaryButton(
                    label:     'Create Account',
                    isLoading: auth.status == AuthStatus.loading,
                    onPressed: _submit,
                    icon:      Icons.rocket_launch_rounded,
                    useAccent: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.goNamed('login'),
                      child: const Text('Sign In'),
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