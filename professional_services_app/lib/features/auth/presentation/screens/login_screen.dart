import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 🔥 Importación añadida

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import 'auth_shared.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
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
              Text(
                'Bienvenido de vuelta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Entra a tu espacio de servicios profesionales.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 26),
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
                label: 'Iniciar sesion',
                icon: Icons.login,
                isLoading: authState.isSubmitting,
                onPressed: authState.isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: authState.isSubmitting ? null : _openRegister,
                child: const Text('Crear una cuenta nueva'),
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

    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _openRegister() async {
    // 🚀 GOROUTER: Navegamos esperando un resultado (el correo registrado)
    final String? result = await context.push<String>('/register');

    if (!mounted || result == null) {
      return;
    }

    _emailController.text = result;
    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada. Ahora inicia sesion con tus datos.'),
      ),
    );
  }
}