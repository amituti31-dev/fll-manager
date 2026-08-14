import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

// Bonus / extra-rules editor for a single mission, shared by the robot
// planning screen (mission grid) and the scoring screen (mission checklist)
// so both surfaces read and write the same AppProvider.missionExtra entry.
class MissionExtraSheet extends StatefulWidget {
  final Mission mission;
  const MissionExtraSheet({super.key, required this.mission});

  @override
  State<MissionExtraSheet> createState() => _MissionExtraSheetState();
}

class _MissionExtraSheetState extends State<MissionExtraSheet> {
  late final TextEditingController _bonusCtrl;
  late final TextEditingController _bonusPtsCtrl;
  late final TextEditingController _rulesCtrl;
  late bool _bonusDone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final extra = context.read<AppProvider>().missionExtra[widget.mission.id];
    _bonusCtrl = TextEditingController(text: extra?.bonus ?? '');
    _bonusPtsCtrl = TextEditingController(text: extra != null && extra.bonusPts > 0 ? '${extra.bonusPts}' : '');
    _rulesCtrl = TextEditingController(text: extra?.rules ?? '');
    _bonusDone = extra?.bonusDone ?? false;
  }

  @override
  void dispose() {
    _bonusCtrl.dispose();
    _bonusPtsCtrl.dispose();
    _rulesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<AppProvider>().saveMissionExtra(
      widget.mission.id,
      bonus: _bonusCtrl.text.trim(),
      bonusPts: int.tryParse(_bonusPtsCtrl.text.trim()) ?? 0,
      rules: _rulesCtrl.text.trim(),
      bonusDone: _bonusDone,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('📝 ${widget.mission.name}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            textAlign: TextAlign.center),
        SizedBox(height: 16),
        Text('בונוסים שמתקיימים במשימה', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        SizedBox(height: 4),
        TextField(controller: _bonusCtrl, maxLines: 3,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'לדוגמה: בונוס נוסף אם...')),
        SizedBox(height: 12),
        Text('ניקוד הבונוס', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        SizedBox(height: 4),
        TextField(controller: _bonusPtsCtrl, keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: '0')),
        SizedBox(height: 12),
        Text('חוקים נוספים למשימה', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        SizedBox(height: 4),
        TextField(controller: _rulesCtrl, maxLines: 3,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'הערות וחוקים נוספים...')),
        SizedBox(height: 8),
        CheckboxListTile(
          value: _bonusDone,
          onChanged: (v) => setState(() => _bonusDone = v ?? false),
          title: Text('🎁 השגנו את הבונוס', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.accent2,
          contentPadding: EdgeInsets.zero,
        ),
        SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent2),
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור'),
          ),
        ),
      ]),
    );
  }
}
