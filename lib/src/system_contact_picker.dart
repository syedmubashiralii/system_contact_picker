import '../system_contact_picker_platform_interface.dart';
import 'models.dart';

class SystemContactPicker {
  const SystemContactPicker();

  Future<List<PickedContact>> pickContacts({
    Set<ContactField> fields = defaultContactPickerFields,
    bool allowMultiple = false,
    int? limit,
    bool matchAllFields = false,
  }) {
    _validate(fields: fields, limit: limit);
    return SystemContactPickerPlatform.instance.pickContacts(
      fields: fields,
      allowMultiple: allowMultiple,
      limit: limit,
      matchAllFields: matchAllFields,
    );
  }

  Future<PickedContact?> pickContact({
    Set<ContactField> fields = defaultContactPickerFields,
    bool matchAllFields = false,
  }) async {
    final contacts = await pickContacts(
      fields: fields,
      allowMultiple: false,
      limit: 1,
      matchAllFields: matchAllFields,
    );
    return contacts.isEmpty ? null : contacts.first;
  }

  Future<ContactPickerCapabilities> getCapabilities() {
    return SystemContactPickerPlatform.instance.getCapabilities();
  }

  void _validate({required Set<ContactField> fields, required int? limit}) {
    if (fields.isEmpty) {
      throw ArgumentError.value(
        fields,
        'fields',
        'Must request at least one field.',
      );
    }
    if (limit != null && (limit < 1 || limit > 100)) {
      throw RangeError.range(
        limit,
        1,
        100,
        'limit',
        'Android 17 Contact Picker supports a maximum selection limit of 100.',
      );
    }
  }
}
