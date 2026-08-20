import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_splash_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate splash png assets', () async {
    await generateSplashAssets();
  });
}
