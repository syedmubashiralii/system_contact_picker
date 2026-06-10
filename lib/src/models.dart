/// Data models returned by the native contact picker.
library;

import 'dart:typed_data';

/// Fields requested by default when opening the contact picker.
const defaultContactPickerFields = <ContactField>{
  ContactField.phone,
  ContactField.email,
};

/// A contact property that the native picker should return.
enum ContactField {
  /// Structured and display name values.
  name,

  /// Phone numbers.
  phone,

  /// Email addresses.
  email,

  /// Postal addresses.
  postalAddress,

  /// Company, department, and job title values.
  organization,

  /// Contact relationships.
  relation,

  /// Dates and birthday values.
  event,

  /// A thumbnail image, when available.
  photo,

  /// Website URLs.
  website,

  /// Nicknames.
  nickname,
}

/// Describes the contact picker behavior available on the current platform.
class ContactPickerCapabilities {
  /// Creates a platform capability description.
  const ContactPickerCapabilities({
    required this.platform,
    this.androidSdkInt,
    required this.usesAndroid17ContactPicker,
    required this.supportsMultiple,
    required this.requiresReadContactsPermission,
    this.maximumSelectionLimit,
  });

  /// Creates capabilities from a platform-channel map.
  factory ContactPickerCapabilities.fromMap(Map<dynamic, dynamic> map) {
    return ContactPickerCapabilities(
      platform: map['platform'] as String? ?? 'unknown',
      androidSdkInt: map['androidSdkInt'] as int?,
      usesAndroid17ContactPicker:
          map['usesAndroid17ContactPicker'] as bool? ?? false,
      supportsMultiple: map['supportsMultiple'] as bool? ?? false,
      requiresReadContactsPermission:
          map['requiresReadContactsPermission'] as bool? ?? false,
      maximumSelectionLimit: map['maximumSelectionLimit'] as int?,
    );
  }

  /// Lowercase platform name reported by the native implementation.
  final String platform;

  /// Android SDK version, or `null` on non-Android platforms.
  final int? androidSdkInt;

  /// Whether Android's API 37+ system Contact Picker is active.
  final bool usesAndroid17ContactPicker;

  /// Whether the active picker can return more than one contact.
  final bool supportsMultiple;

  /// Whether selecting a contact requires `READ_CONTACTS`.
  final bool requiresReadContactsPermission;

  /// Maximum supported selection count, or `null` when unconstrained.
  final int? maximumSelectionLimit;
}

/// A contact selected through the native system picker.
class PickedContact {
  /// Creates a normalized selected contact.
  const PickedContact({
    required this.id,
    this.lookupKey,
    required this.displayName,
    this.givenName,
    this.middleName,
    this.familyName,
    this.namePrefix,
    this.nameSuffix,
    this.phones = const <ContactDataItem>[],
    this.emails = const <ContactDataItem>[],
    this.postalAddresses = const <ContactPostalAddress>[],
    this.organizations = const <ContactOrganization>[],
    this.websites = const <ContactDataItem>[],
    this.relations = const <ContactDataItem>[],
    this.events = const <ContactDataItem>[],
    this.nicknames = const <ContactDataItem>[],
    this.thumbnail,
  });

  /// Creates a contact from a platform-channel map.
  factory PickedContact.fromMap(Map<dynamic, dynamic> map) {
    return PickedContact(
      id: map['id'] as String? ?? '',
      lookupKey: map['lookupKey'] as String?,
      displayName: map['displayName'] as String? ?? '',
      givenName: map['givenName'] as String?,
      middleName: map['middleName'] as String?,
      familyName: map['familyName'] as String?,
      namePrefix: map['namePrefix'] as String?,
      nameSuffix: map['nameSuffix'] as String?,
      phones: _dataItems(map['phones']),
      emails: _dataItems(map['emails']),
      postalAddresses: _postalAddresses(map['postalAddresses']),
      organizations: _organizations(map['organizations']),
      websites: _dataItems(map['websites']),
      relations: _dataItems(map['relations']),
      events: _dataItems(map['events']),
      nicknames: _dataItems(map['nicknames']),
      thumbnail: _bytes(map['thumbnail']),
    );
  }

  /// Platform contact identifier.
  final String id;

  /// Android lookup key, when provided by the platform.
  final String? lookupKey;

  /// Human-readable name suitable for display.
  final String displayName;

  /// Given or first name.
  final String? givenName;

  /// Middle name.
  final String? middleName;

  /// Family or last name.
  final String? familyName;

  /// Name prefix, such as a title.
  final String? namePrefix;

  /// Name suffix.
  final String? nameSuffix;

  /// Selected phone numbers.
  final List<ContactDataItem> phones;

  /// Selected email addresses.
  final List<ContactDataItem> emails;

  /// Selected postal addresses.
  final List<ContactPostalAddress> postalAddresses;

  /// Selected organization details.
  final List<ContactOrganization> organizations;

  /// Selected website URLs.
  final List<ContactDataItem> websites;

  /// Selected relationship values.
  final List<ContactDataItem> relations;

  /// Selected dates and birthday values.
  final List<ContactDataItem> events;

  /// Selected nicknames.
  final List<ContactDataItem> nicknames;

