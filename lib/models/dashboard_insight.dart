enum DashboardInsightType { positive, warning, negative, neutral }

class DashboardInsight {
  const DashboardInsight({
    required this.title,
    required this.description,
    required this.type,
  });

  final String title;
  final String description;
  final DashboardInsightType type;
}
