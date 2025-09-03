import 'package:flutter_test/flutter_test.dart';

// This file is intentionally skipped. The integrated E2E test lives in
// integration_test/export_flow_test.dart to avoid multiple app launches.
void main() {
  testWidgets('skipped duplicate E2E (see export_flow_test.dart)', (
    tester,
  ) async {
    expect(true, isTrue);
  }, skip: true);
}
