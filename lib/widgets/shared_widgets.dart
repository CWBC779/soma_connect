import 'package:flutter/material.dart';
import '../models/models.dart';
import '../themes/app_theme.dart';

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: FemoraTheme.warmText,
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final String? sub;
  final Color? subColor;

  const MetricTile({
    required this.value,
    required this.unit,
    required this.label,
    this.sub,
    this.subColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FemoraTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FemoraTheme.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: FemoraTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: FemoraTheme.warmText,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 10),
            Text(
              sub!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subColor ?? FemoraTheme.warmText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PhaseBadge extends StatelessWidget {
  final CyclePhase phase;
  final String? customLabel;
  final double? fontSize;

  const PhaseBadge(this.phase, {this.customLabel, this.fontSize, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: phase.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        customLabel ?? phase.label,
        style: TextStyle(
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          color: phase.textColor,
        ),
      ),
    );
  }
}

class IntensityDots extends StatelessWidget {
  final int intensity;
  final Color fillColor;
  final double size;

  const IntensityDots({
    required this.intensity,
    this.fillColor = FemoraTheme.rose,
    this.size = 10,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final filled = intensity.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < filled;
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(right: index < 4 ? size * 0.5 : 0),
          decoration: BoxDecoration(
            color: isActive ? fillColor : FemoraTheme.warmGray,
            borderRadius: BorderRadius.circular(size / 2),
          ),
        );
      }),
    );
  }
}

class ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final String displayValue;
  final Color barColor;

  const ProgressRow({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.barColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: FemoraTheme.warmText,
              ),
            ),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FemoraTheme.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: FemoraTheme.warmGray,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class InsightBanner extends StatelessWidget {
  final String emoji;
  final String text;

  const InsightBanner({
    required this.emoji,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FemoraTheme.warmGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: FemoraTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectButton extends StatelessWidget {
  final String label;

  const ConnectButton(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: const BorderSide(color: FemoraTheme.warmBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundColor: FemoraTheme.ink,
        backgroundColor: FemoraTheme.cardBg,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

class DisclaimerBox extends StatelessWidget {
  final String text;

  const DisclaimerBox(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FemoraTheme.warmGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: FemoraTheme.warmText,
          height: 1.4,
        ),
      ),
    );
  }
}
