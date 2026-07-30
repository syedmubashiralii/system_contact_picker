import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_contact_picker/system_contact_picker.dart';

void main() {
  runApp(const ContactPickerExampleApp());
}

class ContactPickerExampleApp extends StatelessWidget {
  const ContactPickerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ContactPickerExamplePage(),
    );
  }
}

class ContactPickerExamplePage extends StatefulWidget {
  const ContactPickerExamplePage({super.key});

  @override
  State<ContactPickerExamplePage> createState() =>
      _ContactPickerExamplePageState();
}

class _ContactPickerExamplePageState extends State<ContactPickerExamplePage> {
  final _picker = const SystemContactPicker();
  ContactPickerCapabilities? _capabilities;
  List<PickedContact> _contacts = const <PickedContact>[];
  String? _error;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await _picker.getCapabilities();
      if (!mounted) return;
      setState(() => _capabilities = capabilities);
    } catch (_) {
      // Widget tests run without a platform implementation.
    }
  }

  Future<void> _pickField(ContactField field) async {
    await _run(() {
      return _picker.pickContacts(fields: <ContactField>{field});
    });
  }

  Future<void> _pickMultiple() async {
    await _run(() {
      return _picker.pickContacts(
        allowMultiple: true,
        limit: 5,
        fields: const <ContactField>{ContactField.phone, ContactField.email},
      );
    });
  }

  Future<void> _pickPhoneOnly() async {
    await _pickField(ContactField.phone);
  }

  Future<void> _pickRichContact() async {
    await _run(() {
      return _picker.pickContacts(
        fields: <ContactField>{...ContactField.values},
      );
    });
  }

  Future<void> _run(Future<List<PickedContact>> Function() action) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final contacts = await action();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _error = '${error.code}: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  bool _supportsFields(Iterable<ContactField> fields) {
    final capabilities = _capabilities;
    return capabilities != null &&
        fields.every(capabilities.supportedFields.contains);
  }

  String _pickerMode(ContactPickerCapabilities capabilities) {
    if (capabilities.platform == 'android') {
      if (capabilities.usesAndroid17ContactPicker) {
        return 'Android 17+ privacy-preserving Contact Picker';
      }
      return 'Android 9–16 permissionless legacy picker';
    }
    return 'iOS ContactsUI picker';
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _capabilities;
    return Scaffold(
      appBar: AppBar(title: const Text('System Contact Picker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (capabilities == null)
            const LinearProgressIndicator()
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _pickerMode(capabilities),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Platform: ${capabilities.platform}'
                      '${capabilities.androidSdkInt == null ? '' : ' · API ${capabilities.androidSdkInt}'}\n'
                      'Contacts permission: not required\n'
                      'Selection: ${capabilities.supportsMultiple ? 'single or multiple' : 'one contact and one field'}\n'
                      'Supported fields: ${ContactField.values.where(capabilities.supportedFields.contains).map((field) => field.name).join(', ')}',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Permissionless examples',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                onPressed:
                    !_isBusy &&
                        _supportsFields(<ContactField>[ContactField.phone])
                    ? _pickPhoneOnly
                    : null,
                child: const Text('Pick phone'),
              ),
              OutlinedButton(
                onPressed:
                    !_isBusy &&
                        _supportsFields(<ContactField>[ContactField.email])
                    ? () => _pickField(ContactField.email)
                    : null,
                child: const Text('Pick email'),
              ),
              OutlinedButton(
                onPressed:
                    !_isBusy &&
                        _supportsFields(<ContactField>[
                          ContactField.postalAddress,
                        ])
                    ? () => _pickField(ContactField.postalAddress)
                    : null,
                child: const Text('Pick address'),
              ),
              OutlinedButton(
                onPressed:
                    !_isBusy &&
                        _supportsFields(<ContactField>[ContactField.name])
                    ? () => _pickField(ContactField.name)
                    : null,
                child: const Text('Pick name'),
              ),
            ],
          ),
          if (capabilities?.supportsMultiple ?? false) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Multi-contact selection',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed:
                      !_isBusy &&
                          _supportsFields(<ContactField>[
                            ContactField.phone,
                            ContactField.email,
                          ])
                      ? _pickMultiple
                      : null,
                  child: const Text('Pick up to 5 contacts'),
                ),
                FilledButton.tonal(
                  onPressed: !_isBusy && _supportsFields(ContactField.values)
                      ? _pickRichContact
                      : null,
                  child: const Text('Pick all fields'),
                ),
              ],
            ),
          ] else if (capabilities != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Multiple contact selection is unavailable on Android 9–16. '
                  'Google’s permissionless system picker supports it starting with '
                  'Android 17 (API 37). This device can select one contact at a time.',
                ),
              ),
            ),
          ],
          if (_isBusy) ...<Widget>[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          for (final contact in _contacts) ContactTile(contact: contact),
        ],
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({required this.contact, super.key});

  final PickedContact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              contact.displayName.isEmpty ? '(No name)' : contact.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final phone in contact.phones) Text('Phone: ${phone.value}'),
            for (final email in contact.emails) Text('Email: ${email.value}'),
            for (final address in contact.postalAddresses)
              Text('Address: ${address.formatted ?? address.street ?? ''}'),
            for (final organization in contact.organizations)
              Text('Organization: ${organization.company ?? ''}'),
            for (final website in contact.websites)
              Text('Website: ${website.value}'),
            for (final relation in contact.relations)
              Text('Relation: ${relation.value}'),
            for (final event in contact.events) Text('Event: ${event.value}'),
            for (final nickname in contact.nicknames)
              Text('Nickname: ${nickname.value}'),
            if (contact.thumbnail != null) const Text('Photo: available'),
          ],
        ),
      ),
    );
  }
}
