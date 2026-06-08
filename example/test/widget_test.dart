// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:system_contact_picker_example/main.dart';

void main() {
  testWidgets('renders picker controls', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ContactPickerExampleApp());

    expect(find.text('System Contact Picker'), findsOneWidget);
    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('Pick up to 5'), findsOneWidget);
    expect(find.text('Phone only'), findsOneWidget);
  });
}
