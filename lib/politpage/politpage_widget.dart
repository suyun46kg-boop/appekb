import 'dart:io';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/theme/ekb_breakpoints.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'politpage_model.dart';
export 'politpage_model.dart';

class PolitpageWidget extends StatefulWidget {
  const PolitpageWidget({super.key});

  static String routeName = 'politpage';
  static String routePath = '/politpage';

  @override
  State<PolitpageWidget> createState() => _PolitpageWidgetState();
}

class _PolitpageWidgetState extends State<PolitpageWidget> {
  late PolitpageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PolitpageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _sharePdf(BuildContext context) async {
    if (_isSharing) return;

    final box = context.findRenderObject() as RenderBox?;
    final originRect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromLTWH(0, 0, MediaQuery.sizeOf(context).width, 100);

    setState(() => _isSharing = true);

    try {
      final bytes = await rootBundle.load('assets/pdfs/privacy_policy.pdf');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/privacy_policy_ekbkg.pdf');
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              tempFile.path,
              mimeType: 'application/pdf',
              name: 'privacy_policy_ekbkg.pdf',
            )
          ],
          subject: 'Политика конфиденциальности EKBKG',
          sharePositionOrigin: originRect,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Политика конфиденциальности EKBKG:\nРазработчик: Алтынбек Абдираманов\nДата вступления: 20 июня 2026 г.\nКонтакты: suyun.46.kg@gmail.com',
          subject: 'Политика конфиденциальности EKBKG',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goNamed(DbddWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackground,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.primaryText,
          ),
          onPressed: _navigateBack,
        ),
        title: Text(
          'Политика конфиденциальности',
          style: theme.titleMedium.override(
            font: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
            ),
            color: theme.primaryText,
            fontSize: 18.0,
          ),
        ),
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.ios_share_rounded,
                    color: theme.primary,
                  ),
            tooltip: 'Поделиться PDF',
            onPressed: () => _sharePdf(context),
          ),
        ],
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: EkbBreakpoints.maxListWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Title & Metadata
                  Text(
                    'Политика конфиденциальности — EKBKG',
                    style: theme.headlineSmall.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                      ),
                      fontSize: 22.0,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Разработчик: Алтынбек Абдираманов • Дата вступления в силу: 20 июня 2026 г.',
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.inter(),
                      color: theme.secondaryText,
                      fontSize: 13.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // PDF Quick Action Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 26.0,
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Официальный документ PDF',
                                style: theme.bodyLarge.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  fontSize: 15.0,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                'Доступен для скачивания и отправки',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _sharePdf(context),
                          icon: const Icon(Icons.share, size: 16.0, color: Color(0xFF1D4ED8)),
                          label: Text(
                            'PDF',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1D4ED8),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Summary Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: theme.alternate),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: theme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Краткое резюме',
                              style: theme.titleSmall.override(
                                font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                color: theme.primaryText,
                                fontSize: 15.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Политика конфиденциальности приложения EKBKG регламентирует сбор личных данных (имя, контакты, геолокацию и фото) для регистрации, управления объявлениями и коммуникации пользователей.\n\n'
                          'Данные хранятся на защищённых серверах Supabase (AWS) и не передаются третьим лицам без согласия. Пользователь вправе удалить аккаунт (обработка запроса до 30 дней), получить копию данных или отказаться от использования приложения.\n\n'
                          'Контакты поддержки: suyun.46.kg@gmail.com',
                          style: theme.bodyMedium.override(
                            font: GoogleFonts.inter(),
                            color: theme.primaryText,
                            fontSize: 14.0,
                            lineHeight: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Section 1
                  _buildSectionHeader(theme, '1. Общие положения'),
                  _buildParagraph(
                    theme,
                    'Настоящая Политика конфиденциальности описывает, как приложение EKBKG собирает, '
                    'использует и защищает персональные данные пользователей.',
                  ),
                  const SizedBox(height: 16.0),

                  // Section 2
                  _buildSectionHeader(theme, '2. Какие данные мы собираем'),
                  _buildBullet(theme, 'Имя и фамилия — для профиля и отображения в объявлениях.'),
                  _buildBullet(theme, 'Адрес электронной почты — для авторизации и сервисных сообщений.'),
                  _buildBullet(theme, 'Номер телефона — для связи между покупателем и продавцом.'),
                  _buildBullet(theme, 'Местоположение (город) — выбирается пользователем вручную для фильтрации товаров.'),
                  _buildBullet(theme, 'Фотографии, загружаемые в объявления — для демонстрации предлагаемых товаров и услуг.'),
                  const SizedBox(height: 16.0),

                  // Section 3
                  _buildSectionHeader(theme, '3. Как мы используем данные'),
                  _buildBullet(theme, 'Для регистрации и авторизации пользователей.'),
                  _buildBullet(theme, 'Для размещения и отображения объявлений.'),
                  _buildBullet(theme, 'Для связи между покупателем и продавцом.'),
                  _buildBullet(theme, 'Для улучшения и оптимизации работы приложения.'),
                  _buildBullet(theme, 'Для обеспечения безопасности и модерации сообщества.'),
                  const SizedBox(height: 16.0),

                  // Section 4
                  _buildSectionHeader(theme, '4. Хранение данных'),
                  _buildParagraph(
                    theme,
                    'Данные хранятся на серверах Supabase и защищены в соответствии со стандартами '
                    'безопасности AWS (Amazon Web Services). Применяются технологии шифрования данных при передаче (HTTPS/TLS) '
                    'и строгие правила доступа на уровне строк (Row Level Security).',
                  ),
                  const SizedBox(height: 16.0),

                  // Section 5
                  _buildSectionHeader(theme, '5. Передача данных третьим лицам'),
                  _buildParagraph(
                    theme,
                    'Мы не продаём и не передаём ваши данные третьим лицам без вашего согласия. '
                    'Передача может производиться исключительно в предусмотренных законом случаях.',
                  ),
                  const SizedBox(height: 16.0),

                  // Section 6
                  _buildSectionHeader(theme, '6. Права пользователя. Удаление аккаунта'),
                  _buildParagraph(theme, 'Вы можете в любое время:'),
                  _buildBullet(
                    theme,
                    'Удалить аккаунт: в приложении откройте Профиль → Удалить аккаунт, либо отправьте запрос на suyun.46.kg@gmail.com, указав имя пользователя, email или номер телефона, привязанный к аккаунту. Запрос обрабатывается в течение 30 дней.',
                  ),
                  _buildBullet(theme, 'Запросить копию своих персональных данных.'),
                  _buildBullet(theme, 'Отказаться от использования сервиса.'),
                  const SizedBox(height: 16.0),

                  // Section 7
                  _buildSectionHeader(theme, '7. Контакты'),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('mailto:suyun.46.kg@gmail.com');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Color(0xFF2563EB), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'suyun.46.kg@gmail.com',
                            style: theme.bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                              color: const Color(0xFF2563EB),
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Section 8: Zero Tolerance EULA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '8. Правила сообщества и нулевая терпимость (EULA)',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF991B1B),
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Мы придерживаемся политики нулевой терпимости к неприемлемому контенту и оскорбительным действиям (There is no tolerance for objectionable content or abusive users). Любой неприемлемый контент или пользователи, нарушающие правила, будут немедленно заблокированы или удалены.',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF991B1B),
                            fontSize: 13.0,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Bottom Button to go back or continue
                  FFButtonWidget(
                    onPressed: _navigateBack,
                    text: 'Назад',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 50.0,
                      color: const Color(0xFF1877F2),
                      textStyle: theme.titleSmall.override(
                        font: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                      elevation: 0.0,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  const SizedBox(height: 30.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(FlutterFlowTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
      child: Text(
        text,
        style: theme.titleMedium.override(
          font: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
          color: theme.primaryText,
          fontSize: 16.0,
        ),
      ),
    );
  }

  Widget _buildParagraph(FlutterFlowTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: theme.bodyMedium.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
          fontSize: 14.0,
          lineHeight: 1.5,
        ),
      ),
    );
  }

  Widget _buildBullet(FlutterFlowTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: theme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                fontSize: 14.0,
                lineHeight: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
