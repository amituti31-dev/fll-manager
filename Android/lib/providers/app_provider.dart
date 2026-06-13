import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

enum AppStatus { loading, unauthenticated, needsTeam, ready }

class AppProvider extends ChangeNotifier {
  AppStatus status = AppStatus.loading;
  String? teamId;
  String teamName = 'FLL Team';
  String? teamLogo;
  String currentSeason = 'Unearthed 2026';
  String? mentorCode;
  String? studentCode;

  Member? currentUser;
  bool isAdmin = false;
  bool isDarkMode = true;

  String innovationProblem = '';
  String innovationSolution = '';
  String? competitionDate;
  String? judgingPdfName;

  List<Member> members = [];
  List<LogEntry> logs = [];
  List<ArchivedSeason> archives = [];
  List<Mission> missions = missions2026.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
  List<Improvement> improvements = [];
  List<ScoreRun> scores = [];
  Map<int, bool> missionChecks = {};
  Map<String, List<RubricItem>> rubrics = {'values': [], 'robot': [], 'innovation': []};
  List<StickyNote> stickies = [];
  List<MemberTask> memberTasks = [];
  List<ChecklistItem> checklist = _defaultChecklist();
  List<GalleryItem> gallery = [];
  List<JudgingQuestion> judgingQuestions = _defaultJudgingQuestions();
  List<LinkItem> links = [];
  List<StrategyBoard> strategyBoards = [];

  static List<ChecklistItem> _defaultChecklist() => [
    ChecklistItem(id: 1, text: 'ארגון חברי הקבוצה'),
    ChecklistItem(id: 2, text: 'סיכומי אימונים'),
    ChecklistItem(id: 3, text: 'פרזנטציה מודפסת'),
    ChecklistItem(id: 4, text: 'תיקיית שיפורים רובוט'),
    ChecklistItem(id: 5, text: 'הרצאת הורים ורכזים'),
  ];

  static List<JudgingQuestion> _defaultJudgingQuestions() => [
    JudgingQuestion(id: 1, category: 'robot', question: 'כיצד תכננתם את הרובוט?'),
    JudgingQuestion(id: 2, category: 'robot', question: 'איזה שיפורים עשיתם לאורך העונה?'),
    JudgingQuestion(id: 3, category: 'robot', question: 'מה הגדול ביותר שלמדתם בתכנון?'),
    JudgingQuestion(id: 4, category: 'robot', question: 'כיצד חילקתם את תפקידי הרובוט בין חברי הקבוצה?'),
    JudgingQuestion(id: 5, category: 'robot', question: 'מה אתם הכי גאים בו מבחינת הרובוט?'),
    JudgingQuestion(id: 6, category: 'innovation', question: 'מה הבעיה שזיהיתם?'),
    JudgingQuestion(id: 7, category: 'innovation', question: 'עם מי נועצתם בנושא הבעיה?'),
    JudgingQuestion(id: 8, category: 'innovation', question: 'מה הפתרון שפיתחתם?'),
    JudgingQuestion(id: 9, category: 'innovation', question: 'כיצד בדקתם שהפתרון עובד?'),
    JudgingQuestion(id: 10, category: 'innovation', question: 'מה שיניתם לאחר הבדיקות?'),
    JudgingQuestion(id: 11, category: 'values', question: 'כיצד מתבטא Discovery בקבוצתכם?'),
    JudgingQuestion(id: 12, category: 'values', question: 'תנו דוגמה לרגע של Teamwork'),
    JudgingQuestion(id: 13, category: 'values', question: 'כיצד הפגנתם Inclusion?'),
    JudgingQuestion(id: 14, category: 'values', question: 'מה עשיתם שהיה Fun?'),
    JudgingQuestion(id: 15, category: 'values', question: 'מה Impact יש לפרויקט שלכם?'),
  ];

