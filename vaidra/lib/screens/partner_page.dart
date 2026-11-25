// partner_page.dart
// Partner registration for hospitals and pharmacies.
// Shows the verification status (pending / verified / rejected). A verified
// partner can update its own availability — only what the partner reports
// is ever shown, never inferred. Admin verification happens via the API;
// there is no admin screen in the app.
import 'package:flutter/material.dart';
import 'package:vaidra/services/api_service.dart';

class PartnerPage extends StatefulWidget {
  const PartnerPage({Key? key}) : super(key: key);

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  Map<String, dynamic> _partner = {};
  bool _hasPartner = false;
  bool _loading = true;
  String? _error;

  String _orgType = 'hospital';
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _erStatus = 'Open';
  final _icuController = TextEditingController();
  final _bedsController = TextEditingController();
  final _diagnosticsController = TextEditingController();
  final _specialistsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _icuController.dispose();
    _bedsController.dispose();
    _diagnosticsController.dispose();
    _specialistsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final partner = await ApiService().getMyPartner();
      if (mounted) {
        setState(() {
          _partner = partner;
          _hasPartner = partner.isNotEmpty;
          _loading = false;
        });
        _fillAvailabilityFields();
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

  void _fillAvailabilityFields() {
    // Availability is flat on the partner object (no nested map).
    _erStatus = _partner['er_status']?.toString() ?? 'Open';
    _icuController.text = _partner['icu_beds_available']?.toString() ?? '';
    _bedsController.text =
        _partner['general_beds_available']?.toString() ?? '';
    _diagnosticsController.text =
        _partner['diagnostics_available']?.toString() ?? '';
    _specialistsController.text =
        _partner['specialists_available']?.toString() ?? '';
  }

  String _status() => _partner['verification_status']?.toString() ?? 'pending';
  bool get _isVerified => _status().toLowerCase() == 'verified';

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the organisation name')),
      );
      return;
    }
    try {
      await ApiService().registerPartner({
        'org_type': _orgType,
        'org_name': name,
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Registration submitted — verification status: pending.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _saveAvailability() async {
    try {
      await ApiService().updatePartnerAvailability({
        'er_status': _erStatus,
        'icu_beds_available': int.tryParse(_icuController.text.trim()),
        'general_beds_available': int.tryParse(_bedsController.text.trim()),
        'diagnostics_available': _diagnosticsController.text.trim(),
        'specialists_available': _specialistsController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner registration'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_hasPartner) ...[
                        const Text(
                          'Register your hospital or pharmacy with Vaidra. '
                          'Verification is done by the Vaidra team — this '
                          'form only submits your details.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _orgType,
                          decoration: const InputDecoration(
                            labelText: 'Organisation type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'hospital',
                                child: Text('Hospital')),
                            DropdownMenuItem(
                                value: 'pharmacy',
                                child: Text('Pharmacy')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _orgType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Organisation name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B9C7A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Submit registration'),
                          ),
                        ),
                      ] else ...[
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.business,
                              color: _statusColor(_status()),
                            ),
                            title: Text(
                              _partner['org_name']?.toString() ??
                                  'Your organisation',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${_partner['org_type']?.toString() ?? ''}'
                              '${_partner['address'] != null ? '\n${_partner['address']}' : ''}',
                            ),
                            isThreeLine: true,
                            trailing: Chip(
                              label: Text(_status()),
                              backgroundColor: _statusColor(_status())
                                  .withOpacity(0.15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_isVerified)
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.hourglass_top),
                              title: Text('Awaiting verification'),
                              subtitle: Text(
                                'The Vaidra team verifies partner details. '
                                'Availability can be updated once verified.',
                              ),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Update availability',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Only what you report is shown — never inferred.',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _erStatus,
                            decoration: const InputDecoration(
                              labelText: 'Emergency (ER) status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Open', child: Text('Open')),
                              DropdownMenuItem(
                                  value: 'Limited',
                                  child: Text('Limited')),
                              DropdownMenuItem(
                                  value: 'Closed',
                                  child: Text('Closed')),
                              DropdownMenuItem(
                                  value: 'Unknown',
                                  child: Text('Unknown')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _erStatus = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _icuController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'ICU beds',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _bedsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'General beds',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _diagnosticsController,
                            decoration: const InputDecoration(
                              labelText: 'Diagnostics available',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _specialistsController,
                            decoration: const InputDecoration(
                              labelText: 'Specialists on duty',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saveAvailability,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B9C7A),
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  const Text('Save availability'),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}
