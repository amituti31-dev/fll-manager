import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/month_calendar.dart' show coreValueStyles;

/// AI "season story" — mirrors web/js/story.js (same input format, same
/// instructions, same model order) so both clients produce comparable stories.
/// The Gemini key is the team's, read from the mentor-only ai-config doc.
/// Student/author names are never sent.
class SeasonStoryService {
  static const models = ['gemini-flash-latest', 'gemini-2.5-flash']; // first that works
  static const _inputLimit = 60000;

  static const instructions = '''אתה עוזר לקבוצת FIRST LEGO League בישראל לכתוב את "סיפור העונה" שלה, על סמך התיעוד שהקבוצה אספה לאורך העונה (מפגשים, תיעודים יומיים, פתקי ערכי ליבה ואבני דרך).
כתוב בעברית, בגוף ראשון רבים ("אנחנו"), טקסט רציף, חם ומעניין שאפשר להציג לשופטים ולהורים.
היצמד לעובדות שבנתונים בלבד — אל תמציא אירועים, שמות, מספרים או הישגים שלא מופיעים בהם.
מבנה: כותרת קצרה; פתיחה; פרקים לפי שלבי העונה (לפי חודשים או נושאים); פרק על ערכי הליבה (גילוי, חדשנות, השפעה, הכלה, עבודת צוות, הנאה) עם דוגמאות קונקרטיות מהפתקים; סיכום ומה למדנו.
אורך: 500 עד 900 מילים. טקסט פשוט בלבד — בלי Markdown, בלי כוכביות ובלי סימני #. כותרות פרקים בשורה נפרדת.''';

  static const _topicLabels = {'general': '📌 כללי', 'robot': '🤖 רובוט', 'innovation': '💡 חדשנות', 'values': '⭐ ערכים'};

  /// Everything that happened this season, grouped by date — no author names.
  static String buildInput(AppProvider prov) {
    final days = <String, ({List<MeetingPlan> meetings, List<LogEntry> logs, List<StickyNote> notes, List<Milestone> milestones})>{};
    ({List<MeetingPlan> meetings, List<LogEntry> logs, List<StickyNote> notes, List<Milestone> milestones}) day(String d) =>
        days.putIfAbsent(d, () => (meetings: <MeetingPlan>[], logs: <LogEntry>[], notes: <StickyNote>[], milestones: <Milestone>[]));
    for (final m in prov.meetingPlans) { if (m.date.isNotEmpty) day(m.date).meetings.add(m); }
    for (final l in prov.logs) {
      // Daily logs only (innovation research/ideas/sharing entries use their own topics).
      if (l.date.isNotEmpty && l.allTopics.every(_topicLabels.containsKey)) day(l.date).logs.add(l);
    }
    for (final s in prov.stickies) { if (s.date.isNotEmpty) day(s.date).notes.add(s); }
    for (final m in prov.milestones) {
      final d = m.done ? (m.actualDate ?? m.targetDate) : m.targetDate;
      if (d.isNotEmpty) day(d).milestones.add(m);
    }
    String valueName(String v) => coreValueStyles[v]?.$2 ?? v;

    final out = <String>[
      'קבוצה: ${prov.teamName}',
      'עונה: ${prov.currentSeason}',
      'הבעיה שבחרנו בפרויקט החדשנות: ${prov.innovationProblem.isEmpty ? '—' : prov.innovationProblem}',
      'הפתרון שלנו: ${prov.innovationSolution.isEmpty ? '—' : prov.innovationSolution}',
      'הניקוד הטוב ביותר בריצת רובוט: ${prov.scores.isEmpty ? '—' : prov.bestScore} מתוך ${prov.maxScore}',
      '',
    ];
    for (final d in (days.keys.toList()..sort())) {
      final x = days[d]!;
      out.add('## $d');
      for (final m in x.meetings) {
        out.add('מפגש: ${m.title}');
        if (m.plan.isNotEmpty) out.add('  תכנון: ${m.plan}');
        if (m.summary.isNotEmpty) out.add('  מה קרה בפועל: ${m.summary}');
      }
      for (final l in x.logs) {
        final values = l.values.isEmpty ? '' : ' | ערכים: ${l.values.map(valueName).join(', ')}';
        out.add('- תיעוד [${l.allTopics.map((t) => _topicLabels[t] ?? t).join(', ')}$values]: ${l.text}');
      }
      for (final s in x.notes) { out.add('- פתק ערך ליבה (${valueName(s.value)}): ${s.text}'); }
      for (final m in x.milestones) { out.add('- אבן דרך${m.done ? ' שהושגה' : ''}: ${m.title}'); }
      out.add('');
    }
    final text = out.join('\n');
    return text.length > _inputLimit ? text.substring(text.length - _inputLimit) : text;
  }

  /// Calls Gemini; returns (text, model). Throws a Hebrew message on failure.
  static Future<(String, String)> generate(String key, String input) async {
    String? lastErr;
    for (final model in models) {
      final res = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': key},
        body: jsonEncode({
          'system_instruction': {'parts': [{'text': instructions}]},
          'contents': [{'role': 'user', 'parts': [{'text': input}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 8192},
        }),
      ).timeout(const Duration(seconds: 90));
      Map<String, dynamic> body = {};
      try { body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>; } catch (_) {}
      if (res.statusCode == 200) {
        final parts = ((body['candidates'] as List?)?.firstOrNull as Map?)?['content']?['parts'] as List? ?? const [];
        final text = parts.map((p) => (p as Map)['text'] ?? '').join().trim();
        if (text.isNotEmpty) return (text, model);
        lastErr = 'ה-AI לא החזיר טקסט (ייתכן שהתוכן נחסם). נסו שוב.';
        break;
      }
      final msg = (body['error'] as Map?)?['message']?.toString() ?? 'HTTP ${res.statusCode}';
      if (res.statusCode == 404) { lastErr = msg; continue; } // model not available — try the next
      if (res.statusCode == 400 && msg.toLowerCase().contains('api key')) throw 'המפתח לא תקין. בדקו אותו בהגדרות.';
      if (res.statusCode == 403) throw 'אין הרשאה למפתח הזה (בדקו שהוא מ-Google AI Studio).';
      if (res.statusCode == 429) throw 'הגעתם למגבלת השימוש החינמית לעכשיו. נסו שוב מאוחר יותר.';
      throw msg.substring(0, math.min(msg.length, 200));
    }
    throw lastErr ?? 'שגיאה לא ידועה';
  }
}
