import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../domain/providers/auth_provider.dart';
import '../../app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // ── Active User Dashboard Profile Card ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: AppRadius.cardRadius,
            ),
            child: Row(
              children: [
                // Avatar Badge Render Component
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.displayMediumOnDark
                          .copyWith(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '',
                          style: AppTextStyles.headlineSmall
                              .copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? '',
                          style: AppTextStyles.bodyMediumOnDark,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const _EditProfileScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text('General',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textHint)),
          const SizedBox(height: AppSpacing.sm),

          _SettingsTile(
            icon: Icons.warehouse_outlined,
            color: AppColors.primary,
            label: 'Warehouses',
            onTap: () => context.goNamed('warehouses'),
          ),
          _SettingsTile(
            icon: Icons.inventory_2_outlined,
            color: AppColors.secondary,
            label: 'Products',
            onTap: () => context.goNamed('products'),
          ),
          _SettingsTile(
            icon: Icons.history_rounded,
            color: AppColors.accent,
            label: 'Inventory Logs',
            onTap: () => context.goNamed('logs'),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text('Account',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textHint)),
          const SizedBox(height: AppSpacing.sm),

          _SettingsTile(
            icon: Icons.person_outline_rounded,
            color: AppColors.primary,
            label: 'Edit Profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
            ),
          ),

          // Sign Out Action Router wrapped inside a clean global modal guard
          _SettingsTile(
            icon: Icons.logout_rounded,
            color: AppColors.danger,
            label: 'Sign Out',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: AppRouter.rootNavigatorKey.currentContext ?? context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(
                          AppRouter.rootNavigatorKey.currentContext ??
                              context)
                          .pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(
                          AppRouter.rootNavigatorKey.currentContext ??
                              context)
                          .pop(true),
                      child: Text('Sign Out',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final globalContext =
                    AppRouter.rootNavigatorKey.currentContext;
                if (globalContext != null && globalContext.mounted) {
                  await globalContext.read<AuthProvider>().logout();
                  if (globalContext.mounted) globalContext.go('/login');
                }
              }
            },
          ),

          const SizedBox(height: AppSpacing.xl),
          Center(child: Text('StockNest v1.0.0', style: AppTextStyles.bodySmall)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Private Sub-view: Edit Profile Screen
// ══════════════════════════════════════════════════════════════════

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _changePassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl.text = user?.name ?? '';
    _emailCtrl.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  /// Packages user profile updates and validates conditional security fields.
  /// If the password toggle is checked, passes password modifications safely down the river.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();

    final success = await provider.updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      newPassword: _changePassword && _newPassCtrl.text.isNotEmpty
          ? _newPassCtrl.text
          : null,
      currentPassword: _changePassword ? _currentPassCtrl.text : null,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Update failed'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppTextField(
                label: 'Full Name *',
                hint: 'Your name',
                controller: _nameCtrl,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Email *',
                hint: 'your@email.com',
                controller: _emailCtrl,
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Password Toggle Switch Configuration Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Change Password', style: AppTextStyles.labelMedium),
                  Switch(
                    value: _changePassword,
                    onChanged: (v) => setState(() {
                      _changePassword = v;
                      if (!v) {
                        _currentPassCtrl.clear();
                        _newPassCtrl.clear();
                        _confirmPassCtrl.clear();
                      }
                    }),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),

              // Conditional Visibility Segment: Password Modification Inputs Array
              if (_changePassword) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Current Password *',
                  hint: '••••••••',
                  controller: _currentPassCtrl,
                  obscureText: _obscureCurrent,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (_changePassword && (v == null || v.isEmpty)) {
                      return 'Current password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'New Password *',
                  hint: '••••••••',
                  controller: _newPassCtrl,
                  obscureText: _obscureNew,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (_changePassword) {
                      if (v == null || v.isEmpty) return 'New password is required';
                      if (v.length < 6) return 'At least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirm New Password *',
                  hint: '••••••••',
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (_changePassword && v != _newPassCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              Consumer<AuthProvider>(
                builder: (_, p, __) => PrimaryButton(
                  label: 'Save Changes',
                  icon: Icons.save_rounded,
                  isLoading: p.status == AuthStatus.loading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Settings ListTile Component ──────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.inputRadius,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: AppTextStyles.labelMedium),
        trailing:
        const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}