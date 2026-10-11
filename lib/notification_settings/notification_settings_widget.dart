import '/dbdd/category_block_background.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/theme/ekb_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/category_subscriptions.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  static String routeName = 'notificationSettings';
  static String routePath = '/notification-settings';

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _text2 = Color(0xFF475569);
  static const _divider = Color(0xFFEEF1F6);
  static const _pageHPad = 20.0;

  /// (id категории, картинка, ключ перевода названия).
  static const _categories = [
    (3, 'assets/images/categories/category_apartment.png', 'cukp48gd'),
    (2, 'assets/images/categories/category_job.png', 'me5sh2dc'),
    (14, 'assets/images/categories/category_border.png', '4lwpgqmm'),
    (1, 'assets/images/categories/category_auto.png', 'r4qsbrdp'),
    (13, 'assets/images/categories/category_entertainment.png', 'vp95t6yz'),
    (4, 'assets/images/categories/category_services.png', 'ccc9cors'),
    (9, 'assets/images/categories/category_sale_v2.png', 'pnpqtuk7'),
    (5, 'assets/images/categories/category_parttime.png', 'noun7do1'),
  ];

  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadSelected();
  }

  Future<void> _loadSelected() async {
    final ids = await CategorySubscriptions.load();
    if (!mounted) return;
    setState(() => _selected.addAll(ids));
  }

  String _t(String ru, String ky) =>
      FFLocalizations.of(context).getVariableText(ruText: ru, kyText: ky);

  String _categoryName(String key) {
    final name = FFLocalizations.of(context).getText(key);
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _save() async {
    // Оставляем подписки на категории, которых нет в этом списке.
    final known = _categories.map((c) => c.$1).toSet();
    final others = (await CategorySubscriptions.load()).difference(known);
    await CategorySubscriptions.save({...others, ..._selected});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('Настройки сохранены', 'Жөндөөлөр сакталды')),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.safePop();
  }

  Widget _header(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return EkbAppBarBackground(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      padding: EdgeInsets.fromLTRB(_pageHPad, topPad + 12, _pageHPad, 28),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: EkbBreakpoints.maxFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.safePop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _t('Уведомления', 'Билдирмелер'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _t(
                  'Включите категории, которые вам важны',
                  'Сиз үчүн маанилүү категорияларды күйгүзүңүз',
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(int index) {
    final (id, asset, nameKey) = _categories[index];
    final on = _selected.contains(id);
    final isLast = index == _categories.length - 1;

    return InkWell(
      onTap: () => _toggle(id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border:
              isLast ? null : const Border(bottom: BorderSide(color: _divider)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF5F5F7),
                child: Image.asset(asset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _categoryName(nameKey),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
            ),
            Switch.adaptive(
              value: on,
              activeTrackColor: _blue,
              onChanged: (_) => _toggle(id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final count = _selected.length;
    final total = _categories.length;

    return Container(
      padding: EdgeInsets.fromLTRB(
        _pageHPad,
        12,
        _pageHPad,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: EkbBreakpoints.maxFormWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count > 0
                    ? _t('Включено категорий: $count из $total',
                        'Күйгүзүлгөн категориялар: $count / $total')
                    : _t('Ни одна категория не включена',
                        'Бир да категория күйгүзүлгөн жок'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _text2,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _text,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _t('Готово', 'Даяр'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _header(context),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: EkbBreakpoints.maxFormWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _pageHPad, 12, _pageHPad, 16),
                        child: Column(
                          children: [
                            for (var i = 0; i < _categories.length; i++)
                              _row(i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }
}
