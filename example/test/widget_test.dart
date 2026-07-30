import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_contact_picker/system_contact_picker.dart';
import 'package:system_contact_picker/system_contact_picker_platform_interface.dart';

import 'package:system_contact_picker_example/main.dart';

class FakeContactPickerPlatform extends SystemContactPickerPlatform {
  FakeContactPickerPlatform(this.capabilities);

  final ContactPickerCapabilities capabilities;
  Set<ContactField>? lastFields;
  bool? lastAllowMultiple;
  int? lastLimit;

  @override
  Future<ContactPickerCapabilities> getCapabilities() async => capabilities;

  @override
  Future<List<PickedContact>> pickContacts({
    required Set<ContactField> fields,
    required bool allowMultiple,
    required int? limit,
    required bool matchAllFields,
  }) async {
    lastFields = fields;
    lastAllowMultiple = allowMultiple;
    lastLimit = limit;
    return const <PickedContact>[];
  }
}

void main() {
  final initialPlatform = SystemContactPickerPlatform.instance;

  tearDown(() => SystemContactPickerPlatform.instance = initialPlatform);

  testWidgets('Android 9 shows only permissionless legacy actions', (
    WidgetTester tester,
  ) async {
    SystemContactPickerPlatform.instance = FakeContactPickerPlatform(
      const ContactPickerCapabilities(
        platform: 'android',
        androidSdkInt: 28,
        usesAndroid17ContactPicker: false,
        supportsMultiple: false,
        requiresReadContactsPermission: false,
        supportedFields: <ContactField>{
          ContactField.name,
          ContactField.phone,
          ContactField.email,
          ContactField.postalAddress,
        },
        maximumSelectionLimit: 1,
      ),
    );

    await tester.pumpWidget(const ContactPickerExampleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Android 9–16 permissionless legacy picker'),
      findsOneWidget,
    );
    expect(find.text('Pick phone'), findsOneWidget);
    expect(find.text('Pick email'), findsOneWidget);
    expect(find.text('Pick address'), findsOneWidget);
    expect(find.text('Pick name'), findsOneWidget);
    expect(find.text('Pick up to 5 contacts'), findsNothing);
    expect(find.textContaining('unavailable on Android 9–16'), findsOneWidget);
  });

  testWidgets('Android 17 enables modern multi-contact actions', (
    WidgetTester tester,
  ) async {
    final platform = FakeContactPickerPlatform(
      ContactPickerCapabilities(
        platform: 'android',
        androidSdkInt: 37,
        usesAndroid17ContactPicker: true,
        supportsMultiple: true,
        requiresReadContactsPermission: false,
        supportedFields: <ContactField>{...ContactField.values},
        maximumSelectionLimit: 100,
      ),
    );
    SystemContactPickerPlatform.instance = platform;

    await tester.pumpWidget(const ContactPickerExampleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Android 17+ privacy-preserving Contact Picker'),
      findsOneWidget,
    );
    await tester.tap(find.text('Pick up to 5 contacts'));
    await tester.pumpAndSettle();

    expect(platform.lastAllowMultiple, true);
    expect(platform.lastLimit, 5);
    expect(platform.lastFields, <ContactField>{
      ContactField.phone,
      ContactField.email,
    });
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Pick up to 5 contacts'),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Pick all fields'),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.textContaining('unavailable on Android 9–16'), findsNothing);
  });
}
