# system_contact_picker

Native Flutter contact picker for Android and iOS.

## Platform behavior

| Platform | Picker | Permission behavior | Multiple selection |
| --- | --- | --- | --- |
| Android 17+ | API 37+ system Contact Picker | No contacts permission | Supported, limit 1-100 |
| Android 9–16 | API 28–36 legacy `Intent.ACTION_PICK` | No contacts permission | One contact and one supported field |
| iOS 13+ | `CNContactPickerViewController` | No contacts permission | Supported by ContactsUI, limit applied after selection |

Android 17 returns a session URI and the plugin immediately queries that URI for
the requested fields. Legacy Android queries only the exact result URI that the
user selected; it never reads the address book directly.

The supported Android release range is Android 9 (API 28) through the latest
Android release. The plugin currently retains a lower technical `minSdk` of 24,
so it does not unnecessarily block existing Android 7–8 applications.

## Usage

```dart
import 'package:system_contact_picker/system_contact_picker.dart';

const picker = SystemContactPicker();

final contact = await picker.pickContact(); // Phone is the privacy-first default.

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

The default field is phone. Request only the fields required by the user-facing
feature.

On Android 9–16 (API 28–36), the permissionless legacy picker supports exactly
one of `name`, `phone`, `email`, or `postalAddress` per request. Requesting
multiple fields or another field throws a platform exception with code
`unsupported_legacy_fields`. Use `getCapabilities()` before presenting choices
that depend on richer fields.

Passing `allowMultiple: true` on Android 9–16 throws
`multiple_not_supported`. Native multi-contact selection is available only on
Android 17+ and iOS; it cannot be implemented through the permissionless legacy
Android picker.

## Capabilities

Use `getCapabilities()` when the UI needs to adapt to platform limits.

```dart
final capabilities = await picker.getCapabilities();

if (!capabilities.supportsMultiple) {
  // Android 9–16 can only return one contact.
}

if (!capabilities.supportedFields.contains(ContactField.organization)) {
  // Hide richer-field actions on the legacy Android picker.
}
```

## Android setup

No host-app manifest change is required. The plugin declares no contacts
permission and never requests `READ_CONTACTS` at runtime.

The Android 17 constants are used as documented string values so the plugin can compile on Flutter/Android SDK installations that have not installed API 37 yet.

## iOS setup

No `Info.plist` contacts usage description is required. The picker uses Apple's
sandboxed ContactsUI flow, does not request broad Contacts authorization, and
returns only the user's final selection.

## Google Play policy and Data safety

Google Play's Contacts Permission policy applies to apps targeting Android 17
(API 37) or later. Apps that carry `READ_CONTACTS` must qualify for a permitted
core use case and complete the Play Console declaration. This plugin does not
carry that permission, so using the picker does not create a Contacts Permission
declaration requirement by itself.

Selected contact data is returned to the host app in memory. The plugin does not
store or transmit it. The host app remains responsible for:

- requesting only data needed for a clearly described user-facing feature;
- keeping its privacy policy and Play Data safety answers consistent with any
  storage or off-device transmission it adds; and
- never publishing or disclosing non-public contact data without authorization.

## References

- Android Contact Picker guide: https://developer.android.com/about/versions/17/features/contact-picker
- Android `ContactsPickerSessionContract`: https://developer.android.com/reference/android/provider/ContactsPickerSessionContract
- Android `Intent.EXTRA_USE_SYSTEM_CONTACTS_PICKER`: https://developer.android.com/reference/android/content/Intent#EXTRA_USE_SYSTEM_CONTACTS_PICKER
- Google Play Contacts Permission guidance: https://support.google.com/googleplay/android-developer/answer/16935362
- Google Play User Data policy: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play Data safety guidance: https://support.google.com/googleplay/android-developer/answer/10787469
- iOS `CNContactPickerViewController`: https://developer.apple.com/documentation/contactsui/cncontactpickerviewcontroller
