# system_contact_picker

Native Flutter contact picker for Android and iOS.

## Platform behavior

| Platform | Picker | Permission behavior | Multiple selection |
| --- | --- | --- | --- |
| Android API 37+ | Android 17 system Contact Picker | No `READ_CONTACTS` runtime permission | Supported, limit 1-100 |
| Android API 36 and below | Legacy `Intent.ACTION_PICK` Contacts picker | Runtime `READ_CONTACTS`, manifest scoped with `maxSdkVersion="36"` | Falls back to one contact |
| iOS 13+ | `CNContactPickerViewController` | Add `NSContactsUsageDescription` to the host app | Supported by ContactsUI, limit applied after selection |

Android 17 returns a session URI and the plugin immediately queries that URI for the requested fields. Legacy Android resolves the selected contact and queries `ContactsContract.Data` after `READ_CONTACTS` is granted.

## Usage

```dart
import 'package:system_contact_picker/system_contact_picker.dart';

const picker = SystemContactPicker();

final contact = await picker.pickContact(
  fields: const {ContactField.phone, ContactField.email},
);

final contacts = await picker.pickContacts(
  fields: const {ContactField.phone, ContactField.email},
  allowMultiple: true,
  limit: 5,
  matchAllFields: false,
);
```

The plugin returns normalized `PickedContact` models:

```dart
for (final contact in contacts) {
  print(contact.displayName);
  for (final phone in contact.phones) {
    print('${phone.label}: ${phone.value}');
  }
  for (final email in contact.emails) {
    print('${email.label}: ${email.value}');
  }
}
```

## Fields

Supported request fields:

```dart
ContactField.name
ContactField.phone
ContactField.email
ContactField.postalAddress
ContactField.organization
ContactField.relation
ContactField.event
ContactField.photo
ContactField.website
ContactField.nickname
```

Default fields are phone and email.

## Capabilities

Use `getCapabilities()` when the UI needs to adapt to platform limits.

```dart
final capabilities = await picker.getCapabilities();

if (!capabilities.supportsMultiple) {
  // Android API 36 and below can only return one contact.
}
```

## Android setup

No host-app manifest change is required for the package permission. The plugin manifest includes:

```xml
<uses-permission
    android:name="android.permission.READ_CONTACTS"
    android:maxSdkVersion="36" />
```

That keeps the broad contacts permission away from Android 17+ while preserving the legacy picker path on older devices.

The Android 17 constants are used as documented string values so the plugin can compile on Flutter/Android SDK installations that have not installed API 37 yet.

## iOS setup

Add a contacts usage description to the host app's `ios/Runner/Info.plist`:

```xml
<key>NSContactsUsageDescription</key>
<string>Select contacts to share with this app.</string>
```

The picker uses Apple's sandboxed ContactsUI flow and does not call the broad Contacts authorization prompt before presenting the picker.

## References

- Android Contact Picker guide: https://developer.android.com/about/versions/17/features/contact-picker
- Android `ContactsPickerSessionContract`: https://developer.android.com/reference/android/provider/ContactsPickerSessionContract
- Android `Intent.EXTRA_USE_SYSTEM_CONTACTS_PICKER`: https://developer.android.com/reference/android/content/Intent#EXTRA_USE_SYSTEM_CONTACTS_PICKER
- iOS `CNContactPickerViewController`: https://developer.apple.com/documentation/contactsui/cncontactpickerviewcontroller
