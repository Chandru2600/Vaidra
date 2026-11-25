// emergency_contacts_page.dart
// Emergency contacts: list / add / edit / delete through the backend
// (/emergency-contacts, login required). Fields: name, relationship,
// phone, is_primary.
import 'package:flutter/material.dart';
import 'package:vaidra/services/api_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<dynamic> _contacts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService().getEmergencyContacts();
      if (mounted) {
        setState(() {
          _contacts = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final id = contact['id'];
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove ${contact['name'] ?? 'this contact'} from your emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService().deleteEmergencyContact(int.parse(id.toString()));
      _loadContacts();
    } catch (e) {
      _showError('Could not delete contact: $e');
    }
  }

  Future<void> _showContactForm({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    final relationshipController =
        TextEditingController(text: existing?['relationship']?.toString() ?? '');
    final phoneController = TextEditingController(text: existing?['phone']?.toString() ?? '');
    bool isPrimary = existing?['is_primary'] == true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add emergency contact' : 'Edit emergency contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                      labelText: 'Relationship (e.g. Mother, Friend)'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                CheckboxListTile(
                  title: const Text('Primary contact'),
                  value: isPrimary,
                  onChanged: (value) =>
                      setDialogState(() => isPrimary = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _showError('Name and phone number are required.');
      return;
    }
    final data = <String, dynamic>{
      'name': name,
      'relationship': relationshipController.text.trim(),
      'phone': phone,
      'is_primary': isPrimary,
    };
    try {
      if (existing == null) {
        await ApiService().addEmergencyContact(data);
      } else {
        await ApiService()
            .updateEmergencyContact(int.parse(existing['id'].toString()), data);
      }
      _loadContacts();
    } catch (e) {
      _showError('Could not save contact: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactForm(),
        backgroundColor: const Color(0xFF6B9C7A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadContacts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No emergency contacts yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final raw = _contacts[index];
                        final contact = raw is Map
                            ? Map<String, dynamic>.from(raw)
                            : <String, dynamic>{};
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: contact['is_primary'] == true
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            title: Text(
                              '${contact['name'] ?? 'Contact'}'
                              '${contact['relationship'] != null && (contact['relationship'] as String).isNotEmpty ? ' (${contact['relationship']})' : ''}'
                              '${contact['is_primary'] == true ? '  \u2022 Primary' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(contact['phone']?.toString() ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showContactForm(existing: contact),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteContact(contact),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