  // Defers notifyListeners() to after the current frame to avoid
  // "_dependents.isEmpty: is not true" when called during Flutter's
  // resumption after a native operation (e.g. image picker).
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  // ─── Reset ────────────────────────────────────────

  void _resetToDefaults() {
    teamName = 'FLL Team';
    teamLogo = null;
    currentSeason = 'Unearthed 2026';
    mentorCode = null;
    studentCode = null;
    members = [];
    logs = [];
    archives = [];
    missions = missions2026.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    improvements = [];
    scores = [];
    missionChecks = {};
    rubrics = {'values': [], 'robot': [], 'innovation': []};
    stickies = [];
    memberTasks = [];
    checklist = _defaultChecklist();
    innovationProblem = '';
    innovationSolution = '';
    competitionDate = null;
    gallery = [];
    judgingQuestions = _defaultJudgingQuestions();
    links = [];
    strategyBoards = [];
  }

  // ─── Boot ──────────────────────────────────────────

  Future<void> init() async {
    final fbUser = FirebaseService.currentUser;
    if (fbUser == null) {
      status = AppStatus.unauthenticated;
      notifyListeners();
      return;
    }
    await _loginWithFirebaseUser(fbUser.email!);
  }

  Future<void> _loginWithFirebaseUser(String email) async {
    final tid = await FirebaseService.findTeamForUser(email);
    if (tid == null) {
      status = AppStatus.needsTeam;
      notifyListeners();
      return;
    }
    _resetToDefaults();
    teamId = tid;
    await loadTeamData();
    final member = members.firstWhere(
      (m) => m.email == email,
      orElse: () => Member(id: '', name: '', email: email, role: 'student', color: AppColors.avatarColors[0]),
    );
    currentUser = member;
    isAdmin = member.isAdmin;
    status = AppStatus.ready;
    notifyListeners();
  }

  // ─── Load / Save ───────────────────────────────────

