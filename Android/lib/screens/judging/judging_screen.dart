import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class JudgingScreen extends StatefulWidget {
  const JudgingScreen({super.key});

  @override
  State<JudgingScreen> createState() => _JudgingScreenState();
}

class _JudgingScreenState extends State<JudgingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: '🤖 רובוט'),
            Tab(text: '💡 חדשנות'),
            Tab(text: '⭐ ערכים'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _CategoryTab(category: 'robot',      color: AppColors.accent,  prov: prov),
            _CategoryTab(category: 'innovation', color: AppColors.accent2, prov: prov),
            _CategoryTab(category: 'values',     color: AppColors.gold,    prov: prov),
          ],
        ),
      ),
    ]);
  }
}

// ─── Category tab ─────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  final String category;
  final Color color;
  final AppProvider prov;
  const _CategoryTab({required this.category, required this.color, required this.prov});

  Future<void> _editAnswer(BuildContext context, JudgingQuestion q) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditAnswerDialog(question: q, color: color),
    );
    if (result != null && context.mounted) {
      await context.read<AppProvider>().updateJudgingAnswer(q.id, result);
    }
  }

  Future<void> _addQuestion(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _AddQuestionDialog(color: color),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      await context.read<AppProvider>().addJudgingQuestion(JudgingQuestion(
        id: DateTime.now().millisecondsSinceEpoch,
        category: category,
        question: result,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = prov.judgingQuestions
        .where((q) => q.category == category)
        .toList();
    final answered = questions.where((q) => q.answer.isNotEmpty).length;

    return Column(children: [
      // Progress bar header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$answered / ${questions.length} שאלות נענו',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: questions.isEmpty ? 0 : answered / questions.length,
                minHeight: 5,
                backgroundColor: AppColors.surface3,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ])),
          if (prov.isAdmin) ...[
            SizedBox(width: 12),
            IconButton(
              onPressed: () => _addQuestion(context),
              icon: Icon(Icons.add_circle_outline, color: color, size: 24),
              tooltip: 'הוסף שאלה',
            ),
          ],
        ]),
      ),
      Expanded(
        child: questions.isEmpty
            ? Center(child: Text('אין שאלות',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: questions.length,
                itemBuilder: (_, i) => _QuestionCard(
                  question: questions[i],
                  color: color,
                  number: i + 1,
                  onTap: () => _editAnswer(context, questions[i]),
                  onDelete: prov.isAdmin
                      ? () => context.read<AppProvider>()
                          .deleteJudgingQuestion(questions[i].id)
                      : null,
                ),
              ),
      ),
    ]);
  }
}

// ─── Dialogs ──────────────────────────────────────────

class _EditAnswerDialog extends StatefulWidget {
  final JudgingQuestion question;
  final Color color;
  const _EditAnswerDialog({required this.question, required this.color});

  @override
  State<_EditAnswerDialog> createState() => _EditAnswerDialogState();
}

class _EditAnswerDialogState extends State<_EditAnswerDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.question.answer);
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
      title: Text(widget.question.question,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      content: SingleChildScrollView(
        child: TextField(
          controller: _ctrl,
          style: TextStyle(color: AppColors.textPrimary),
          maxLines: 6,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'כתוב את התשובה שלכם כאן...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: widget.color),
          child: Text('שמור'),
        ),
      ],
    );
  }
}

class _AddQuestionDialog extends StatefulWidget {
  final Color color;
  const _AddQuestionDialog({required this.color});

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('הוסף שאלה', style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _ctrl,
        style: TextStyle(color: AppColors.textPrimary),
        autofocus: true,
        decoration: InputDecoration(hintText: 'טקסט השאלה...'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: widget.color),
          child: Text('הוסף'),
        ),
      ],
    );
  }
}

// ─── Question card ────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final JudgingQuestion question;
  final Color color;
  final int number;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _QuestionCard({
    required this.question,
    required this.color,
    required this.number,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswer = question.answer.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAnswer ? color.withAlpha(100) : AppColors.border,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Question header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hasAnswer ? color.withAlpha(20) : AppColors.surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: hasAnswer ? color : AppColors.surface3,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$number', style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                )),
              ),
              SizedBox(width: 10),
              Expanded(child: Text(question.question, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ))),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, size: 16, color: AppColors.textTertiary),
                ),
              SizedBox(width: 4),
              Icon(
                hasAnswer ? Icons.check_circle : Icons.edit_outlined,
                size: 16,
                color: hasAnswer ? color : AppColors.textTertiary,
              ),
            ]),
          ),
          // Answer area
          Padding(
            padding: const EdgeInsets.all(12),
            child: hasAnswer
                ? Text(question.answer, style: TextStyle(
                    fontSize: 13, color: AppColors.textPrimary, height: 1.5))
                : Text('לחץ לכתיבת תשובה...', style: TextStyle(
                    fontSize: 13, color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic)),
          ),
        ]),
      ),
    );
  }
}
