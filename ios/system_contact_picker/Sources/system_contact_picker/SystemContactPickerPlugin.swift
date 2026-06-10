import Contacts
import ContactsUI
import Flutter
import UIKit

public class SystemContactPickerPlugin: NSObject, FlutterPlugin, CNContactPickerDelegate {
  private var pendingResult: FlutterResult?
  private var pendingOptions: PickerOptions?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "system_contact_picker",
      binaryMessenger: registrar.messenger()
    )
    let instance = SystemContactPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickContacts":
      pickContacts(call: call, result: result)
    case "getCapabilities":
      result([
        "platform": "ios",
        "usesAndroid17ContactPicker": false,
        "supportsMultiple": true,
        "requiresReadContactsPermission": false,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    complete([])
  }

  public func contactPicker(
    _ picker: CNContactPickerViewController,
    didSelect contact: CNContact
  ) {
    complete([contact])
  }

  public func contactPicker(
    _ picker: CNContactPickerViewController,
    didSelect contacts: [CNContact]
  ) {
    complete(contacts)
  }

  private func pickContacts(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(
        code: "already_active",
        message: "A contact picker request is already active.",
        details: nil
      ))
      return
    }
    guard let options = PickerOptions(call: call) else {
      result(FlutterError(
        code: "bad_arguments",
        message: "Invalid contact picker arguments.",
        details: nil
      ))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(
        code: "activity_unavailable",
        message: "Unable to find a view controller to present the contact picker.",
        details: nil
      ))
      return
    }

    let picker = CNContactPickerViewController()
    picker.delegate = self
    picker.displayedPropertyKeys = displayedPropertyKeys(for: options.fields)
    picker.predicateForEnablingContact = contactPredicate(for: options.fields, matchAll: options.matchAllFields)

    pendingResult = result
    pendingOptions = options
    presenter.present(picker, animated: true)
  }

  private func complete(_ contacts: [CNContact]) {
    guard let result = pendingResult else { return }
    let options = pendingOptions
    let maxCount = options?.allowMultiple == true ? options?.limit : 1
    let selected = maxCount == nil ? contacts : Array(contacts.prefix(maxCount!))
    pendingResult = nil
    pendingOptions = nil
    result(selected.map(contactMap))
  }

  private func topViewController() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
    return visibleViewController(from: root)
  }

  private func visibleViewController(from controller: UIViewController?) -> UIViewController? {
    if let presented = controller?.presentedViewController {
      return visibleViewController(from: presented)
    }
    if let navigation = controller as? UINavigationController {
      return visibleViewController(from: navigation.visibleViewController)
    }
    if let tab = controller as? UITabBarController {
      return visibleViewController(from: tab.selectedViewController)
    }
    return controller
  }

  private func displayedPropertyKeys(for fields: [String]) -> [String] {
    var keys = Set<String>()
    keys.insert(CNContactGivenNameKey)
    keys.insert(CNContactMiddleNameKey)
    keys.insert(CNContactFamilyNameKey)
    keys.insert(CNContactNamePrefixKey)
    keys.insert(CNContactNameSuffixKey)

    for field in fields {
      switch field {
      case "name":
        keys.insert(CNContactGivenNameKey)
        keys.insert(CNContactMiddleNameKey)
        keys.insert(CNContactFamilyNameKey)
        keys.insert(CNContactNamePrefixKey)
        keys.insert(CNContactNameSuffixKey)
      case "phone":
        keys.insert(CNContactPhoneNumbersKey)
      case "email":
        keys.insert(CNContactEmailAddressesKey)
      case "postalAddress":
        keys.insert(CNContactPostalAddressesKey)
      case "organization":
        keys.insert(CNContactOrganizationNameKey)
        keys.insert(CNContactDepartmentNameKey)
        keys.insert(CNContactJobTitleKey)
      case "relation":
        keys.insert(CNContactRelationsKey)
      case "event":
        keys.insert(CNContactDatesKey)
        keys.insert(CNContactBirthdayKey)
      case "photo":
        keys.insert(CNContactImageDataAvailableKey)
        keys.insert(CNContactThumbnailImageDataKey)
      case "website":
        keys.insert(CNContactUrlAddressesKey)
      case "nickname":
        keys.insert(CNContactNicknameKey)
      default:
        break
      }
    }

    return Array(keys)
  }

  private func contactPredicate(for fields: [String], matchAll: Bool) -> NSPredicate? {
    let clauses = fields.compactMap { field -> String? in
      switch field {
      case "name":
        return "(givenName.length > 0 OR familyName.length > 0 OR organizationName.length > 0)"
      case "phone":
        return "phoneNumbers.@count > 0"
      case "email":
        return "emailAddresses.@count > 0"
      case "postalAddress":
        return "postalAddresses.@count > 0"
      case "organization":
        return "(organizationName.length > 0 OR departmentName.length > 0 OR jobTitle.length > 0)"
      case "relation":
        return "contactRelations.@count > 0"
      case "event":
        return "(dates.@count > 0 OR birthday != nil)"
      case "photo":
        return "imageDataAvailable == YES"
      case "website":
        return "urlAddresses.@count > 0"
      case "nickname":
        return "nickname.length > 0"
      default:
        return nil
      }
    }
    guard !clauses.isEmpty else { return nil }
    return NSPredicate(format: clauses.joined(separator: matchAll ? " AND " : " OR "))
  }

  private func contactMap(_ contact: CNContact) -> [String: Any] {
    var map: [String: Any] = [
      "id": contact.identifier,
      "displayName": displayName(contact),
    ]

    if available(contact, CNContactGivenNameKey) { map["givenName"] = contact.givenName }
    if available(contact, CNContactMiddleNameKey) { map["middleName"] = contact.middleName }
    if available(contact, CNContactFamilyNameKey) { map["familyName"] = contact.familyName }
    if available(contact, CNContactNamePrefixKey) { map["namePrefix"] = contact.namePrefix }
    if available(contact, CNContactNameSuffixKey) { map["nameSuffix"] = contact.nameSuffix }
    if available(contact, CNContactPhoneNumbersKey) { map["phones"] = phoneItems(contact.phoneNumbers) }
    if available(contact, CNContactEmailAddressesKey) { map["emails"] = labeledStringItems(contact.emailAddresses) }
    if available(contact, CNContactPostalAddressesKey) { map["postalAddresses"] = postalAddresses(contact.postalAddresses) }
    if available(contact, CNContactUrlAddressesKey) { map["websites"] = labeledStringItems(contact.urlAddresses) }
    if available(contact, CNContactRelationsKey) { map["relations"] = relationItems(contact.contactRelations) }
    var events: [[String: Any]] = []
    if available(contact, CNContactDatesKey) {
      events.append(contentsOf: dateItems(contact.dates))
    }
    if available(contact, CNContactBirthdayKey), let birthday = contact.birthday {
      events.append(dataItem(value: dateString(birthday), label: "birthday", type: "birthday"))
    }
    if !events.isEmpty { map["events"] = events }

    if available(contact, CNContactNicknameKey), !contact.nickname.isEmpty {
      map["nicknames"] = [["value": contact.nickname]]
    }
    if available(contact, CNContactOrganizationNameKey) ||
      available(contact, CNContactDepartmentNameKey) ||
      available(contact, CNContactJobTitleKey) {
      let organization = organizationMap(contact)
      if !organization.isEmpty { map["organizations"] = [organization] }
    }
    if available(contact, CNContactThumbnailImageDataKey),
      let thumbnail = contact.thumbnailImageData {
      map["thumbnail"] = FlutterStandardTypedData(bytes: thumbnail)
    }

    return map
  }

  private func displayName(_ contact: CNContact) -> String {
    let formatter = CNContactFormatter()
    formatter.style = .fullName
    if let name = formatter.string(from: contact), !name.isEmpty {
      return name
    }
    if available(contact, CNContactOrganizationNameKey), !contact.organizationName.isEmpty {
      return contact.organizationName
    }
    return ""
  }

  private func phoneItems(_ values: [CNLabeledValue<CNPhoneNumber>]) -> [[String: Any]] {
    return values.map {
      dataItem(value: $0.value.stringValue, label: localizedLabel($0.label), type: $0.label)
    }
  }

  private func labeledStringItems(_ values: [CNLabeledValue<NSString>]) -> [[String: Any]] {
    return values.map {
      dataItem(value: String($0.value), label: localizedLabel($0.label), type: $0.label)
    }
  }

  private func relationItems(_ values: [CNLabeledValue<CNContactRelation>]) -> [[String: Any]] {
    return values.map {
      dataItem(value: $0.value.name, label: localizedLabel($0.label), type: $0.label)
    }
  }

  private func dateItems(_ values: [CNLabeledValue<NSDateComponents>]) -> [[String: Any]] {
    return values.map {
      dataItem(value: dateString($0.value), label: localizedLabel($0.label), type: $0.label)
    }
  }

  private func postalAddresses(_ values: [CNLabeledValue<CNPostalAddress>]) -> [[String: Any]] {
    let formatter = CNPostalAddressFormatter()
    return values.map { value in
      let address = value.value
      return compact([
        "formatted": formatter.string(from: address),
        "street": address.street,
        "city": address.city,
        "region": address.state,
        "postalCode": address.postalCode,
        "country": address.country,
        "isoCountryCode": address.isoCountryCode,
        "label": localizedLabel(value.label),
        "type": value.label,
      ])
    }
  }

  private func organizationMap(_ contact: CNContact) -> [String: Any] {
    return compact([
      "company": available(contact, CNContactOrganizationNameKey) ? contact.organizationName : nil,
      "department": available(contact, CNContactDepartmentNameKey) ? contact.departmentName : nil,
      "title": available(contact, CNContactJobTitleKey) ? contact.jobTitle : nil,
    ])
  }

  private func dataItem(value: String, label: String?, type: String?) -> [String: Any] {
    return compact([
      "value": value,
      "label": label,
      "type": type,
    ])
  }

  private func compact(_ map: [String: Any?]) -> [String: Any] {
    var compacted: [String: Any] = [:]
    for (key, value) in map {
      if let value = value as? String, value.isEmpty { continue }
      if let value = value { compacted[key] = value }
    }
    return compacted
  }

  private func available(_ contact: CNContact, _ key: String) -> Bool {
    return contact.isKeyAvailable(key)
  }

  private func localizedLabel(_ label: String?) -> String? {
    guard let label = label else { return nil }
    return CNLabeledValue<NSString>.localizedString(forLabel: label)
  }

  private func dateString(_ components: DateComponents) -> String {
    let year = components.year.map { String(format: "%04d", $0) }
    let month = components.month.map { String(format: "%02d", $0) }
    let day = components.day.map { String(format: "%02d", $0) }
    return [year, month, day].compactMap { $0 }.joined(separator: "-")
  }

  private func dateString(_ components: NSDateComponents) -> String {
    let year = components.year == NSDateComponentUndefined ? nil : String(format: "%04d", components.year)
    let month = components.month == NSDateComponentUndefined ? nil : String(format: "%02d", components.month)
    let day = components.day == NSDateComponentUndefined ? nil : String(format: "%02d", components.day)
    return [year, month, day].compactMap { $0 }.joined(separator: "-")
  }
}

private struct PickerOptions {
  let fields: [String]
  let allowMultiple: Bool
  let limit: Int?
  let matchAllFields: Bool

  init?(call: FlutterMethodCall) {
    guard let arguments = call.arguments as? [String: Any] else { return nil }
    let rawFields = arguments["fields"] as? [String] ?? ["phone", "email"]
    let uniqueFields = Array(NSOrderedSet(array: rawFields)) as? [String] ?? rawFields
    guard !uniqueFields.isEmpty else { return nil }
    fields = uniqueFields
    allowMultiple = arguments["allowMultiple"] as? Bool ?? false
    limit = arguments["limit"] as? Int
    matchAllFields = arguments["matchAllFields"] as? Bool ?? false
  }
}