  Future<void> loadTeamData() async {
    if (teamId == null) return;
    final settings = await FirebaseService.loadSettings(teamId!);
    final data = await FirebaseService.loadData(teamId!);

    if (settings != null) {
      teamName = settings['teamName'] as String? ?? 'FLL Team';
      teamLogo = settings['teamLogo'] as String?;
      currentSeason = settings['currentSeason'] as String? ?? 'Unearthed 2026';
      mentorCode = settings['mentorCode'] as String?;
      studentCode = settings['studentCode'] as String?;
      isDarkMode = settings['isDarkMode'] as bool? ?? true;
      if (isDarkMode) { AppColors.applyDark(); } else { AppColors.applyLight(); }
      competitionDate = settings['competitionDate'] as String?;
      judgingPdfName = settings['judgingPdfName'] as String?;
    }

    final archiveRaw = await FirebaseService.loadArchives(teamId!);
    archives = archiveRaw.map(ArchivedSeason.fromMap).toList();

    final galleryRaw = await FirebaseService.loadGallery(teamId!);
    gallery = galleryRaw.map(GalleryItem.fromMap).toList();

    final linksRaw = await FirebaseService.loadLinks(teamId!);
    links = linksRaw.map(LinkItem.fromMap).toList();

    final strategyRaw = await FirebaseService.loadStrategyBoards(teamId!);
    strategyBoards = strategyRaw.map(StrategyBoard.fromMap).toList();

    if (data != null) {
      members = _parseList(data['members'], Member.fromMap);
      logs = _parseList(data['logs'], LogEntry.fromMap);
      innovationProblem = data['innovationProblem'] as String? ?? '';
      innovationSolution = data['innovationSolution'] as String? ?? '';
      improvements = _parseList(data['improvements'], Improvement.fromMap);
      scores = _parseList(data['scores'], ScoreRun.fromMap);
      stickies = _parseList(data['stickies'], StickyNote.fromMap);
      memberTasks = _parseList(data['memberTasks'], MemberTask.fromMap);

      if (data['checklist'] != null) {
        checklist = _parseList(data['checklist'], ChecklistItem.fromMap);
      }
      if (data['missionChecks'] != null) {
        final raw = data['missionChecks'] as Map<String, dynamic>;
        missionChecks = raw.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v as bool));
      }
      if (data['missions'] != null) {
        missions = _parseList(data['missions'], Mission.fromMap);
      }
      if (data['rubrics'] != null) {
        final raw = data['rubrics'] as Map<String, dynamic>;
        rubrics = {
          'values': _parseList(raw['values'], RubricItem.fromMap),
          'robot': _parseList(raw['robot'], RubricItem.fromMap),
          'innovation': _parseList(raw['innovation'], RubricItem.fromMap),
        };
      }
      if (data['judgingQuestions'] != null) {
        judgingQuestions = _parseList(data['judgingQuestions'], JudgingQuestion.fromMap);
      }
    }
  }

  static List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromMap) {
    if (raw == null) return [];
    return (raw as List).map((e) => fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> _saveSettings() async {
    if (teamId == null) return;
    await FirebaseService.saveSettings(teamId!, {
      'teamName': teamName,
      'teamLogo': teamLogo,
      'currentSeason': currentSeason,
      'teamId': teamId,
      'mentorCode': mentorCode,
      'studentCode': studentCode,
      'isDarkMode': isDarkMode,
      'competitionDate': competitionDate,
      'judgingPdfName':  judgingPdfName,
    });
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    if (isDarkMode) { AppColors.applyDark(); } else { AppColors.applyLight(); }
    notifyListeners();
    await _saveSettings();
  }

  Future<void> _saveData() async {
    if (teamId == null) return;
    await FirebaseService.saveData(teamId!, {
      'innovationProblem': innovationProblem,
      'innovationSolution': innovationSolution,
      'members': members.map((m) => m.toMap()).toList(),
      'logs': logs.map((l) => l.toMap()).toList(),
      'improvements': improvements.map((i) => i.toMap()).toList(),
      'scores': scores.map((s) => s.toMap()).toList(),
      'stickies': stickies.map((s) => s.toMap()).toList(),
      'memberTasks': memberTasks.map((t) => t.toMap()).toList(),
      'checklist': checklist.map((c) => c.toMap()).toList(),
      'missionChecks': missionChecks.map((k, v) => MapEntry(k.toString(), v)),
      'missions': missions.map((m) => m.toMap()).toList(),
      'rubrics': {
        'values': rubrics['values']!.map((r) => r.toMap()).toList(),
        'robot': rubrics['robot']!.map((r) => r.toMap()).toList(),
        'innovation': rubrics['innovation']!.map((r) => r.toMap()).toList(),
      },
      'judgingQuestions': judgingQuestions.map((q) => q.toMap()).toList(),
    });
  }

  Future<void> save() async {
    await Future.wait([_saveSettings(), _saveData()]);
  }

  // ─── Auth actions ──────────────────────────────────

  Future<void> signInWithGoogle() async {
    final cred = await FirebaseService.signInWithGoogle();
    await _loginWithFirebaseUser(cred.user!.email!);
  }

  Future<void> signInWithEmail(String email, String password) async {
    await FirebaseService.signInWithEmail(email, password);
    await _loginWithFirebaseUser(email);
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      await FirebaseService.registerWithEmail(email, password);
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        await FirebaseService.signInWithEmail(email, password);
      } else {
        rethrow;
      }
    }
    await _loginWithFirebaseUser(email);
  }

  Future<void> signOut() async {
    await FirebaseService.signOut();
    _resetToDefaults();
    status = AppStatus.unauthenticated;
    currentUser = null;
    isAdmin = false;
    teamId = null;
    notifyListeners();
  }

  // ─── Team creation ────────────────────────────────

  Future<void> createTeam({required String userName, required String tName, required String email}) async {
    _resetToDefaults();

    // Generate a unique teamId — retry if one already exists
    String tid;
    do { tid = FirebaseService.generateTeamId(tName); }
    while (await FirebaseService.teamExists(tid));

    final mc = FirebaseService.generateJoinCode();
    final sc = FirebaseService.generateJoinCode();

    teamId = tid;
    teamName = tName;
    mentorCode = mc;
    studentCode = sc;

    final founder = Member(
      id: FirebaseService.currentUser!.uid,
      name: userName,
      email: email,
      role: 'admin',
      color: AppColors.avatarColors[0],
    );
    members = [founder];
    currentUser = founder;
    isAdmin = true;

    // Full overwrite (no merge) so no stale data from a previous collision remains
    await FirebaseService.initTeamData(tid, {
      'teamName': tName,
      'teamLogo': null,
      'currentSeason': currentSeason,
      'teamId': tid,
      'mentorCode': mc,
      'studentCode': sc,
    }, {
      'members': [founder.toMap()],
      'logs': [],
      'improvements': [],
      'scores': [],
      'stickies': [],
      'memberTasks': [],
      'checklist': checklist.map((c) => c.toMap()).toList(),
      'missionChecks': {},
      'missions': missions.map((m) => m.toMap()).toList(),
      'rubrics': {'values': [], 'robot': [], 'innovation': []},
      'innovationProblem': '',
      'innovationSolution': '',
    });

    await FirebaseService.saveJoinCodes(teamId: tid, teamName: tName, mentorCode: mc, studentCode: sc);
    await FirebaseService.registerUserToTeam(email, tid);

    status = AppStatus.ready;
    notifyListeners();
  }

  Future<void> joinTeam({required String code, required String fullName, required String email}) async {
    final tid = await FirebaseService.findTeamByJoinCode(code);
    if (tid == null) throw Exception('קוד לא נמצא');

    final role = await FirebaseService.getRoleByCode(code);
    _resetToDefaults();
    teamId = tid;

    await FirebaseService.registerUserToTeam(email, tid);
    await loadTeamData();

    final existing = members.firstWhere((m) => m.email == email, orElse: () => Member(id: '', name: '', email: '', role: '', color: AppColors.avatarColors[0]));
    if (existing.id.isNotEmpty) {
      currentUser = existing;
      isAdmin = existing.isAdmin;
    } else {
      final newMember = Member(
        id: FirebaseService.currentUser!.uid,
        name: fullName,
        email: email,
        role: role,
        color: AppColors.avatarColors[members.length % AppColors.avatarColors.length],
      );
      members.add(newMember);
      currentUser = newMember;
      isAdmin = newMember.isAdmin;
      await _saveData();
    }
    status = AppStatus.ready;
    notifyListeners();
  }

  // ─── Innovation texts ──────────────────────────────

  Future<void> updateInnovationProblem(String text) async {
    innovationProblem = text;
    notifyListeners();
    await _saveData();
  }

  Future<void> updateInnovationSolution(String text) async {
    innovationSolution = text;
    notifyListeners();
    await _saveData();
  }

  // ─── Logs ─────────────────────────────────────────

  Future<void> addLog(LogEntry entry) async {
    logs.add(entry);
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteLog(int id) async {
    logs.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveData();
  }

  // ─── Missions ─────────────────────────────────────

  Future<void> toggleMission(int id) async {
    missionChecks[id] = !(missionChecks[id] ?? false);
    notifyListeners();
    await _saveData();
  }

  int get totalScore => missions
      .where((m) => missionChecks[m.id] == true)
      .fold(0, (sum, m) => sum + m.pts);

  Future<void> updateMission(int id, String name, int pts) async {
    final m = missions.firstWhere((m) => m.id == id);
    m.name = name;
    m.pts = pts;
    notifyListeners();
    await _saveData();
  }

  Future<void> resetMissions() async {
    missions = missions2026.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    notifyListeners();
    await _saveData();
  }

  int get doneMissions => missionChecks.values.where((v) => v).length;

  // ─── Scores ───────────────────────────────────────

  Future<void> saveRun() async {
    scores.add(ScoreRun(
      date: DateTime.now().toIso8601String().split('T')[0],
      score: totalScore,
      notes: 'ריצה ${scores.length + 1}',
    ));
    notifyListeners();
    await _saveData();
  }

  int get bestScore => scores.isEmpty ? 0 : scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);

  // ─── Improvements ─────────────────────────────────

  Future<void> addImprovement(Improvement imp) async {
    improvements.add(imp);
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteImprovement(int id) async {
    improvements.removeWhere((i) => i.id == id);
    notifyListeners();
    await _saveData();
  }

  // ─── Rubrics ──────────────────────────────────────

  Future<void> addCustomRubric(String category, String question) async {
    rubrics[category]!.add(RubricItem(id: DateTime.now().microsecondsSinceEpoch, question: question));
    notifyListeners();
    await _saveData();
  }

  Future<void> setRubricScoreAtIndex(String category, int index, int score) async {
    final list = rubrics[category]!;
    if (index < 0 || index >= list.length) return;
    list[index].score = score;
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteRubricAtIndex(String category, int index) async {
    final list = rubrics[category]!;
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
    await _saveData();
  }

  // ─── Stickies ─────────────────────────────────────

  Future<void> addSticky(StickyNote note) async {
    stickies.add(note);
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteSticky(int id) async {
    stickies.removeWhere((s) => s.id == id);
    notifyListeners();
    await _saveData();
  }

  // ─── Members ──────────────────────────────────────

  Future<void> addMember(Member m) async {
    members.add(m);
    notifyListeners();
    await _saveData();
    if (teamId != null) {
      await FirebaseService.registerUserToTeam(m.email, teamId!);
    }
  }

  Future<void> removeMember(String id) async {
    members.removeWhere((m) => m.id == id);
    notifyListeners();
    await _saveData();
  }

  Future<void> updateTeamName(String name) async {
    teamName = name;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> updateTeamLogo(String? base64) async {
    teamLogo = base64;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> changePassword(String currentPassword, String newPassword) =>
      FirebaseService.changePassword(currentPassword: currentPassword, newPassword: newPassword);

  Future<void> updateMemberName(String memberId, String newName) async {
    final member = members.firstWhere((m) => m.id == memberId, orElse: () => members.first);
    member.name = newName;
    if (memberId == currentUser?.id) currentUser?.name = newName;
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteTeam() async {
    final tid = teamId;
    final mc  = mentorCode;
    final sc  = studentCode;
    final emails = members.map((m) => m.email).toList();
    if (tid == null) return;
    await FirebaseService.deleteTeam(
      teamId: tid,
      mentorCode: mc,
      studentCode: sc,
      memberEmails: emails,
    );
    await FirebaseService.signOut();
    _resetToDefaults();
    status = AppStatus.unauthenticated;
    currentUser = null;
    isAdmin = false;
    teamId = null;
    notifyListeners();
  }

  Future<void> resetScoringData() async {
    missionChecks = {};
    scores = [];
    missions = missions2026.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    rubrics = {'values': [], 'robot': [], 'innovation': []};
    notifyListeners();
    await _saveData();
  }

  Future<void> resetAllData() async {
    logs = [];
    improvements = [];
    scores = [];
    missionChecks = {};
    missions = missions2026.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    rubrics = {'values': [], 'robot': [], 'innovation': []};
    stickies = [];
    memberTasks = [];
    checklist = _defaultChecklist();
    innovationProblem = '';
    innovationSolution = '';
    gallery = [];
    for (final q in judgingQuestions) { q.answer = ''; }
    notifyListeners();
    await _saveData();
    if (teamId != null) {
      await Future.wait([
        FirebaseService.clearChat(teamId!),
        FirebaseService.saveGallery(teamId!, []),
      ]);
    }
  }

  Future<void> regenerateJoinCodes() async {
    if (teamId == null) return;
    final mc = FirebaseService.generateJoinCode();
    final sc = FirebaseService.generateJoinCode();
    mentorCode = mc;
    studentCode = sc;
    notifyListeners();
    await _saveSettings();
    await FirebaseService.saveJoinCodes(
      teamId: teamId!, teamName: teamName, mentorCode: mc, studentCode: sc,
    );
  }

  Future<void> leaveTeam() async {
    final email = currentUser?.email;
    final uid = currentUser?.id;
    if (email != null && uid != null) {
      members.removeWhere((m) => m.id == uid);
      await _saveData();
      await FirebaseService.unregisterUserFromTeam(email);
    }
    await FirebaseService.signOut();
    _resetToDefaults();
    status = AppStatus.unauthenticated;
    currentUser = null;
    isAdmin = false;
    teamId = null;
    notifyListeners();
  }

  Future<void> deleteAccount({String? password}) async {
    final email = currentUser?.email;
    final uid = currentUser?.id;
    if (email != null && uid != null) {
      members.removeWhere((m) => m.id == uid);
      await _saveData();
      await FirebaseService.unregisterUserFromTeam(email);
    }
    await FirebaseService.reauthAndDeleteUser(password: password);
    _resetToDefaults();
    status = AppStatus.unauthenticated;
    currentUser = null;
    isAdmin = false;
    teamId = null;
    notifyListeners();
  }

  // ─── Member Tasks ─────────────────────────────────

  Future<void> addMemberTask(MemberTask task) async {
    memberTasks.add(task);
    notifyListeners();
    await _saveData();
    if (task.due != null) {
      await NotificationService.scheduleTaskReminder(task);
    }
  }

  Future<void> toggleMemberTask(int id) async {
    final t = memberTasks.firstWhere((t) => t.id == id);
    t.done = !t.done;
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteMemberTask(int id) async {
    memberTasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveData();
    await NotificationService.cancelTaskReminder(id);
  }

  static bool isTaskOverdue(MemberTask t) {
    if (t.done || t.due == null) return false;
    final parts = t.due!.split('/');
    if (parts.length != 3) return false;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return false;
    return DateTime(y, m, d).isBefore(DateTime.now());
  }

  List<MemberTask> getOverdueTasksFor(String memberId) =>
      memberTasks.where((t) => (t.memberId == memberId || t.memberId == 'all') && isTaskOverdue(t)).toList();

  int get overdueCountForMe => getOverdueTasksFor(currentUser?.id ?? '').length;

  // ─── Checklist ────────────────────────────────────

  Future<void> toggleChecklist(int id) async {
    final item = checklist.firstWhere((c) => c.id == id);
    item.done = !item.done;
    notifyListeners();
    await _saveData();
  }

  Future<void> addChecklistItem(String text) async {
    checklist.add(ChecklistItem(id: DateTime.now().millisecondsSinceEpoch, text: text));
    notifyListeners();
    await _saveData();
  }

  // ─── Archives ─────────────────────────────────────

  Future<void> archiveCurrentSeason() async {
    if (teamId == null) return;
    final snapshot = ArchivedSeason(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      seasonName: currentSeason,
      archivedDate: DateTime.now().toIso8601String().split('T')[0],
      archivedBy: currentUser?.name ?? '',
      memberCount: members.length,
      bestScore: bestScore,
      runsCount: scores.length,
      improvementsCount: improvements.length,
      logsCount: logs.length,
    );
    archives.add(snapshot);
    await FirebaseService.saveArchives(teamId!, archives.map((a) => a.toMap()).toList());
    notifyListeners();
  }

  Future<void> deleteArchive(String id) async {
    if (teamId == null) return;
    archives.removeWhere((a) => a.id == id);
    await FirebaseService.saveArchives(teamId!, archives.map((a) => a.toMap()).toList());
    notifyListeners();
  }

  // ─── Competition date ──────────────────────────────

  int? get daysToCompetition {
    if (competitionDate == null) return null;
    final d = DateTime.tryParse(competitionDate!);
    if (d == null) return null;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final comp = DateTime(d.year, d.month, d.day);
    return comp.difference(today).inDays;
  }

  Future<void> setCompetitionDate(DateTime? date) async {
    competitionDate = date?.toIso8601String();
    notifyListeners();
    await _saveSettings();
  }

  // ─── Judging PDF ──────────────────────────────────

  Future<void> setJudgingPdfName(String name) async {
    judgingPdfName = name;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> removeJudgingPdf() async {
    if (teamId != null && judgingPdfName != null) {
      await FirebaseService.deleteJudgingPdf(teamId!);
    }
    judgingPdfName = null;
    notifyListeners();
    await _saveSettings();
  }

  // ─── Mission status ────────────────────────────────

  Future<void> setMissionStatus(int id, String status) async {
    final m = missions.firstWhere((m) => m.id == id);
    m.status = status;
    notifyListeners();
    await _saveData();
  }

  Map<String, int> get missionStatusCounts {
    return {
      'not_tried': missions.where((m) => m.status == 'not_tried').length,
      'in_progress': missions.where((m) => m.status == 'in_progress').length,
      'ready': missions.where((m) => m.status == 'ready').length,
    };
  }

  // ─── Gallery ───────────────────────────────────────

  Future<void> _saveGallery() async {
    if (teamId == null) return;
    await FirebaseService.saveGallery(teamId!, gallery.map((g) => g.toMap()).toList());
  }

  Future<void> addGalleryItem(GalleryItem item) async {
    gallery.add(item);
    _safeNotify();
    await _saveGallery();
  }

  Future<void> deleteGalleryItem(int id) async {
    gallery.removeWhere((g) => g.id == id);
    _safeNotify();
    await _saveGallery();
  }

  Future<void> updateGalleryItemCaption(int id, String caption) async {
    final item = gallery.firstWhere((g) => g.id == id);
    item.caption = caption;
    notifyListeners();
    await _saveGallery();
  }

  // ─── Links ────────────────────────────────────────────

  Future<void> _saveLinks() async {
    if (teamId == null) return;
    await FirebaseService.saveLinks(teamId!, links.map((l) => l.toMap()).toList());
  }

  Future<void> addLink(LinkItem item) async {
    links.add(item);
    notifyListeners();
    await _saveLinks();
  }

  Future<void> deleteLink(int id) async {
    links.removeWhere((l) => l.id == id);
    notifyListeners();
    await _saveLinks();
  }

  // ─── Strategy Boards ─────────────────────────────────

  Future<void> _saveStrategyBoards() async {
    if (teamId == null) return;
    await FirebaseService.saveStrategyBoards(teamId!, strategyBoards.map((b) => b.toMap()).toList());
  }

  Future<void> addStrategyBoard(StrategyBoard board) async {
    strategyBoards.add(board);
    notifyListeners();
    await _saveStrategyBoards();
  }

  Future<void> updateStrategyBoard(StrategyBoard board) async {
    final idx = strategyBoards.indexWhere((b) => b.id == board.id);
    if (idx != -1) strategyBoards[idx] = board;
    notifyListeners();
    await _saveStrategyBoards();
  }

  Future<void> deleteStrategyBoard(int id) async {
    strategyBoards.removeWhere((b) => b.id == id);
    notifyListeners();
    await _saveStrategyBoards();
  }

  // ─── Judging questions ─────────────────────────────

  Future<void> updateJudgingAnswer(int id, String answer) async {
    final q = judgingQuestions.firstWhere((q) => q.id == id);
    q.answer = answer;
    notifyListeners();
    await _saveData();
  }

  Future<void> addJudgingQuestion(JudgingQuestion q) async {
    judgingQuestions.add(q);
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteJudgingQuestion(int id) async {
    judgingQuestions.removeWhere((q) => q.id == id);
    notifyListeners();
    await _saveData();
  }

}
