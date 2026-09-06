import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the exported sky mascot asset', () async {
    final data = await rootBundle.load(
      'assets/illustrations/clouds/mascot-cloud.png',
    );

    expect(data.lengthInBytes, greaterThan(0));
  });
}
