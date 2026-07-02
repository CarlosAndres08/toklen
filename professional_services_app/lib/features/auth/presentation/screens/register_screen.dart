import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import 'auth_shared.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'client';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _listenForAuthErrors();

    final AuthState authState =
        ref.watch(authControllerProvider).value ?? const AuthState();

    return AuthShell(
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: authState.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu cuenta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Activa tu perfil para contratar o vender servicios.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 26),
              AppTextField(
                controller: _nameController,
                label: 'Nombre',
                hintText: 'Carlos Andres',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: validateName,
              ),
              const SizedBox(height: 16),
              RoleSelector(
                selectedRole: _selectedRole,
                onChanged: (String role) => setState(() {
                  _selectedRole = role;
                }),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'correo@toklen.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Minimo 8 caracteres',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: validatePassword,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Crear cuenta',
                icon: Icons.arrow_forward,
                isLoading: authState.isSubmitting,
                onPressed: authState.isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: authState.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _listenForAuthErrors() {
    ref.listen<AsyncValue<AuthState>>(authControllerProvider, (
      _,
      AsyncValue<AuthState> next,
    ) {
      next.whenData((AuthState authState) {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        final String message = authState.errorMessage ?? '';
        if (message.isEmpty) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        Future<void>.microtask(
          ref.read(authControllerProvider.notifier).clearError,
        );
      });
    });
  }

  Future<void> _submit() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final bool created = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rol: _selectedRole,
        );

    if (!mounted || !created) {
      return;
    }

    Navigator.of(context).pop(_emailController.text.trim());
  }
}
