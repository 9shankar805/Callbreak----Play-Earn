import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Compact coin balance pill — used in headers/nav bars.
class CoinDisplay extends StatelessWidget {
  final int balance;
  final bool compact;
  final VoidCallback? onTap;

  const CoinDisplay({
    super.key,
    required this.balance,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical:   compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2D160C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.headerGold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.headerGold.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🪙', style: TextStyle(fontSize: compact ? 13 : 16)),
            const SizedBox(width: 5),
            Text(
              _formatted(balance),
              style: TextStyle(
                color: AppTheme.headerGold,
                fontSize: compact ? 12 : 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.add_circle_outline,
                  color: AppTheme.headerGold.withValues(alpha: 0.7),
                  size: compact ? 12 : 15),
            ],
          ],
        ),
      ),
    );
  }

  String _formatted(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
