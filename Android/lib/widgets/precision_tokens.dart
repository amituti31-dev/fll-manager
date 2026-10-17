import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Tappable chip showing how many precision tokens are left and what they're
/// worth; opens a picker (6…0). Used on the robot and scoring screens.
class PrecisionTokensChip extends StatelessWidget {
  final bool compact;
  const PrecisionTokensChip({super.key, this.compact = false});

  Future<void> _pick(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('כמה אסימוני דיוק נשארו?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
          ),
          for (final n in [6, 5, 4, 3, 2, 1, 0])
            ListTile(
              leading: Icon(
                n == prov.precisionTokens ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: n == prov.precisionTokens ? AppColors.accent2 : AppColors.textTertiary,
              ),
              title: Text('נשארו $n', style: TextStyle(color: AppColors.textPrimary)),
              trailing: Text('${precisionTokenPoints[n]} נק\'',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent2)),
              onTap: () => Navigator.pop(ctx, n),
            ),
        ]),
      ),
    );
    if (picked != null) await prov.setPrecisionTokens(picked);
  }

  @override
  Widget build(BuildContext context) {
    final n = context.select<AppProvider, int>((p) => p.precisionTokens);
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent2.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent2.withAlpha(120)),
        ),
        child: Text(compact ? '$n/6 · ${precisionTokenPoints[n]}' : 'נשארו $n · ${precisionTokenPoints[n]} נק\'',
            style: TextStyle(fontSize: compact ? 10 : 12, fontWeight: FontWeight.w700, color: AppColors.accent2)),
      ),
    );
  }
}
