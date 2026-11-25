// history_detail_page.dart
// Detail view for a past scan, opened from the home history list.
// Fetches GET /scans/{id} and shows the same "Preliminary guidance —
// not a diagnosis" card as the fresh-upload result screen. The scan image
// is shown only when the backend returns a usable http(s) URL; otherwise a
// placeholder icon is shown. Never crashes on a missing image or field.
import 'package:flutter/material.dart';
import 'package:vaidra/services/api_service.dart';
import 'package:vaidra/services/tts_service.dart';

class HistoryDetailPage extends StatefulWidget {
  final String scanId;
  final String? fallbackTitle;

  const HistoryDetailPage({Key? key, required this.scanId, this.fallbackTitle})
      : super(key: key);

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  Map<String, dynamic>? _scan;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scan = await ApiService().getScanById(widget.scanId);
      if (mounted) {
        setState(() {
          _scan = scan;
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

  Map<String, dynamic> _resultMap() {
    if (_scan != null) {
      final result = _scan!['result'];
      if (result is Map) return Map<String, dynamic>.from(result);
    }
    return <String, dynamic>{};
  }

  String? _imageUrl() {
    if (_scan == null) return null;
    for (final key in ['image_url', 'imageUrl', 'image']) {
      final value = _scan![key];
      if (value is String && value.startsWith('http')) return value;
    }
    return null;
  }

  String _speakText(Map<String, dynamic> result) {
    final steps = _asStrings(result['steps']);
    final parts = <String>[
      'Possible condition: ${result['condition'] ?? 'unknown'}.',
      'Confidence: ${_confidence(result)} percent.',
      'Severity: ${result['severity'] ?? 'unknown'}.',
    ];
    if (steps.isNotEmpty) {
      parts.add('First aid: ${steps.join('. ')}');
    }
    return parts.join(' ');
  }

  List<String> _asStrings(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return <String>[value];
    }
    return <String>[];
  }

  int _confidence(Map<String, dynamic> result) {
    final value = result['confidence'];
    if (value is num) return value.toInt();
    return 0;
  }

  Color _sevColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'URGENT':
        return Colors.red;
      case 'MODERATE':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _resultMap();
    final imageUrl = _imageUrl();
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: Text(widget.fallbackTitle ?? 'Scan detail'),
        actions: [
          if (_scan != null) SpeakButton(text: _speakText(result)),
        ],
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
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
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
                    children: [
                      // Safety wording: preliminary guidance, never a diagnosis.
                      Card(
                        color: isDark
                            ? Colors.amber.shade900.withOpacity(0.25)
                            : Colors.amber.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_rounded,
                              color: Colors.amber),
                          title: const Text(
                            'Preliminary guidance — not a diagnosis',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            result['disclaimer']?.toString() ??
                                'This is AI-generated general information only. '
                                    'It may be wrong and it is not a medical diagnosis. '
                                    'See a qualified doctor for a diagnosis. '
                                    'In an emergency call 112.',
                          ),
                        ),
                      ),
                      if (result['uncertainty'] != null &&
                          result['uncertainty'].toString().isNotEmpty)
                        Card(
                          color: isDark ? const Color(0xFF1E1E1E) : null,
                          child: ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('About this result'),
                            subtitle: Text(result['uncertainty'].toString()),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Card(
                        color: isDark ? const Color(0xFF1E1E1E) : null,
                        child: Column(
                          children: [
                            if (imageUrl != null)
                              Image.network(
                                imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 64, color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(
                                height: 120,
                                child: Center(
                                  child: Icon(Icons.image_outlined,
                                      size: 64, color: Colors.grey),
                                ),
                              ),
                            ListTile(
                              title: Text(
                                'Possible condition: ${result['condition'] ?? 'Unknown'}',
                                style: TextStyle(
                                    color: isDark ? Colors.white : null),
                              ),
                              subtitle: Text(
                                'Confidence: ${_confidence(result)}%',
                                style: TextStyle(
                                    color: isDark ? Colors.white70 : null),
                              ),
                              trailing: Chip(
                                label: Text(
                                    'Severity: ${result['severity'] ?? 'Unknown'}'),
                                backgroundColor: _sevColor(
                                    result['severity']?.toString() ?? ''),
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        color: isDark ? const Color(0xFF1E1E1E) : null,
                        child: ListTile(
                          title: Text('First aid',
                              style: TextStyle(
                                  color: isDark ? Colors.white : null)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _asStrings(result['steps']).isNotEmpty
                                ? _asStrings(result['steps'])
                                    .map((s) => Text('• $s',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null)))
                                    .toList()
                                : [
                                    Text('No specific steps provided. Consult a doctor.',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null))
                                  ],
                          ),
                        ),
                      ),
                      Card(
                        color: isDark
                            ? Colors.red.shade900.withOpacity(0.2)
                            : Colors.red.shade50,
                        child: ListTile(
                          title: Text(
                            'Warning signs',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.redAccent
                                    : Colors.red),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _asStrings(result['warnings']).isNotEmpty
                                ? _asStrings(result['warnings'])
                                    .map((w) => Text('• $w',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null)))
                                    .toList()
                                : [
                                    Text('Monitor for worsening symptoms.',
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : null))
                                  ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/emergency'),
                        icon: const Icon(Icons.phone),
                        label: const Text('Emergency help'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
