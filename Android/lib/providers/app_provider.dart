import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/season_story_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

enum AppStatus { loading, unauthenticated, needsTeam, ready }

class AppProvider extends ChangeNotifier {
  AppStatus status = AppStatus.loading;
  String? teamId;
  String teamName = 'FLL Team';
  String? teamLogo;
  String currentSeason = officialSeasonName;
  String? mentorCode;
  String? studentCode;

  Member? currentUser;
  bool isAdmin = false;
  bool isDarkMode = true;

  String innovationProblem = '';
  String innovationSolution = '';
  /// Web's innovation "research findings" (data.findings) and "community sharing"
  /// text (data.innovationSharing) — shown read-only next to Android's own
  /// research/sharing log entries. Android never writes these fields.
  List<LogEntry> webFindings = [];
  String webInnovationSharing = '';
  /// AI "season story" generated on web/desktop (data.seasonStory) — read-only here,
  /// never written by Android so a stale copy can't overwrite a newer story.
  String? seasonStoryText;
  String? seasonStoryCreatedAt;
  String? competitionDate;
  String? lastBackupAt; // ISO time of the last full backup (admin-data, shared with web)
  String? judgingPdfName;

  List<Member> members = [];
  List<LogEntry> logs = [];
  List<ArchivedSeason> archives = [];
  List<Mission> missions = officialMissions.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
  List<Improvement> improvements = [];
  List<Interview> interviews = [];
  List<ScoreRun> scores = [];
  Map<int, bool> missionChecks = {};
  int precisionTokens = 6; // precision tokens left (0-6) — see precisionTokenPoints
  Map<int, MissionExtra> missionExtra = {};
  Map<String, List<RubricItem>> rubrics = {'values': [], 'robot': [], 'innovation': []};
  // Official judging grid (judging room): marks[cat][fieldId] = 1-4, notes[cat][fieldId] =
  // "כיצד הקבוצה הצטיינה?" (when marked מצטיינת), feedback[tab][greatJob|thinkAbout].
  Map<String, Map<String, int>> rubricMarks = {'innovation': {}, 'robot': {}};
  Map<String, Map<String, String>> rubricNotes = {'innovation': {}, 'robot': {}};
  Map<String, Map<String, String>> rubricFeedback = {};
  List<StickyNote> stickies = [];
  List<MemberTask> memberTasks = [];
  List<ChecklistItem> checklist = _defaultChecklist();
  List<GalleryItem> gallery = [];
  List<JudgingQuestion> judgingQuestions = _defaultJudgingQuestions();
  List<LinkItem> links = [];
  List<StrategyBoard> strategyBoards = [];
  List<Milestone> milestones = [];
  List<MeetingPlan> meetingPlans = [];

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
    currentSeason = officialSeasonName;
    mentorCode = null;
    studentCode = null;
    members = [];
    logs = [];
    archives = [];
    missions = officialMissions.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    improvements = [];
    interviews = [];
    scores = [];
    missionChecks = {};
    precisionTokens = 6;
    missionExtra = {};
    rubrics = {'values': [], 'robot': [], 'innovation': []};
    rubricMarks = {'innovation': {}, 'robot': {}};
    rubricNotes = {'innovation': {}, 'robot': {}};
    rubricFeedback = {};
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
    milestones = [];
    meetingPlans = [];
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
    var member = members.firstWhere(
      (m) => m.email == email,
      orElse: () => Member(id: '', name: '', email: email, role: 'student', color: AppColors.avatarColors[0]),
    );
    if (member.id.isEmpty) {
      // Registered to this team but missing from the member list (students who
      // joined before self-join was allowed weren't saved) — add them now.
      final role = await FirebaseService.getOwnRegistryRole(email, tid);
      final fbUser = FirebaseService.currentUser;
      if (role != null && fbUser != null) {
        final healed = Member(
          id: fbUser.uid,
          name: (fbUser.displayName?.isNotEmpty ?? false) ? fbUser.displayName! : email.split('@').first,
          email: email,
          role: role,
          color: AppColors.avatarColors[members.length % AppColors.avatarColors.length],
        );
        final ok = role == 'student' ? await FirebaseService.addSelfToMembers(tid, healed.toMap()) : true;
        if (ok) {
          members.add(healed);
          member = healed;
          if (role != 'student') { try { await _saveData(); } catch (_) {} }
        }
      }
    }
    currentUser = member;
    isAdmin = member.isAdmin;
    // Self-heal: keep the registry's role in sync on every login, so a role
    // recorded before this field existed (or changed since) stays correct
    // for the Firestore isMentor() check without needing a manual rejoin.
    if (member.id.isNotEmpty) {
      await FirebaseService.registerUserToTeam(email, tid, member.role);
    }
    status = AppStatus.ready;
    notifyListeners();
  }

  // ─── Load / Save ───────────────────────────────────

  Future<void> loadTeamData() async {
    if (teamId == null) return;
    final settings = await FirebaseService.loadSettings(teamId!);
    final data = await FirebaseService.loadData(teamId!);
    final adminData = await FirebaseService.loadAdminData(teamId!);

    if (settings != null) {
      teamName = settings['teamName'] as String? ?? 'FLL Team';
      teamLogo = settings['teamLogo'] as String?;
      currentSeason = settings['currentSeason'] as String? ?? officialSeasonName;
      mentorCode = settings['mentorCode'] as String?;
      studentCode = settings['studentCode'] as String?;
      await _loadThemePref();
      competitionDate = settings['competitionDate'] as String?;
      judgingPdfName = settings['judgingPdfName'] as String?;
    }

    final archiveRaw = await FirebaseService.loadArchives(teamId!);
    archives = archiveRaw.map(ArchivedSeason.fromMap).toList();

    final galleryPhotos = await FirebaseService.loadGalleryPhotos(teamId!);
    final legacyGalleryItems = await FirebaseService.loadLegacyGalleryItems(teamId!);
    final mergedGallery = await _mergeAndMigratePhotos(
      galleryPhotos, legacyGalleryItems,
      (item) => FirebaseService.saveGalleryPhoto(teamId!, item),
      () => FirebaseService.clearLegacyGalleryItems(teamId!),
    );
    gallery = mergedGallery.map(GalleryItem.fromMap).toList();

    // Links are shared with web in data.links. Older Android versions kept them
    // in a separate 'links' doc — merge those in once, then empty that doc.
    final sharedLinks = _parseList(data?['links'], LinkItem.fromMap);
    final legacyLinks = (await FirebaseService.loadLinks(teamId!)).map(LinkItem.fromMap).toList();
    links = [...sharedLinks, ...legacyLinks.where((l) => !sharedLinks.any((s) => s.id == l.id))];
    final migrateLinks = legacyLinks.isNotEmpty;

    final strategyRaw = await FirebaseService.loadStrategyBoards(teamId!);
    strategyBoards = strategyRaw.map(StrategyBoard.fromMap).toList();

    final improvementPhotos = await FirebaseService.loadImprovementPhotos(teamId!);
    final legacyImprovements = (data != null && data['improvements'] != null)
        ? (data['improvements'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : null;
    final mergedImprovements = await _mergeAndMigratePhotos(
      improvementPhotos, legacyImprovements,
      (item) => FirebaseService.saveImprovementPhoto(teamId!, item),
      () => FirebaseService.clearLegacyImprovementsField(teamId!),
    );
    improvements = mergedImprovements.map(Improvement.fromMap).toList();

    if (data != null) {
      logs = _parseList(data['logs'], LogEntry.fromMap);
      innovationProblem = data['innovationProblem'] as String? ?? '';
      innovationSolution = data['innovationSolution'] as String? ?? '';
      webInnovationSharing = data['innovationSharing'] as String? ?? '';
      webFindings = [
        for (final f in (data['findings'] as List? ?? const []))
          if (f is Map)
            LogEntry(
              id: (f['id'] as num?)?.toInt() ?? 0,
              topic: 'research',
              text: f['text']?.toString() ?? '',
              author: f['author']?.toString() ?? '',
              date: f['date']?.toString() ?? '',
              title: (f['tag']?.toString().isNotEmpty ?? false) ? f['tag'].toString() : null,
            ),
      ];
      final story = data['seasonStory'];
      seasonStoryText = story is Map ? story['text'] as String? : null;
      seasonStoryCreatedAt = story is Map ? story['createdAt'] as String? : null;
      interviews = _parseList(data['interviews'], Interview.fromMap);
      stickies = _parseList(data['stickies'], StickyNote.fromMap);
      memberTasks = _parseList(data['memberTasks'], MemberTask.fromMap);
      milestones = _parseList(data['milestones'], Milestone.fromMap);
      meetingPlans = _parseList(data['meetingPlans'], MeetingPlan.fromMap);
      final pt = data['precisionTokens'];
      if (pt is num && pt >= 0 && pt <= 6) precisionTokens = pt.toInt();
      if (data['missionChecks'] != null) {
        final raw = data['missionChecks'] as Map<String, dynamic>;
        missionChecks = raw.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v as bool));
      }
      if (data['missionExtra'] != null) {
        final raw = data['missionExtra'] as Map<String, dynamic>;
        missionExtra = raw.map((k, v) =>
            MapEntry(int.tryParse(k) ?? 0, MissionExtra.fromMap(Map<String, dynamic>.from(v as Map))));
      }
    }

    if (adminData != null) {
      members = _parseList(adminData['members'], Member.fromMap);
      scores = _parseList(adminData['scores'], ScoreRun.fromMap);

      if (adminData['checklist'] != null) {
        checklist = _parseList(adminData['checklist'], ChecklistItem.fromMap);
      }
      // Fallback for teams that haven't saved since this moved to "data".
      if (data?['missionChecks'] == null && adminData['missionChecks'] != null) {
        final raw = adminData['missionChecks'] as Map<String, dynamic>;
        missionChecks = raw.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v as bool));
      }
      // Shared with web as `customMissions` (empty = the built-in official list).
      // `missions` is the old Android-only field, read only as a fallback.
      final shared = adminData['customMissions'];
      if (shared is List) {
        missions = shared.isEmpty
            ? officialMissions.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList()
            : _parseList(shared, Mission.fromMap);
      } else if (adminData['missions'] != null) {
        missions = _parseList(adminData['missions'], Mission.fromMap);
      }
      if (adminData['rubrics'] != null) {
        final raw = adminData['rubrics'] as Map<String, dynamic>;
        rubrics = {
          'values': _parseList(raw['values'], RubricItem.fromMap),
          'robot': _parseList(raw['robot'], RubricItem.fromMap),
          'innovation': _parseList(raw['innovation'], RubricItem.fromMap),
        };
      }
      final official = adminData['officialRubric'];
      if (official is Map) {
        final marks = official['marks'];
        final feedback = official['feedback'];
        final notes = official['notes'];
        rubricNotes = {
          for (final cat in ['innovation', 'robot'])
            cat: {
              if (notes is Map && notes[cat] is Map)
                for (final e in (notes[cat] as Map).entries) e.key.toString(): e.value?.toString() ?? '',
            },
        };
        rubricMarks = {
          for (final cat in ['innovation', 'robot'])
            cat: {
              if (marks is Map && marks[cat] is Map)
                for (final e in (marks[cat] as Map).entries)
                  if (e.value is num) e.key.toString(): (e.value as num).toInt(),
            },
        };
        rubricFeedback = {
          if (feedback is Map)
            for (final e in feedback.entries)
              if (e.value is Map)
                e.key.toString(): {
                  for (final f in (e.value as Map).entries) f.key.toString(): f.value?.toString() ?? '',
                },
        };
      }
      lastBackupAt = adminData['lastBackupAt'] as String?;
    }
    // Judging Q&A is shared with web in data.judgingQuestions (any member can
    // answer); older Android versions kept it in mentor-only admin-data.
    final jq = data?['judgingQuestions'] ?? adminData?['judgingQuestions'];
    if (jq is List && jq.isNotEmpty) judgingQuestions = _parseList(jq, JudgingQuestion.fromMap);
    // Mission practice status is shared with web in data.missionStatuses
    // (any member); older Android versions kept it inside the mission list.
    final statuses = data?['missionStatuses'];
    if (statuses is Map) {
      for (final m in missions) {
        final st = statuses[m.id.toString()];
        if (st is String) m.status = st;
      }
    }
    _applyOfficialBonuses();
    if (migrateLinks) {
      try {
        await _saveData();
        await FirebaseService.saveLinks(teamId!, const []);
      } catch (_) {}
    }
  }

  static List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromMap) {
    if (raw == null) return [];
    return (raw as List).map((e) => fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  // Merges the new per-photo subcollection docs with any legacy embedded
  // array (the pre-split "data doc field" or old single-doc gallery format)
  // into one list. Legacy items are lazily migrated into their own documents
  // (idempotent: doc id = item id, so a retry just overwrites the same doc)
  // and the legacy field is cleared only once the migration write actually
  // succeeds, so a failed/offline migration is retried on the next load
  // instead of silently losing the images.
  static Future<List<Map<String, dynamic>>> _mergeAndMigratePhotos(
    List<Map<String, dynamic>> subcollectionItems,
    List<Map<String, dynamic>>? legacyItems,
    Future<void> Function(Map<String, dynamic> item) saveFn,
    Future<void> Function() clearLegacyFn,
  ) async {
    final byId = <String, Map<String, dynamic>>{};
    for (final item in subcollectionItems) {
      final id = item['id']?.toString();
      if (id != null) byId[id] = item;
    }
    if (legacyItems != null && legacyItems.isNotEmpty) {
      final toMigrate = legacyItems.where((item) {
        final id = item['id']?.toString();
        return id != null && !byId.containsKey(id);
      }).toList();
      if (toMigrate.isNotEmpty) {
        try {
          await Future.wait(toMigrate.map(saveFn));
          await clearLegacyFn();
        } catch (e) {
          debugPrint('Photo migration failed, will retry next load: $e');
        }
      }
      for (final item in legacyItems) {
        final id = item['id']?.toString();
        if (id != null && !byId.containsKey(id)) byId[id] = item;
      }
    }
    final list = byId.values.toList();
    list.sort((a, b) => ((a['id'] as num?) ?? 0).compareTo((b['id'] as num?) ?? 0));
    return list;
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
      'competitionDate': competitionDate,
      'judgingPdfName':  judgingPdfName,
    });
  }

  // Dark/light is a personal, per-device preference. It used to be written to
  // the team's settings doc — changing it for everyone, and failing for students.
  Future<File> _themePrefFile() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/theme_pref.txt');

  Future<void> _loadThemePref() async {
    try {
      final f = await _themePrefFile();
      isDarkMode = !(await f.exists()) || (await f.readAsString()).trim() != 'light';
    } catch (_) {
      isDarkMode = true;
    }
    if (isDarkMode) { AppColors.applyDark(); } else { AppColors.applyLight(); }
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    if (isDarkMode) { AppColors.applyDark(); } else { AppColors.applyLight(); }
    notifyListeners();
    try { await (await _themePrefFile()).writeAsString(isDarkMode ? 'dark' : 'light'); } catch (_) {}
  }

  // "data" — writable by any team member (students included). missionChecks
  // is here too: any member can toggle a mission as done.
  Future<void> _saveData() async {
    if (teamId == null) return;
    await FirebaseService.saveData(teamId!, {
      'innovationProblem': innovationProblem,
      'innovationSolution': innovationSolution,
      'logs': logs.map((l) => l.toMap()).toList(),
      // Improvements are NOT written here — each photo is its own document
      // under a subcollection (see addImprovement/deleteImprovement), to
      // keep this document well under 1MB. Clean up the old embedded copy.
      'improvements': FieldValue.delete(),
      'interviews': interviews.map((i) => i.toMap()).toList(),
      'stickies': stickies.map((s) => s.toMap()).toList(),
      'memberTasks': memberTasks.map((t) => t.toMap()).toList(),
      'missionChecks': missionChecks.map((k, v) => MapEntry(k.toString(), v)),
      'precisionTokens': precisionTokens,
      'missionExtra': missionExtra.map((k, v) => MapEntry(k.toString(), v.toMap())),
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'meetingPlans': meetingPlans.map((m) => m.toMap()).toList(),
      'links': links.map((l) => l.toMap()).toList(),
      'judgingQuestions': judgingQuestions.map((q) => q.toMap()).toList(),
      'missionStatuses': {for (final m in missions) if (m.status != 'not_tried') m.id.toString(): m.status},
      // Planned-meetings feature was removed — the calendar shows value stickies instead.
      'meetings': FieldValue.delete(),
    });

    // "admin-data" — mentor-only per Firestore rules. A non-mentor calling
    // this (e.g. leaving the team removes them from `members` locally)
    // will have this write rejected server-side; swallow it rather than
    // let it block the rest of the flow (matches the web client, which
    // catches Firestore write errors around this same data).
    try {
      await FirebaseService.saveAdminData(teamId!, {
        'members': members.map((m) => m.toMap()).toList(),
        'scores': scores.map((s) => s.toMap()).toList(),
        'checklist': checklist.map((c) => c.toMap()).toList(),
        // Clean up the copy written by v1.0.8, before this moved to "data".
        'missionChecks': FieldValue.delete(),
        'customMissions': missions.map((m) => m.toMap()).toList(),
        'missions': FieldValue.delete(),
        'rubrics': {
          'values': rubrics['values']!.map((r) => r.toMap()).toList(),
          'robot': rubrics['robot']!.map((r) => r.toMap()).toList(),
          'innovation': rubrics['innovation']!.map((r) => r.toMap()).toList(),
        },
        'officialRubric': {'marks': rubricMarks, 'notes': rubricNotes, 'feedback': rubricFeedback},
        // Moved to "data" (any member can answer) — drop the old mentor-only copy.
        'judgingQuestions': FieldValue.delete(),
      });
    } catch (_) {}
  }

  Future<void> save() async {
    await Future.wait([_saveSettings(), _saveData()]);
  }

  // Full manual backup — everything the team owns, as one JSON map. Used by
  // the "גיבוי מלא" button in Settings; not the same shape as the Firestore
  // tiers (gallery/improvements are per-photo subcollections there), but
  // this snapshot is about capturing current state for backup, not mirroring
  // how it's synced.
  /// Generates the season story with the team's Gemini key (mentors only) and
  /// saves it to data.seasonStory with a targeted write — the general _saveData()
  /// never writes it, so a stale copy here can't overwrite a newer story.
  Future<void> generateSeasonStory() async {
    if (!isAdmin || teamId == null) throw 'יצירת סיפור זמינה למנטורים בלבד';
    final key = await FirebaseService.getAiKey(teamId!);
    if (key == null) throw 'קודם צריך לשמור מפתח Gemini בהגדרות (פעם אחת לכל הקבוצה)';
    if (stickies.isEmpty && logs.isEmpty && meetingPlans.isEmpty) throw 'אין עדיין מספיק תיעוד לסיפור';
    final (text, model) = await SeasonStoryService.generate(key, SeasonStoryService.buildInput(this));
    final createdAt = DateTime.now().toUtc().toIso8601String();
    await FirebaseService.saveData(teamId!, {
      'seasonStory': {'text': text, 'createdAt': createdAt, 'model': model},
    });
    seasonStoryText = text;
    seasonStoryCreatedAt = createdAt;
    notifyListeners();
  }

  /// Full backup in the shared format; records the time so the reminder resets.
  Future<Map<String, dynamic>> exportFullBackup() async {
    final backup = await FirebaseService.exportRawBackup(teamId!, teamName);
    lastBackupAt = DateTime.now().toUtc().toIso8601String();
    notifyListeners();
    if (isAdmin) {
      try { await FirebaseService.saveAdminData(teamId!, {'lastBackupAt': lastBackupAt}); } catch (_) {}
    }
    return backup;
  }

  /// Mentors: no backup yet, or the last one is 14+ days old.
  bool get backupOverdue {
    if (!isAdmin) return false;
    final last = lastBackupAt == null ? null : DateTime.tryParse(lastBackupAt!);
    return last == null || DateTime.now().difference(last).inDays >= 14;
  }

  Map<String, dynamic> exportBackupData() => {
    'teamName': teamName,
    'currentSeason': currentSeason,
    'mentorCode': mentorCode,
    'studentCode': studentCode,
    'competitionDate': competitionDate,
    'innovationProblem': innovationProblem,
    'innovationSolution': innovationSolution,
    'members': members.map((m) => m.toMap()).toList(),
    'logs': logs.map((l) => l.toMap()).toList(),
    'archives': archives.map((a) => a.toMap()).toList(),
    'missions': missions.map((m) => m.toMap()).toList(),
    'improvements': improvements.map((i) => i.toMap()).toList(),
    'interviews': interviews.map((i) => i.toMap()).toList(),
    'scores': scores.map((s) => s.toMap()).toList(),
    'missionChecks': missionChecks.map((k, v) => MapEntry(k.toString(), v)),
    'missionExtra': missionExtra.map((k, v) => MapEntry(k.toString(), v.toMap())),
    'rubrics': {
      'values': rubrics['values']!.map((r) => r.toMap()).toList(),
      'robot': rubrics['robot']!.map((r) => r.toMap()).toList(),
      'innovation': rubrics['innovation']!.map((r) => r.toMap()).toList(),
    },
    'stickies': stickies.map((s) => s.toMap()).toList(),
    'memberTasks': memberTasks.map((t) => t.toMap()).toList(),
    'checklist': checklist.map((c) => c.toMap()).toList(),
    'gallery': gallery.map((g) => g.toMap()).toList(),
    'judgingQuestions': judgingQuestions.map((q) => q.toMap()).toList(),
    'links': links.map((l) => l.toMap()).toList(),
    'strategyBoards': strategyBoards.map((b) => b.toMap()).toList(),
    'milestones': milestones.map((m) => m.toMap()).toList(),
    'meetingPlans': meetingPlans.map((m) => m.toMap()).toList(),
  };

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

    // Register before writing any team document — the Firestore rules
    // require the caller to already be recorded as this team's mentor to
    // write protected docs (settings/admin-data), and the registry write
    // itself only needs the caller's own auth, so it must go first.
    await FirebaseService.registerUserToTeam(email, tid, 'admin');

    // Full overwrite (no merge) so no stale data from a previous collision remains
    await FirebaseService.initTeamData(tid, {
      'teamName': tName,
      'teamLogo': null,
      'currentSeason': currentSeason,
      'teamId': tid,
      'mentorCode': mc,
      'studentCode': sc,
    }, {
      'logs': [],
      'improvements': [],
      'stickies': [],
      'memberTasks': [],
      'innovationProblem': '',
      'innovationSolution': '',
      'milestones': [],
      'meetingPlans': [],
    }, {
      'members': [founder.toMap()],
      'scores': [],
      'checklist': checklist.map((c) => c.toMap()).toList(),
      'missionChecks': {},
      'customMissions': missions.map((m) => m.toMap()).toList(),
      'rubrics': {'values': [], 'robot': [], 'innovation': []},
    });
    await FirebaseService.saveJoinCodes(teamId: tid, teamName: tName, mentorCode: mc, studentCode: sc);

    status = AppStatus.ready;
    notifyListeners();
  }

  Future<void> joinTeam({required String code, required String fullName, required String email}) async {
    // Each step is named in the error so a failure (e.g. permission-denied)
    // says where it happened.
    Future<T> step<T>(String name, Future<T> Function() run) async {
      try {
        return await run();
      } catch (e) {
        throw Exception('$name: $e');
      }
    }

    final tid = await step('חיפוש הקוד', () => FirebaseService.findTeamByJoinCode(code));
    if (tid == null) throw Exception('קוד לא נמצא');
    final codeRole = await step('בדיקת סוג הקוד', () => FirebaseService.getRoleByCode(code));

    // Register FIRST: firestore.rules only let registered members read the
    // team's docs, so loading before registering failed with permission-denied
    // for anyone joining for the first time. If this user is already
    // registered to this team, keep that role (self-registration can't change
    // a recorded role).
    final registeredRole = await step('בדיקת רישום קיים', () => FirebaseService.getOwnRegistryRole(email, tid));
    final role = registeredRole ?? codeRole;
    if (registeredRole == null) {
      await step('רישום לקבוצה', () => FirebaseService.registerUserToTeam(email, tid, role));
    }

    _resetToDefaults();
    teamId = tid;
    await step('טעינת נתוני הקבוצה', () => loadTeamData());

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
      if (newMember.isAdmin) {
        await step('שמירת החבר החדש', () => _saveData());
      } else {
        // Students can only append themselves to the member list (rules: isSelfJoin).
        await step('הוספה לרשימת החברים', () => FirebaseService.addSelfToMembers(tid, newMember.toMap()));
      }
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

  // ─── Interviews ───────────────────────────────────

  Future<void> addInterview(Interview interview) async {
    interviews.add(interview);
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteInterview(int id) async {
    interviews.removeWhere((i) => i.id == id);
    notifyListeners();
    await _saveData();
  }

  // ─── Missions ─────────────────────────────────────

  Future<void> toggleMission(int id) async {
    missionChecks[id] = !(missionChecks[id] ?? false);
    notifyListeners();
    await _saveData();
  }

  /// The official precision-tokens entry (scored by tokens left, not a plain check).
  bool isPrecisionTokens(Mission m) {
    final official = officialMissions.where((o) => o.id == precisionTokensId).firstOrNull;
    return m.id == precisionTokensId && official != null && m.name == official.name;
  }

  /// Points an item scores right now (0 when unchecked).
  int missionPoints(Mission m) {
    if (missionChecks[m.id] != true) return 0;
    return isPrecisionTokens(m) ? precisionTokenPoints[precisionTokens] : m.pts;
  }

  Future<void> setPrecisionTokens(int n) async {
    precisionTokens = n.clamp(0, 6);
    notifyListeners();
    await _saveData();
  }

  int get totalScore {
    final base = missions.fold(0, (total, m) => total + missionPoints(m));
    final bonus = missionExtra.values
        .where((e) => e.bonusDone)
        .fold(0, (total, e) => total + e.bonusPts);
    return base + bonus;
  }

  Future<void> saveMissionExtra(int id, {required String bonus, required int bonusPts, required String rules, required bool bonusDone}) async {
    missionExtra[id] = MissionExtra(bonus: bonus, bonusPts: bonusPts, rules: rules, bonusDone: bonusDone);
    notifyListeners();
    await _saveData();
  }

  // Quick one-tap bonus toggle for the competition-prep screen — same
  // interaction as toggleMission(), but flips bonusDone instead of the
  // mission's own missionChecks entry.
  Future<void> toggleMissionBonusDone(int id) async {
    final extra = missionExtra[id];
    if (extra == null) return;
    extra.bonusDone = !extra.bonusDone;
    notifyListeners();
    await _saveData();
  }

  // NOTE: unlike web (where editing one mission has to snapshot the whole
  // OFFICIAL_MISSIONS fallback into state.customMissions the first time it
  // happens), `missions` here is always a concrete, directly-owned list —
  // even freshly after resetMissions() it's a copy, never a live reference
  // to officialMissions. So there's no separate "locked in" moment on Android:
  // it's effectively always been that way, from first boot.
  Future<void> updateMission(int id, String name, int pts) async {
    final m = missions.firstWhere((m) => m.id == id);
    m.name = name;
    m.pts = pts;
    notifyListeners();
    await _saveData();
  }

  /// Pre-fills the official bonus (text + points) for missions that are still
  /// the official ones (same id and name), unless the team already set one.
  /// Also splits the bonus out of a mission's pts if an older version saved the
  /// combined max (e.g. M01 as 30 instead of 20 + 10 bonus).
  void _applyOfficialBonuses() {
    officialBonuses.forEach((id, b) {
      final (bonusPts, bonusText) = b;
      final official = officialMissions.where((m) => m.id == id).firstOrNull;
      final m = missions.where((x) => x.id == id).firstOrNull;
      if (official == null || m == null || m.name != official.name) return;
      if (m.pts == official.pts + bonusPts) m.pts = official.pts;
      final extra = missionExtra[id];
      if (extra == null) {
        missionExtra[id] = MissionExtra(bonus: bonusText, bonusPts: bonusPts);
      } else if (extra.bonusPts <= 0) {
        extra.bonusPts = bonusPts;
        if (extra.bonus.isEmpty) extra.bonus = bonusText;
      }
    });
  }

  Future<void> resetMissions() async {
    missions = officialMissions.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    _applyOfficialBonuses();
    notifyListeners();
    await _saveData();
  }

  // Full replace with a mentor-imported mission list (JSON import). Distinct
  // from resetMissions(), which reverts to the built-in officialMissions —
  // this replaces with an arbitrary list and, since ids may no longer line
  // up with the old set, resets missionChecks/missionExtra to avoid stale
  // notes/ticks pointing at the wrong mission.
  Future<void> replaceMissions(List<Mission> newMissions, {Map<int, MissionExtra>? extras, String? season}) async {
    missions = newMissions;
    missionChecks = {};
    precisionTokens = 6;
    missionExtra = extras ?? {};
    // Unlike web (which mixes an active + archived seasons into one array
    // that must stay in sync), currentSeason here is a plain string with no
    // parallel list to desync — just overwrite it.
    if (season != null && season.isNotEmpty) currentSeason = season;
    notifyListeners();
    await _saveData();
    if (season != null && season.isNotEmpty) await _saveSettings();
  }

  /// The 15 robot-game missions — everything except the official equipment-
  /// inspection / precision-tokens entries (scored, but not missions).
  bool isRealMission(Mission m) {
    if (!officialNonMissionIds.contains(m.id)) return true;
    final official = officialMissions.where((o) => o.id == m.id).firstOrNull;
    return official == null || official.name != m.name;
  }

  List<Mission> get realMissions => missions.where(isRealMission).toList();

  static const innovationLogTopics = {'research', 'ideas', 'sharing'};

  /// Daily-log entries only (innovation research/ideas/sharing are separate).
  List<LogEntry> get dailyLogs => logs.where((l) => !innovationLogTopics.contains(l.topic)).toList();

  /// Research findings from both clients (Android log entries + web findings).
  List<LogEntry> get researchEntries =>
      [...logs.where((l) => l.topic == 'research'), ...webFindings]..sort((a, b) => a.date.compareTo(b.date));

  int get doneMissions => realMissions.where((m) => missionChecks[m.id] == true).length;

  /// Highest possible robot-game score: every item's points plus its bonus (530 for BIOGLOW™).
  int get maxScore => missions.fold(0, (a, m) => a + m.pts + (missionExtra[m.id]?.bonusPts ?? 0));

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
    if (teamId != null) await FirebaseService.saveImprovementPhoto(teamId!, imp.toMap());
  }

  Future<void> deleteImprovement(int id) async {
    improvements.removeWhere((i) => i.id == id);
    notifyListeners();
    if (teamId != null) await FirebaseService.deleteImprovementPhoto(teamId!, id);
  }

  // ─── Rubrics (official judging grid) ─────────────

  /// Marks [level] (1-4) for a criterion; marking the same level again clears it.
  Future<void> setRubricMark(String cat, String fieldId, int level) async {
    final marks = rubricMarks.putIfAbsent(cat, () => {});
    if (marks[fieldId] == level) {
      marks.remove(fieldId);
    } else {
      marks[fieldId] = level;
    }
    notifyListeners();
    await _saveData();
  }

  Future<void> setRubricNote(String cat, String fieldId, String value) async {
    final notes = rubricNotes.putIfAbsent(cat, () => {});
    if ((notes[fieldId] ?? '') == value) return;
    notes[fieldId] = value;
    await _saveData();
  }

  /// "איפוס המחוון" — clears the marks, notes and feedback shown on [tab]
  /// (the core-values tab shows only feedback, so only that is cleared there).
  Future<void> resetRubricTab(String tab) async {
    for (final r in tab == 'values' ? const <({String cat, RubricSectionDef section, RubricFieldDef field})>[] : rubricRows(tab)) {
      rubricMarks[r.cat]?.remove(r.field.id);
      rubricNotes[r.cat]?.remove(r.field.id);
    }
    rubricFeedback.remove(tab);
    notifyListeners();
    await _saveData();
  }

  Future<void> setRubricFeedback(String tab, String field, String value) async {
    final fb = rubricFeedback.putIfAbsent(tab, () => {});
    if ((fb[field] ?? '') == value) return;
    fb[field] = value;
    await _saveData();
  }

  /// 0..1 — average marked level out of 4 (unmarked criteria count as 0).
  double rubricRatio(String tab) {
    final rows = rubricRows(tab);
    if (rows.isEmpty) return 0;
    final sum = rows.fold<int>(0, (a, r) => a + (rubricMarks[r.cat]?[r.field.id] ?? 0));
    return sum / (rows.length * 4);
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

  // ─── Meeting plans ────────────────────────────────

  static String _todayIso() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Meetings whose date has passed (or is today) with no summary yet, oldest first.
  List<MeetingPlan> get meetingsAwaitingSummary =>
      meetingPlans.where((m) => m.date.compareTo(_todayIso()) <= 0 && m.summary.trim().isEmpty).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  MeetingPlan? meetingForDay(String iso) => meetingPlans.where((m) => m.date == iso).firstOrNull;

  /// Adds or replaces (by id) a meeting plan. Returns false if another meeting
  /// already exists on that date.
  Future<bool> saveMeetingPlan(MeetingPlan plan) async {
    if (meetingPlans.any((m) => m.date == plan.date && m.id != plan.id)) return false;
    final i = meetingPlans.indexWhere((m) => m.id == plan.id);
    if (i == -1) {
      meetingPlans.add(plan);
    } else {
      meetingPlans[i] = plan;
    }
    notifyListeners();
    await _saveData();
    return true;
  }

  Future<void> deleteMeetingPlan(int id) async {
    meetingPlans.removeWhere((m) => m.id == id);
    notifyListeners();
    await _saveData();
  }

  // ─── Milestones ───────────────────────────────────

  Future<void> addMilestone(Milestone milestone) async {
    milestones.add(milestone);
    milestones.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    notifyListeners();
    await _saveData();
  }

  Future<void> toggleMilestone(int id) async {
    final m = milestones.firstWhere((m) => m.id == id);
    m.done = !m.done;
    notifyListeners();
    await _saveData();
  }

  Future<void> updateMilestone(Milestone milestone) async {
    final i = milestones.indexWhere((m) => m.id == milestone.id);
    if (i == -1) return;
    milestones[i] = milestone;
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteMilestone(int id) async {
    milestones.removeWhere((m) => m.id == id);
    notifyListeners();
    await _saveData();
  }

  // ─── Members ──────────────────────────────────────

  Future<void> addMember(Member m) async {
    members.add(m);
    notifyListeners();
    await _saveData();
    if (teamId != null) {
      await FirebaseService.registerUserToTeam(m.email, teamId!, m.role);
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

  Future<void> updateSeasonName(String name) async {
    if (name.isEmpty) return;
    currentSeason = name;
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

  Future<void> toggleJuniorMentor(String memberId) async {
    final i = members.indexWhere((m) => m.id == memberId);
    if (i == -1 || members[i].isAdmin) return;
    members[i].juniorMentor = !members[i].juniorMentor;
    notifyListeners();
    await _saveData();
  }

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
    precisionTokens = 6;
    missionExtra = {};
    scores = [];
    missions = officialMissions.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    rubrics = {'values': [], 'robot': [], 'innovation': []};
    rubricMarks = {'innovation': {}, 'robot': {}};
    rubricNotes = {'innovation': {}, 'robot': {}};
    rubricFeedback = {};
    notifyListeners();
    await _saveData();
  }

  Future<void> resetAllData() async {
    logs = [];
    improvements = [];
    interviews = [];
    scores = [];
    missionChecks = {};
    precisionTokens = 6;
    missionExtra = {};
    missions = officialMissions.map((m) => Mission(id: m.id, name: m.name, pts: m.pts)).toList();
    rubrics = {'values': [], 'robot': [], 'innovation': []};
    rubricMarks = {'innovation': {}, 'robot': {}};
    rubricNotes = {'innovation': {}, 'robot': {}};
    rubricFeedback = {};
    stickies = [];
    memberTasks = [];
    checklist = _defaultChecklist();
    innovationProblem = '';
    innovationSolution = '';
    gallery = [];
    milestones = [];
    meetingPlans = [];
    for (final q in judgingQuestions) { q.answer = ''; }
    notifyListeners();
    await _saveData();
    if (teamId != null) {
      await Future.wait([
        FirebaseService.clearChat(teamId!),
        FirebaseService.clearAllGalleryPhotos(teamId!),
        FirebaseService.clearAllImprovementPhotos(teamId!),
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
    if (t.done) return false;
    final due = parseTaskDue(t.due);
    return due != null && due.isBefore(DateTime.now());
  }

  List<MemberTask> getOverdueTasksFor(String memberId) {
    final m = members.where((x) => x.id == memberId).firstOrNull ?? (currentUser?.id == memberId ? currentUser : null);
    return memberTasks.where((t) => taskAppliesTo(t, m) && isTaskOverdue(t)).toList();
  }

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
    // Shared with web (settings doc) as 'YYYY-MM-DD'.
    competitionDate = date?.toIso8601String().split('T')[0];
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

  Future<void> addGalleryItem(GalleryItem item) async {
    gallery.add(item);
    _safeNotify();
    if (teamId != null) await FirebaseService.saveGalleryPhoto(teamId!, item.toMap());
  }

  Future<void> deleteGalleryItem(int id) async {
    gallery.removeWhere((g) => g.id == id);
    _safeNotify();
    if (teamId != null) await FirebaseService.deleteGalleryPhoto(teamId!, id);
  }

  Future<void> updateGalleryItemCaption(int id, String caption) async {
    final item = gallery.firstWhere((g) => g.id == id);
    item.caption = caption;
    notifyListeners();
    if (teamId != null) await FirebaseService.updateGalleryPhotoCaption(teamId!, id, caption);
  }

  // ─── Links ────────────────────────────────────────────

  // Links live in data.links (shared with web).
  Future<void> _saveLinks() => _saveData();

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
