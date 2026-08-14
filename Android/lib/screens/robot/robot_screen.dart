import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../services/tour_keys.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_source_picker.dart';
import '../../widgets/mission_extra_sheet.dart';
import '../scoring/scoring_screen.dart' show EditMissionsSheet;

class RobotScreen extends StatefulWidget {
  final void Function(int)? navigateTo;
  const RobotScreen({super.key, this.navigateTo});

  static void showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddImprovementSheet(),
    );
  }

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  String _filter = 'הכל';

  void _showEditMissions(BuildContext context, AppProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => EditMissionsSheet(prov: prov),
    );
  }

  void _showMissionExtraSheet(BuildContext context, Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => MissionExtraSheet(mission: m),
    );
  }

  Future<void> _pickAndImportMissionsJson(BuildContext context, AppProvider prov) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    String raw;
    try {
      raw = utf8.decode(result.files.single.bytes!);
    } catch (e) {
      if (mounted) _showImportError(context, 'קובץ לא תקין (קידוד לא נתמך)');
      return;
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (e) {
      if (mounted) _showImportError(context, 'קובץ JSON לא תקין: $e');
      return;
    }

    final validation = _validateMissionsJson(parsed);
    if (validation.error != null) {
      if (mounted) _showImportError(context, validation.error!);
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MissionImportPreviewSheet(
        missions: validation.missions!,
        extras: validation.extras!,
        season: validation.season,
        prov: prov,
      ),
    );
  }

  void _showImportError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('⚠️ ייבוא נכשל', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('סגור')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final done = prov.doneMissions;
    final total = prov.missions.length;
    final imagesOnly = prov.improvements.where((i) => i.imageBase64 != null).toList();

    final filtered = _filter == 'הושלמו'
        ? prov.missions.where((m) => prov.missionChecks[m.id] == true).toList()
        : _filter == 'לא הושלמו'
            ? prov.missions.where((m) => prov.missionChecks[m.id] != true).toList()
            : prov.missions;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Progress header
      Container(
        key: TourKeys.robotProgressHeader,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0x1A3D7FFF), Color(0x0A00D4A0)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Text('🤖', style: TextStyle(fontSize: 36)),
          SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('תכנון רובוט', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
            Text('$done/$total משימות הושלמו', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? done / total : 0, minHeight: 6,
                backgroundColor: AppColors.surface3,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ])),
        ]),
      ),
      SizedBox(height: 12),

      // Shortcut buttons
      Row(children: [
        Expanded(
          child: _ShortcutBtn(
            icon: '⏱️',
            label: 'טיימר ריצה',
            color: AppColors.accent,
            onTap: () => widget.navigateTo?.call(3),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ShortcutBtn(
            icon: '🎯',
            label: 'ניקוד רובוט',
            color: AppColors.accent2,
            onTap: () => widget.navigateTo?.call(3),
          ),
        ),
      ]),
      SizedBox(height: 16),

      // Missions section header
      Row(children: [
        Text('⛏️', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Expanded(
          child: Text('$total משימות – Unearthed 2026',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        ),
        if (prov.isAdmin)
          GestureDetector(
            onTap: () => _pickAndImportMissionsJson(context, prov),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withAlpha(80)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.file_upload, size: 12, color: AppColors.gold),
                SizedBox(width: 4),
                Text('ייבא JSON', style: TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        if (prov.isAdmin)
          GestureDetector(
            onTap: () => _showEditMissions(context, prov),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withAlpha(80)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit, size: 12, color: AppColors.accent),
                SizedBox(width: 4),
                Text('ערוך', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ]),
      SizedBox(height: 10),

      // Filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final f in ['הכל', 'הושלמו', 'לא הושלמו'])
            GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _filter == f ? AppColors.accent : AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _filter == f ? AppColors.accent : AppColors.border),
                ),
                child: Text(f, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _filter == f ? Colors.white : AppColors.textSecondary,
                )),
              ),
            ),
        ]),
      ),
      SizedBox(height: 10),

      // Missions grid
      GridView.builder(
        key: TourKeys.robotMissionsGrid,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final m = filtered[i];
          final isDone = prov.missionChecks[m.id] == true;
          final extra = prov.missionExtra[m.id];
          final hasNotes = extra != null && (extra.bonus.isNotEmpty || extra.rules.isNotEmpty || extra.bonusDone);
          return Stack(children: [
            GestureDetector(
              onTap: () => context.read<AppProvider>().toggleMission(m.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.accent2.withAlpha(20) : AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDone ? AppColors.accent2 : AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(
                      isDone ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 18,
                      color: isDone ? AppColors.accent2 : AppColors.border,
                    ),
                    Text('⛏️', style: TextStyle(fontSize: 18)),
                  ]),
                  const Spacer(),
                  Text(
                    m.name.contains('–') ? m.name.split('–').last.trim() : m.name,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isDone ? AppColors.accent2 : AppColors.textPrimary),
                    textAlign: TextAlign.end,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text('${m.pts} נק\'', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace',
                    color: isDone ? AppColors.accent2 : AppColors.textTertiary,
                  )),
                ]),
              ),
            ),
            Positioned(
              bottom: 4, left: 4,
              child: GestureDetector(
                onTap: () => _showMissionExtraSheet(context, m),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasNotes ? AppColors.gold.withAlpha(50) : Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    border: hasNotes ? Border.all(color: AppColors.gold, width: 1) : null,
                  ),
                  child: Text(extra?.bonusDone == true ? '🎁' : '📝', style: TextStyle(fontSize: 11)),
                ),
              ),
            ),
          ]);
        },
      ),
      SizedBox(height: 20),

      // Improvements gallery header
      Row(key: TourKeys.robotGallerySection, children: [
        const _SectionTitle('📸', 'תמונות שיפורים'),
        const Spacer(),
        if (imagesOnly.length >= 2)
          TextButton.icon(
            onPressed: () => _showSlideshow(context, imagesOnly),
            icon: Icon(Icons.slideshow, size: 16, color: AppColors.accent3),
            label: Text('סרטון', style: TextStyle(color: AppColors.accent3, fontSize: 13)),
          ),
        TextButton.icon(
          onPressed: () => RobotScreen.showAddDialog(context),
          icon: Icon(Icons.add, size: 16, color: AppColors.accent2),
          label: Text('הוסף', style: TextStyle(color: AppColors.accent2, fontSize: 13)),
        ),
      ]),
      SizedBox(height: 8),

      // Gallery
      imagesOnly.isEmpty
          ? GestureDetector(
              onTap: () => RobotScreen.showAddDialog(context),
              child: Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface2, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('📷', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 6),
                  Text('הוסף תמונות שיפורים', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ]),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
              itemCount: imagesOnly.length,
              itemBuilder: (_, i) {
                final imp = imagesOnly[i];
                return GestureDetector(
                  onTap: () => _showImageDetail(context, imp, i, imagesOnly),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(fit: StackFit.expand, children: [
                      _ImprovementImage(imageBase64: imp.imageBase64!),
                      if (prov.isAdmin)
                        Positioned(top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => context.read<AppProvider>().deleteImprovement(imp.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                              child: Text('🗑️', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                      Positioned(bottom: 0, left: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          color: Colors.black54,
                          child: Text(imp.name, style: TextStyle(color: Colors.white, fontSize: 10),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
    ]);
  }

  static void _showSlideshow(BuildContext context, List<Improvement> images) {
    showDialog(
      context: context,
      builder: (_) => _SlideshowDialog(improvements: images),
    );
  }

  static void _showImageDetail(BuildContext context, Improvement imp, int index, List<Improvement> all) {
    showDialog(
      context: context,
      builder: (_) => _SlideshowDialog(improvements: all, initialIndex: index, autoPlay: false),
    );
  }
}

// ─── Image Widget ─────────────────────────────────────

class _ImprovementImage extends StatelessWidget {
  final String imageBase64;
  const _ImprovementImage({required this.imageBase64});

  @override
  Widget build(BuildContext context) {
    try {
      final raw = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
      final bytes = base64Decode(raw);
      return Image.memory(bytes, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
    color: AppColors.surface3,
    alignment: Alignment.center,
    child: Text('🖼️', style: TextStyle(fontSize: 32)),
  );
}

// ─── Slideshow Dialog ─────────────────────────────────

class _SlideshowDialog extends StatefulWidget {
  final List<Improvement> improvements;
  final int initialIndex;
  final bool autoPlay;
  const _SlideshowDialog({required this.improvements, this.initialIndex = 0, this.autoPlay = true});

  @override
  State<_SlideshowDialog> createState() => _SlideshowDialogState();
}

class _SlideshowDialogState extends State<_SlideshowDialog> {
  late PageController _pageCtrl;
  late int _current;
  Timer? _timer;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
    if (widget.autoPlay) _startPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startPlay() {
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_current < widget.improvements.length - 1) {
        _current++;
        _pageCtrl.animateToPage(_current,
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        setState(() {});
      } else {
        _timer?.cancel();
        setState(() => _playing = false);
      }
    });
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      if (_current == widget.improvements.length - 1) {
        _current = 0;
        _pageCtrl.jumpToPage(0);
      }
      _startPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Text('${_current + 1}/${widget.improvements.length}',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // Images
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.improvements.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final imp = widget.improvements[i];
                return Column(children: [
                  Expanded(
                    child: _ImprovementImage(imageBase64: imp.imageBase64!),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Text(imp.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      if (imp.desc.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(imp.desc, style: TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
                      ],
                    ]),
                  ),
                ]);
              },
            ),
          ),

          // Progress dots + controls
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < widget.improvements.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                width: i == _current ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _current ? AppColors.accent : Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ]),

          if (widget.improvements.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white, size: 44),
                onPressed: _togglePlay,
              ),
            ),
        ]),
      ),
    );
  }
}

