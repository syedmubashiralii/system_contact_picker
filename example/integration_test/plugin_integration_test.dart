// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:system_contact_picker/system_contact_picker.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getCapabilities returns platform details', (
    WidgetTester tester,
  ) async {
    const plugin = SystemContactPicker();
    final capabilities = await plugin.getCapabilities();

    expect(capabilities.platform.isNotEmpty, true);
    expect(capabilities.requiresReadContactsPermission, false);
    if (capabilities.platform == 'android') {
      final sdk = capabilities.androidSdkInt!;
      expect(sdk, greaterThanOrEqualTo(28));
      if (sdk <= 36) {
        expect(capabilities.usesAndroid17ContactPicker, false);
        expect(capabilities.supportsMultiple, false);
        expect(capabilities.maximumSelectionLimit, 1);
        expect(capabilities.supportedFields, <ContactField>{
          ContactField.name,
          ContactField.phone,
          ContactField.email,
          ContactField.postalAddress,
        });
      } else {
        expect(capabilities.usesAndroid17ContactPicker, true);
        expect(capabilities.supportsMultiple, true);
        expect(capabilities.maximumSelectionLimit, 100);
        expect(capabilities.supportedFields, <ContactField>{
          ...ContactField.values,
        });
      }
    }
  });

  testWidgets('legacy Android rejects misleading multi-contact requests', (
    WidgetTester tester,
  ) async {
    const plugin = SystemContactPicker();
    final capabilities = await plugin.getCapabilities();
    if (capabilities.platform != 'android' ||
        (capabilities.androidSdkInt ?? 37) >= 37) {
      return;
    }

    await expectLater(
      plugin.pickContacts(
        fields: const <ContactField>{ContactField.phone},
        allowMultiple: true,
        limit: 5,
      ),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'multiple_not_supported',
        ),
      ),
    );
  });

  testWidgets('Android rejects malformed native arguments without crashing', (
    WidgetTester tester,
  ) async {
    const plugin = SystemContactPicker();
    final capabilities = await plugin.getCapabilities();
    if (capabilities.platform != 'android') {
      return;
    }

    const channel = MethodChannel('system_contact_picker');
    final malformedArguments = <Map<String, Object?>>[
      <String, Object?>{'fields': 'phone'},
      <String, Object?>{
        'fields': <Object?>['phone', 7],
      },
      <String, Object?>{
        'fields': <String>['unknown'],
      },
      <String, Object?>{'allowMultiple': 1},
      <String, Object?>{'matchAllFields': 'true'},
      <String, Object?>{'limit': 1.5},
      <String, Object?>{'limit': 101},
    ];

    for (final arguments in malformedArguments) {
      await expectLater(
        channel.invokeListMethod<dynamic>('pickContacts', arguments),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'bad_arguments',
          ),
        ),
        reason: 'arguments=$arguments',
      );
    }
  });
}
