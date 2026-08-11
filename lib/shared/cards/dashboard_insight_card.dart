import 'package:flutter/material.dart';
import 'package:quanto_posso/app/theme/app_colors.dart';
import 'package:quanto_posso/app/theme/app_radius.dart';
import 'package:quanto_posso/app/theme/app_spacing.dart';
import 'package:quanto_posso/app/theme/app_typography.dart';
import 'package:quanto_posso/models/dashboard_insight.dart';

class DashboardInsightCard extends StatelessWidget {
  const DashboardInsightCard({super.key, required this.insight});

  final DashboardInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (insight.type) {
      DashboardInsightType.positive => (
        Icons.trending_down_rounded,
        AppColors.success,
      ),
      DashboardInsightType.warning => (
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
      DashboardInsightType.negative => (
        Icons.error_outline_rounded,
        AppColors.error,
      ),
      DashboardInsightType.neutral => (
        Icons.lightbulb_outline_rounded,
        AppColors.primary,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight.description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
