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
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
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
    
    final email = authService.currentUser?.email ?? '';
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
    final user = authService.currentUser;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_reset, size: 40,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'AirShero',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your new password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Welcome, ${user.firstName}! You are logging in as ${user.role.displayName}.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'You must set a new password before accessing the system.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomInputField(
                  label: 'New Password',
                  value: _newPassword,
                  icon: _obscureNew ? Icons.visibility_off : Icons.visibility,
                  obscureText: _obscureNew,
                  onChanged: (v) => setState(() => _newPassword = v),
                  onIconTap: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),

                CustomInputField(
                  label: 'Confirm Password',
                  value: _confirmPassword,
                  icon: _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  obscureText: _obscureConfirm,
                  onChanged: (v) => setState(() => _confirmPassword = v),
                  onIconTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 8),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        label: 'Set Password',
                        icon: Icons.check,
                        onPressed: _submit,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}