import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'system_contact_picker_platform_interface.dart';
import 'src/models.dart';

/// An implementation of [SystemContactPickerPlatform] that uses method channels.
class MethodChannelSystemContactPicker extends SystemContactPickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('system_contact_picker');

  @override
  Future<List<PickedContact>> pickContacts({
    required Set<ContactField> fields,
    required bool allowMultiple,
    required int? limit,
    required bool matchAllFields,
  }) async {
    final contacts = await methodChannel
        .invokeListMethod<dynamic>('pickContacts', <String, Object?>{
          'fields': fields.map((field) => field.name).toList(growable: false),
          'allowMultiple': allowMultiple,
          'limit': limit,
          'matchAllFields': matchAllFields,
        });
    return (contacts ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map(PickedContact.fromMap)
        .toList(growable: false);
  }

  @override
  Future<ContactPickerCapabilities> getCapabilities() async {
    final capabilities = await methodChannel.invokeMapMethod<dynamic, dynamic>(
      'getCapabilities',
    );
    return ContactPickerCapabilities.fromMap(
      capabilities ?? const <dynamic, dynamic>{},
    );
  }
}
