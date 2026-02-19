import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../custom_button.dart';
import '../custom_input_field.dart';
import '../custom_select_field.dart';

class CreateUserDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onUserCreated;

  const CreateUserDialog({
    super.key,
    required this.onUserCreated,
  });

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  String _email = '';
  String _firstName = '';
  String _lastName = '';

  UserRole _selectedRole = UserRole.salesAgent;
  String _selectedAirline = 'Ukraine International';

  final List<String> _airlines = [
    'Ukraine International',
    'Wizz Air',
    'SkyUp Airlines',
    'Ryanair',
    'LOT Polish Airlines',
    'Turkish Airlines',
    'AirShero System',
  ];

  bool get _isFormValid =>
      _email.contains('@') && _firstName.isNotEmpty && _lastName.isNotEmpty;

  void _handleSubmit() {
    if (!_isFormValid) return;

    // Статус завжди pendingActivation — email з посиланням надсилається автоматично
    final userData = {
      'email': _email,
      'firstName': _firstName,
      'lastName': _lastName,
      'role': _selectedRole.name,
      'status': UserStatus.pendingActivation.name,
      'airlineName': _selectedAirline,
    };

    widget.onUserCreated(userData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Підказка про автоматичний email
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'An activation email will be sent automatically so the user can set their password.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── EMAIL ────────────────────────────────────────────
              CustomInputField(
                label: 'Email *',
                value: _email,
                icon: Icons.email_outlined,
                onChanged: (value) => setState(() => _email = value),
              ),

              const SizedBox(height: 12),

              // ── FIRST NAME & LAST NAME ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      label: 'First Name *',
                      value: _firstName,
                      icon: Icons.person_outlined,
                      onChanged: (value) => setState(() => _firstName = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomInputField(
                      label: 'Last Name *',
                      value: _lastName,
                      icon: Icons.person_outlined,
                      onChanged: (value) => setState(() => _lastName = value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── AIRLINE ──────────────────────────────────────────
              CustomSelectField(
                label: 'Airline',
                icon: Icons.flight,
                value: _selectedAirline,
                items: _airlines,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedAirline = value);
                },
              ),

              const SizedBox(height: 12),

              // ── ROLE ─────────────────────────────────────────────
              CustomSelectField(
                label: 'Role *',
                icon: Icons.badge_outlined,
                value: _selectedRole.displayName,
                items: UserRole.values.map((r) => r.displayName).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = UserRole.values.firstWhere((r) => r.displayName == value);
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // ── BUTTONS ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    label: 'Create User',
                    onPressed: _isFormValid ? _handleSubmit : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}