import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/services/app_update_service.dart';

class AppForceUpdateScreen extends StatelessWidget {
  const AppForceUpdateScreen({
    super.key,
    required this.result,
  });

  final AppUpdateCheckResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A56DB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                FFLocalizations.of(context).getVariableText(
                  ruText: 'Требуется обновление',
                  kyText: 'Жаңыртуу талап кылынат',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.currentVersion} → ${result.latestVersion}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => launchURL(result.storeUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A56DB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    FFLocalizations.of(context).getVariableText(
                      ruText: 'Обновить',
                      kyText: 'Жаңыртуу',
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppUpdateDialog {
  static Future<void> showSoft(
    BuildContext context,
    AppUpdateCheckResult result,
  ) async {
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            FFLocalizations.of(context).getVariableText(
              ruText: 'Доступно обновление',
              kyText: 'Жаңыртуу бар',
            ),
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            result.message,
            style: GoogleFonts.inter(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AppUpdateService.dismissSoftUpdate(result.latestVersion);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                FFLocalizations.of(context).getVariableText(
                  ruText: 'Позже',
                  kyText: 'Кийин',
                ),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () async {
                await launchURL(result.storeUrl);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                FFLocalizations.of(context).getVariableText(
                  ruText: 'Обновить',
                  kyText: 'Жаңыртуу',
                ),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
