import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/auth_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/custom/custom_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _firstName;
  late String _lastName;
  late String _email;

  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _firstName = user?.firstName ?? '';
    _lastName = user?.lastName ?? '';
    _email = user?.email ?? '';
  }

  bool get _hasChanges {
    final user = context.read<AuthService>().currentUser;
    return _firstName != (user?.firstName ?? '') ||
        _lastName != (user?.lastName ?? '') ||
        _email != (user?.email ?? '');
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; _success = null; });
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    final success = await auth.updateProfile(
      firstName: _firstName != user?.firstName ? _firstName : null,
      lastName: _lastName != user?.lastName ? _lastName : null,
      email: _email != user?.email ? _email : null,
    );

    if (mounted) {
      setState(() {
        _saving = false;
        if (success) {
          _success = 'Profile updated successfully';
        } else {
          _error = auth.errorMessage ?? 'Failed to update profile';
        }
      });
    }
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() { _uploadingPhoto = true; _error = null; _success = null; });
    final auth = context.read<AuthService>();
    final success = await auth.updateProfilePhoto(
      file.bytes!.toList(),
      file.name,
    );
    if (mounted) {
      setState(() {
        _uploadingPhoto = false;
        if (success) {
          _success = 'Photo updated successfully';
        } else {
          _error = 'Failed to upload photo';
        }
      });
    }
  }

  void _cancel() {
    final user = context.read<AuthService>().currentUser;
    setState(() {
      _firstName = user?.firstName ?? '';
      _lastName = user?.lastName ?? '';
      _email = user?.email ?? '';
      _error = null;
      _success = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Text('Profile',
            style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileRow(context),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildBanner(context, _error!, isError: true),
          ],
          if (_success != null) ...[
            const SizedBox(height: 16),
            _buildBanner(context, _success!, isError: false),
          ],
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
      
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = context.watch<AuthService>().currentUser;
    final initials = '${_firstName.isNotEmpty ? _firstName[0] : ''}${_lastName.isNotEmpty ? _lastName[0] : ''}'.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer,
                border: Border.all(
                    color: colors.outline.withValues(alpha: 0.15)),
              ),
              child: user?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.avatarUrl!,
                        key: ValueKey(user.avatarUrl),
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(initials,
                              style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w500,
                                  color: colors.primary)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(initials,
                          style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              color: colors.primary)),
                    ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _uploadingPhoto ? null : _pickPhoto,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(
                        color: colors.outline.withValues(alpha: 0.3)),
                  ),
                  child: _uploadingPhoto
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.primary),
                        )
                      : Icon(Icons.camera_alt_outlined,
                          size: 15, color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 28),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      label: 'First name',
                      value: _firstName,
                      icon: Icons.person_outline,
                      onChanged: (v) => setState(() => _firstName = v),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomInputField(
                      label: 'Last name',
                      value: _lastName,
                      icon: Icons.person_outline,
                      onChanged: (v) => setState(() => _lastName = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomInputField(
                label: 'Email',
                value: _email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => setState(() => _email = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  
  Widget _buildBanner(BuildContext context, String message,
      {required bool isError}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? colors.errorContainer.withValues(alpha: 0.5)
            : colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? colors.error : colors.primary,
          ),
          const SizedBox(width: 8),
          Text(message,
              style: TextStyle(
                  fontSize: 13,
                  color: isError ? colors.error : colors.primary)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _hasChanges ? _cancel : null,
          style: TextButton.styleFrom(
            foregroundColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : CustomButton(
                label: 'Save changes',
                icon: Icons.check_outlined,
                isIconAfterLabel: false,
                onPressed: _hasChanges ? _save : null,
                verticalPadding: 12,
                horizontalPadding: 20,
              ),
      ],
    );
  }
}