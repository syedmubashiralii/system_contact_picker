import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_contact_picker/system_contact_picker.dart';
import 'package:system_contact_picker/system_contact_picker_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSystemContactPicker();
  const channel = MethodChannel('system_contact_picker');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          switch (methodCall.method) {
            case 'pickContacts':
              return <Map<String, Object?>>[
                <String, Object?>{
                  'id': 'lookup-1',
                  'displayName': 'Grace Hopper',
                  'phones': <Map<String, Object?>>[
                    <String, Object?>{
                      'value': '+15555550101',
                      'label': 'mobile',
                    },
                  ],
                },
              ];
            case 'getCapabilities':
              return <String, Object?>{
                'platform': 'android',
                'androidSdkInt': 37,
                'usesAndroid17ContactPicker': true,
                'supportsMultiple': true,
                'requiresReadContactsPermission': false,
                'maximumSelectionLimit': 100,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickContacts sends normalized options and parses contacts', () async {
    final contacts = await platform.pickContacts(
      fields: const <ContactField>{ContactField.phone, ContactField.email},
      allowMultiple: true,
      limit: 5,
      matchAllFields: true,
    );

    expect(calls.single.method, 'pickContacts');
    expect(calls.single.arguments, <String, Object?>{
      'fields': <String>['phone', 'email'],
      'allowMultiple': true,
      'limit': 5,
      'matchAllFields': true,
    });
    expect(contacts.single.displayName, 'Grace Hopper');
    expect(contacts.single.phones.single.value, '+15555550101');
  });

  test('getCapabilities parses platform capabilities', () async {
    final capabilities = await platform.getCapabilities();

    expect(capabilities.usesAndroid17ContactPicker, isTrue);
    expect(capabilities.maximumSelectionLimit, 100);
  });
}
