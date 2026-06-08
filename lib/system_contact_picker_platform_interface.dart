import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'system_contact_picker_method_channel.dart';
import 'src/models.dart';

abstract class SystemContactPickerPlatform extends PlatformInterface {
  /// Constructs a SystemContactPickerPlatform.
  SystemContactPickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static SystemContactPickerPlatform _instance =
      MethodChannelSystemContactPicker();

  /// The default instance of [SystemContactPickerPlatform] to use.
  ///
  /// Defaults to [MethodChannelSystemContactPicker].
  static SystemContactPickerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SystemContactPickerPlatform] when
  /// they register themselves.
  static set instance(SystemContactPickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<PickedContact>> pickContacts({
    required Set<ContactField> fields,
    required bool allowMultiple,
    required int? limit,
    required bool matchAllFields,
  }) {
    throw UnimplementedError('pickContacts() has not been implemented.');
  }

  Future<ContactPickerCapabilities> getCapabilities() {
    throw UnimplementedError('getCapabilities() has not been implemented.');
  }
}
