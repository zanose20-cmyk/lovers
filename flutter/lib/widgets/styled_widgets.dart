import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final double? blurRadius;
  final EdgeInsetsGeometry? padding;

  const GradientCard({super.key, required this.child, this.colors, this.blurRadius, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? AppColors.premiumGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: blurRadius ?? 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class RoomTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const RoomTypeChip({super.key, required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.backgroundCardLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textHint, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const BadgeChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatBox({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }
}

class InteractiveChip<T> extends StatelessWidget {
  final T value;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const InteractiveChip({super.key, required this.value, required this.selected, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.backgroundCardLight),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textHint)),
      ),
    );
  }
}
