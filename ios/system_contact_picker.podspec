#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint system_contact_picker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'system_contact_picker'
  s.version          = '0.0.1'
  s.summary          = 'Native Flutter contact picker for Android and iOS.'
  s.description      = <<-DESC
Uses Android 17 Contact Picker when available, Android legacy Contacts picker below API 37, and iOS ContactsUI.
                       DESC
  s.homepage         = 'https://pub.dev/packages/system_contact_picker'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'system_contact_picker contributors' => 'contributors@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'system_contact_picker/Sources/system_contact_picker/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'system_contact_picker_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
