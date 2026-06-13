import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/image_source_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _teamNameCtrl;
  late TextEditingController _myNameCtrl;
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _pickingLogo = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    final prov = context.read<AppProvider>();
    _teamNameCtrl = TextEditingController(text: prov.teamName);
    _myNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _myNameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(AppProvider prov) async {
    setState(() => _pickingLogo = true);
    try {
      final picked = await pickImageWithSource(
        context,
        maxWidth: 400, maxHeight: 400, quality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await prov.updateTeamLogo(base64Encode(bytes));
      }
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
    }
  }

  Future<void> _changePassword(AppProvider prov) async {
    final current = _currentPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    if (current.isEmpty || newPass.isEmpty) {
      _snackbar('נא למלא את כל השדות', AppColors.red); return;
    }
    if (newPass.length < 6) {
      _snackbar('סיסמה חדשה חייבת לפחות 6 תווים', AppColors.red); return;
    }
    if (newPass != confirm) {
      _snackbar('הסיסמאות אינן תואמות', AppColors.red); return;
    }
    setState(() => _changingPassword = true);
    try {
      await prov.changePassword(current, newPass);
      if (mounted) {
        _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
        _snackbar('הסיסמה שונתה בהצלחה ✓', AppColors.accent2);
      }
    } catch (e) {
      if (mounted) _snackbar('שגיאה: ${e.toString()}', AppColors.red);
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}.${d.month}.${d.year}';
  }

  Future<void> _pickCompetitionDate(BuildContext context, AppProvider prov) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 400)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) await prov.setCompetitionDate(picked);
  }

  void _snackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _confirmRegenerateCodes(BuildContext context, AppProvider prov) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('חדש קודים', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('הקודים הישנים יבוטלו. חברים קיימים לא יושפעו. להמשיך?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent3),
            child: Text('צור קודים חדשים'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await prov.regenerateJoinCodes();
      if (context.mounted) _snackbar('קודים חדשים נוצרו בהצלחה ✓', AppColors.accent2);
    }
  }

  Future<void> _confirmDeleteTeam(BuildContext context, AppProvider prov) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחיקת קבוצה', style: TextStyle(color: AppColors.red)),
        content: Text('האם אתה בטוח שברצונך למחוק את "${prov.teamName}"?\nכל הנתונים יימחקו לצמיתות.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('כן, מחק', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('אישור סופי', style: TextStyle(color: AppColors.red)),
        content: Text('פעולה זו בלתי הפיכה לחלוטין.\nכל החברים, הניקוד, היומן והצ\'אט יימחקו.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text('מחק לצמיתות'),
          ),
        ],
      ),
    );
    if (second == true && context.mounted) await prov.deleteTeam();
  }

  Future<void> _confirmResetAll(BuildContext context, AppProvider prov) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('איפוס כל נתוני העונה', style: TextStyle(color: AppColors.red)),
        content: Text(
          'ימחקו לצמיתות:\n• יומן יומי\n• שיפורי רובוט\n• מחוונים\n• פתקי ערכים\n• משימות חברים\n• צ\'אט קבוצתי\n• ניקוד וריצות\n\nחברי הקבוצה לא יימחקו.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('אפס הכל', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('אישור סופי', style: TextStyle(color: AppColors.red)),
        content: Text('פעולה זו בלתי הפיכה לחלוטין. להמשיך?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text('אפס הכל'),
          ),
        ],
      ),
    );
    if (second == true && context.mounted) {
      await prov.resetAllData();
      if (context.mounted) _snackbar('כל נתוני העונה אופסו ✓', AppColors.accent2);
    }
  }

  Future<void> _confirmLeaveTeam(BuildContext context, AppProvider prov) async {
    final isOnlyAdmin = prov.isAdmin &&
        prov.members.where((m) => m.isAdmin).length == 1;
    if (isOnlyAdmin) {
      _snackbar('אתה המנטור היחיד. העבר הרשאות לחבר אחר לפני יציאה.', AppColors.red);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('יציאה מהקבוצה', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('תוסר מהקבוצה ותוכל להצטרף לקבוצה אחרת. הנתונים שלך ישארו.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent3),
            child: Text('צא מהקבוצה'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) await prov.leaveTeam();
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AppProvider prov) async {
    // Returns the password (String) when confirmed, null when cancelled.
    // Non-email users pop with '' (empty). Email users pop with their password text.
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(isEmail: FirebaseService.isEmailUser),
    );
    if (password != null && context.mounted) {
      await prov.deleteAccount(password: password.isEmpty ? null : password);
    }
  }

  void _copyCode(String code, String label) {
    Clipboard.setData(ClipboardData(text: code));
    _snackbar('$label הועתק: $code', AppColors.accent2);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final me = prov.members.firstWhere(
      (m) => m.id == prov.currentUser?.id,
      orElse: () => prov.members.isNotEmpty
          ? prov.members.first
          : prov.currentUser ?? prov.members.first,
    );
    final remainingChanges = prov.isAdmin ? null : (2 - me.nameChanges).clamp(0, 2);

    return ListView(padding: const EdgeInsets.all(16), children: [

      // ── Team info + logo ──────────────────────────────
      _Card(children: [
        _CardHeader('👥', 'פרטי קבוצה'),
        SizedBox(height: 12),

        // Logo display + picker
        if (prov.isAdmin) ...[
          Row(children: [
            // Logo preview
            if (prov.teamLogo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Builder(builder: (_) {
                  try {
                    return Image.memory(base64Decode(prov.teamLogo!),
                        width: 60, height: 60, fit: BoxFit.cover);
                  } catch (_) { return SizedBox.shrink(); }
                }),
              )
            else
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 28),
              ),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('לוגו קבוצה', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              SizedBox(height: 6),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _pickingLogo ? null : () => _pickLogo(prov),
                  icon: _pickingLogo
                      ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.upload, size: 14),
                  label: Text(prov.teamLogo != null ? 'החלף' : 'העלה', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent2,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (prov.teamLogo != null) ...[
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => prov.updateTeamLogo(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('הסר', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ]),
            ]),
          ]),
          SizedBox(height: 14),
          Divider(color: AppColors.border),
          SizedBox(height: 10),
        ],

        TextField(
          controller: _teamNameCtrl,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(labelText: 'שם הקבוצה'),
          enabled: prov.isAdmin,
        ),
        if (prov.isAdmin) ...[
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => prov.updateTeamName(_teamNameCtrl.text.trim()),
              child: Text('💾 שמור שם קבוצה'),
            ),
          ),
        ],
      ]),
      SizedBox(height: 12),

      // ── My name ───────────────────────────────────────
      _Card(children: [
        _CardHeader('⚙️', 'שינוי שם שלי'),
        SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('שם נוכחי: ${prov.currentUser?.name ?? ""}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          if (!prov.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: remainingChanges == 0 ? AppColors.red.withAlpha(30) : AppColors.accent2.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$remainingChanges שינויים נותרו',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: remainingChanges == 0 ? AppColors.red : AppColors.accent2,
                  )),
            ),
        ]),
        SizedBox(height: 10),
        if (!prov.isAdmin && remainingChanges == 0)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.red.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withAlpha(60)),
            ),
            child: Row(children: [
              Icon(Icons.lock, color: AppColors.red, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text('הגעת למקסימום שינויי שם. פנה למנטור לשינוי שם.',
                  style: TextStyle(fontSize: 12, color: AppColors.red, height: 1.4))),
            ]),
          )
        else ...[
          TextField(
            controller: _myNameCtrl,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'שם חדש'),
          ),
          SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final name = _myNameCtrl.text.trim();
              if (name.isEmpty) return;
              if (!prov.isAdmin && me.nameChanges >= 2) {
                _snackbar('הגעת למקסימום שינויי שם', AppColors.red); return;
              }
              me.name = name;
              if (!prov.isAdmin) me.nameChanges++;
              prov.currentUser?.name = name;
              await prov.save();
              if (mounted) setState(() => _myNameCtrl.clear());
              if (mounted) _snackbar('שם שונה ל-$name', AppColors.accent2);
            },
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent),
            child: Text('✏️ שנה שם'),
          ),
        ],
      ]),
      SizedBox(height: 12),

      // ── Password change (email users only) ───────────
      if (FirebaseService.isEmailUser) ...[
        _Card(children: [
          _CardHeader('🔒', 'שינוי סיסמה'),
          SizedBox(height: 12),
          _passField(_currentPassCtrl, 'סיסמה נוכחית'),
          SizedBox(height: 8),
          _passField(_newPassCtrl, 'סיסמה חדשה (לפחות 6 תווים)'),
          SizedBox(height: 8),
          _passField(_confirmPassCtrl, 'אימות סיסמה חדשה'),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changingPassword ? null : () => _changePassword(prov),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: _changingPassword
                  ? SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('🔒 שנה סיסמה'),
            ),
          ),
        ]),
        SizedBox(height: 12),
      ],

      // ── Admin: change any member's name ───────────────
      if (prov.isAdmin && prov.members.isNotEmpty) ...[
        _Card(children: [
          _CardHeader('👤', 'שינוי שם חברים'),
          SizedBox(height: 4),
          Text('כמנטור תוכל לשנות שם לכל חבר קבוצה',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          SizedBox(height: 12),
          ...prov.members.map((m) => _MemberNameRow(
            member: m,
            onSave: (newName) async {
              await prov.updateMemberName(m.id, newName);
              _snackbar('שם שונה ל-$newName', AppColors.accent2);
            },
          )),
        ]),
        SizedBox(height: 12),
      ],

      // ── Join codes ────────────────────────────────────
      if (prov.isAdmin) ...[
        _Card(children: [
          _CardHeader('🔑', 'קודי הצטרפות לקבוצה'),
          SizedBox(height: 12),
          _CodeBox(
            label: '👑 קוד מנטורים',
            code: prov.mentorCode ?? '----',
            gradient: LinearGradient(colors: [AppColors.accent3, AppColors.gold]),
            onCopy: () => _copyCode(prov.mentorCode ?? '', 'קוד מנטורים'),
          ),
          SizedBox(height: 10),
          _CodeBox(
            label: '🎓 קוד תלמידים',
            code: prov.studentCode ?? '----',
            gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
            onCopy: () => _copyCode(prov.studentCode ?? '', 'קוד תלמידים'),
          ),
          SizedBox(height: 12),
          Text(
            '💡 שתף את הקודים עם חברי הקבוצה. מנטורים ← קוד מנטורים 👑',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
        ]),
        SizedBox(height: 12),

        _Card(children: [
          _CardHeader('ℹ️', 'מזהה קבוצה'),
          SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
            child: Text(prov.teamId ?? 'לא זמין',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.accent)),
          ),
        ]),
        SizedBox(height: 12),

        _Card(children: [
          _CardHeader('📅', 'תאריך תחרות'),
          SizedBox(height: 8),
          Text('הגדר תאריך התחרות לקבלת ספירה לאחור בלוח הבקרה',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          SizedBox(height: 12),
          if (prov.competitionDate != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent2.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent2.withAlpha(80)),
              ),
              child: Text(_formatDate(prov.competitionDate!),
                  style: TextStyle(fontSize: 14, color: AppColors.accent2, fontWeight: FontWeight.w700)),
            ),
            SizedBox(height: 10),
          ],
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _pickCompetitionDate(context, prov),
              icon: Icon(Icons.calendar_today, size: 14),
              label: Text(prov.competitionDate != null ? 'שנה תאריך' : 'בחר תאריך תחרות'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent2),
            )),
            if (prov.competitionDate != null) ...[
              SizedBox(width: 8),
              IconButton(
                onPressed: () => prov.setCompetitionDate(null),
                icon: Icon(Icons.clear, size: 18, color: AppColors.red),
                tooltip: 'הסר תאריך',
              ),
            ],
          ]),
        ]),
        SizedBox(height: 12),

        _Card(children: [
          _CardHeader('🗑️', 'איפוס כל נתוני העונה'),
          SizedBox(height: 8),
          Text('מוחק יומן, שיפורים, מחוונים, פתקים, משימות, צ\'אט וניקוד. חברי הקבוצה נשארים.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmResetAll(context, prov),
              icon: Text('🗑️'),
              label: Text('אפס הכל'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: BorderSide(color: AppColors.red),
              ),
            ),
          ),
        ]),
        SizedBox(height: 12),

        _Card(children: [
          _CardHeader('🔄', 'חדש קודי הצטרפות'),
          SizedBox(height: 8),
          Text('יצירת קודים חדשים תבטל את הקודים הישנים. חברים קיימים לא יושפעו.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmRegenerateCodes(context, prov),
              icon: Text('🔄'),
              label: Text('צור קודים חדשים'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent3),
            ),
          ),
        ]),
        SizedBox(height: 12),
      ],

      // ── Theme toggle ──────────────────────────────────────
      _Card(children: [
        _CardHeader('🎨', 'מראה'),
        SizedBox(height: 8),
        Row(children: [
          Text(prov.isDarkMode ? '🌙 מצב כהה' : '☀️ מצב בהיר',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          Spacer(),
          Switch(
            value: prov.isDarkMode,
            onChanged: (_) => prov.toggleTheme(),
            activeThumbColor: AppColors.accent,
          ),
        ]),
      ]),
      SizedBox(height: 12),

      // ── About ──────────────────────────────────────────
      _Card(children: [
        _CardHeader('ℹ️', 'אודות'),
        SizedBox(height: 8),
        Text('FLL Team Manager\nגרסה 1.0.0 – Unearthed 2026\nפותח עבור קבוצות FIRST LEGO League',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.7)),
      ]),
      SizedBox(height: 12),

      // ── Delete team (admin only) ──────────────────────
      if (prov.isAdmin) ...[
        _Card(children: [
          _CardHeader('💣', 'מחיקת קבוצה'),
          SizedBox(height: 8),
          Text('מוחק את כל נתוני הקבוצה לצמיתות — חברים, ניקוד, יומן, הכל. לא ניתן לשחזר.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDeleteTeam(context, prov),
              icon: Text('💣'),
              label: Text('מחק קבוצה'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: BorderSide(color: AppColors.red),
              ),
            ),
          ),
        ]),
        SizedBox(height: 12),
      ],

      // ── Leave team ────────────────────────────────────
      _Card(children: [
        _CardHeader('🚪', 'יציאה מהקבוצה'),
        SizedBox(height: 8),
        Text('תוסר מהקבוצה ותוכל להצטרף לקבוצה אחרת. החשבון שלך ישאר פעיל.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLeaveTeam(context, prov),
            icon: Text('🚪'),
            label: Text('צא מהקבוצה'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent3,
              side: BorderSide(color: AppColors.accent3),
            ),
          ),
        ),
      ]),
      SizedBox(height: 12),

      // ── Delete account ────────────────────────────────
      _Card(children: [
        _CardHeader('⚠️', 'מחיקת חשבון'),
        SizedBox(height: 8),
        Text('מחיקת החשבון תסיר אותך מהקבוצה לצמיתות. הנתונים של הקבוצה לא יימחקו.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDeleteAccount(context, prov),
            icon: Text('🗑️'),
            label: Text('מחק חשבון'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red),
            ),
          ),
        ),
      ]),
      SizedBox(height: 12),

      // ── Sign out ──────────────────────────────────────
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text('התנתקות', style: TextStyle(color: AppColors.textPrimary)),
                content: Text('להתנתק מהאפליקציה?',
                    style: TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
                  TextButton(onPressed: () => Navigator.pop(context, true),
                      child: Text('התנתק', style: TextStyle(color: AppColors.red))),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AppProvider>().signOut();
            }
          },
          icon: Text('🚪'),
          label: Text('התנתק'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red, side: BorderSide(color: AppColors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ]);
  }

  Widget _passField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    obscureText: true,
    style: TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(hintText: hint),
  );
}

