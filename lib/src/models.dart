import 'dart:typed_data';

const defaultContactPickerFields = <ContactField>{
  ContactField.phone,
  ContactField.email,
};

enum ContactField {
  name,
  phone,
  email,
  postalAddress,
  organization,
  relation,
  event,
  photo,
  website,
  nickname,
}

class ContactPickerCapabilities {
  const ContactPickerCapabilities({
    required this.platform,
    this.androidSdkInt,
    required this.usesAndroid17ContactPicker,
    required this.supportsMultiple,
    required this.requiresReadContactsPermission,
    this.maximumSelectionLimit,
  });

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

  final String platform;
  final int? androidSdkInt;
  final bool usesAndroid17ContactPicker;
  final bool supportsMultiple;
  final bool requiresReadContactsPermission;
  final int? maximumSelectionLimit;
}

class PickedContact {
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

  final String id;
  final String? lookupKey;
  final String displayName;
  final String? givenName;
  final String? middleName;
  final String? familyName;
  final String? namePrefix;
  final String? nameSuffix;
  final List<ContactDataItem> phones;
  final List<ContactDataItem> emails;
  final List<ContactPostalAddress> postalAddresses;
  final List<ContactOrganization> organizations;
  final List<ContactDataItem> websites;
  final List<ContactDataItem> relations;
  final List<ContactDataItem> events;
  final List<ContactDataItem> nicknames;
  final Uint8List? thumbnail;

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
      'postalAddresses': postalAddresses
          .map((address) => address.toMap())
          .toList(),
      'organizations': organizations
          .map((organization) => organization.toMap())
          .toList(),
      'websites': websites.map((item) => item.toMap()).toList(),
      'relations': relations.map((item) => item.toMap()).toList(),
      'events': events.map((item) => item.toMap()).toList(),
      'nicknames': nicknames.map((item) => item.toMap()).toList(),
      'thumbnail': thumbnail,
    };
  }
}

class ContactDataItem {
  const ContactDataItem({
    required this.value,
    this.label,
    this.type,
    this.normalizedValue,
  });

  factory ContactDataItem.fromMap(Map<dynamic, dynamic> map) {
    return ContactDataItem(
      value: map['value'] as String? ?? '',
      label: map['label'] as String?,
      type: map['type'] as String?,
      normalizedValue: map['normalizedValue'] as String?,
    );
  }

  final String value;
  final String? label;
  final String? type;
  final String? normalizedValue;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'value': value,
      'label': label,
      'type': type,
      'normalizedValue': normalizedValue,
    };
  }
}

class ContactPostalAddress {
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

  final String? formatted;
  final String? street;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? country;
  final String? isoCountryCode;
  final String? label;
  final String? type;

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

class ContactOrganization {
  const ContactOrganization({
    this.company,
    this.department,
    this.title,
    this.label,
    this.type,
  });

  factory ContactOrganization.fromMap(Map<dynamic, dynamic> map) {
    return ContactOrganization(
      company: map['company'] as String?,
      department: map['department'] as String?,
      title: map['title'] as String?,
      label: map['label'] as String?,
      type: map['type'] as String?,
    );
  }

  final String? company;
  final String? department;
  final String? title;
  final String? label;
  final String? type;

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
