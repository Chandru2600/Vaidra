// family_page.dart
// Family Relay: family groups, incidents and status updates.
// Location is never tracked — the toggle only records whether you agree
// to share your location with the group during an incident.
// All data comes from the backend (/family/*); nothing is fabricated.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaidra/services/api_service.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({Key? key}) : super(key: key);

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  List<dynamic> _groups = [];
  bool _loading = true;
  String? _error;
  final _createController = TextEditingController();
  final _joinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _createController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await ApiService().getFamilyGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
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

  int? _groupId(dynamic raw) {
    if (raw is Map && raw['id'] != null) {
      return int.tryParse(raw['id'].toString());
    }
    return null;
  }

  Future<void> _createGroup() async {
    final name = _createController.text.trim();
    if (name.isEmpty) return;
    try {
      final group = await ApiService().createFamilyGroup(name);
      _createController.clear();
      await _load();
      if (mounted) {
        final code = group['invite_code']?.toString() ?? '';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Group created'),
            content: code.isEmpty
                ? const Text('Share the group name with your family to join.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Share this invite code with your family:'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              code,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invite code copied')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
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

  Future<void> _joinGroup() async {
    final code = _joinController.text.trim();
    if (code.isEmpty) return;
    try {
      await ApiService().joinFamilyGroup(code);
      _joinController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined the family group')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Relay'),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.amber.shade900.withOpacity(0.25)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Location is never tracked — this only records whether you '
                          'agree to share it with your family during an incident.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'My groups',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_groups.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.family_restroom),
                            title: Text('No family groups yet'),
                            subtitle: Text(
                                'Create a group or join one with an invite code.'),
                          ),
                        )
                      else
                        ..._groups.map((raw) {
                          final group =
                              raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.family_restroom,
                                  color: Color(0xFF6B9C7A)),
                              title: Text(
                                group['name']?.toString() ?? 'Family group',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                group['invite_code'] != null
                                    ? 'Invite code: ${group['invite_code']}'
                                    : 'Tap to open',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                final id = _groupId(group);
                                if (id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupDetailPage(
                                        groupId: id,
                                        groupName:
                                            group['name']?.toString() ?? 'Family group',
                                        members: group['members'] is List
                                            ? List<dynamic>.from(
                                                group['members'] as List)
                                            : <dynamic>[],
                                      ),
                                    ),
                                  ).then((_) => _load());
                                }
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                      const Text(
                        'Create a group',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _createController,
                              decoration: const InputDecoration(
                                hintText: 'Group name, e.g. Loni Family',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _createGroup,
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Join a group',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _joinController,
                              decoration: const InputDecoration(
                                hintText: 'Invite code',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _joinGroup,
                            child: const Text('Join'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class GroupDetailPage extends StatefulWidget {
  final int groupId;
  final String groupName;
  final List<dynamic> members;

  const GroupDetailPage(
      {Key? key,
      required this.groupId,
      required this.groupName,
      required this.members})
      : super(key: key);

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<dynamic> _incidents = [];
  bool _loading = true;
  String? _error;
  bool _shareLocation = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _hospitalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final incidents =
          await ApiService().getGroupIncidents(widget.groupId);
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _loading = false;
        });
      }
      // Initialise the sharing toggle from my own membership record.
      try {
        final profile = await ApiService().getProfile();
        final myId = profile['id']?.toString();
        if (myId != null && mounted) {
          for (final raw in widget.members) {
            if (raw is Map && raw['user_id']?.toString() == myId) {
              setState(() {
                _shareLocation = raw['can_share_location'] == true;
              });
              break;
            }
          }
        }
      } catch (_) {
        // Sharing flag stays at its default; the toggle still works.
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

  int? _incidentId(dynamic raw) {
    if (raw is Map && raw['id'] != null) {
      return int.tryParse(raw['id'].toString());
    }
    return null;
  }

  Future<void> _toggleSharing(bool value) async {
    final previous = _shareLocation;
    setState(() => _shareLocation = value);
    try {
      await ApiService().setLocationSharing(widget.groupId, value);
    } catch (e) {
      if (mounted) {
        setState(() => _shareLocation = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _createIncident() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    try {
      await ApiService().createIncident(widget.groupId, {
        'title': title,
        'description': _descController.text.trim(),
        'hospital_destination': _hospitalController.text.trim(),
      });
      _titleController.clear();
      _descController.clear();
      _hospitalController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident shared with the group')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
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
                      SwitchListTile(
                        title: const Text('Share my location in an incident'),
                        subtitle: const Text(
                          'Off by default. This only records your consent — '
                          'your location is never tracked by Vaidra.',
                        ),
                        value: _shareLocation,
                        onChanged: _toggleSharing,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Members',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (widget.members.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.people_outline),
                            title: Text('No member list available yet'),
                          ),
                        )
                      else
                        ...widget.members.map((raw) {
                          final member = raw is Map
                              ? Map<String, dynamic>.from(raw)
                              : <String, dynamic>{};
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(
                                member['name']?.toString() ?? 'Member',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                  member['email']?.toString() ?? ''),
                              trailing:
                                  member['can_share_location'] == true
                                      ? const Chip(
                                          label: Text('Sharing location'))
                                      : null,
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      const Text(
                        'Incidents',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_incidents.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('No incidents in this group yet'),
                          ),
                        )
                      else
                        ..._incidents.map((raw) {
                          final incident = raw is Map
                              ? Map<String, dynamic>.from(raw)
                              : <String, dynamic>{};
                          final status =
                              incident['status']?.toString() ?? 'open';
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                status.toLowerCase() == 'resolved'
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                color: status.toLowerCase() == 'resolved'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                incident['title']?.toString() ?? 'Incident',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${incident['description']?.toString() ?? ''}'
                                '${incident['hospital_destination'] != null && incident['hospital_destination'].toString().isNotEmpty ? '\nGoing to: ${incident['hospital_destination']}' : ''}'
                                '\nStatus: $status',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                final id = _incidentId(incident);
                                if (id != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          IncidentDetailPage(
                                        incidentId: id,
                                        groupId: widget.groupId,
                                        title: incident['title']
                                                ?.toString() ??
                                            'Incident',
                                      ),
                                    ),
                                  ).then((_) => _load());
                                }
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                      const Text(
                        'Report an incident',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'What happened? e.g. Fall at home',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Details (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _hospitalController,
                        decoration: const InputDecoration(
                          hintText: 'Hospital destination (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _createIncident,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.warning_amber_rounded),
                          label: const Text('Share incident with group'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class IncidentDetailPage extends StatefulWidget {
  final int incidentId;
  final int groupId;
  final String title;

  const IncidentDetailPage(
      {Key? key,
      required this.incidentId,
      required this.groupId,
      required this.title})
      : super(key: key);

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  List<dynamic> _updates = [];
  bool _loading = true;
  String? _error;
  final _updateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _updateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // The backend embeds updates in each incident of the group list;
      // there is no separate GET endpoint for one incident's updates.
      final incidents =
          await ApiService().getGroupIncidents(widget.groupId);
      Map<String, dynamic>? found;
      for (final raw in incidents) {
        if (raw is Map &&
            raw['id']?.toString() == widget.incidentId.toString()) {
          found = Map<String, dynamic>.from(raw);
          break;
        }
      }
      if (mounted) {
        setState(() {
          _updates = found != null && found['updates'] is List
              ? List<dynamic>.from(found['updates'] as List)
              : <dynamic>[];
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

  Future<void> _addUpdate() async {
    final message = _updateController.text.trim();
    if (message.isEmpty) return;
    try {
      await ApiService().addIncidentUpdate(widget.incidentId, message);
      _updateController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _resolve() async {
    try {
      await ApiService().resolveIncident(widget.incidentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident marked as resolved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
              : Column(
                  children: [
                    Expanded(
                      child: _updates.isEmpty
                          ? const Center(
                              child: Text('No status updates yet.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _updates.length,
                              itemBuilder: (context, index) {
                                final raw = _updates[index];
                                final update = raw is Map
                                    ? Map<String, dynamic>.from(raw)
                                    : <String, dynamic>{};
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.update),
                                    title: Text(update['message']
                                            ?.toString() ??
                                        ''),
                                    subtitle: Text([
                                      if (update['author_name'] != null)
                                        update['author_name'].toString(),
                                      if (update['created_at'] != null)
                                        update['created_at'].toString(),
                                    ].join(' • ')),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _updateController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a status update…',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addUpdate,
                                child: const Text('Post'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _resolve,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Mark as resolved'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
