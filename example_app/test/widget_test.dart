import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resume_upload_example/main.dart';

void main() {
  testWidgets('launches with the upload screen and Start Upload disabled until a file is picked', (tester) async {
    // UploadManager.initialize stores a device ID in SharedPreferences.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Resume Upload'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Server URL'), findsOneWidget);

    final startButton = find.ancestor(of: find.text('Start Upload'), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(startButton, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(startButton).onPressed, isNull);

    // Dispose the page so its memory-monitor timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
