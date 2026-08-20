import 'dart:io';

import 'package:ekbkyrgyzdar/components/ekbkg_logo.dart';
import 'package:flutter/material.dart';

Future<void> generateSplashAssets() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _saveLogoPng(
    'android/app/src/main/res/drawable-nodpi/splash_logo_ekbkg.png',
    360,
  );

  await _saveLogoPng(
    'ios/Runner/Assets.xcassets/SplashLogo.imageset/splash_logo.png',
    360,
  );
}

Future<void> main() async {
  await generateSplashAssets();
}

Future<void> _saveLogoPng(String path, double size) async {
  final bytes = await ekbkgLogoPngBytes(
    size,
    color: EkbkgLogo.brandYellow,
    logoScale: 0.72,
  );
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}