// ─── Member name row (admin only) ────────────────────

class _MemberNameRow extends StatefulWidget {
  final dynamic member;
  final Future<void> Function(String) onSave;
  const _MemberNameRow({required this.member, required this.onSave});

  @override
  State<_MemberNameRow> createState() => _MemberNameRowState();
}

class _MemberNameRowState extends State<_MemberNameRow> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.member.name as String);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: m.color,
          radius: 14,
          child: Text((m.name as String).isNotEmpty ? (m.name as String)[0] : '?',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _editing
              ? TextField(
                  controller: _ctrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  ),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name as String,
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  Text(m.role == 'admin' ? '👑 מנטור' : '🎓 תלמיד  •  ${(m.nameChanges as int)} שינויים',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
        ),
        if (_editing) ...[
          IconButton(
            icon: Icon(Icons.check, color: AppColors.accent2, size: 18),
            onPressed: () async {
              final name = _ctrl.text.trim();
              if (name.isEmpty) return;
              await widget.onSave(name);
              setState(() => _editing = false);
            },
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textTertiary, size: 18),
            onPressed: () {
              _ctrl.text = widget.member.name as String;
              setState(() => _editing = false);
            },
          ),
        ] else
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.textSecondary, size: 16),
            onPressed: () => setState(() => _editing = true),
          ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _CardHeader extends StatelessWidget {
  final String icon;
  final String title;
  const _CardHeader(this.icon, this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: TextStyle(fontSize: 18)),
    SizedBox(width: 8),
    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
  ]);
}

class _CodeBox extends StatelessWidget {
  final String label;
  final String code;
  final LinearGradient gradient;
  final VoidCallback onCopy;
  const _CodeBox({required this.label, required this.code, required this.gradient, required this.onCopy});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      SizedBox(height: 6),
      Text(code, style: TextStyle(fontFamily: 'monospace', fontSize: 28,
          fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
      SizedBox(height: 8),
      TextButton(
        onPressed: onCopy,
        style: TextButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text('📋 העתק', style: TextStyle(fontSize: 12)),
      ),
    ]),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  final bool isEmail;
  const _DeleteAccountDialog({required this.isEmail});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('מחיקת חשבון', style: TextStyle(color: AppColors.red)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('פעולה זו בלתי הפיכה. תוסר מהקבוצה לצמיתות.',
            style: TextStyle(color: AppColors.textSecondary)),
        if (widget.isEmail) ...[
          SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'אמת זהות — הכנס סיסמה'),
          ),
        ],
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
        TextButton(
          onPressed: () => Navigator.pop(context, widget.isEmail ? _ctrl.text : ''),
          child: Text('מחק חשבון', style: TextStyle(color: AppColors.red)),
        ),
      ],
    );
  }
}
