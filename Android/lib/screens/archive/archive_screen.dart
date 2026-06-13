import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final archives = prov.archives.reversed.toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Header
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('📦', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('ארכיון עונות', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          ]),
          SizedBox(height: 6),
          Text('${archives.length} עונות בארכיון',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ),
      SizedBox(height: 16),

      // Archive current season (admins only)
      if (prov.isAdmin) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('📸', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('עונה נוכחית', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
            ]),
            SizedBox(height: 8),
            Text('עונה: ${prov.currentSeason}',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('חברים: ${prov.members.length}  |  שיא: ${prov.bestScore} נק\'  |  ריצות: ${prov.scores.length}',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmArchive(context, prov),
                icon: Text('📦'),
                label: Text('שמור עונה בארכיון'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        SizedBox(height: 16),
      ],

      // Archives list
      if (archives.isEmpty)
        Container(
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('📦', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('אין עונות בארכיון', style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
            SizedBox(height: 4),
            Text('לחץ "שמור עונה בארכיון" לשמירת העונה הנוכחית',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                textAlign: TextAlign.center),
          ]),
        )
      else ...[
        Row(children: [
          Text('📋', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('עונות שמורות', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        ]),
        SizedBox(height: 10),
        for (final archive in archives)
          _ArchiveCard(archive: archive, isAdmin: prov.isAdmin),
      ],
    ]);
  }

  static Future<void> _confirmArchive(BuildContext context, AppProvider prov) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('שמור עונה', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'לשמור את עונת "${prov.currentSeason}" בארכיון?\n\nהנתונים הנוכחיים יצולמו ויישמרו.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('שמור')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await prov.archiveCurrentSeason();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('העונה נשמרה בארכיון ✓'),
              backgroundColor: AppColors.accent2),
        );
      }
    }
  }
}

// ─── Archive Card ─────────────────────────────────────

class _ArchiveCard extends StatelessWidget {
  final ArchivedSeason archive;
  final bool isAdmin;
  const _ArchiveCard({required this.archive, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Text('📦', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(archive.seasonName,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
              Text('נארכב ב-${archive.archivedDate} ע"י ${archive.archivedBy}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            if (isAdmin)
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Text('🗑️', style: TextStyle(fontSize: 16)),
              ),
          ]),
        ),

        // Stats grid
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            _StatBox('👥', '${archive.memberCount}', 'חברים'),
            SizedBox(width: 8),
            _StatBox('🏆', '${archive.bestScore}', 'שיא נק\''),
            SizedBox(width: 8),
            _StatBox('▶', '${archive.runsCount}', 'ריצות'),
            SizedBox(width: 8),
            _StatBox('🔧', '${archive.improvementsCount}', 'שיפורים'),
          ]),
        ),

        // Export row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.download, size: 13, color: AppColors.textTertiary),
              SizedBox(width: 4),
              Text('ייצוא נתונים:', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ]),
            SizedBox(height: 6),
            Row(children: [
              _ExportBtn(label: 'JSON', color: AppColors.accent,
                  onTap: () => _exportJson(context)),
              SizedBox(width: 8),
              _ExportBtn(label: 'CSV', color: AppColors.accent2,
                  onTap: () => _exportCsv(context)),
              SizedBox(width: 8),
              _ExportBtn(label: 'PDF', color: AppColors.accent3,
                  onTap: () => _exportPdf(context)),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחיקת ארכיון', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('למחוק את ארכיון "${archive.seasonName}"?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteArchive(archive.id);
              Navigator.pop(context);
            },
            child: Text('מחק', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  // ── JSON export ──────────────────────────────────────
  Future<void> _exportJson(BuildContext context) async {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(archive.toMap());
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${archive.seasonName}_export.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'FLL Archive – ${archive.seasonName}',
      );
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // ── CSV export ───────────────────────────────────────
  Future<void> _exportCsv(BuildContext context) async {
    try {
      final buf = StringBuffer();
      buf.writeln('Field,Value');
      buf.writeln('"Season Name","${archive.seasonName}"');
      buf.writeln('"Archived Date","${archive.archivedDate}"');
      buf.writeln('"Archived By","${archive.archivedBy}"');
      buf.writeln('"Members",${archive.memberCount}');
      buf.writeln('"Best Score",${archive.bestScore}');
      buf.writeln('"Runs",${archive.runsCount}');
      buf.writeln('"Improvements",${archive.improvementsCount}');
      buf.writeln('"Logs",${archive.logsCount}');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${archive.seasonName}_export.csv');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'FLL Archive – ${archive.seasonName}',
      );
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // ── PDF export ───────────────────────────────────────
  Future<void> _exportPdf(BuildContext context) async {
    try {
      final doc = pw.Document();
      final stats = [
        ['Members', '${archive.memberCount}'],
        ['Best Score', '${archive.bestScore} pts'],
        ['Runs', '${archive.runsCount}'],
        ['Improvements', '${archive.improvementsCount}'],
        ['Logs', '${archive.logsCount}'],
      ];

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue800,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('FLL Team Manager – Season Archive',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Season: ${archive.seasonName}',
                    style: pw.TextStyle(color: PdfColors.grey300, fontSize: 13)),
              ]),
            ),
            pw.SizedBox(height: 24),

            pw.Text('Archive Info',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Field', 'Value'],
              data: [
                ['Season Name', archive.seasonName],
                ['Archived Date', archive.archivedDate],
                ['Archived By', archive.archivedBy],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue700),
              cellStyle: const pw.TextStyle(fontSize: 11),
              border: pw.TableBorder.all(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 20),

            pw.Text('Statistics',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Metric', 'Value'],
              data: stats,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColors.teal700),
              cellStyle: const pw.TextStyle(fontSize: 11),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text('Generated by FLL Team Manager – Unearthed 2026',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9)),
          ],
        ),
      ));

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: '${archive.seasonName}_export.pdf',
      );
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('שגיאה: $msg'), backgroundColor: AppColors.red),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────

class _ExportBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ExportBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: color,
      )),
    ),
  );
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatBox(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Text(icon, style: TextStyle(fontSize: 16)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ),
  );
}
