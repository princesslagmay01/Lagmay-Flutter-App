import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modern, sleek card to display a single grade record.
class GradeCard extends StatelessWidget {
  const GradeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    this.score,
    this.total,
    this.points,
    this.badgeText,
    this.badgeColor,
    this.statusText,
    this.statusColor,
  });

  final String title;
  final String subtitle;
  final DateTime date;

  // For scored items (quizzes, exams, activities, projects)
  final int? score;
  final int? total;

  // For oral recitations
  final int? points;

  // Optional badge (e.g. "Short", "Prelim")
  final String? badgeText;
  final Color? badgeColor;

  // Optional status text (e.g. "Present", "Absent")
  final String? statusText;
  final Color? statusColor;

  static const _accent = Color(0xFF8B5CF6);

  double? get _percentage {
    if (score != null && total != null && total! > 0) {
      return score! / total!;
    }
    return null;
  }

  Color get _scoreColor {
    if (_percentage == null) return _accent;
    if (_percentage! >= 0.75) return const Color(0xFF66BB6A);
    if (_percentage! >= 0.50) return const Color(0xFFFFCA28);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1535) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F0A1E);
    final textMuted = isDark ? const Color(0xFF9D8EC4) : const Color(0xFF6B5E8F);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Future expansion or details view can go here
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Left: Icon or Date Block
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(date).toUpperCase(),
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Middle: title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            _Badge(text: badgeText!, color: badgeColor ?? _accent),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Right: score ring / status
                if (statusText != null)
                  _StatusChip(text: statusText!, color: statusColor ?? _accent)
                else if (_percentage != null)
                  _CircularScore(
                    score: score!,
                    total: total!,
                    percentage: _percentage!,
                    color: _scoreColor,
                  )
                else if (points != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$points',
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  const _CircularScore({
    required this.score,
    required this.total,
    required this.percentage,
    required this.color,
  });
  
  final int score;
  final int total;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/$total',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 9,
                    height: 1.0,
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
