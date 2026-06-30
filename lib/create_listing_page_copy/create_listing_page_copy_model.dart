import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/sheet2_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/index.dart';
import 'create_listing_page_copy_widget.dart' show CreateListingPageCopyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateListingPageCopyModel
    extends FlutterFlowModel<CreateListingPageCopyWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for namefild widget.
  FocusNode? namefildFocusNode;
  TextEditingController? namefildTextController;
  String? Function(BuildContext, String?)? namefildTextControllerValidator;
  // State field(s) for opisanifild widget.
  FocusNode? opisanifildFocusNode;
  TextEditingController? opisanifildTextController;
  String? Function(BuildContext, String?)? opisanifildTextControllerValidator;
  // State field(s) for pricefild widget.
  FocusNode? pricefildFocusNode;
  TextEditingController? pricefildTextController;
  String? Function(BuildContext, String?)? pricefildTextControllerValidator;
  // State field(s) for numberfild widget.
  FocusNode? numberfildFocusNode;
  TextEditingController? numberfildTextController;
  String? Function(BuildContext, String?)? numberfildTextControllerValidator;
  // State field(s) for cityfild widget.
  FocusNode? cityfildFocusNode;
  TextEditingController? cityfildTextController;
  String? Function(BuildContext, String?)? cityfildTextControllerValidator;
  bool isDataUploading_uploadData89k = false;
  FFUploadedFile uploadedLocalFile_uploadData89k =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData89k = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    namefildFocusNode?.dispose();
    namefildTextController?.dispose();

    opisanifildFocusNode?.dispose();
    opisanifildTextController?.dispose();

    pricefildFocusNode?.dispose();
    pricefildTextController?.dispose();

    numberfildFocusNode?.dispose();
    numberfildTextController?.dispose();

    cityfildFocusNode?.dispose();
    cityfildTextController?.dispose();
  }
}
