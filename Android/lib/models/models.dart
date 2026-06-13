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

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.color,
    this.pin = '',
    this.nameChanges = 0,
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

final List<Mission> missions2026 = [
  Mission(id: 1,  name: 'M01 – צמח קטן',         pts: 20),
  Mission(id: 2,  name: 'M02 – בית הצמחים',       pts: 20),
  Mission(id: 3,  name: 'M03 – מנהרת ים',         pts: 20),
  Mission(id: 4,  name: 'M04 – ספינת ים',         pts: 20),
  Mission(id: 5,  name: 'M05 – שרשרת עץ',         pts: 25),
  Mission(id: 6,  name: 'M06 – קוצים וכדור כוח',  pts: 25),
  Mission(id: 7,  name: 'M07 – חישוק',            pts: 25),
  Mission(id: 8,  name: 'M08 – שרשרת פחם',        pts: 20),
  Mission(id: 9,  name: 'M09 – לא רכוס סינורית', pts: 25),
  Mission(id: 10, name: 'M10 – ממחזר חרכוב',      pts: 20),
  Mission(id: 11, name: 'M11 – כוח עמוק',         pts: 20),
  Mission(id: 12, name: 'M12 – ספינת קוצים',      pts: 30),
  Mission(id: 13, name: 'M13 – חרוב הבר',         pts: 25),
  Mission(id: 14, name: 'M14 – פחמן',             pts: 20),
  Mission(id: 15, name: 'M15 – נקודת ציפור',      pts: 20),
];

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
