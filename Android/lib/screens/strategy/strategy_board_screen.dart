import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

// ─── Main screen ──────────────────────────────────────
class StrategyBoardScreen extends StatelessWidget {
  const StrategyBoardScreen({super.key});

  static Future<void> showAddDialog(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _NewBoardDialog(),
    );
    if (result == null || !context.mounted) return;

    final board = StrategyBoard(
      id: DateTime.now().millisecondsSinceEpoch,
      title: result['title'] as String,
      backgroundBase64: result['bg'] as String?,
      strokes: [],
      date: DateTime.now().toIso8601String().split('T')[0],
      author: prov.currentUser?.name ?? '',
    );
    await prov.addStrategyBoard(board);
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => _BoardEditor(board: board),
        fullscreenDialog: true,
      ));
    }
  }

  void _openEditor(BuildContext context, StrategyBoard board) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _BoardEditor(board: board),
      fullscreenDialog: true,
    ));
  }

  Future<void> _confirmDelete(BuildContext context, AppProvider prov, StrategyBoard board) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחק לוח', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('למחוק את "${board.title}"?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('מחק', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await prov.deleteStrategyBoard(board.id);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final boards = prov.strategyBoards;

    if (boards.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🗺️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('אין לוחות אסטרטגיה',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
        const SizedBox(height: 6),
        Text('לחץ ➕ ליצירת לוח חדש',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ]));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: boards.length,
      itemBuilder: (_, i) => _BoardCard(
        board: boards[i],
        onTap: () => _openEditor(context, boards[i]),
        onLongPress: () => _confirmDelete(context, prov, boards[i]),
      ),
    );
  }
}

// ─── Board card ───────────────────────────────────────
class _BoardCard extends StatelessWidget {
  final StrategyBoard board;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BoardCard({required this.board, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: board.backgroundBase64 != null
                ? Stack(fit: StackFit.expand, children: [
                    Image.memory(base64Decode(board.backgroundBase64!), fit: BoxFit.cover),
                    if (board.strokes.isNotEmpty)
                      CustomPaint(painter: _PreviewPainter(board.strokes)),
                  ])
                : Container(
                    color: AppColors.surface2,
                    child: const Center(child: Text('🗺️', style: TextStyle(fontSize: 40))),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(board.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('${board.author} · ${board.date}',
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Preview painter (thumbnail) ─────────────────────
class _PreviewPainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  const _PreviewPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length < 2) continue;
      final paint = Paint()
        ..color = Color(s.colorValue)
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points.first.x, s.points.first.y);
      for (final p in s.points.skip(1)) path.lineTo(p.x, p.y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => false;
}

// ─── New board dialog ─────────────────────────────────
class _NewBoardDialog extends StatefulWidget {
  const _NewBoardDialog();

  @override
  State<_NewBoardDialog> createState() => _NewBoardDialogState();
}

class _NewBoardDialogState extends State<_NewBoardDialog> {
  final _titleCtrl = TextEditingController();
  String? _bgBase64;
  bool _picking = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _bgBase64 = base64Encode(bytes));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('לוח אסטרטגיה חדש', style: TextStyle(color: AppColors.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'שם הלוח (למשל: הרצה 1)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _picking ? null : _pickImage,
          icon: _picking
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_bgBase64 == null ? Icons.image_outlined : Icons.check_circle_outline,
                  color: _bgBase64 == null ? AppColors.textSecondary : AppColors.accent2),
          label: Text(
            _bgBase64 == null ? 'העלה תמונת לוח מטלות' : 'תמונה נבחרה ✓',
            style: TextStyle(color: _bgBase64 == null ? AppColors.textSecondary : AppColors.accent2),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(context, {'title': title, 'bg': _bgBase64});
          },
          child: const Text('צור'),
        ),
      ],
    );
  }
}

// ─── Board editor ─────────────────────────────────────

class _DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _DrawStroke({required this.points, required this.color, required this.width});
}

class _BoardEditor extends StatefulWidget {
  final StrategyBoard board;
  const _BoardEditor({required this.board});

  @override
  State<_BoardEditor> createState() => _BoardEditorState();
}

class _BoardEditorState extends State<_BoardEditor> {
  late final List<_DrawStroke> _strokes;
  _DrawStroke? _current;
  Color _penColor = Colors.red;
  double _penWidth = 3.0;
  bool _saving = false;
  Uint8List? _bgBytes;

