import 'package:flutter_test/flutter_test.dart';
import '_world.dart';

/// Usage: the Page view mode is set to Single
Future<void> thePageViewModeIsSetToSingle(WidgetTester tester) async {
  TestWorld.prefs['page_view'] = 'single';
}