  /// Contact thumbnail bytes, when requested and available.
  final Uint8List? thumbnail;

  /// Converts this contact to its platform-channel representation.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'lookupKey': lookupKey,
      'displayName': displayName,
      'givenName': givenName,
      'middleName': middleName,
      'familyName': familyName,
      'namePrefix': namePrefix,
      'nameSuffix': nameSuffix,
      'phones': phones.map((item) => item.toMap()).toList(),
      'emails': emails.map((item) => item.toMap()).toList(),
      'postalAddresses':
          postalAddresses.map((address) => address.toMap()).toList(),
      'organizations':
          organizations.map((organization) => organization.toMap()).toList(),
      'websites': websites.map((item) => item.toMap()).toList(),
      'relations': relations.map((item) => item.toMap()).toList(),
      'events': events.map((item) => item.toMap()).toList(),
      'nicknames': nicknames.map((item) => item.toMap()).toList(),
      'thumbnail': thumbnail,
    };
  }
}

/// A labeled string value from a contact record.
class ContactDataItem {
  /// Creates a contact data item.
  const ContactDataItem({
    required this.value,
    this.label,
    this.type,
    this.normalizedValue,
  });

  /// Creates a data item from a platform-channel map.
  factory ContactDataItem.fromMap(Map<dynamic, dynamic> map) {
    return ContactDataItem(
      value: map['value'] as String? ?? '',
      label: map['label'] as String?,
      type: map['type'] as String?,
      normalizedValue: map['normalizedValue'] as String?,
    );
  }

  /// Contact data value.
  final String value;

  /// Localized label suitable for display.
  final String? label;

  /// Raw platform label or type.
  final String? type;

  /// Platform-normalized value, when available.
  final String? normalizedValue;

  /// Converts this item to its platform-channel representation.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'value': value,
      'label': label,
      'type': type,
      'normalizedValue': normalizedValue,
    };
  }
}

/// A structured postal address from a contact record.
class ContactPostalAddress {
  /// Creates a contact postal address.
  const ContactPostalAddress({
    this.formatted,
    this.street,
    this.city,
    this.region,
    this.postalCode,
    this.country,
    this.isoCountryCode,
    this.label,
    this.type,
  });

  /// Creates a postal address from a platform-channel map.
  factory ContactPostalAddress.fromMap(Map<dynamic, dynamic> map) {
    return ContactPostalAddress(
      formatted: map['formatted'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      region: map['region'] as String?,
      postalCode: map['postalCode'] as String?,
      country: map['country'] as String?,
      isoCountryCode: map['isoCountryCode'] as String?,
      label: map['label'] as String?,
      type: map['type'] as String?,
    );
  }

  /// Full address formatted for display.
  final String? formatted;

  /// Street portion of the address.
  final String? street;

  /// City or locality.
  final String? city;

  /// State, province, or region.
  final String? region;

  /// Postal or ZIP code.
  final String? postalCode;

  /// Country name.
  final String? country;

  /// ISO country code.
  final String? isoCountryCode;

  /// Localized label suitable for display.
  final String? label;

  /// Raw platform label or type.
  final String? type;

  /// Converts this address to its platform-channel representation.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'formatted': formatted,
      'street': street,
      'city': city,
      'region': region,
      'postalCode': postalCode,
      'country': country,
      'isoCountryCode': isoCountryCode,
      'label': label,
      'type': type,
    };
  }
}

/// Organization details from a contact record.
class ContactOrganization {
  /// Creates contact organization details.
  const ContactOrganization({
    this.company,
    this.department,
    this.title,
    this.label,
    this.type,
  });

  /// Creates organization details from a platform-channel map.
  factory ContactOrganization.fromMap(Map<dynamic, dynamic> map) {
    return ContactOrganization(
      company: map['company'] as String?,
      department: map['department'] as String?,
      title: map['title'] as String?,
      label: map['label'] as String?,
      type: map['type'] as String?,
    );
  }

  /// Company or organization name.
  final String? company;

  /// Department name.
  final String? department;

  /// Job title.
  final String? title;

  /// Localized label suitable for display.
  final String? label;

  /// Raw platform label or type.
  final String? type;

  /// Converts this organization to its platform-channel representation.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'company': company,
      'department': department,
      'title': title,
      'label': label,
      'type': type,
    };
  }
}

List<ContactDataItem> _dataItems(Object? value) {
  return _maps(value).map(ContactDataItem.fromMap).toList(growable: false);
}

List<ContactPostalAddress> _postalAddresses(Object? value) {
  return _maps(value).map(ContactPostalAddress.fromMap).toList(growable: false);
}

List<ContactOrganization> _organizations(Object? value) {
  return _maps(value).map(ContactOrganization.fromMap).toList(growable: false);
}

List<Map<dynamic, dynamic>> _maps(Object? value) {
  if (value is! List) {
    return const <Map<dynamic, dynamic>>[];
  }
  return value.whereType<Map<dynamic, dynamic>>().toList(growable: false);
}

Uint8List? _bytes(Object? value) {
  if (value is Uint8List) {
    return value;
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is List) {
    return Uint8List.fromList(value.cast<int>());
  }
  return null;
}
