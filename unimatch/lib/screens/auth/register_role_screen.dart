// lib/screens/auth/register_role_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../screens/registration/id_card_camera_screen.dart';
import '../../widgets/tm_button.dart';
import '../../widgets/tm_button.dart' as tm;

class RegisterRoleScreen extends StatefulWidget {
  const RegisterRoleScreen({super.key});

  @override
  State<RegisterRoleScreen> createState() => _RegisterRoleScreenState();
}

class _RegisterRoleScreenState extends State<RegisterRoleScreen> {
  UserRole? _selectedRole;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _subjectsCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedRole == null) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    bool success;
    if (_selectedRole == UserRole.student) {
      success = await auth.signUpStudent(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
      );
    } else {
      final subjects = _subjectsCtrl.text.split(',').map((s) => s.trim()).toList();
      final rate = double.tryParse(_rateCtrl.text);
      success = await auth.signUpTutor(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        subjects: subjects,
        hourlyRate: rate,
      );
    }
    if (success && mounted) {
      if (_selectedRole == UserRole.tutor) {
        final uploadedUrl = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (ctx) => IDCardCameraScreen(
              onSuccess: (url) {
                Navigator.of(ctx).pop(url);
              },
            ),
          ),
        );

        if (uploadedUrl != null) {
          await context.read<AuthProvider>().storeTutorIdCard(uploadedUrl);
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your role',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        role: UserRole.student,
                        selected: _selectedRole == UserRole.student,
                        onTap: () => setState(() => _selectedRole = UserRole.student),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleCard(
                        role: UserRole.tutor,
                        selected: _selectedRole == UserRole.tutor,
                        onTap: () => setState(() => _selectedRole = UserRole.tutor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_selectedRole != null) ...[
                  tm.TMTextField(
                    label: 'Name',
                    controller: _nameCtrl,
                    prefixIcon: const Icon(Icons.person),
                    validator: (v) => v?.isEmpty ?? true ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  tm.TMTextField(
                    label: 'Email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                    validator: (v) => v?.contains('@') ?? false ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),
                  tm.TMTextField(
                    label: 'Password',
                    controller: _passCtrl,
                    obscureText: _obscure,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                    validator: (v) => v != null && v.length >= 6 ? null : 'Password must be at least 6 characters',
                  ),
                  if (_selectedRole == UserRole.tutor) ...[
                    const SizedBox(height: 16),
                    tm.TMTextField(
                      label: 'Subjects (comma separated)',
                      controller: _subjectsCtrl,
                      prefixIcon: const Icon(Icons.book),
                      validator: (v) => v?.isEmpty ?? true ? 'Enter subjects' : null,
                    ),
                    const SizedBox(height: 16),
                    tm.TMTextField(
                      label: 'Hourly Rate (optional)',
                      controller: _rateCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (auth.error != null)
                    tm.TMErrorBanner(
                      message: auth.error!,
                      onDismiss: auth.clearError,
                    ),
                  TMButton(
                    label: 'Create Account',
                    onPressed: _submit,
                    loading: auth.loading,
                    icon: Icons.person_add,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              role == UserRole.student ? Icons.school : Icons.psychology,
              size: 48,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              role.name.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}