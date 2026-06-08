import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:system_contact_picker/system_contact_picker.dart';
import 'package:system_contact_picker/system_contact_picker_method_channel.dart';
import 'package:system_contact_picker/system_contact_picker_platform_interface.dart';

class MockSystemContactPickerPlatform
    with MockPlatformInterfaceMixin
    implements SystemContactPickerPlatform {
  @override
  Future<List<PickedContact>> pickContacts({
    required Set<ContactField> fields,
    required bool allowMultiple,
    required int? limit,
    required bool matchAllFields,
  }) {
    return Future.value(<PickedContact>[
      const PickedContact(
        id: '1',
        displayName: 'Ada Lovelace',
        phones: <ContactDataItem>[ContactDataItem(value: '+15555550100')],
      ),
    ]);
  }

  @override
  Future<ContactPickerCapabilities> getCapabilities() {
    return Future.value(
      const ContactPickerCapabilities(
        platform: 'android',
        androidSdkInt: 37,
        usesAndroid17ContactPicker: true,
        supportsMultiple: true,
        requiresReadContactsPermission: false,
        maximumSelectionLimit: 100,
      ),
    );
  }
}

void main() {
  final initialPlatform = SystemContactPickerPlatform.instance;

  test('$MethodChannelSystemContactPicker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSystemContactPicker>());
  });

  test('pickContact returns the first selected contact', () async {
    SystemContactPickerPlatform.instance = MockSystemContactPickerPlatform();

    const picker = SystemContactPicker();
    final contact = await picker.pickContact();

    expect(contact?.displayName, 'Ada Lovelace');
    expect(contact?.phones.single.value, '+15555550100');
  });

  test('empty fields are rejected', () {
    const picker = SystemContactPicker();

    expect(
      () => picker.pickContacts(fields: const <ContactField>{}),
      throwsArgumentError,
    );
  });

  test('selection limit is capped at Android 17 maximum', () {
    const picker = SystemContactPicker();

    expect(
      () => picker.pickContacts(allowMultiple: true, limit: 101),
      throwsRangeError,
    );
  });
}
