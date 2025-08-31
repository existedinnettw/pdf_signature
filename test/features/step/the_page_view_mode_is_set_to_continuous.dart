import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the Page view mode is set to Continuous
Future<void> thePageViewModeIsSetToContinuous(WidgetTester tester) async {
  // Logic-level test: no widget tree; just mark a flag if needed
  TestWorld.prefs['page_view'] = 'continuous';
}