// ─── Add Improvement Sheet ────────────────────────────

class _AddImprovementSheet extends StatefulWidget {
  const _AddImprovementSheet();
  @override
  State<_AddImprovementSheet> createState() => _AddImprovementSheetState();
}

class _AddImprovementSheetState extends State<_AddImprovementSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _imageBase64;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final file = await pickImageWithSource(
        context,
        maxWidth: 800, maxHeight: 800, quality: 70,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final prov = context.read<AppProvider>();
    await prov.addImprovement(Improvement(
      id: DateTime.now().millisecondsSinceEpoch,
      name: _nameCtrl.text.trim(),
      desc: _descCtrl.text.trim(),
      missionId: '',
      imageBase64: _imageBase64,
      date: DateTime.now().toIso8601String().split('T')[0],
      author: prov.currentUser?.name ?? 'אנונימי',
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🔧 הוסף שיפור רובוט',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 16),
        TextField(controller: _nameCtrl, autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'שם השיפור *')),
        SizedBox(height: 8),
        TextField(controller: _descCtrl, maxLines: 2,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'תיאור (אופציונלי)')),
        SizedBox(height: 12),

        // Image picker
        GestureDetector(
          onTap: _pickingImage ? null : _pickImage,
          child: Container(
            width: double.infinity,
            height: _imageBase64 != null ? 160 : 80,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _imageBase64 != null ? AppColors.accent2 : AppColors.border),
            ),
            child: _pickingImage
                ? Center(child: CircularProgressIndicator(color: AppColors.accent2))
                : _imageBase64 != null
                    ? Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _ImprovementImage(imageBase64: _imageBase64!),
                        ),
                        Positioned(top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageBase64 = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate, color: AppColors.textTertiary, size: 28),
                        SizedBox(height: 6),
                        Text('הוסף תמונה (אופציונלי)', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ]),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent2),
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור'),
          ),
        ),
      ]),
    );
  }
}

