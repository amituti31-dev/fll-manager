import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _registry = 'fll-teams-registry';

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Auth ──────────────────────────────────────────

  static const _webClientId =
      '493332319136-09vu4i13ufiiomc1beiv6bee6if1qc70.apps.googleusercontent.com';

  static Future<UserCredential> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  static bool get isEmailUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('לא מחובר');
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  static Future<void> unregisterUserFromTeam(String email) async {
    final key = email.replaceAll(RegExp(r'[.@]'), '_');
    await _db.collection(_registry).doc(key).delete();
  }

  static Future<void> reauthAndDeleteUser({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
      if (isGoogle) {
        await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
        final googleUser = await GoogleSignIn.instance.authenticate();
        final cred = GoogleAuthProvider.credential(idToken: googleUser.authentication.idToken);
        await user.reauthenticateWithCredential(cred);
      } else if (password != null && user.email != null) {
        final cred = EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(cred);
      } else {
        throw Exception('נדרשת כניסה מחדש. התנתק והתחבר שוב לפני מחיקת החשבון.');
      }
      await user.delete();
    }
  }

  // ─── Team Registry ─────────────────────────────────

  static Future<String?> findTeamForUser(String email) async {
    final key = email.replaceAll(RegExp(r'[.@]'), '_');
    final snap = await _db.collection(_registry).doc(key).get();
    if (snap.exists) return snap.data()?['teamId'] as String?;
    return null;
  }

  static Future<void> registerUserToTeam(String email, String teamId) async {
    final key = email.replaceAll(RegExp(r'[.@]'), '_');
    await _db.collection(_registry).doc(key).set({'teamId': teamId, 'email': email});
  }

  static Future<String?> findTeamByJoinCode(String code) async {
    final mentorSnap = await _db.collection(_registry).doc('mentor_$code').get();
    if (mentorSnap.exists) {
      return mentorSnap.data()?['teamId'] as String?;
    }
    final studentSnap = await _db.collection(_registry).doc('student_$code').get();
    if (studentSnap.exists) {
      return studentSnap.data()?['teamId'] as String?;
    }
    return null;
  }

  static Future<String> getRoleByCode(String code) async {
    final mentorSnap = await _db.collection(_registry).doc('mentor_$code').get();
    if (mentorSnap.exists) return 'admin';
    return 'student';
  }

  static Future<void> saveJoinCodes({
    required String teamId,
    required String teamName,
    required String mentorCode,
    required String studentCode,
  }) async {
    await Future.wait([
      _db.collection(_registry).doc('mentor_$mentorCode').set({
        'teamId': teamId, 'joinCode': mentorCode, 'role': 'admin', 'teamName': teamName,
        'createdAt': DateTime.now().toIso8601String(),
      }),
      _db.collection(_registry).doc('student_$studentCode').set({
        'teamId': teamId, 'joinCode': studentCode, 'role': 'student', 'teamName': teamName,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    ]);
  }

  // ─── Team Data ─────────────────────────────────────

  static Future<bool> teamExists(String teamId) async {
    try {
      final snap = await _db.collection(teamId).doc('settings').get();
      return snap.exists;
    } on FirebaseException catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loadSettings(String teamId) async {
    final snap = await _db.collection(teamId).doc('settings').get();
    return snap.exists ? snap.data() : null;
  }

  static Future<Map<String, dynamic>?> loadData(String teamId) async {
    final snap = await _db.collection(teamId).doc('data').get();
    return snap.exists ? snap.data() : null;
  }

  static Future<void> saveSettings(String teamId, Map<String, dynamic> data) async {
    await _db.collection(teamId).doc('settings').set(data, SetOptions(merge: true));
  }

  static Future<void> saveData(String teamId, Map<String, dynamic> data) async {
    await _db.collection(teamId).doc('data').set(data, SetOptions(merge: true));
  }

  // Full overwrite — used on team creation to wipe any stale data at that ID
  static Future<void> initTeamData(String teamId, Map<String, dynamic> settings, Map<String, dynamic> data) async {
    await Future.wait([
      _db.collection(teamId).doc('settings').set(settings),
      _db.collection(teamId).doc('data').set(data),
    ]);
  }

  static Future<void> deleteTeam({
    required String teamId,
    required String? mentorCode,
    required String? studentCode,
    required List<String> memberEmails,
  }) async {
    final futures = <Future>[
      _db.collection(teamId).doc('settings').delete(),
      _db.collection(teamId).doc('data').delete(),
      _db.collection(teamId).doc('chats').delete(),
      _db.collection(teamId).doc('archives').delete(),
      _db.collection(teamId).doc('gallery').delete(),
      _db.collection(teamId).doc('links').delete(),
      _db.collection(teamId).doc('strategy').delete(),

      if (mentorCode != null)
        _db.collection(_registry).doc('mentor_$mentorCode').delete(),
      if (studentCode != null)
        _db.collection(_registry).doc('student_$studentCode').delete(),
      for (final email in memberEmails)
        _db.collection(_registry).doc(email.replaceAll(RegExp(r'[.@]'), '_')).delete(),
    ];
    await Future.wait(futures);
  }

  // ─── Chat Realtime ─────────────────────────────────

  static Stream<DocumentSnapshot<Map<String, dynamic>>> chatStream(String teamId) =>
      _db.collection(teamId).doc('chats').snapshots();

  static Future<void> clearChat(String teamId) =>
      _db.collection(teamId).doc('chats').delete();

  static Future<void> sendChatMessage({
    required String teamId,
    required String channel,
    required ChatMessage message,
    String? privateKey,
  }) async {
    final docRef = _db.collection(teamId).doc('chats');
    final snap = await docRef.get();
    final data = snap.exists ? snap.data()! : <String, dynamic>{};

    if (channel == 'private' && privateKey != null) {
      final pvt = Map<String, dynamic>.from(data['private'] as Map? ?? {});
      final msgs = List<dynamic>.from(pvt[privateKey] as List? ?? []);
      msgs.add(message.toMap());
      if (msgs.length > 100) msgs.removeRange(0, msgs.length - 100);
      pvt[privateKey] = msgs;
      await docRef.set({'private': pvt}, SetOptions(merge: true));
    } else {
      final msgs = List<dynamic>.from(data[channel] as List? ?? []);
      msgs.add(message.toMap());
      if (msgs.length > 100) msgs.removeRange(0, msgs.length - 100);
      await docRef.set({channel: msgs}, SetOptions(merge: true));
    }
  }

  // ─── Archives ──────────────────────────────────────

  static Future<List<Map<String, dynamic>>> loadArchives(String teamId) async {
    final snap = await _db.collection(teamId).doc('archives').get();
    if (!snap.exists) return [];
    final raw = snap.data()?['list'] as List?;
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveArchives(String teamId, List<Map<String, dynamic>> archives) async {
    await _db.collection(teamId).doc('archives').set({'list': archives});
  }

  static Future<List<Map<String, dynamic>>> loadGallery(String teamId) async {
    final snap = await _db.collection(teamId).doc('gallery').get();
    if (!snap.exists) return [];
    final raw = snap.data()?['items'] as List?;
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveGallery(String teamId, List<Map<String, dynamic>> items) async {
    await _db.collection(teamId).doc('gallery').set({'items': items});
  }

  static Future<List<Map<String, dynamic>>> loadLinks(String teamId) async {
    final snap = await _db.collection(teamId).doc('links').get();
    if (!snap.exists) return [];
    final raw = snap.data()?['items'] as List?;
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveLinks(String teamId, List<Map<String, dynamic>> items) async {
    await _db.collection(teamId).doc('links').set({'items': items});
  }

  static Future<void> voteChatPoll({
    required String teamId,
    required String channel,
    required int messageId,
    required String memberId,
    required int optionIndex,
  }) async {
    final docRef = _db.collection(teamId).doc('chats');
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final msgs = List<dynamic>.from(data[channel] as List? ?? []);
    final idx = msgs.indexWhere((m) => (m as Map)['id'] == messageId);
    if (idx == -1) return;
    final msg = Map<String, dynamic>.from(msgs[idx] as Map);
    final votes = Map<String, dynamic>.from(msg['pollVotes'] as Map? ?? {});
    votes[memberId] = optionIndex;
    msg['pollVotes'] = votes;
    msgs[idx] = msg;
    await docRef.set({channel: msgs}, SetOptions(merge: true));
  }

  static Future<void> closeChatPoll({
    required String teamId,
    required String channel,
    required int messageId,
  }) async {
    final docRef = _db.collection(teamId).doc('chats');
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final msgs = List<dynamic>.from(data[channel] as List? ?? []);
    final idx = msgs.indexWhere((m) => (m as Map)['id'] == messageId);
    if (idx == -1) return;
    final msg = Map<String, dynamic>.from(msgs[idx] as Map);
    msg['pollClosed'] = true;
    msgs[idx] = msg;
    await docRef.set({channel: msgs}, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> loadStrategyBoards(String teamId) async {
    final snap = await _db.collection(teamId).doc('strategy').get();
    if (!snap.exists) return [];
    final raw = snap.data()?['boards'] as List?;
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveStrategyBoards(String teamId, List<Map<String, dynamic>> boards) async {
    await _db.collection(teamId).doc('strategy').set({'boards': boards});
  }

  // ─── Judging PDF ───────────────────────────────────

  static Future<void> saveJudgingPdf(String teamId, Uint8List bytes, String name) async {
    await _db.collection(teamId).doc('judging_pdf').set({
      'name': name,
      'data': base64Encode(bytes),
    });
  }

  static Future<Map<String, dynamic>?> loadJudgingPdf(String teamId) async {
    final snap = await _db.collection(teamId).doc('judging_pdf').get();
    if (!snap.exists) return null;
    return snap.data();
  }

  static Future<void> deleteJudgingPdf(String teamId) async {
    await _db.collection(teamId).doc('judging_pdf').delete();
  }

  // ─── Utils ─────────────────────────────────────────

  static String generateJoinCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const digits = '23456789';
    final rng = Random.secure();
    final code = List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
    final nums = List.generate(4, (_) => digits[rng.nextInt(digits.length)]).join();
    return '$code-$nums';
  }

  static String generateTeamId(String teamName) {
    final slug = teamName.toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9֐-׿-]'), '');
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    final rng = Random.secure();
    final suffix = List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'team-$slug-$suffix';
  }
}
