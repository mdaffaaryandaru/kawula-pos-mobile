part of '../pages/admin_dashboard_page.dart';

class _DashboardMetric {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
    required this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
  final String detail;
}

class _DashboardAction {
  const _DashboardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
}
