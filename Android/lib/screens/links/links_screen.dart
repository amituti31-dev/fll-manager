import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

// ─── Category metadata ────────────────────────────────
class _Cat {
  final String id;
  final String label;
  final Color color;
  const _Cat(this.id, this.label, this.color);
}

const _cats = [
  _Cat('general',    '🌐 כללי',    AppColors.accent),
  _Cat('robot',      '🤖 רובוט',   AppColors.accent2),
  _Cat('innovation', '💡 חדשנות',  AppColors.gold),
  _Cat('judging',    '🎓 שיפוט',   AppColors.red),
];

// ─── Screen ───────────────────────────────────────────
class LinksScreen extends StatefulWidget {
  const LinksScreen({super.key});

  static void showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddLinkDialog(),
    );
  }

  @override
  State<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends State<LinksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _cats.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא ניתן לפתוח את הקישור'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('הקישור הועתק ✓'), backgroundColor: AppColors.accent2,
          duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _confirmDelete(AppProvider prov, LinkItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחק קישור', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('למחוק את "${item.title}"?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('מחק', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) await prov.deleteLink(item.id);
  }

  void _showItemMenu(BuildContext context, AppProvider prov, LinkItem item) {
    final canDelete = prov.isAdmin || item.addedBy == (prov.currentUser?.name ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.open_in_new, color: AppColors.accent),
            title: Text('פתח קישור', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () { Navigator.pop(context); _openUrl(item.url); },
          ),
          ListTile(
            leading: Icon(Icons.copy, color: AppColors.accent2),
            title: Text('העתק קישור', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () { Navigator.pop(context); _copyUrl(item.url); },
          ),
          if (canDelete)
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.red),
              title: Text('מחק', style: TextStyle(color: AppColors.red)),
              onTap: () { Navigator.pop(context); _confirmDelete(prov, item); },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Column(children: [
      // ── Tab bar ────────────────────────────────────
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: _cats.map((c) {
            final count = prov.links.where((l) => l.category == c.id).length;
            return Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c.label, style: const TextStyle(fontSize: 13)),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: c.color.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: TextStyle(fontSize: 11, color: c.color,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            );
          }).toList(),
        ),
      ),
      // ── Content ─────────────────────────────────────
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: _cats.map((c) {
            final items = prov.links.where((l) => l.category == c.id).toList();
            if (items.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.label.split(' ').first,
                    style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('אין קישורים עדיין',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
                const SizedBox(height: 6),
                Text('לחץ ➕ להוסיף קישור',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) => _LinkTile(
                item: items[i],
                color: c.color,
                onTap: () => _openUrl(items[i].url),
                onLongPress: () => _showItemMenu(context, prov, items[i]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

// ─── Link tile ────────────────────────────────────────
class _LinkTile extends StatelessWidget {
  final LinkItem item;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _LinkTile({
    required this.item, required this.color,
    required this.onTap, required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.link, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(item.url,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: color)),
            const SizedBox(height: 3),
            Text('${item.addedBy} · ${item.date}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ])),
          Icon(Icons.open_in_new, size: 16, color: AppColors.textTertiary),
        ]),
      ),
    );
  }
}

// ─── Add link dialog ──────────────────────────────────
class _AddLinkDialog extends StatefulWidget {
  const _AddLinkDialog();

  @override
  State<_AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<_AddLinkDialog> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl   = TextEditingController();
  String _category = 'general';
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('➕ הוסף קישור', style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'כותרת (למשל: חוקי FLL 2026)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlCtrl,
            style: TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.url,
            decoration: InputDecoration(hintText: 'https://...'),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _category,
            isExpanded: true,
            dropdownColor: AppColors.surface2,
            style: TextStyle(color: AppColors.textPrimary),
            items: _cats.map((c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.label),
            )).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'general'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            final title = _titleCtrl.text.trim();
            final url   = _urlCtrl.text.trim();
            if (title.isEmpty) {
              setState(() => _error = 'חובה להזין כותרת');
              return;
            }
            if (!url.startsWith('http')) {
              setState(() => _error = 'הקישור חייב להתחיל ב-http');
              return;
            }
            final prov = context.read<AppProvider>();
            await prov.addLink(LinkItem(
              id: DateTime.now().millisecondsSinceEpoch,
              title: title,
              url: url,
              category: _category,
              addedBy: prov.currentUser?.name ?? '',
              date: DateTime.now().toIso8601String().split('T')[0],
            ));
            if (mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: Text('הוסף'),
        ),
      ],
    );
  }
}
