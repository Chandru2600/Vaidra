// lifecard_page.dart
// My LifeCard: emergency medical profile — blood group, allergies, conditions,
// medications, notes, preferred hospital, insurance — plus a permission
// toggle for sharing with emergency contacts and a share token shown as
// plain text with a copy button. Medical data is NEVER rendered into a QR
// code; only the token is shareable.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaidra/services/api_service.dart';

class LifeCardPage extends StatefulWidget {
  const LifeCardPage({Key? key}) : super(key: key);

  @override
  State<LifeCardPage> createState() => _LifeCardPageState();
}

class _LifeCardPageState extends State<LifeCardPage> {
  static const List<String> _bloodGroups = <String>[
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  String? _bloodGroup;
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();
  final _preferredHospitalController = TextEditingController();
  final _insuranceController = TextEditingController();
  bool _shareWithContacts = false;
  String? _shareToken;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLifeCard();
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    _preferredHospitalController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  void _fillFrom(Map<String, dynamic> data) {
    final bg = data['blood_group']?.toString();
    _bloodGroup = (bg != null && _bloodGroups.contains(bg)) ? bg : null;
    _allergiesController.text = data['allergies']?.toString() ?? '';
    _conditionsController.text = data['conditions']?.toString() ?? '';
    _medicationsController.text = data['medications']?.toString() ?? '';
    _notesController.text = data['notes']?.toString() ?? '';
    _preferredHospitalController.text = data['preferred_hospital']?.toString() ?? '';
    _insuranceController.text = data['insurance']?.toString() ?? '';
    _shareWithContacts = data['share_with_contacts'] == true;
    _shareToken = data['share_token']?.toString();
  }

  Future<void> _loadLifeCard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService().getLifeCard();
      if (mounted) {
        setState(() {
          _fillFrom(data);
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

  Future<void> _saveLifeCard() async {
    setState(() => _saving = true);
    try {
      final data = await ApiService().updateLifeCard(<String, dynamic>{
        'blood_group': _bloodGroup,
        'allergies': _allergiesController.text.trim(),
        'conditions': _conditionsController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'notes': _notesController.text.trim(),
        'preferred_hospital': _preferredHospitalController.text.trim(),
        'insurance': _insuranceController.text.trim(),
        'share_with_contacts': _shareWithContacts,
      });
      if (mounted) {
        setState(() {
          _fillFrom(data);
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LifeCard saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save LifeCard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My LifeCard'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900.withOpacity(0.3)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Could not load your saved LifeCard: $_error\n'
                        'You can still fill it in below and save.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    value: _bloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood group',
                      border: OutlineInputBorder(),
                    ),
                    items: _bloodGroups
                        .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => _bloodGroup = value),
                  ),
                  const SizedBox(height: 16),
                  _field(_allergiesController, 'Allergies',
                      'e.g. Penicillin, peanuts (comma separated)'),
                  const SizedBox(height: 16),
                  _field(_conditionsController, 'Medical conditions',
                      'e.g. Asthma, diabetes (comma separated)'),
                  const SizedBox(height: 16),
                  _field(_medicationsController, 'Current medications',
                      'Names only — no doses here'),
                  const SizedBox(height: 16),
                  _field(_preferredHospitalController, 'Preferred hospital', ''),
                  const SizedBox(height: 16),
                  _field(_insuranceController, 'Insurance', 'Provider / policy reference'),
                  const SizedBox(height: 16),
                  _field(_notesController, 'Notes', 'Anything responders should know',
                      maxLines: 3),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Share with emergency contacts'),
                    subtitle: const Text(
                      'Your emergency contacts may see this LifeCard. '
                      'You control this switch.',
                    ),
                    value: _shareWithContacts,
                    onChanged: (value) => setState(() => _shareWithContacts = value),
                  ),
                  const SizedBox(height: 8),
                  if (_shareToken != null && _shareToken!.isNotEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text('Share token'),
                        subtitle: SelectableText(
                          _shareToken!,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy token',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _shareToken!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share token copied')),
                            );
                          },
                        ),
                      ),
                    ),
                  if (_shareToken == null || _shareToken!.isEmpty)
                    const Text(
                      'A share token will appear here after you save your LifeCard.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveLifeCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9C7A),
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save LifeCard',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your medical details stay on your account and are only shared '
                    'when you turn sharing on. They are never put into a QR code.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
