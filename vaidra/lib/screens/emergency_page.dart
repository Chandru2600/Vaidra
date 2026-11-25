// emergency_page.dart
// Emergency Mode: reachable WITHOUT login. No account, no forms, no paywall.
// Big buttons, high contrast. Vaidra never tracks or stores live location:
// the Maps links below open Google Maps, which uses the phone's own location.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vaidra/services/api_service.dart';
import 'package:vaidra/services/tts_service.dart';
import 'package:vaidra/screens/first_aid_page.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({Key? key}) : super(key: key);

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  List<dynamic> _contacts = [];
  bool _loadingContacts = false;
  String? _contactsError;

  final TextEditingController _triageController = TextEditingController();
  Map<String, dynamic>? _triageResult;
  bool _triageLoading = false;
  String? _triageError;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;

  @override
  void dispose() {
    _triageController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _runTriage() async {
    final text = _triageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _triageLoading = true;
      _triageError = null;
      _triageResult = null;
    });
    try {
      final result = await ApiService().triageEmergency(text);
      if (mounted) {
        setState(() {
          _triageResult = result;
          _triageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _triageError = e.toString();
          _triageLoading = false;
        });
      }
    }
  }

  Future<void> _openGuide(String guideId) async {
    try {
      final raw = await rootBundle.loadString('assets/first_aid_guides.json');
      final data = json.decode(raw);
      final List<dynamic> guides =
          data is Map ? (data['guides'] as List<dynamic>? ?? <dynamic>[]) : <dynamic>[];
      for (final g in guides) {
        if (g is Map && g['id']?.toString() == guideId) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FirstAidDetailPage(
                guide: Map<String, dynamic>.from(g),
              ),
            ),
          );
          return;
        }
      }
      if (mounted) {
        Navigator.pushNamed(context, '/first-aid');
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushNamed(context, '/first-aid');
      }
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      // Speech recognition unavailable — the mic button stays hidden.
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      setState(() => _listening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _triageController.text = result.recognizedWords;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => _listening = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Contacts only exist for a logged-in user; the page itself works without login.
    if (ApiService().isLoggedIn) {
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loadingContacts = true;
      _contactsError = null;
    });
    try {
      final list = await ApiService().getEmergencyContacts();
      if (mounted) {
        setState(() {
          _contacts = list;
          _loadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contactsError = e.toString();
          _loadingContacts = false;
        });
      }
    }
  }

  Map<String, dynamic>? get _primaryContact {
    if (_contacts.isEmpty) return null;
    for (final c in _contacts) {
      if (c is Map && c['is_primary'] == true) {
        return Map<String, dynamic>.from(c);
      }
    }
    final first = _contacts.first;
    return first is Map ? Map<String, dynamic>.from(first) : null;
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place the call to $number')),
      );
    }
  }

  Future<void> _openMapsSearch(String query) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _primaryContact;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFDF3F3),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        title: const Text('Emergency', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'If someone is in danger, call now. Do not wait.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            // One-tap 112 — works without login.
            SizedBox(
              height: 96,
              child: ElevatedButton.icon(
                onPressed: () => _callNumber('112'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 36),
                label: const Text(
                  'CALL 112',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EmergencyActionButton(
                    label: 'Ambulance\n108',
                    icon: Icons.airport_shuttle,
                    onPressed: () => _callNumber('108'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmergencyActionButton(
                    label: 'Ambulance\n102',
                    icon: Icons.local_hospital,
                    onPressed: () => _callNumber('102'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Describe what happened',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type what happened in plain words. The assistant checks for danger signs first — it never delays calling 112 to ask more questions.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _triageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'e.g. chest pain and difficulty breathing',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_speechAvailable) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _listening ? Icons.mic_off : Icons.mic,
                      color: _listening ? Colors.red : null,
                    ),
                    tooltip: _listening
                        ? 'Stop listening'
                        : 'Speak instead of typing',
                    onPressed: _toggleListening,
                  ),
                ],
              ],
            ),
            if (_listening)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Listening… speak now',
                  style: TextStyle(fontSize: 13, color: Colors.red),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _triageLoading ? null : _runTriage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.health_and_safety),
                label: _triageLoading
                    ? const Text('Checking…', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))
                    : const Text('Check what to do', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_triageError != null) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Assistant unavailable'),
                  subtitle: Text(_triageError!),
                ),
              ),
            ],
            if (_triageResult != null) ...[
              const SizedBox(height: 12),
              _TriageResultCard(
                result: _triageResult!,
                onCall112: () => _callNumber('112'),
                onViewGuide: _triageResult!['guide_id'] != null
                    ? () => _openGuide(_triageResult!['guide_id'].toString())
                    : null,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Emergency contact',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!ApiService().isLoggedIn)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Log in to call your saved emergency contact.'),
                  subtitle: Text('Emergency numbers above work without an account.'),
                ),
              )
            else if (_loadingContacts)
              const Center(child: CircularProgressIndicator())
            else if (_contactsError != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Emergency contacts unavailable'),
                  subtitle: Text(_contactsError!),
                ),
              )
            else if (primary == null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt),
                  title: const Text('No emergency contact saved yet'),
                  subtitle: const Text('Add one from the home screen after logging in.'),
                  trailing: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/emergency-contacts'),
                    child: const Text('Add'),
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.red),
                  title: Text(
                    '${primary['name'] ?? 'Contact'}'
                    '${primary['relationship'] != null ? ' (${primary['relationship']})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(primary['phone']?.toString() ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Colors.red),
                    onPressed: () => _callNumber(primary['phone'].toString()),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Find help nearby',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _EmergencyActionButton(
              label: 'Find hospitals near me',
              icon: Icons.local_hospital,
              onPressed: () => Navigator.pushNamed(context, '/discover-hospitals'),
            ),
            const SizedBox(height: 12),
            _EmergencyActionButton(
              label: 'First-aid guides (works offline)',
              icon: Icons.menu_book,
              onPressed: () => Navigator.pushNamed(context, '/first-aid'),
            ),
            const SizedBox(height: 12),
            _EmergencyActionButton(
              label: 'Share my location via Maps',
              icon: Icons.share_location,
              onPressed: () => _openMapsSearch('hospitals near me'),
            ),
            const SizedBox(height: 12),
            Text(
              'Vaidra does not track or store your live location. The Maps link opens '
              'Google Maps, which uses your phone\u2019s own location.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _EmergencyActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 64,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black87,
          side: BorderSide(color: Colors.red.shade700, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, color: Colors.red.shade700, size: 24),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _TriageResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onCall112;
  final VoidCallback? onViewGuide;

  const _TriageResultCard({
    required this.result,
    required this.onCall112,
    this.onViewGuide,
  });

  @override
  Widget build(BuildContext context) {
    final escalation = result['escalation']?.toString() ?? '';
    final isEmergency = escalation == 'CALL_112_NOW';
    return Card(
      color: isEmergency ? Colors.red.shade50 : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isEmergency ? Icons.emergency : Icons.info_outline,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['message']?.toString() ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'General information only, not medical advice. If unsure, call 112 immediately.',
              style: TextStyle(fontSize: 13),
            ),
            Row(
              children: [
                SpeakButton(
                  text: '${result['message']?.toString() ?? ''} '
                      'If unsure, call 112 immediately.',
                ),
                const Text('Read aloud', style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            if (isEmergency)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onCall112,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.phone_in_talk),
                  label: const Text('CALL 112 NOW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            if (onViewGuide != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onViewGuide,
                icon: const Icon(Icons.menu_book),
                label: const Text('View first-aid guide'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
