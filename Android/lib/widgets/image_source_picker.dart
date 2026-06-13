import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet asking Camera vs Gallery, then returns the picked file.
Future<XFile?> pickImageWithSource(
  BuildContext context, {
  double maxWidth = 800,
  double maxHeight = 800,
  int quality = 75,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _SourceSheet(),
  );
  if (source == null) return null;
  return ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: quality,
  );
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _SourceBtn(
                icon: Icons.camera_alt_rounded,
                label: '📷 מצלמה',
                color: AppColors.accent,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SourceBtn(
                icon: Icons.photo_library_rounded,
                label: '🖼️ גלריה',
                color: AppColors.accent2,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ),
          ]),
          SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SourceBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ),
  );
}
