// first_aid_page.dart
// First-aid learning guides. The bundled JSON in assets/ is the source of
// truth and works fully offline. If the backend is reachable, fresher guides
// from GET /first-aid/guides replace the bundled copy; any failure keeps the
// bundled copy. Content is general information only — no medication names,
// no dosages, no prescription advice.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaidra/services/api_service.dart';
import 'package:vaidra/services/tts_service.dart';

const String _kDisclaimer =
    'General information only, not medical advice. In an emergency call 112.';

class FirstAidPage extends StatefulWidget {
  const FirstAidPage({Key? key}) : super(key: key);

  @override
  State<FirstAidPage> createState() => _FirstAidPageState();
}

class _FirstAidPageState extends State<FirstAidPage> {
  List<dynamic> _guides = [];
  bool _loading = true;
  String _source = 'offline';

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    // Bundled copy first — always works offline.
    try {
      final raw = await rootBundle.loadString('assets/first_aid_guides.json');
      final data = json.decode(raw);
      final List<dynamic> bundled =
          data is Map ? (data['guides'] as List<dynamic>? ?? <dynamic>[]) : <dynamic>[];
      if (mounted) {
        setState(() {
          _guides = bundled;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
    // Try the server for fresher content; keep the bundled copy on any failure.
    try {
      final remote = await ApiService().getFirstAidGuides();
      if (remote.isNotEmpty && mounted) {
        setState(() {
          _guides = remote;
          _source = 'server';
        });
      }
    } catch (_) {
      // Offline or backend not updated yet — bundled guides stay.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('First-Aid Learning'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _guides.isEmpty
              ? const Center(child: Text('No first-aid guides available.'))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: isDark ? Colors.amber.shade900.withOpacity(0.25) : Colors.amber.shade50,
                      child: Text(
                        _source == 'server'
                            ? '$_kDisclaimer Guides updated from the server.'
                            : '$_kDisclaimer Guides stored on your phone — works offline.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _guides.length,
                        itemBuilder: (context, index) {
                          final guide = _guides[index];
                          final map = guide is Map ? guide : <String, dynamic>{};
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.menu_book, color: Colors.red),
                              title: Text(
                                map['title']?.toString() ?? 'Guide',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FirstAidDetailPage(
                                      guide: Map<String, dynamic>.from(map),
                                    ),
                                  ),
                                );
                              },
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

class FirstAidDetailPage extends StatelessWidget {
  final Map<String, dynamic> guide;

  const FirstAidDetailPage({Key? key, required this.guide}) : super(key: key);

  List<String> _asStrings(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return <String>[value];
    }
    return <String>[];
  }

  Widget _section(BuildContext context, String heading, List<String> items,
      {Color? headingColor}) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: headingColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u2022  ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
                ],
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }

  String _speakText() {
    final parts = <String>[
      guide['title']?.toString() ?? 'First-aid guide',
    ];
    final danger = _asStrings(guide['danger_signs']);
    if (danger.isNotEmpty) {
      parts.add('Danger signs: ${danger.join('. ')}');
    }
    final steps = _asStrings(guide['steps']);
    if (steps.isNotEmpty) {
      parts.add('What to do: ${steps.join('. ')}');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(guide['title']?.toString() ?? 'First-aid guide'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        actions: [
          SpeakButton(text: _speakText()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900.withOpacity(0.25) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                guide['disclaimer']?.toString() ?? _kDisclaimer,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            _section(context, 'Danger signs', _asStrings(guide['danger_signs']),
                headingColor: Colors.red),
            _section(context, 'What to do', _asStrings(guide['steps'])),
            _section(context, 'What NOT to do', _asStrings(guide['what_not_to_do'])),
            _section(context, 'Call 112 when', _asStrings(guide['call_112_when']),
                headingColor: Colors.red),
          ],
        ),
      ),
    );
  }
}
