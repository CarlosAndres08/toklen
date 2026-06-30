import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
class AuthShell extends StatelessWidget {
  const AuthShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= 920;

            if (isWide) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1120,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 36),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                      const Expanded(child: AuthBrandPanel()),
                      const SizedBox(width: 36),
                      SizedBox(
                        width: 440,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const CompactBrandHeader(),
                        const SizedBox(height: 28),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 480),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ToklenMark(isLight: true),
          const Spacer(),
          Text(
            'Servicios profesionales con confianza desde el primer contacto.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Agenda, cotiza y conversa con proveedores verificados en una experiencia simple y cuidada.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 32),
          const TrustStrip(),
        ],
      ),
    );
  }
}

class CompactBrandHeader extends StatelessWidget {
  const CompactBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: <Widget>[ToklenMark()]);
  }
}

class ToklenMark extends StatelessWidget {
  const ToklenMark({this.isLight = false, super.key});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isLight
        ? AppColors.onPrimary
        : AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isLight
                ? AppColors.onPrimary.withValues(alpha: 0.16)
                : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(0), // Espacio interno para que el logo no toque los bordes
          child: SvgPicture.asset(
  isLight
      ? 'assets/images/logo_light.svg'
      : 'assets/images/logo.svg',

  fit: BoxFit.contain,
),
        ),
        const SizedBox(width: 12),
        Text(
          AppConfig.appName,
          style: TextStyle(
            color: foreground,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const <Widget>[
        TrustPill(icon: Icons.lock_outline, label: 'JWT seguro'),
        TrustPill(icon: Icons.verified_outlined, label: 'Perfiles verificados'),
        TrustPill(icon: Icons.forum_outlined, label: 'Chat integrado'),
      ],
    );
  }
}

class TrustPill extends StatelessWidget {
  const TrustPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppColors.onPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.selectedRole,
    required this.onChanged,
    super.key,
  });

  final String selectedRole;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          SegmentButton(
            label: 'Cliente',
            isSelected: selectedRole == 'client',
            onTap: () => onChanged('client'),
          ),
          SegmentButton(
            label: 'Proveedor',
            isSelected: selectedRole == 'provider',
            onTap: () => onChanged('provider'),
          ),
        ],
      ),
    );
  }
}

class SegmentButton extends StatelessWidget {
  const SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

String? validateName(String? value) {
  final String text = value?.trim() ?? '';
  if (text.length < 2) {
    return 'Ingresa tu nombre.';
  }
  return null;
}

String? validateEmail(String? value) {
  final String text = value?.trim() ?? '';
  final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  if (!emailPattern.hasMatch(text)) {
    return 'Ingresa un email válido.';
  }
  return null;
}

String? validatePassword(String? value) {
  final String text = value ?? '';
  if (text.length < 8) {
    return 'Usa al menos 8 caracteres.';
  }
  return null;
}