// ─── Mission JSON Import ──────────────────────────────
//
// Validates a { season, missions:[{id,name,pts,bonus?,rules?},...] } file
// (produced externally — there is no in-app AI/Cloud Function). bonus/rules
// are optional free text, pre-filled into missionExtra on confirm (the same
// fields the "📝 בונוס/חוקים" sheet edits by hand). On confirm this fully
// replaces the mission list; AppProvider.replaceMissions() resets
// missionChecks/missionExtra too, since imported ids have no guaranteed
// relationship to the previous set.

class _MissionValidationResult {
  final String? error;
  final List<Mission>? missions;
  final Map<int, MissionExtra>? extras;
  final String? season;
  _MissionValidationResult.error(String message)
      : error = message, missions = null, extras = null, season = null;
  _MissionValidationResult.ok(List<Mission> m, Map<int, MissionExtra> e, String? s)
      : error = null, missions = m, extras = e, season = s;
}

_MissionValidationResult _validateMissionsJson(dynamic raw) {
  if (raw is! Map || raw['missions'] is! List) {
    return _MissionValidationResult.error('מבנה קובץ לא תקין — נדרש אובייקט עם שדה missions (מערך)');
  }
  final rawMissions = raw['missions'] as List;
  if (rawMissions.length < 10) {
    return _MissionValidationResult.error('מספר משימות נמוך מדי (${rawMissions.length}) — נדרשות לפחות 10');
  }
  final seenIds = <int>{};
  final cleaned = <Mission>[];
  final extras = <int, MissionExtra>{};
  for (int i = 0; i < rawMissions.length; i++) {
    final m = rawMissions[i];
    if (m is! Map) return _MissionValidationResult.error('משימה #${i + 1} אינה אובייקט תקין');
    final idRaw = m['id'];
    final id = idRaw is num ? idRaw.toInt() : int.tryParse('$idRaw');
    final name = (m['name'] is String) ? (m['name'] as String).trim() : '';
    final ptsRaw = m['pts'];
    final pts = ptsRaw is num ? ptsRaw.toDouble() : double.tryParse('$ptsRaw');
    if (id == null || id <= 0) return _MissionValidationResult.error('משימה #${i + 1}: מזהה (id) לא תקין');
    if (seenIds.contains(id)) return _MissionValidationResult.error('מזהה משימה כפול: $id');
    if (name.isEmpty) return _MissionValidationResult.error('משימה #${i + 1}: חסר שם');
    if (pts == null || pts < 0 || pts > 200) return _MissionValidationResult.error('משימה #${i + 1}: ניקוד לא סביר ($ptsRaw)');
    seenIds.add(id);
    cleaned.add(Mission(id: id, name: name.length > 200 ? name.substring(0, 200) : name, pts: pts.round()));
    final bonus = (m['bonus'] is String) ? (m['bonus'] as String).trim() : '';
    final rules = (m['rules'] is String) ? (m['rules'] as String).trim() : '';
    final bonusPtsRaw = m['bonusPts'];
    final bonusPtsNum = bonusPtsRaw is num ? bonusPtsRaw : num.tryParse('$bonusPtsRaw');
    final bonusPts = (bonusPtsNum != null && bonusPtsNum > 0 && bonusPtsNum <= 200) ? bonusPtsNum.round() : 0;
    if (bonus.isNotEmpty || rules.isNotEmpty || bonusPts > 0) {
      extras[id] = MissionExtra(
        bonus: bonus.length > 1000 ? bonus.substring(0, 1000) : bonus,
        bonusPts: bonusPts,
        rules: rules.length > 1000 ? rules.substring(0, 1000) : rules,
      );
    }
  }
  final rawSeason = (raw['season'] is String) ? (raw['season'] as String).trim() : '';
  final season = rawSeason.isEmpty ? null : (rawSeason.length > 100 ? rawSeason.substring(0, 100) : rawSeason);
  return _MissionValidationResult.ok(cleaned, extras, season);
}

