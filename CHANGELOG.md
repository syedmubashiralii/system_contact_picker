## 0.0.4

* Allow `name` with one legacy Android value field (`phone`, `email`, or
  `postalAddress`) on API 36 and below, and return `displayName` without
  requiring broad contacts permission.
* Validate every native method-channel argument before building an Android
  intent, convert launch/query failures into stable platform errors, and keep
  pending picker calls alive across configuration changes.

## 0.0.3

* Removed `READ_CONTACTS` and changed legacy Android selection to use only the
  user-granted result URI.
* Added platform-supported field reporting and documented permissionless picker
  limitations below Android 17.
* Removed the unnecessary iOS Contacts usage-description requirement.
* Corrected iOS single-selection mode so it no longer presents multi-select UI.
* Updated the example to adapt its actions across Android 9–16, Android 17+,
  and iOS instead of presenting unsupported legacy operations.
* Documented Android 9-to-latest support and set the example's minimum SDK to 28.
* Hid the multi-contact example on Android 9–16 and added a clear
  `multiple_not_supported` native error for unsupported requests.

## 0.0.2

* Documented the complete public Dart API.
* Added Swift Package Manager support for iOS.
* Preserved CocoaPods support with a shared Swift source layout.

## 0.0.1

* Initial Android and iOS system contact picker plugin.
* Added Android 17 Contact Picker support with session URI querying.
* Added a legacy Android fallback for API 36 and below.
* Added iOS `CNContactPickerViewController` implementation.
