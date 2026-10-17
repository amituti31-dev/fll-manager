import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Member ───────────────────────────────────────────
class Member {
  final String id;
  String name;
  final String email;
  String role; // 'admin' | 'student'
  final Color color;
  String pin;
  int nameChanges;
  bool juniorMentor; // "מנטור צעיר" — a label on a student, no extra permissions

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.color,
    this.pin = '',
    this.nameChanges = 0,
    this.juniorMentor = false,
  });

  bool get isAdmin => role == 'admin';

  factory Member.fromMap(Map<String, dynamic> m) {
    final colorIndex = (m['colorIndex'] as int?) ?? 0;
    return Member(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      role: m['role'] as String? ?? 'student',
      color: AppColors.avatarColors[colorIndex % AppColors.avatarColors.length],
      pin: m['pin'] as String? ?? '',
      nameChanges: m['nameChanges'] as int? ?? 0,
      juniorMentor: m['juniorMentor'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'colorIndex': AppColors.avatarColors.indexOf(color).clamp(0, 5),
    'pin': pin,
    'nameChanges': nameChanges,
    'juniorMentor': juniorMentor,
  };
}

// ─── Log Entry ────────────────────────────────────────
class LogEntry {
  final int id;
  final String topic; // 'general' | 'robot' | 'innovation' | 'values' | 'research'
  final String text;
  final String author;
  final String date;
  final String? imageBase64;
  final String? title;
  final String? audioPath;

  LogEntry({
    required this.id,
    required this.topic,
    required this.text,
    required this.author,
    required this.date,
    this.imageBase64,
    this.title,
    this.audioPath,
  });

  factory LogEntry.fromMap(Map<String, dynamic> m) => LogEntry(
    id: m['id'] as int,
    topic: m['topic'] as String? ?? 'general',
    text: m['text'] as String? ?? '',
    author: m['author'] as String? ?? '',
    date: m['date'] as String? ?? '',
    imageBase64: m['image'] as String?,
    title: m['title'] as String?,
    audioPath: m['audioPath'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'topic': topic,
    'text': text,
    'author': author,
    'date': date,
    'image': imageBase64,
    'title': title,
    'audioPath': audioPath,
  };
}

// ─── Interview ────────────────────────────────────────
class Interview {
  final int id;
  final String expert;
  final String role;
  final String org;
  final String text;
  final String quotes;
  final String author;
  final String date;

  Interview({
    required this.id,
    required this.expert,
    this.role = '',
    this.org = '',
    required this.text,
    this.quotes = '',
    required this.author,
    required this.date,
  });

  factory Interview.fromMap(Map<String, dynamic> m) => Interview(
    id: (m['id'] as num).toInt(),
    expert: m['expert'] as String? ?? '',
    role: m['role'] as String? ?? '',
    org: m['org'] as String? ?? '',
    text: m['text'] as String? ?? '',
    quotes: m['quotes'] as String? ?? '',
    author: m['author'] as String? ?? '',
    date: m['date'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'expert': expert,
    'role': role,
    'org': org,
    'text': text,
    'quotes': quotes,
    'author': author,
    'date': date,
  };
}

// ─── Mission ──────────────────────────────────────────
class Mission {
  final int id;
  String name;
  int pts;
  String status; // 'not_tried' | 'in_progress' | 'ready'

  Mission({required this.id, required this.name, required this.pts, this.status = 'not_tried'});

  factory Mission.fromMap(Map<String, dynamic> m) => Mission(
    id: (m['id'] as num).toInt(),
    name: m['name'] as String? ?? '',
    pts: (m['pts'] as num?)?.toInt() ?? 0,
    status: m['status'] as String? ?? 'not_tried',
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'pts': pts, 'status': status};
}

// Free-text bonus/rule notes per mission, kept separate from Mission itself
// so any team member can edit them (Mission lives in mentor-only admin-data).
class MissionExtra {
  String bonus;
  int bonusPts;
  String rules;
  bool bonusDone;

  MissionExtra({this.bonus = '', this.bonusPts = 0, this.rules = '', this.bonusDone = false});

  factory MissionExtra.fromMap(Map<String, dynamic> m) => MissionExtra(
    bonus: m['bonus'] as String? ?? '',
    bonusPts: (m['bonusPts'] as num?)?.toInt() ?? 0,
    rules: m['rules'] as String? ?? '',
    bonusDone: m['bonusDone'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {'bonus': bonus, 'bonusPts': bonusPts, 'rules': rules, 'bonusDone': bonusDone};
}

// Official FIRST LEGO League season + robot-game missions, from FIRST Israel's scorer
// (fll-events.firstisrael.org.il/tools/scorer, scoresheet version 2026-08-04) and season list
// (lems.firstisrael.org.il/api/portal/seasons). pts = the most each mission scores without its
// bonus; officialBonuses holds the bonus parts (450 + 80 = 530 total).
// Keep web/js/defaults.js and Android/lib/models/models.dart identical; update both each season.
const officialSeasonName = 'BIOGLOW™';
final List<Mission> officialMissions = [
  Mission(id: 1,  name: 'M01 – סקר בעזרת רחפן', pts: 20),
  Mission(id: 2,  name: 'M02 – זרעים נפצים', pts: 30),
  Mission(id: 3,  name: 'M03 – להפוך את הסלע', pts: 20),
  Mission(id: 4,  name: 'M04 – עלים ברי מזל', pts: 10),
  Mission(id: 5,  name: 'M05 – שורשים מתפרסים', pts: 20),
  Mission(id: 6,  name: 'M06 – טירוף חותכי העלים', pts: 40),
  Mission(id: 7,  name: 'M07 – תפטיר אדיר', pts: 20),
  Mission(id: 8,  name: 'M08 – פלונטר', pts: 30),
  Mission(id: 9,  name: 'M09 – פלטפורמת מחקר', pts: 30),
  Mission(id: 10, name: 'M10 – בתי גידול זעירים ועדינים', pts: 20),
  Mission(id: 11, name: 'M11 – חלון אל העבר', pts: 20),
  Mission(id: 12, name: 'M12 – זקן היער', pts: 30),
  Mission(id: 13, name: 'M13 – מין מפתח', pts: 30),
  Mission(id: 14, name: 'M14 – זרעים של התחדשות', pts: 20),
  Mission(id: 15, name: 'M15 – אדריכלות ביוצנטרית', pts: 40),
  Mission(id: 16, name: 'ביקורת ציוד', pts: 20),
  Mission(id: 17, name: 'אסימוני דיוק', pts: 50),
];
// Scored but not robot-game missions: equipment inspection (16) and precision tokens (17).
const officialNonMissionIds = {16, 17};

// Precision tokens (id 17): the team starts with 6; points depend on how many are
// left at the end of the match (official scorer: 0→0, 1→10, 2→15, 3→25, 4→35, 5–6→50).
const precisionTokensId = 17;
const precisionTokenPoints = [0, 10, 15, 25, 35, 50, 50];

// mission id → (bonus pts, official bonus text); pre-filled into missionExtra.
const Map<int, (int, String)> officialBonuses = {
  1: (10, 'מפת ה-LiDAR התהפכה לחלוטין, וסמן הסריקה נמצא לפחות חלקית באזור הסקר'),
  3: (10, 'הסלע הוחזר למצב ההתחלתי שלו'),
  4: (20, 'החרגול נשאר במצבו ההתחלתי לאורך המקצה'),
  7: (20, 'חיבורים בין תפטיר פרוס לחלוטין של קבוצה אחת לשורש צמח פרוס לחלוטין של הקבוצה ממול'),
  14: (20, 'זרעים שנוגעים בשטיח'),
};

// ─── Score Run ────────────────────────────────────────
class ScoreRun {
  final String date;
  final int score;
  final String notes;

  ScoreRun({required this.date, required this.score, required this.notes});

  factory ScoreRun.fromMap(Map<String, dynamic> m) => ScoreRun(
    date: m['date'] as String? ?? '',
    score: m['score'] as int? ?? 0,
    notes: m['notes'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'date': date, 'score': score, 'notes': notes};
}

// ─── Improvement ─────────────────────────────────────
class Improvement {
  final int id;
  final String name;
  final String desc;
  final String missionId;
  final String? imageBase64;
  final String date;
  final String author;

  Improvement({
    required this.id,
    required this.name,
    required this.desc,
    required this.missionId,
    this.imageBase64,
    required this.date,
    required this.author,
  });

  factory Improvement.fromMap(Map<String, dynamic> m) => Improvement(
    id: m['id'] as int,
    name: m['name'] as String? ?? '',
    desc: m['desc'] as String? ?? '',
    missionId: m['mission'] as String? ?? '',
    imageBase64: m['image'] as String?,
    date: m['date'] as String? ?? '',
    author: m['author'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'desc': desc,
    'mission': missionId,
    'image': imageBase64,
    'date': date,
    'author': author,
  };
}

// ─── Rubric ───────────────────────────────────────────
class RubricItem {
  final int id;
  final String question;
  int score; // 0-4
  String notes;

  RubricItem({required this.id, required this.question, this.score = 0, this.notes = ''});

  factory RubricItem.fromMap(Map<String, dynamic> m) => RubricItem(
    id: (m['id'] as num).toInt(),
    question: m['q'] as String? ?? '',
    score: m['score'] as int? ?? 0,
    notes: m['notes'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'id': id, 'q': question, 'score': score, 'notes': notes};
}

// Official FIRST Israel judging rubrics (fll-events.firstisrael.org.il/tools/rubrics,
// rubric version 2025-11-23): each criterion has the official text for the first
// three levels (the 4th, "מצטיינת", has no text — judges just mark it).
// coreValues = the official rubric counts this criterion toward core values too;
// the core-values tab is just those criteria, sharing the same marks.
class RubricFieldDef {
  final String id;
  final bool coreValues;
  final List<String> levels;
  const RubricFieldDef(this.id, this.coreValues, this.levels);
}

class RubricSectionDef {
  final String id;
  final String title;
  final String description;
  final List<RubricFieldDef> fields;
  const RubricSectionDef(this.id, this.title, this.description, this.fields);
}

const Map<String, List<RubricSectionDef>> rubricGrid = {
  'innovation': [
    RubricSectionDef('identify', 'זיהוי',
      'הקבוצה הגדירה את הבעיה באופן ברור וחקרה אותה היטב.', [
        RubricFieldDef('problem', false, ['הגדרת הבעיה אינה ברורה', 'הגדרת הבעיה ברורה באופן חלקי', 'הגדרת הבעיה ברורה']),
        RubricFieldDef('research', true, ['עדות מינימלית למחקר', 'עדות חלקית למחקר על סמך מקור אחד או יותר', 'מחקר ברור ומפורט על סמך מגוון מקורות מידע']),
      ]),
    RubricSectionDef('design', 'תכנון',
      'הקבוצה בנתה ביחד את תוכנית הפרויקט ופיתחה ביחד את רעיונותיה.', [
        RubricFieldDef('plan', false, ['עדות מינימלית לתוכנית עבודה תכליתית', 'עדות חלקית לתוכנית עבודה תכליתית', 'עדות ניכרת לתוכנית עבודה תכליתית']),
        RubricFieldDef('participation', true, ['עדות מינימלית שכל חברי הקבוצה השתתפו בתהליך הפיתוח', 'עדות חלקית שכל חברי הקבוצה השתתפו בתהליך הפיתוח', 'עדות ניכרת שכל חברי הקבוצה השתתפו בתהליך הפיתוח']),
      ]),
    RubricSectionDef('create', 'יצירה',
      'הקבוצה פיתחה רעיון מקורי או התבססה על אחד קיים, תוך הכנת דגם או סרטוט של אב־טיפוס לשם הצגת הפתרון.', [
        RubricFieldDef('innovation', true, ['הסבר מינימלי של חדשנות הפתרון', 'הסבר פשטני של חדשנות הפתרון', 'הסבר מפורט של חדשנות הפתרון']),
        RubricFieldDef('model', false, ['דגם או סרטוט של הפתרון אינו ברור', 'דגם או סרטוט פשוט של הפתרון', 'דגם או סרטוט מפורט של הפתרון']),
      ]),
    RubricSectionDef('iterate', 'חזרה ושינוי',
      'הקבוצה שיתפה את הרעיונות שלה, אספה משובים ובעקבותיהם שילבה שיפורים בפתרון.', [
        RubricFieldDef('share', false, ['שיתוף מינימלי של הפתרון עם אחרים', 'הפתרון שותף עם לפחות אדם אחד או קבוצה אחת', 'הפתרון שותף עם אנשים רבים או קבוצות רבות']),
        RubricFieldDef('improve', false, ['עדות מינימלית לשיפורים על סמך המשוב', 'עדות חלקית לשיפורים על סמך המשוב', 'עדות ניכרת לשיפורים על סמך המשוב']),
      ]),
    RubricSectionDef('communicate', 'הצגה',
      'הקבוצה שיתפה במצגת תכליתית את הפתרון שלה ואת השפעתו על אחרים, וחגגה את ההתקדמות שלה.', [
        RubricFieldDef('explanation', true, ['הסבר הפתרון והשפעתו האפשרית על אחרים אינם ברורים', 'הסבר הפתרון והשפעתו האפשרית על אחרים ברורים חלקית', 'הסבר הפתרון והשפעתו האפשרית על אחרים ברורים לחלוטין']),
        RubricFieldDef('pride', true, ['הקבוצה מדגימה גאווה או התלהבות באופן מינימלי', 'הקבוצה מדגימה גאווה או התלהבות באופן חלקי', 'הקבוצה מדגימה גאווה או התלהבות באופן ניכר']),
      ]),
  ],
  'robot': [
    RubricSectionDef('identify', 'זיהוי',
      'הקבוצה הגדירה אילו משימות תנסה לפתור, חקרה משאבים של בנייה ותכנות ונעזרה בהנחייה על פי הצורך.', [
        RubricFieldDef('strategy', false, ['עדות מינימלית לאסטרטגיית משימה', 'עדות חלקית לאסטרטגיית משימה', 'עדות ניכרת לאסטרטגיית משימה']),
        RubricFieldDef('resources', true, ['שימוש מינימלי במשאבי בנייה ותכנות', 'שימוש מוגבל במשאבי בנייה ותכנות', 'שימוש ניכר במשאבי בנייה ותכנות לתמיכה באסטרטגיית המשימה']),
      ]),
    RubricSectionDef('design', 'תכנון',
      'הקבוצה עבדה ביחד על תכנון הרובוט ופיתחה את המיומנויות הנדרשות של בנייה ותכנות.', [
        RubricFieldDef('contribution', true, ['עדות מינימלית שכל חברי הקבוצה תרמו רעיונות', 'עדות חלקית שכל חברי הקבוצה תרמו רעיונות', 'עדות ניכרת שכל חברי הקבוצה תרמו רעיונות']),
        RubricFieldDef('skills', false, ['עדות מינימלית למיומנויות בנייה ותכנות אצל כל חברי הקבוצה', 'עדות חלקית למיומנויות בנייה ותכנות אצל כל חברי הקבוצה', 'עדות ניכרת למיומנויות בנייה ותכנות אצל כל חברי הקבוצה']),
      ]),
    RubricSectionDef('create', 'יצירה',
      'הקבוצה פיתחה תכנונים הנדסיים מקוריים או שיפרה תכנונים קיימים בהתאם לאסטרטגיית המשימה שלה.', [
        RubricFieldDef('attachments', false, ['הסבר לא ברור של התוספות והייעוד שלהן', 'הסבר פשטני של התוספות והייעוד שלהן', 'הסבר מפורט של התוספות החדשניות והייעוד שלהן']),
        RubricFieldDef('code', false, ['הסבר לא ברור של התוכנה ו/או שימוש בחיישנים', 'הסבר פשטני של התוכנה ו/או שימוש בחיישנים', 'הסבר מפורט של התוכנה ו/או שימוש חדשני בחיישנים']),
      ]),
    RubricSectionDef('iterate', 'חזרה ושינוי',
      'הקבוצה ביצעה בדיקות חוזרות של הרובוט והתוכנה במטרה לזהות תחומים שדורשים שיפור ושילבה את הממצאים בפתרונות שלה.', [
        RubricFieldDef('test', false, ['עדות מינימלית לבדיקות הרובוט והתוכנה', 'עדות חלקית לבדיקות הרובוט והתוכנה', 'עדות ניכרת לבדיקות חוזרות של הרובוט והתוכנה']),
        RubricFieldDef('improve', true, ['עדות מינימלית לשיפורים שהוכנסו בעקבות הבדיקות', 'עדות חלקית לשיפורים שהוכנסו בעקבות הבדיקות', 'עדות ניכרת לשיפורים שהוכנסו בעקבות הבדיקות']),
      ]),
    RubricSectionDef('communicate', 'הצגה',
      'הקבוצה הסבירה באופן תכליתי מה היא למדה מתהליך תכנון הרובוט וחגגה את התקדמותה.', [
        RubricFieldDef('explanation', true, ['הסבר לא ברור של התהליך והפקת לקחים', 'הסבר פשטני של התהליך והפקת לקחים', 'הסבר מפורט של התהליך והפקת לקחים']),
        RubricFieldDef('pride', true, ['הקבוצה מדגימה גאווה או התלהבות מינימלית מהעבודה שלה', 'הקבוצה מדגימה גאווה או התלהבות חלקית מהעבודה שלה', 'הקבוצה מדגימה גאווה או התלהבות ניכרת מהעבודה שלה']),
      ]),
  ],
};

const rubricTitles = {'innovation': 'פרויקט החדשנות', 'robot': 'תכנון הרובוט'};
const rubricLevels = ['מתחילה', 'מתפתחת', 'מיומנת', 'מצטיינת'];
// Column colors per tab, as on the official site.
const rubricColors = {
  'innovation': [Color(0xFFE9ECF7), Color(0xFFBDC6E4), Color(0xFF90A3D2), Color(0xFF5E82BF)],
  'robot':      [Color(0xFFEDF4EC), Color(0xFFC6DDC5), Color(0xFF99C69C), Color(0xFF64AF75)],
  'values':     [Color(0xFFFAECEA), Color(0xFFF3D0C9), Color(0xFFEBB3AA), Color(0xFFE4928B)],
};

/// Every criterion shown on [tab] ('innovation' | 'robot' | 'values').
List<({String cat, RubricSectionDef section, RubricFieldDef field})> rubricRows(String tab) {
  final cats = tab == 'values' ? ['innovation', 'robot'] : [tab];
  return [
    for (final cat in cats)
      for (final section in rubricGrid[cat]!)
        for (final field in section.fields)
          if (tab != 'values' || field.coreValues) (cat: cat, section: section, field: field),
  ];
}

// ─── Sticky Note ─────────────────────────────────────
class StickyNote {
  final int id;
  final String value; // discovery | innovation | impact | inclusion | teamwork | fun
  final String text;
  final String date;

  StickyNote({required this.id, required this.value, required this.text, required this.date});

  factory StickyNote.fromMap(Map<String, dynamic> m) => StickyNote(
    id: m['id'] as int,
    value: m['value'] as String? ?? 'discovery',
    text: m['text'] as String? ?? '',
    date: m['date'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'id': id, 'value': value, 'text': text, 'date': date};
}

// ─── Chat Message ─────────────────────────────────────
class ChatMessage {
  final int id;
  final String authorId;
  final String authorName;
  final String text;
  final String ts;
  final bool isAnnouncement;
  final bool isPoll;
  final List<String> pollOptions;
  final Map<String, int> pollVotes; // memberId → optionIndex
  final bool pollClosed;

  ChatMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.ts,
    this.isAnnouncement = false,
    this.isPoll = false,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.pollClosed = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id: m['id'] as int? ?? 0,
    authorId: m['authorId'] as String? ?? '',
    authorName: m['authorName'] as String? ?? '',
    text: m['text'] as String? ?? '',
    ts: m['ts'] as String? ?? '',
    isAnnouncement: m['isAnnouncement'] as bool? ?? false,
    isPoll: m['isPoll'] as bool? ?? false,
    pollOptions: m['pollOptions'] != null
        ? List<String>.from(m['pollOptions'] as List)
        : const [],
    pollVotes: m['pollVotes'] != null
        ? (m['pollVotes'] as Map).map((k, v) => MapEntry(k as String, v as int))
        : const {},
    pollClosed: m['pollClosed'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'text': text,
    'ts': ts,
    if (isAnnouncement) 'isAnnouncement': true,
    if (isPoll) ...{
      'isPoll': true,
      'pollOptions': pollOptions,
      'pollVotes': pollVotes,
      if (pollClosed) 'pollClosed': true,
    },
  };
}

// ─── Member Task ─────────────────────────────────────
/// Task targets besides a single member id ('all' existed before; the other two are new).
const taskGroupLabels = {'all': '👥 כל הקבוצה', 'all-mentors': '👑 כל המנטורים', 'all-students': '🎓 כל התלמידים'};
bool isGroupTask(String memberId) => taskGroupLabels.containsKey(memberId);

/// Does task [t] apply to member [m]?
bool taskAppliesTo(MemberTask t, Member? m) {
  if (m == null) return t.memberId == 'all';
  return switch (t.memberId) {
    'all' => true,
    'all-mentors' => m.isAdmin,
    'all-students' => !m.isAdmin,
    _ => t.memberId == m.id,
  };
}

class MemberTask {
  final int id;
  final String memberId;
  final String memberName;
  final String desc;
  final String? due;
  bool done;

  MemberTask({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.desc,
    this.due,
    this.done = false,
  });

  factory MemberTask.fromMap(Map<String, dynamic> m) => MemberTask(
    id: m['id'] as int,
    memberId: m['memberId'] as String? ?? '',
    memberName: m['memberName'] as String? ?? '',
    desc: m['desc'] as String? ?? '',
    due: m['due'] as String?,
    done: m['done'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'memberId': memberId,
    'memberName': memberName,
    'desc': desc,
    'due': due,
    'done': done,
  };
}

// ─── Gallery Item ─────────────────────────────────────
class GalleryItem {
  final int id;
  final String imageBase64;
  String caption;
  final String date;
  final String author;

  GalleryItem({
    required this.id,
    required this.imageBase64,
    this.caption = '',
    required this.date,
    required this.author,
  });

  factory GalleryItem.fromMap(Map<String, dynamic> m) => GalleryItem(
    id: m['id'] as int,
    imageBase64: m['image'] as String? ?? '',
    caption: m['caption'] as String? ?? '',
    date: m['date'] as String? ?? '',
    author: m['author'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'image': imageBase64, 'caption': caption,
    'date': date, 'author': author,
  };
}

// ─── Link Item ────────────────────────────────────────
class LinkItem {
  final int id;
  final String title;
  final String url;
  final String category; // 'general' | 'robot' | 'innovation' | 'judging'
  final String addedBy;
  final String date;

  LinkItem({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.addedBy,
    required this.date,
  });

  factory LinkItem.fromMap(Map<String, dynamic> m) => LinkItem(
    id:       m['id']       as int,
    title:    m['title']    as String? ?? '',
    url:      m['url']      as String? ?? '',
    category: m['category'] as String? ?? 'general',
    addedBy:  m['addedBy']  as String? ?? '',
    date:     m['date']     as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'url': url,
    'category': category, 'addedBy': addedBy, 'date': date,
  };
}

// ─── Judging Question ─────────────────────────────────
class JudgingQuestion {
  final int id;
  final String category; // 'robot' | 'innovation' | 'values'
  final String question;
  String answer;

  JudgingQuestion({
    required this.id,
    required this.category,
    required this.question,
    this.answer = '',
  });

  factory JudgingQuestion.fromMap(Map<String, dynamic> m) => JudgingQuestion(
    id: m['id'] as int,
    category: m['category'] as String? ?? 'robot',
    question: m['question'] as String? ?? '',
    answer: m['answer'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'category': category, 'question': question, 'answer': answer,
  };
}

// ─── Archived Season ─────────────────────────────────
class ArchivedSeason {
  final String id;
  final String seasonName;
  final String archivedDate;
  final String archivedBy;
  final int memberCount;
  final int bestScore;
  final int runsCount;
  final int improvementsCount;
  final int logsCount;

  ArchivedSeason({
    required this.id,
    required this.seasonName,
    required this.archivedDate,
    required this.archivedBy,
    required this.memberCount,
    required this.bestScore,
    required this.runsCount,
    required this.improvementsCount,
    required this.logsCount,
  });

  factory ArchivedSeason.fromMap(Map<String, dynamic> m) => ArchivedSeason(
    id: m['id'] as String? ?? '',
    seasonName: m['seasonName'] as String? ?? '',
    archivedDate: m['archivedDate'] as String? ?? '',
    archivedBy: m['archivedBy'] as String? ?? '',
    memberCount: m['memberCount'] as int? ?? 0,
    bestScore: m['bestScore'] as int? ?? 0,
    runsCount: m['runsCount'] as int? ?? 0,
    improvementsCount: m['improvementsCount'] as int? ?? 0,
    logsCount: m['logsCount'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'seasonName': seasonName,
    'archivedDate': archivedDate,
    'archivedBy': archivedBy,
    'memberCount': memberCount,
    'bestScore': bestScore,
    'runsCount': runsCount,
    'improvementsCount': improvementsCount,
    'logsCount': logsCount,
  };
}

// ─── Strategy Board ───────────────────────────────────
class StrokePoint {
  final double x;
  final double y;
  StrokePoint(this.x, this.y);
  factory StrokePoint.fromMap(Map<String, dynamic> m) =>
      StrokePoint((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
  Map<String, dynamic> toMap() => {'x': x, 'y': y};
}

class DrawnStroke {
  final List<StrokePoint> points;
  final int colorValue;
  final double width;
  DrawnStroke({required this.points, required this.colorValue, required this.width});
  factory DrawnStroke.fromMap(Map<String, dynamic> m) => DrawnStroke(
    points: (m['pts'] as List)
        .map((p) => StrokePoint.fromMap(Map<String, dynamic>.from(p as Map)))
        .toList(),
    colorValue: m['color'] as int,
    width: (m['width'] as num).toDouble(),
  );
  Map<String, dynamic> toMap() => {
    'pts': points.map((p) => p.toMap()).toList(),
    'color': colorValue,
    'width': width,
  };
}

class StrategyBoard {
  final int id;
  String title;
  final String? backgroundBase64;
  final List<DrawnStroke> strokes;
  final String date;
  final String author;

  StrategyBoard({
    required this.id,
    required this.title,
    this.backgroundBase64,
    required this.strokes,
    required this.date,
    required this.author,
  });

  factory StrategyBoard.fromMap(Map<String, dynamic> m) => StrategyBoard(
    id: m['id'] as int,
    title: m['title'] as String? ?? '',
    backgroundBase64: m['bg'] as String?,
    strokes: (m['strokes'] as List? ?? [])
        .map((s) => DrawnStroke.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList(),
    date: m['date'] as String? ?? '',
    author: m['author'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    if (backgroundBase64 != null) 'bg': backgroundBase64,
    'strokes': strokes.map((s) => s.toMap()).toList(),
    'date': date,
    'author': author,
  };
}

// ─── Checklist Item ───────────────────────────────────
class ChecklistItem {
  final int id;
  final String text;
  bool done;

  ChecklistItem({required this.id, required this.text, this.done = false});

  factory ChecklistItem.fromMap(Map<String, dynamic> m) => ChecklistItem(
    id: m['id'] as int,
    text: m['text'] as String? ?? '',
    done: m['done'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};
}

// ─── Meeting plan ─────────────────────────────────────
/// One team meeting: what we plan to do and, afterwards, what actually
/// happened. The value stickies added on [date] are "that meeting's notes".
/// Shared with web as data.meetingPlans.
class MeetingPlan {
  final int id;
  String date; // YYYY-MM-DD
  String title;
  String plan;
  String summary;

  MeetingPlan({required this.id, required this.date, this.title = '', this.plan = '', this.summary = ''});

  factory MeetingPlan.fromMap(Map<String, dynamic> m) => MeetingPlan(
    id: (m['id'] as num).toInt(),
    date: m['date'] as String? ?? '',
    title: m['title'] as String? ?? '',
    plan: m['plan'] as String? ?? '',
    summary: m['summary'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'title': title, 'plan': plan, 'summary': summary};

  String get displayTitle => title.isEmpty ? 'מפגש' : title;
}

// ─── Milestone ──────────────────────────────────────────
class Milestone {
  final int id;
  String title;
  String targetDate;
  bool done;
  String? actualDate; // only set when it differs from targetDate

  Milestone({
    required this.id,
    required this.title,
    required this.targetDate,
    this.done = false,
    this.actualDate,
  });

  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
    id: m['id'] as int,
    title: m['title'] as String? ?? '',
    targetDate: m['targetDate'] as String? ?? '',
    done: m['done'] as bool? ?? false,
    actualDate: m['actualDate'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'targetDate': targetDate, 'done': done,
    'actualDate': actualDate,
  };
}
