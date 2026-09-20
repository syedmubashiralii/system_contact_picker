# system_contact_picker example

Demonstrates permissionless contact selection on every supported platform.

## Android behavior

| Android version | API | Example behavior |
| --- | --- | --- |
| Android 9–16 | 28–36 | Legacy system `ACTION_PICK`; one contact with `name` and one value field per request |
| Android 17+ | 37+ | Privacy-preserving Contact Picker; multiple contacts and multiple fields |

The example declares no contacts permission. Its minimum Android version is
Android 9 (API 28). Phone, email, postal-address, and display-name buttons work
across the entire Android 9-to-latest range. Multi-contact and rich-field
buttons are shown only when the current OS reports support. Android 9–16 never
shows a misleading multi-contact button because its system picker can return
only one selection.

## iOS behavior

iOS 13+ uses `CNContactPickerViewController`, supports single and multiple
selection, and does not require Contacts authorization or an
`NSContactsUsageDescription` entry.

Run the example with:

```sh
flutter run
```