class _MissionImportPreviewSheet extends StatefulWidget {
  final List<Mission> missions;
  final Map<int, MissionExtra> extras;
  final String? season;
  final AppProvider prov;
  const _MissionImportPreviewSheet({required this.missions, required this.extras, required this.season, required this.prov});

  @override
  State<_MissionImportPreviewSheet> createState() => _MissionImportPreviewSheetState();
}

class _MissionImportPreviewSheetState extends State<_MissionImportPreviewSheet> {
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    await widget.prov.replaceMissions(widget.missions, extras: widget.extras);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              widget.season != null ? '📥 ייבוא משימות — ${widget.season}' : '📥 ייבוא משימות מ-JSON',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withAlpha(90)),
              ),
              child: Text(
                '⚠️ פעולה זו תחליף את כל המשימות הקיימות ב-${widget.missions.length} המשימות שלהלן, ותאפס את כל הסימונים שנעשו על המשימות הישנות (כולל בונוסים וחוקים נוספים). לא ניתן לבטל לאחר האישור.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ]),
        ),
        Divider(color: AppColors.border, height: 1),
        Expanded(
          child: ListView.separated(
            controller: scroll,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: widget.missions.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1),
            itemBuilder: (_, i) {
              final m = widget.missions[i];
              final hasExtra = widget.extras.containsKey(m.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Text(
                    hasExtra ? '${m.name} 🎁' : m.name,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                  Text('${m.pts} נק\'', style: TextStyle(
                    fontSize: 12, color: AppColors.accent2, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: Text('ביטול'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent2),
                child: _saving
                    ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('✅ אשר והחלף'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ShortcutBtn extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ShortcutBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: TextStyle(fontSize: 16)),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;
  const _SectionTitle(this.icon, this.title);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: TextStyle(fontSize: 18)),
    SizedBox(width: 8),
    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
  ]);
}
