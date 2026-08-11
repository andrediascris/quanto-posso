import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_shadows.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/features/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';
import 'package:quanto_posso/shared/widgets/app_logo.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OnboardingProgressIndicator(currentStep: 1),
                      const SizedBox(height: AppSpacing.xl),
                      const Center(child: AppLogo(width: 160)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Quanto Posso',
                        textAlign: TextAlign.center,
                        style: AppTypography.h3.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Cuide melhor do seu dinheiro',
                        textAlign: TextAlign.center,
                        style: AppTypography.h2.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Registre seus gastos, acompanhe seu saldo e tome '
                        'decisões com mais clareza.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _BenefitGrid(),
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
          ),
        ),
      ),
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  const _BenefitGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _BenefitItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Controle simples',
        ),
        SizedBox(height: AppSpacing.sm),
        _BenefitItem(icon: Icons.cloud_off_outlined, title: 'Funciona offline'),
        SizedBox(height: AppSpacing.sm),
        _BenefitItem(
          icon: Icons.lock_outline_rounded,
          title: 'Seus dados ficam com você',
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outline),
        boxShadow: const [AppShadows.card],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
