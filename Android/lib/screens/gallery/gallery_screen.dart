import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_source_picker.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _adding = false;

  Future<void> _addPhoto(AppProvider prov) async {
    setState(() => _adding = true);
    try {
      final picked = await pickImageWithSource(
        context,
        maxWidth: 1200, maxHeight: 1200, quality: 50,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);

      final caption = await _getCaptionDialog();
      if (!mounted) return;

      await prov.addGalleryItem(GalleryItem(
        id: DateTime.now().millisecondsSinceEpoch,
        imageBase64: b64,
        caption: caption ?? '',
        date: DateTime.now().toIso8601String().split('T')[0],
        author: prov.currentUser?.name ?? '',
      ));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<String?> _getCaptionDialog() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _CaptionDialog(),
    );
  }

  Future<void> _deleteItem(AppProvider prov, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחק תמונה', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('האם למחוק תמונה זו?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('מחק', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await prov.deleteGalleryItem(id);
  }

  void _viewPhoto(GalleryItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Builder(builder: (_) {
              try {
                return Image.memory(base64Decode(item.imageBase64), fit: BoxFit.contain);
              } catch (_) {
                return SizedBox(
                  height: 200,
                  child: Center(child: Text('שגיאה', style: TextStyle(color: Colors.white))),
                );
              }
            }),
            if (item.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(item.caption,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('${item.author} · ${item.date}',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Expanded(child: Text(
            '${prov.gallery.length} תמונות',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          )),
          ElevatedButton.icon(
            onPressed: _adding ? null : () => _addPhoto(prov),
            icon: _adding
                ? SizedBox(height: 14, width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('📷'),
            label: Text('הוסף תמונה'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ]),
      ),
      Expanded(
        child: prov.gallery.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('🖼️', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('אין תמונות בגלריה',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                SizedBox(height: 6),
                Text('הוסף תמונות מהאימונים והתחרות',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ]))
            : GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
                ),
                itemCount: prov.gallery.length,
                itemBuilder: (_, i) {
                  final item = prov.gallery[i];
                  final canDelete = prov.isAdmin || item.author == (prov.currentUser?.name ?? '');
                  return GestureDetector(
                    onTap: () => _viewPhoto(item),
                    onLongPress: canDelete ? () => _deleteItem(prov, item.id) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(fit: StackFit.expand, children: [
                        Builder(builder: (_) {
                          try {
                            return Image.memory(
                              base64Decode(item.imageBase64),
                              fit: BoxFit.cover,
                              cacheWidth: 300,
                            );
                          } catch (_) {
                            return Container(
                              color: AppColors.surface2,
                              child: Icon(Icons.broken_image, color: AppColors.textTertiary),
                            );
                          }
                        }),
                        if (item.caption.isNotEmpty)
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                              color: Colors.black54,
                              child: Text(item.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _CaptionDialog extends StatefulWidget {
  const _CaptionDialog();

  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
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
      title: Text('כיתוב לתמונה', style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _ctrl,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(hintText: 'כיתוב (אופציונלי)'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: Text('דלג')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text('שמור'),
        ),
      ],
    );
  }
}
