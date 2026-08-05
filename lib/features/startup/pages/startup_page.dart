import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/features/categories/pages/category_setup_page.dart';
import 'package:quanto_posso/features/main/pages/main_shell_page.dart';
import 'package:quanto_posso/features/onboarding/pages/onboarding_page.dart';
import 'package:quanto_posso/features/profile/pages/profile_setup_page.dart';
import 'package:quanto_posso/features/splash/pages/splash_page.dart';
import 'package:quanto_posso/providers/initial_setup_provider.dart';
import 'package:quanto_posso/shared/buttons/primary_button.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InitialSetupProvider>(
      builder: (context, provider, child) {
        return switch (provider.status) {
          InitialSetupStatus.initial ||
          InitialSetupStatus.loading ||
          InitialSetupStatus.saving => const SplashPage(),
          InitialSetupStatus.requiresSetup => OnboardingPage(
            onStart: () => _openProfileSetup(context, provider),
          ),
          InitialSetupStatus.completed => _buildHome(provider),
          InitialSetupStatus.error => _ErrorView(
            message:
                provider.errorMessage ??
                'Não foi possível carregar seus dados.',
            onRetry: provider.initialize,
          ),
        };
      },
    );
  }

  Widget _buildHome(InitialSetupProvider provider) {
    final profile = provider.profile;

    if (profile == null) {
      return _ErrorView(
        message: 'Não foi possível carregar seus dados.',
        onRetry: provider.initialize,
      );
    }

    return MainShellPage(profile: profile, categories: provider.categories);
  }

  void _openProfileSetup(BuildContext context, InitialSetupProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (profileContext) => ProfileSetupPage(
          onContinue: (name, monthlyIncome) {
            Navigator.of(profileContext).push(
              MaterialPageRoute<void>(
                builder: (categoryContext) => CategorySetupPage(
                  onFinish: (selectedCategories) async {
                    try {
                      await provider.completeSetup(
                        name: name,
                        monthlyIncome: monthlyIncome,
                        selectedCategories: selectedCategories,
                      );

                      if (!categoryContext.mounted) {
                        return;
                      }

                      Navigator.of(
                        categoryContext,
                      ).popUntil((route) => route.isFirst);
                    } on Object {
                      if (!categoryContext.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(categoryContext).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            'Não foi possível salvar sua configuração.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'Tentar novamente', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
