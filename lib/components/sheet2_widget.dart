import '/backend/category_utils.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sheet2_model.dart';
export 'sheet2_model.dart';

class Sheet2Widget extends StatefulWidget {
  const Sheet2Widget({super.key});

  @override
  State<Sheet2Widget> createState() => _Sheet2WidgetState();
}

class _Sheet2WidgetState extends State<Sheet2Widget> {
  late Sheet2Model _model;
  late final Future<List<CategoriesRow>> _categoriesFuture;

  /// null = список корневых; иначе выбранный корень (ждём подкатегорию).
  CategoriesRow? _selectedRoot;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Sheet2Model());
    _categoriesFuture = CategoriesTable().queryRows(
      queryFn: (q) => q.order('id1', ascending: true),
    );
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  void _selectCategory(CategoriesRow cat, {CategoriesRow? parent}) {
    final label = parent == null ? cat.name : '${parent.name} · ${cat.name}';
    FFAppState().update(() {
      FFAppState().valuecategoryshit = label;
      FFAppState().idcategorysheet = cat.id1;
    });
    Navigator.pop(context);
  }

  List<CategoriesRow> _roots(List<CategoriesRow> all) =>
      all.where((c) => c.isRoot).toList();

  List<CategoriesRow> _childrenOf(List<CategoriesRow> all, int parentId1) =>
      all.where((c) => c.parentId1 == parentId1).toList();

  Widget _row({
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: FlutterFlowTheme.of(context).secondaryBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 20.0,
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 1.0,
                color: const Color(0x22000000),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showingSubs = _selectedRoot != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                if (showingSubs)
                  IconButton(
                    onPressed: () => setState(() => _selectedRoot = null),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    showingSubs
                        ? _selectedRoot!.name
                        : FFLocalizations.of(context).getText('clselcat'),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_sharp,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CategoriesRow>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 50.0,
                      height: 50.0,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  );
                }

                final all = snapshot.data!;
                final items = showingSubs
                    ? _childrenOf(all, _selectedRoot!.id1)
                    : _roots(all);

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        FFLocalizations.of(context).getText('catemp1'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final cat = items[index];
                    return _row(
                      title: cat.name,
                      onTap: () {
                        if (showingSubs) {
                          _selectCategory(cat, parent: _selectedRoot);
                          return;
                        }
                        final children = _childrenOf(all, cat.id1);
                        if (children.isNotEmpty ||
                            kCategoriesRequiringSubcategory.contains(cat.id1)) {
                          if (children.isEmpty) {
                            // Подкатегории ещё не в БД — не даём выбрать корень.
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  FFLocalizations.of(context)
                                      .getText('clerrsub'),
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _selectedRoot = cat);
                          return;
                        }
                        _selectCategory(cat);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
