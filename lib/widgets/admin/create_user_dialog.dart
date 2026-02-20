import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/admin_api_service.dart';
import '../../services/auth_service.dart';
import '../custom_input_field.dart';
import '../custom_select_field.dart';
import '../custom_button.dart';

class CreateUserDialog extends StatefulWidget {
  final VoidCallback? onUserCreated;

  const CreateUserDialog({super.key, this.onUserCreated});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String? _selectedAirline;
  UserRole? _selectedRole;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _fieldErrors = {};

  late final AdminApiService _adminApi;

  static const List<String> _airlines = [
    'Ukraine International Airlines',
    'Wizz Air',
    'SkyUp Airlines',
    'Ryanair',
    'Bees Airline',
    'Motor Sich Airlines',
    'AirShero System',
  ];

  static final List<UserRole> _selectableRoles = UserRole.values
      .where((r) => r != UserRole.systemAdmin)
      .toList();

  @override
  void initState() {
    super.initState();
    _adminApi = AdminApiService(context.read<AuthService>());
  }

  Future<void> _submit() async {
    final errors = <String, String>{};
    
    if (_firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    }
    if (_lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    }
    if (_email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    }
    if (_selectedAirline == null) {
      errors['airline'] = 'Please select an airline';
    }
    if (_selectedRole == null) {
      errors['role'] = 'Please select a role';
    }

    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = {};
    });

    try {
      await _adminApi.createUser(
        email: _email.trim(),
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        airlineName: _selectedAirline!,
        roleId: _selectedRole!.id,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUserCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $_email created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiValidationException catch (e) {
      setState(() => _fieldErrors = e.fieldErrors);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Create User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomInputField(
                  label: 'First Name',
                  value: _firstName,
                  icon: Icons.person_outline,
                  hint: 'Latin letters only, 4–30 characters',
                  errorText: _fieldErrors['firstName'],
                  onChanged: (v) => setState(() {
                    _firstName = v;
                    _fieldErrors.remove('firstName');
                  }),
                ),
                const SizedBox(height: 12),

                CustomInputField(
                  label: 'Last Name',
                  value: _lastName,
                  icon: Icons.person_outline,
                  hint: 'Latin letters only, 4–30 characters',
                  errorText: _fieldErrors['lastName'],
                  onChanged: (v) => setState(() {
                    _lastName = v;
                    _fieldErrors.remove('lastName');
                  }),
                ),
                const SizedBox(height: 12),

                CustomInputField(
                  label: 'Email',
                  value: _email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Enter a valid email address (e.g. user@example.com)',
                  errorText: _fieldErrors['email'],
                  onChanged: (v) => setState(() {
                    _email = v;
                    _fieldErrors.remove('email');
                  }),
                ),
                const SizedBox(height: 12),

                CustomSelectField(
                  label: 'Airline',
                  value: _selectedAirline ?? 'Select Airline',
                  icon: Icons.flight_outlined,
                  items: _airlines,
                  errorText: _fieldErrors['airline'],
                  onChanged: (v) {
                    if (v != null) setState(() {
                        _selectedAirline = v;
                        _fieldErrors.remove('airline');
                      });
                    },
                ),
                const SizedBox(height: 12),

                CustomSelectField(
                  label: 'Role',
                  value: _selectedRole?.displayName ?? 'Select Role',
                  icon: Icons.badge_outlined,
                  items: _selectableRoles.map((r) => r.displayName).toList(),
                  errorText: _fieldErrors['role'],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedRole = _selectableRoles.firstWhere((r) => r.displayName == v);
                        _fieldErrors.remove('role');
                      });
                    }
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
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

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton(
                              label: 'Create',
                              icon: Icons.person_add_outlined,
                              isIconAfterLabel: false,
                              onPressed: _submit,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}