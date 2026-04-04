import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/admin_api_service.dart';
import '../widgets/custom/custom_input_field.dart';
import '../widgets/custom/custom_button.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  String  _newPassword     = '';
  String  _confirmPassword = '';
  bool    _obscureNew      = true;
  bool    _obscureConfirm  = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_newPassword.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    if (_newPassword != _confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    final authService = context.read<AuthService>();

    try {
      setState(() => _isLoading = true);
      final adminApi = AdminApiService(authService);
      final email    = authService.currentUser?.email ?? '';
      await adminApi.changePassword(_newPassword);
      await authService.login(email, _newPassword);
      if (!mounted) return;
      final role = authService.currentUser?.role;
      context.go(role?.menuItems.first.route ?? '/');
    } on ApiValidationException catch (e) {
      setState(() => _errorMessage = e.fieldErrors.values.first);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final colors      = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final user        = authService.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      body: Row(
        children: [
          _buildLeftPanel(colors, isDark),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: _buildForm(colors, isDark, user),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(ColorScheme colors, bool isDark) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF4C1D95) : colors.primary,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : colors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top:   -80,
            right: -80,
            child: Container(
              width:  260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left:   -40,
            child: Container(
              width:  200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width:  36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flight, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AirShero',
                      style: TextStyle(
                        color:         Colors.white,
                        fontSize:      18,
                        fontWeight:    FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:        Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock_reset, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Password Setup',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'For security reasons, you must set a personal password before accessing the system.',
                        style: TextStyle(
                          color:    Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          height:   1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _Requirement(label: 'At least 8 characters'),
                const SizedBox(height: 8),
                _Requirement(label: 'Both passwords must match'),
                const SizedBox(height: 8),
                _Requirement(label: 'Keep it secure and private'),

                const Spacer(),

                Text(
                  'AirShero v1.0',
                  style: TextStyle(
                    color:    Colors.white.withValues(alpha: 0.25),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ColorScheme colors, bool isDark, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set your password',
          style: TextStyle(
            fontSize:   26,
            fontWeight: FontWeight.w600,
            color:      colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        if (user != null)
          Text(
            'Welcome, ${user.firstName}! You are signing in as ${user.role.displayName}.',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          )
        else
          Text(
            'Create a secure password to access the system.',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),

        const SizedBox(height: 32),

        CustomInputField(
          label:       'New Password',
          value:       _newPassword,
          icon:        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          obscureText: _obscureNew,
          onChanged:   (v) => setState(() => _newPassword = v),
          onIconTap:   () => setState(() => _obscureNew = !_obscureNew),
        ),

        const SizedBox(height: 14),

        CustomInputField(
          label:       'Confirm Password',
          value:       _confirmPassword,
          icon:        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          obscureText: _obscureConfirm,
          onChanged:   (v) => setState(() => _confirmPassword = v),
          onIconTap:   () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        const SizedBox(height: 8),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.error, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomButton(
                label:     'Set Password',
                icon:      Icons.check,
                onPressed: _submit,
              ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(child: Divider(color: colors.outline.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Secure access',
                style: TextStyle(
                  fontSize: 11,
                  color:    colors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.outline.withValues(alpha: 0.2))),
          ],
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  const _Requirement({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  16,
          height: 16,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 10),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color:    Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}