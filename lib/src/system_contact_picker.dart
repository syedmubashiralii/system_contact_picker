/// Public API for opening the native system contact picker.
library;

import '../system_contact_picker_platform_interface.dart';
import 'models.dart';

/// Opens the native system UI for selecting contacts.
class SystemContactPicker {
  /// Creates a contact picker.
  const SystemContactPicker();

  /// Opens the native picker and returns the selected contacts.
  ///
  /// [fields] must not be empty. [limit], when provided, must be from 1 to
  /// 100. Platforms that only support one selection return at most one contact
  /// even when [allowMultiple] is `true`.
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

  /// Opens the native picker and returns one contact, or `null` if cancelled.
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

  /// Returns contact picker capabilities for the current platform.
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
