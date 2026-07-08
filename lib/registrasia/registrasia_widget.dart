import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'registrasia_model.dart';
export 'registrasia_model.dart';

enum _FieldState { neutral, valid, invalid }

class RegistrasiaWidget extends StatefulWidget {
  const RegistrasiaWidget({super.key});

  static String routeName = 'registrasia';
  static String routePath = '/registrasia';

  @override
  State<RegistrasiaWidget> createState() => _RegistrasiaWidgetState();
}

class _RegistrasiaWidgetState extends State<RegistrasiaWidget> {
  late RegistrasiaModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _blueDark = Color(0xFF1341B0);
  static const _text = Color(0xFF0F172A);
  static const _text2 = Color(0xFF475569);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFEF4444);
  static const _pageHPad = 24.0;
  static const _fieldHeight = 54.0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegistrasiaModel());

    _model.namefildTextController ??= TextEditingController();
    _model.namefildFocusNode ??= FocusNode();

    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.confirmPasswordTextController ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ---- derived validation state -------------------------------------

  String get _name => _model.namefildTextController?.text ?? '';
  String get _phone => _model.phoneTextController?.text ?? '';
  String get _password => _model.passwordTextController?.text ?? '';
  String get _confirm => _model.confirmPasswordTextController?.text ?? '';

  bool get _nameValid => _name.trim().isNotEmpty;
  bool get _phoneValid => functions.chekphonenumber(_phone) ?? false;
  bool get _passwordValid => functions.passlenth(_password) ?? false;
  bool get _confirmValid => _confirm.isNotEmpty && _confirm == _password;

  bool get _formValid =>
      _nameValid && _phoneValid && _passwordValid && _confirmValid;

  _FieldState get _nameState =>
      _name.isEmpty ? _FieldState.neutral : _FieldState.valid;
  _FieldState get _phoneState => _phone.isEmpty
      ? _FieldState.neutral
      : (_phoneValid ? _FieldState.valid : _FieldState.invalid);
  _FieldState get _passwordState => _password.isEmpty
      ? _FieldState.neutral
      : (_passwordValid ? _FieldState.valid : _FieldState.invalid);
  _FieldState get _confirmState => _confirm.isEmpty
      ? _FieldState.neutral
      : (_confirmValid ? _FieldState.valid : _FieldState.invalid);

  Color _borderColor(_FieldState s) {
    switch (s) {
      case _FieldState.valid:
        return _green;
      case _FieldState.invalid:
        return _red;
      case _FieldState.neutral:
        return _border;
    }
  }

  Color _iconColor(_FieldState s) {
    switch (s) {
      case _FieldState.valid:
        return _green;
      case _FieldState.invalid:
        return _red;
      case _FieldState.neutral:
        return _text3;
    }
  }

  // ---- header ---------------------------------------------------------

  Widget _header(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(_pageHPad - 4, topPad + 14, _pageHPad - 4, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5FE8), Color(0xFF1341B0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F1341B0),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Text(
              FFLocalizations.of(context).getText('j76pkpsz' /* Регистрация */),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- shared field chrome ---------------------------------------------

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _text2,
        ),
      ),
    );
  }

  Widget _hintRow(String text, _FieldState state) {
    final color = _iconColor(state);
    final icon = state == _FieldState.valid
        ? Icons.check_circle_rounded
        : state == _FieldState.invalid
            ? Icons.error_rounded
            : null;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: color, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _fieldDecoration(_FieldState state) {
    final borderColor = _borderColor(state);
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor,
        width: state == _FieldState.neutral ? 1 : 1.5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _stateSuffixIcon(_FieldState state) {
    if (state == _FieldState.neutral) return const SizedBox.shrink();
    return Icon(
      state == _FieldState.valid
          ? Icons.check_circle_rounded
          : Icons.error_rounded,
      color: _iconColor(state),
      size: 19,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required _FieldState state,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
    bool obscureText = false,
    bool? visibility,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: _fieldHeight,
      decoration: _fieldDecoration(state),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: _iconColor(state), size: 20),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged != null ? (_) => onChanged() : null,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: GoogleFonts.inter(fontSize: 15, color: _text),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: hint,
                hintStyle: GoogleFonts.inter(fontSize: 15, color: _text3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              validator: validator,
            ),
          ),
          if (onToggleVisibility != null) ...[
            InkWell(
              onTap: onToggleVisibility,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  visibility == true
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _text3,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          _stateSuffixIcon(state),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _phoneField() {
    final state = _phoneState;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: _fieldHeight,
      decoration: _fieldDecoration(state),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Text(
              FFLocalizations.of(context).getText('bxxhwa85' /* +7 */),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ),
          Container(width: 1, height: 22, color: _border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: TextFormField(
                controller: _model.phoneTextController,
                focusNode: _model.phoneFocusNode,
                onChanged: (_) => EasyDebounce.debounce(
                  '_model.phoneTextController',
                  const Duration(milliseconds: 150),
                  () => safeSetState(() {}),
                ),
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(fontSize: 15, color: _text),
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: FFLocalizations.of(context)
                      .getText('ehrfrdcl' /* телефон номер */),
                  hintStyle: GoogleFonts.inter(fontSize: 15, color: _text3),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                validator: _model.phoneTextControllerValidator
                    .asValidator(context),
              ),
            ),
          ),
          _stateSuffixIcon(state),
          const SizedBox(width: 14),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required Widget field,
    String? hint,
    _FieldState hintState = _FieldState.neutral,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          field,
          if (hint != null) _hintRow(hint, hintState),
        ],
      ),
    );
  }

  // ---- feedback --------------------------------------------------------

  void _showSnack(String text, {bool isError = true}) {
    final accent = isError ? _red : _green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: _text,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 3200),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent.withValues(alpha: 0.25)),
        ),
      ),
    );
  }

  Widget _termsConsentNotice(BuildContext context) {
    final baseStyle = GoogleFonts.inter(
      fontSize: 12,
      color: _text3,
      height: 1.45,
    );
    final linkStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _blue,
      decoration: TextDecoration.underline,
      decorationColor: _blue,
      height: 1.45,
    );

    Widget termsLink(String textKey) {
      return GestureDetector(
        onTap: () => context.pushNamed(PolitpageWidget.routeName),
        child: Text(
          FFLocalizations.of(context).getText(textKey),
          style: linkStyle,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              FFLocalizations.of(context).getText('rgstrm1ab'),
              style: baseStyle,
              textAlign: TextAlign.center,
            ),
            termsLink('rgstrm2cd'),
            Text(
              FFLocalizations.of(context).getText('rgstrm3ef'),
              style: baseStyle,
            ),
            termsLink('rgstrm4gh'),
          ],
        ),
      ),
    );
  }

  Future<void> _onSignUp() async {
    if (!_phoneValid) {
      _showSnack(FFLocalizations.of(context).getText('authphn1'));
      return;
    }
    if (!_passwordValid) {
      _showSnack(FFLocalizations.of(context).getText('authpwd8'));
      return;
    }
    if (!_confirmValid) {
      _showSnack(FFLocalizations.of(context).getText('authpwdf'));
      return;
    }

    FFAppState().emailstate = '${_model.phoneTextController.text}@app.com';
    FFAppState().hh1 = true;
    FFAppState().update(() {});
    GoRouter.of(context).prepareAuthEvent();

    final user = await authManager.createAccountWithEmail(
      context,
      valueOrDefault<String>(
        FFAppState().emailstate,
        'ssss@app.com',
      ),
      _model.passwordTextController.text,
    );
    if (user == null) {
      return;
    }

    await UserTable().insert({
      'nomer': FFAppState().emailstate,
      'id': currentUserUid,
      'pass': _model.passwordTextController.text,
      'name': _model.namefildTextController.text,
    });

    if (!mounted) return;
    context.pushNamedAuth(
      CreateListingPageCopyWidget.routeName,
      mounted,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _bg,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  _pageHPad,
                  22,
                  _pageHPad,
                  32,
                ),
                child: Form(
                  key: _model.formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(
                        label: FFLocalizations.of(context)
                            .getText('6x9p57c5' /* Имия */),
                        field: _textField(
                          controller: _model.namefildTextController!,
                          focusNode: _model.namefildFocusNode!,
                          hint: FFLocalizations.of(context)
                              .getText('6x9p57c5' /* Имия */),
                          icon: Icons.person_outline_rounded,
                          state: _nameState,
                          onChanged: () => EasyDebounce.debounce(
                            '_model.namefildTextController',
                            const Duration(milliseconds: 300),
                            () => safeSetState(() {}),
                          ),
                          validator: _model.namefildTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                      _field(
                        label: FFLocalizations.of(context)
                            .getText('ehrfrdcl' /* телефон номер */),
                        field: _phoneField(),
                        hint: _phoneState == _FieldState.valid
                            ? FFLocalizations.of(context).getText('authphok')
                            : _phoneState == _FieldState.invalid
                                ? FFLocalizations.of(context).getText('authphno')
                                : FFLocalizations.of(context).getText(
                                    '40hofkj8' /* Номер должен начинаться с 9 (б... */,
                                  ),
                        hintState: _phoneState,
                      ),
                      _field(
                        label: FFLocalizations.of(context)
                            .getText('iddpkkyn' /*    пароль */),
                        field: _textField(
                          controller: _model.passwordTextController!,
                          focusNode: _model.textFieldFocusNode1!,
                          hint: FFLocalizations.of(context)
                              .getText('iddpkkyn' /*    пароль */),
                          icon: Icons.lock_outline_rounded,
                          state: _passwordState,
                          obscureText: !_model.passwordVisibility1,
                          visibility: _model.passwordVisibility1,
                          onToggleVisibility: () => safeSetState(
                            () => _model.passwordVisibility1 =
                                !_model.passwordVisibility1,
                          ),
                          onChanged: () => EasyDebounce.debounce(
                            '_model.passwordTextController',
                            const Duration(milliseconds: 300),
                            () => safeSetState(() {}),
                          ),
                          validator: _model.passwordTextControllerValidator
                              .asValidator(context),
                        ),
                        hint: _passwordState == _FieldState.valid
                            ? FFLocalizations.of(context).getText('authpwds')
                            : _passwordState == _FieldState.invalid
                                ? FFLocalizations.of(context).getText('authpwds2')
                                : FFLocalizations.of(context).getText(
                                    'mjp8jm3a' /* пароль должень состаить миними... */,
                                  ),
                        hintState: _passwordState,
                      ),
                      _field(
                        label: FFLocalizations.of(context).getText(
                          'h5721474' /*   повторите пороль */,
                        ),
                        field: _textField(
                          controller: _model.confirmPasswordTextController!,
                          focusNode: _model.textFieldFocusNode2!,
                          hint: FFLocalizations.of(context).getText(
                            'h5721474' /*   повторите пороль */,
                          ),
                          icon: Icons.lock_outline_rounded,
                          state: _confirmState,
                          obscureText: !_model.passwordVisibility2,
                          visibility: _model.passwordVisibility2,
                          onToggleVisibility: () => safeSetState(
                            () => _model.passwordVisibility2 =
                                !_model.passwordVisibility2,
                          ),
                          onChanged: () => EasyDebounce.debounce(
                            '_model.confirmPasswordTextController',
                            const Duration(milliseconds: 300),
                            () => safeSetState(() {}),
                          ),
                          validator: _model
                              .confirmPasswordTextControllerValidator
                              .asValidator(context),
                        ),
                        hint: _confirmState == _FieldState.valid
                            ? FFLocalizations.of(context).getText('authpwdm')
                            : _confirmState == _FieldState.invalid
                                ? FFLocalizations.of(context).getText('authpwdf')
                                : FFLocalizations.of(context).getText('authpwdr'),
                        hintState: _confirmState,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _formValid
                                  ? const [
                                      Color(0xFF1E5FE8),
                                      Color(0xFF1341B0),
                                    ]
                                  : [
                                      _blue.withValues(alpha: 0.35),
                                      _blueDark.withValues(alpha: 0.35),
                                    ],
                            ),
                            boxShadow: _formValid
                                ? const [
                                    BoxShadow(
                                      color: Color(0x331A56DB),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _onSignUp,
                              child: Center(
                                child: Text(
                                  FFLocalizations.of(context).getText(
                                    'qy7d86gi' /* создать аккаунт */,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _termsConsentNotice(context),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            FFLocalizations.of(context)
                                .getText('xormy5ux' /* у меня есть  */),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _text2,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pushNamed(AvtoryzasiaWidget.routeName);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              FFLocalizations.of(context)
                                  .getText('s9u462x1' /* Акаунт */),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