  static const _palette = [
    Color(0xFFFF4D4D), // red
    Color(0xFF3D7FFF), // blue
    Color(0xFF00D4A0), // green
    Color(0xFFF5C842), // yellow
    Color(0xFFFFFFFF), // white
    Color(0xFF000000), // black
  ];

  @override
  void initState() {
    super.initState();
    _strokes = widget.board.strokes.map((s) => _DrawStroke(
      points: s.points.map((p) => Offset(p.x, p.y)).toList(),
      color: Color(s.colorValue),
      width: s.width,
    )).toList();
    if (widget.board.backgroundBase64 != null) {
      _bgBytes = base64Decode(widget.board.backgroundBase64!);
    }
  }

  Future<void> _pickBackground() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _bgBytes = bytes);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prov = context.read<AppProvider>();
    final updated = StrategyBoard(
      id: widget.board.id,
      title: widget.board.title,
      backgroundBase64: _bgBytes != null ? base64Encode(_bgBytes!) : widget.board.backgroundBase64,
      strokes: _strokes.map((s) => DrawnStroke(
        points: s.points.map((o) => StrokePoint(o.dx, o.dy)).toList(),
        colorValue: s.color.toARGB32(),
        width: s.width,
      )).toList(),
      date: widget.board.date,
      author: widget.board.author,
    );
    await prov.updateStrategyBoard(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.board.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.image_outlined, color: AppColors.textSecondary),
            tooltip: 'שנה רקע',
            onPressed: _pickBackground,
          ),
          IconButton(
            icon: Icon(Icons.undo, color: _strokes.isEmpty ? AppColors.textTertiary : AppColors.textSecondary),
            tooltip: 'בטל',
            onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.removeLast()),
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: AppColors.red),
            tooltip: 'נקה הכל',
            onPressed: _strokes.isEmpty ? null : () => showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text('נקה לוח?', style: TextStyle(color: AppColors.textPrimary)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('נקה', style: TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            ).then((ok) { if (ok == true) setState(() => _strokes.clear()); }),
          ),
          _saving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text('שמור',
                      style: TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
        ],
      ),
      body: Column(children: [
        // ── Drawing canvas ──────────────────────────────
        Expanded(
          child: GestureDetector(
            onPanStart: (d) => setState(() {
              _current = _DrawStroke(
                points: [d.localPosition],
                color: _penColor,
                width: _penWidth,
              );
            }),
            onPanUpdate: (d) => setState(() => _current?.points.add(d.localPosition)),
            onPanEnd: (_) {
              if (_current != null) {
                _strokes.add(_current!);
                setState(() => _current = null);
              }
            },
            child: Stack(fit: StackFit.expand, children: [
              // Background
              if (_bgBytes != null)
                Image.memory(_bgBytes!, fit: BoxFit.contain)
              else
                Container(color: const Color(0xFF1A2235)),
              // Stroke layer
              CustomPaint(
                painter: _StrokePainter(strokes: _strokes, current: _current),
              ),
            ]),
          ),
        ),
        // ── Toolbar ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: AppColors.surface,
          child: Row(children: [
            // Color swatches
            ...List.generate(_palette.length, (i) => GestureDetector(
              onTap: () => setState(() => _penColor = _palette[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _palette[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _penColor == _palette[i] ? AppColors.accent : Colors.white24,
                    width: _penColor == _palette[i] ? 3 : 1,
                  ),
                ),
              ),
            )),
            const Spacer(),
            // Stroke width
            Icon(Icons.brush, color: AppColors.textSecondary, size: 16),
            SizedBox(
              width: 80,
              child: Slider(
                value: _penWidth,
                min: 2,
                max: 14,
                activeColor: _penColor,
                inactiveColor: AppColors.surface2,
                onChanged: (v) => setState(() => _penWidth = v),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Stroke painter ───────────────────────────────────
class _StrokePainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  final _DrawStroke? current;
  const _StrokePainter({required this.strokes, this.current});

  void _paint(Canvas canvas, _DrawStroke s) {
    if (s.points.length < 2) {
      // Single dot
      canvas.drawCircle(s.points.first, s.width / 2,
          Paint()..color = s.color..style = PaintingStyle.fill);
      return;
    }
    final paint = Paint()
      ..color = s.color
      ..strokeWidth = s.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
    for (final p in s.points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) _paint(canvas, s);
    if (current != null) _paint(canvas, current!);
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}
