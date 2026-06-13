import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginStep { choose, auth, create, join }

class _LoginScreenState extends State<LoginScreen> {
  _LoginStep _step = _LoginStep.choose;
  bool _loading = false;
  String _error = '';

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _createEmailCtrl = TextEditingController();
  final _createPassCtrl = TextEditingController();
  final _joinNameCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();
  final _joinEmailCtrl = TextEditingController();
  final _joinPassCtrl = TextEditingController();
  final _setupNameCtrl = TextEditingController();
  final _setupTeamCtrl = TextEditingController();

  bool _showSetup = false;

  @override
  void dispose() {
    for (final c in [_emailCtrl, _passCtrl, _createEmailCtrl, _createPassCtrl,
        _joinNameCtrl, _joinCodeCtrl, _joinEmailCtrl, _joinPassCtrl,
        _setupNameCtrl, _setupTeamCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setError(String msg) => setState(() => _error = msg);
  void _setLoading(bool v) => setState(() => _loading = v);

  Future<void> _signInGoogle() async {
    _setLoading(true); _setError('');
    try {
      final prov = context.read<AppProvider>();
      await prov.signInWithGoogle();
      if (!mounted) return;
      if (prov.status == AppStatus.needsTeam) {
        setState(() => _showSetup = true);
      } else if (prov.status != AppStatus.ready) {
        _setError('סטטוס לא צפוי: ${prov.status}');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _signInEmail() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _setError('נא למלא אימייל וסיסמה'); return;
    }
    _setLoading(true); _setError('');
    try {
      await context.read<AppProvider>().signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      _setError('שגיאה: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _registerForCreate() async {
    if (_createEmailCtrl.text.isEmpty || _createPassCtrl.text.length < 6) {
      _setError('סיסמה חייבת לפחות 6 תווים'); return;
    }
    _setLoading(true); _setError('');
    try {
      final prov = context.read<AppProvider>();
      await prov.registerWithEmail(_createEmailCtrl.text.trim(), _createPassCtrl.text);
      if (prov.status == AppStatus.needsTeam) {
        setState(() => _showSetup = true);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _completeSetup() async {
    if (_setupNameCtrl.text.isEmpty || _setupTeamCtrl.text.isEmpty) {
      _setError('נא למלא שם ושם קבוצה'); return;
    }
    _setLoading(true); _setError('');
    try {
      final prov = context.read<AppProvider>();
      // Use Firebase Auth email (works for both Google and email sign-in)
      final email = FirebaseService.currentUser?.email ?? _createEmailCtrl.text.trim();
      if (email.isEmpty) { _setError('לא נמצא אימייל — נסה להתחבר שוב'); return; }
      await prov.createTeam(
        userName: _setupNameCtrl.text.trim(),
        tName: _setupTeamCtrl.text.trim(),
        email: email,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _joinWithCode() async {
    if (_joinNameCtrl.text.isEmpty || _joinCodeCtrl.text.isEmpty ||
        _joinEmailCtrl.text.isEmpty || _joinPassCtrl.text.length < 6) {
      _setError('נא למלא את כל השדות'); return;
    }
    _setLoading(true); _setError('');
    try {
      final email = _joinEmailCtrl.text.trim();
      final pass  = _joinPassCtrl.text;
      try {
        await FirebaseService.registerWithEmail(email, pass);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          await FirebaseService.signInWithEmail(email, pass);
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      await context.read<AppProvider>().joinTeam(
        code: _joinCodeCtrl.text.trim().toUpperCase(),
        fullName: _joinNameCtrl.text.trim(),
        email: email,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          _setError('סיסמה שגויה לחשבון הזה. נסה שנית או אפס סיסמה.');
          break;
        case 'user-disabled':
          _setError('החשבון הזה הושבת. פנה לתמיכה.');
          break;
        case 'too-many-requests':
          _setError('יותר מדי ניסיונות כניסה. נסה שוב מאוחר יותר.');
          break;
        default:
          _setError(e.message ?? e.code);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _showSetup ? _buildSetupCard() : _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🤖', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('FLL Team Manager',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          SizedBox(height: 24),
          if (_step == _LoginStep.choose) _buildChooseStep(),
          if (_step == _LoginStep.auth) _buildAuthStep(),
          if (_step == _LoginStep.create) _buildCreateStep(),
          if (_step == _LoginStep.join) _buildJoinStep(),
          if (_error.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(_error, style: TextStyle(color: AppColors.red, fontSize: 13),
                textAlign: TextAlign.center),
          ],
          if (_loading) ...[
            SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.accent),
          ],
        ],
      ),
    );
  }

  Widget _buildChooseStep() {
    return Column(
      children: [
        Text('מה תרצה לעשות?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        SizedBox(height: 18),
        _choiceButton('🔑', 'הצטרף לקבוצה קיימת', 'Google או אימייל/סיסמה',
            () => setState(() { _step = _LoginStep.auth; _error = ''; })),
        SizedBox(height: 10),
        _choiceButton('🏆', 'צור קבוצה חדשה', 'אם אתה מנטור ורוצה לפתוח קבוצה',
            () => setState(() { _step = _LoginStep.create; _error = ''; })),
        SizedBox(height: 10),
        _choiceButton('🔗', 'הצטרף לקבוצה', 'יש לך קוד הצטרפות ממנטור',
            () => setState(() { _step = _LoginStep.join; _error = ''; }),
            color: AppColors.accent2),
      ],
    );
  }

  Widget _choiceButton(String icon, String title, String sub, VoidCallback onTap,
      {Color color = AppColors.accent}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: 26)),
            SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                Text(sub, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthStep() {
    return Column(children: [
      _googleButton(_signInGoogle),
      SizedBox(height: 12),
      Divider(color: AppColors.border),
      SizedBox(height: 12),
      _input(_emailCtrl, 'אימייל', TextInputType.emailAddress),
      SizedBox(height: 8),
      _input(_passCtrl, 'סיסמה', TextInputType.text, obscure: true),
      SizedBox(height: 12),
      Row(children: [
        Expanded(child: _btn('כניסה', _signInEmail)),
      ]),
      _backBtn(),
    ]);
  }

  Widget _buildCreateStep() {
    return Column(children: [
      Text('🏆', style: TextStyle(fontSize: 40)),
      SizedBox(height: 8),
      Text('צור קבוצה חדשה',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
      SizedBox(height: 16),
      _googleButton(() async {
        _setLoading(true);
        try {
          final prov = context.read<AppProvider>();
          await prov.signInWithGoogle();
          if (!mounted) return;
          if (prov.status == AppStatus.needsTeam) {
            setState(() => _showSetup = true);
          }
        } catch (e) { _setError(e.toString()); } finally { _setLoading(false); }
      }),
      SizedBox(height: 12),
      Divider(color: AppColors.border),
      SizedBox(height: 12),
      _input(_createEmailCtrl, 'אימייל', TextInputType.emailAddress),
      SizedBox(height: 8),
      _input(_createPassCtrl, 'סיסמה חדשה (לפחות 6 תווים)', TextInputType.text, obscure: true),
      SizedBox(height: 12),
      _btn('הרשם וצור קבוצה', _registerForCreate, color: AppColors.accent),
      _backBtn(),
    ]);
  }

  Widget _buildSetupCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🏆', style: TextStyle(fontSize: 48)),
        SizedBox(height: 8),
        Text('הגדרת קבוצה חדשה',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        SizedBox(height: 20),
        _input(_setupNameCtrl, 'שם שלך', TextInputType.name),
        SizedBox(height: 8),
        _input(_setupTeamCtrl, 'שם הקבוצה (לדוגמה: רובוטיקס 3000)', TextInputType.text),
        SizedBox(height: 16),
        _btn('✓ צור קבוצה', _completeSetup),
        if (_error.isNotEmpty) ...[
          SizedBox(height: 12),
          Text(_error, style: TextStyle(color: AppColors.red, fontSize: 13)),
        ],
        if (_loading) ...[
          SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.accent),
        ],
      ]),
    );
  }

  Widget _buildJoinStep() {
    return Column(children: [
      Text('🔗', style: TextStyle(fontSize: 40)),
      SizedBox(height: 8),
      Text('הצטרף לקבוצה',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
      SizedBox(height: 16),
      _input(_joinNameCtrl, 'שם מלא', TextInputType.name),
      SizedBox(height: 8),
      _input(_joinCodeCtrl, 'קוד הצטרפות (לדוגמה: ABCD-2345)', TextInputType.text,
          caps: TextCapitalization.characters),
      SizedBox(height: 8),
      _input(_joinEmailCtrl, 'אימייל', TextInputType.emailAddress),
      SizedBox(height: 8),
      _input(_joinPassCtrl, 'סיסמה (לפחות 6 תווים)', TextInputType.text, obscure: true),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () async {
            final email = _joinEmailCtrl.text.trim();
            if (email.isEmpty) { _setError('הזן אימייל כדי לאפס סיסמה'); return; }
            try {
              await FirebaseService.sendPasswordReset(email);
              _setError('קישור לאיפוס סיסמה נשלח לאימייל');
            } catch (e) {
              _setError('שגיאה בשליחת אימייל איפוס');
            }
          },
          child: Text('שכחת סיסמה?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
      ),
      _btn('🔗 הצטרף לקבוצה', _joinWithCode, color: AppColors.accent2),
      _backBtn(),
    ]);
  }

  Widget _googleButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
          SizedBox(width: 10),
          Text('התחבר עם Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, TextInputType type,
      {bool obscure = false, TextCapitalization caps = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      textCapitalization: caps,
      textAlign: TextAlign.right,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _btn(String label, VoidCallback onTap, {Color color = AppColors.accent}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _backBtn() {
    return TextButton(
      onPressed: () => setState(() { _step = _LoginStep.choose; _error = ''; _showSetup = false; }),
      child: Text('← חזור', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
