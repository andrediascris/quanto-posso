import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/widgets/app_logo.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const AppLogo(width: 180),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Saiba quanto você ainda pode gastar.',
                          textAlign: TextAlign.center,
                          style: AppTypography.h2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Controle seus gastos de forma simples, privada e '
                          'totalmente offline.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _BenefitItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privado',
                          description:
                              'Seus dados ficam somente no seu celular.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _BenefitItem(
                          icon: Icons.wifi_off_rounded,
                          title: 'Funciona offline',
                          description:
                              'Use o aplicativo mesmo sem conexão com a '
                              'internet.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _BenefitItem(
                          icon: Icons.bolt_rounded,
                          title: 'Rápido e simples',
                          description:
                              'Registre seus gastos em poucos segundos.',
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: 'Começar',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: onStart,
                        ),
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

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
