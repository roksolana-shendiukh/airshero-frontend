import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../widgets/custom/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email           = '';
  String _password        = '';
  bool   _obscurePassword = true;

  Future<void> _login() async {
    if (_email.isEmpty || _password.isEmpty) return;
    final authService = context.read<AuthService>();
    final success     = await authService.login(_email, _password);
    if (success && mounted) {
      final role = authService.currentUser?.role;
      switch (role) {
        case null:
          context.go('/');
        default:
          context.go(role.menuItems.first.route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final colors      = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      body: Row(
        children: [
          _buildLeftPanel(colors, isDark),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: _buildForm(authService, colors, isDark),
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
                        color:      Colors.white,
                        fontSize:   18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                const Text(
                  'Airline Operations\nManagement',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   26,
                    fontWeight: FontWeight.w600,
                    height:     1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Streamline check-in, bookings and\nflight operations from one place.',
                  style: TextStyle(
                    color:  Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height:   1.6,
                  ),
                ),

                const SizedBox(height: 40),

                _FeatureItem(
                  icon:  Icons.how_to_reg_outlined,
                  label: 'Passenger Check-In',
                  sub:   'Fast boarding pass issuance',
                ),
                const SizedBox(height: 14),
                _FeatureItem(
                  icon:  Icons.confirmation_number_outlined,
                  label: 'Booking Management',
                  sub:   'Search, create and manage bookings',
                ),
                const SizedBox(height: 14),
                _FeatureItem(
                  icon:  Icons.flight_takeoff_outlined,
                  label: 'Flight Operations',
                  sub:   'Real-time flight status control',
                ),
                const SizedBox(height: 14),
                _FeatureItem(
                  icon:  Icons.calendar_month_outlined,
                  label: 'Flight Planning',
                  sub:   'Routes, schedules and pricing',
                ),
                const SizedBox(height: 14),
                _FeatureItem(
                  icon:  Icons.admin_panel_settings_outlined,
                  label: 'Administration',
                  sub:   'User management and system access',
                ),

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

  Widget _buildForm(AuthService authService, ColorScheme colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize:   26,
            fontWeight: FontWeight.w600,
            color:      colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to your account to continue',
          style: TextStyle(
            fontSize: 14,
            color:    colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 36),

        CustomInputField(
          label:        'Email address',
          value:        _email,
          icon:         Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged:    (v) => setState(() => _email = v),
        ),

        const SizedBox(height: 14),

        // Stack накладає іконку ока поверх поля без зміни CustomInputField
        Stack(
          alignment: Alignment.centerRight,
          children: [
            CustomInputField(
              label:       'Password',
              value:       _password,
              icon:        Icons.lock_outline,
              obscureText: _obscurePassword,
              onChanged:   (v) => setState(() => _password = v),
            ),
            Positioned(
              right: 4,
              child: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (authService.errorMessage != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.error, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authService.errorMessage!,
                    style: TextStyle(
                      color:    colors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        authService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomButton(
                label:     'Sign In',
                icon:      Icons.arrow_forward,
                onPressed: _login,
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sub;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color:        Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  color:    Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}