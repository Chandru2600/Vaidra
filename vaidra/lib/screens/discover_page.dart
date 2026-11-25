// discover_page.dart
// Nearby hospital / pharmacy / ambulance / blood-bank / diagnostic-centre
// discovery through the backend (GET /discover/*), which reads live
// OpenStreetMap data. Vaidra shows no hours, beds or availability — only
// what OpenStreetMap returns — and labels it as unverified.
// Coordinates default to the Chennai pilot area; the user can change them.
// No location is ever faked: the defaults are labelled as the pilot city.
// No booking or dispatch: the ambulance screen only offers a call-108 button.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:vaidra/services/api_service.dart';

class DiscoverPage extends StatefulWidget {
  final String type; // 'hospital' | 'pharmacy' | 'ambulance' | 'blood-bank' | 'diagnostic'

  const DiscoverPage({Key? key, required this.type}) : super(key: key);

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _latController = TextEditingController(text: '13.0827');
  final _lngController = TextEditingController(text: '80.2707');
  List<dynamic> _results = [];
  bool _loading = true;
  String? _error;

  bool get _isHospital => widget.type == 'hospital';
  bool get _isPharmacy => widget.type == 'pharmacy';
  bool get _isAmbulance => widget.type == 'ambulance';
  bool get _isBloodBank => widget.type == 'blood-bank';
  bool get _isDiagnostic => widget.type == 'diagnostic';

  String get _title {
    if (_isHospital) return 'Find Hospitals';
    if (_isPharmacy) return 'Find Medical Shops';
    if (_isAmbulance) return 'Find Ambulances';
    if (_isBloodBank) return 'Find Blood Banks';
    return 'Find Diagnostic Centres';
  }

  String get _emptyLabel {
    if (_isHospital) return 'hospitals';
    if (_isPharmacy) return 'medical shops';
    if (_isAmbulance) return 'ambulance services';
    if (_isBloodBank) return 'blood banks';
    return 'diagnostic centres';
  }

  IconData get _icon {
    if (_isHospital) return Icons.local_hospital;
    if (_isPharmacy) return Icons.local_pharmacy;
    if (_isAmbulance) return Icons.airport_shuttle;
    if (_isBloodBank) return Icons.bloodtype;
    return Icons.biotech;
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      setState(() => _error = 'Enter a valid latitude and longitude.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<dynamic> results;
      if (_isHospital) {
        results = await ApiService().discoverHospitals(lat: lat, lng: lng);
      } else if (_isPharmacy) {
        results = await ApiService().discoverPharmacies(lat: lat, lng: lng);
      } else if (_isAmbulance) {
        results = await ApiService().discoverAmbulances(lat: lat, lng: lng);
      } else if (_isBloodBank) {
        results = await ApiService().discoverBloodBanks(lat: lat, lng: lng);
      } else {
        results = await ApiService().discoverDiagnostics(lat: lat, lng: lng);
      }
      if (mounted) {
        setState(() {
          _results = results;
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

  String _formatDistance(dynamic value) {
    if (value is num) {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)} km away';
      }
      return '${value.toInt()} m away';
    }
    if (value is String && value.isNotEmpty) return value;
    return 'Distance unknown';
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    }
  }

  Future<void> _openInMaps(Map<String, dynamic> place) async {
    final name = place['name']?.toString() ?? '';
    final address = place['address']?.toString() ?? '';
    final query = address.isEmpty ? name : '$name, $address';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lngController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9C7A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                if (_isAmbulance) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _callNumber('108'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text(
                        'CALL 108 — Ambulance',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ambulances are not booked in the app. In an emergency call 108 or 112.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Default search area: Chennai (pilot city). '
                  'Details from OpenStreetMap, not verified by Vaidra. '
                  'No hours, beds or availability are shown.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
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
                                onPressed: _search,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'No $_emptyLabel found near this location.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final raw = _results[index];
                              final place = raw is Map
                                  ? Map<String, dynamic>.from(raw)
                                  : <String, dynamic>{};
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: Icon(
                                    _icon,
                                    color: const Color(0xFF6B9C7A),
                                  ),
                                  title: Text(
                                    place['name']?.toString() ?? 'Unnamed place',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${place['address']?.toString() ?? 'Address not listed'}\n'
                                    '${_formatDistance(place['distance'])}',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openInMaps(place),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
