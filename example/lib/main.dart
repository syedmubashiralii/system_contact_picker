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

  Future<void> _pickSingle() async {
    await _run(() async {
      final contact = await _picker.pickContact();
      return contact == null
          ? const <PickedContact>[]
          : <PickedContact>[contact];
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
    await _run(() {
      return _picker.pickContacts(
        fields: const <ContactField>{ContactField.phone},
      );
    });
  }

  Future<void> _run(Future<List<PickedContact>> Function() action) async {
    try {
      final contacts = await action();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _error = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _error = '${error.code}: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _capabilities;
    return Scaffold(
      appBar: AppBar(title: const Text('System Contact Picker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (capabilities != null)
            Text(
              'Platform: ${capabilities.platform}'
              '${capabilities.androidSdkInt == null ? '' : ' API ${capabilities.androidSdkInt}'}\n'
              'Multiple: ${capabilities.supportsMultiple ? 'supported' : 'single contact fallback'}\n'
              'Permission: ${capabilities.requiresReadContactsPermission ? 'READ_CONTACTS below API 37' : 'system picker'}',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                onPressed: _pickSingle,
                child: const Text('Pick one'),
              ),
              FilledButton.tonal(
                onPressed: _pickMultiple,
                child: const Text('Pick up to 5'),
              ),
              OutlinedButton(
                onPressed: _pickPhoneOnly,
                child: const Text('Phone only'),
              ),
            ],
          ),
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
          ],
        ),
      ),
    );
  }
}
