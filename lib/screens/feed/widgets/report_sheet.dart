import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

const reportReasons = [
  'Konten tidak pantas',
  'Spam atau iklan',
  'Tidak sesuai tantangan',
  'Foto bukan milik sendiri',
  'Lainnya',
];

class ReportSheet extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onConfirm;
  const ReportSheet({super.key, required this.onClose, required this.onConfirm});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String _selected = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Laporkan Konten',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Pilih alasan pelaporan:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 14),
                  ...reportReasons.map((r) => GestureDetector(
                        onTap: () => setState(() => _selected = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: _selected == r
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selected == r
                                  ? AppColors.primary
                                  : AppColors.textMuted.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Text(r,
                              style: TextStyle(
                                color: _selected == r
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: _selected == r
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              )),
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            side: BorderSide(
                                color: AppColors.textMuted.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Batal',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selected.isEmpty
                              ? null
                              : () => widget.onConfirm(_selected),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            disabledBackgroundColor:
                                AppColors.textMuted.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text('Laporkan',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}