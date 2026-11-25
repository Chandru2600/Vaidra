// subscriptions_page.dart
// Subscription plans. Honest by design:
// - Emergency guidance is never paywalled.
// - Prices are hypotheses for market testing — no payment is charged in
//   this version. Subscribing only records intent (status pending_payment).
// All data comes from the backend (/subscriptions/*); nothing is invented.
import 'package:flutter/material.dart';
import 'package:vaidra/services/api_service.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  List<dynamic> _plans = [];
  Map<String, dynamic> _mine = {};
  bool _loading = true;
  String? _error;

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
      final plans = await ApiService().getPlans();
      Map<String, dynamic> mine = {};
      try {
        mine = await ApiService().getMySubscription();
      } catch (_) {
        // No subscription yet — Basic (free) is the default.
      }
      if (mounted) {
        setState(() {
          _plans = plans;
          _mine = mine;
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

  String _currentPlanId() {
    for (final key in ['plan_id', 'planId', 'plan']) {
      final value = _mine[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  String _planDisplayName(String plan) {
    switch (plan.toUpperCase()) {
      case 'PERSONAL_BASIC':
        return 'Personal Basic (free)';
      case 'PERSONAL_PREMIUM':
        return 'Personal Premium';
      case 'FAMILY_PREMIUM':
        return 'Family Premium';
      default:
        if (plan.isEmpty) return 'Basic (free)';
        return plan
            .split('_')
            .map((w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  String _priceText(Map<String, dynamic> plan) {
    for (final key in ['price_text', 'price_display', 'price']) {
      final value = plan[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  List<String> _features(Map<String, dynamic> plan) {
    final value = plan['features'];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    final id = plan['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final result = await ApiService().subscribePlan(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Intent recorded${result['status'] != null ? ' — status: ${result['status']}' : ''}. No payment was charged.',
            ),
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

  Future<void> _cancel() async {
    try {
      await ApiService().cancelSubscription();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription cancelled')),
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
    final currentId = _currentPlanId();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
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
                              ? Colors.green.shade900.withOpacity(0.4)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Emergency guidance is never paywalled.\n'
                          'Prices below are hypotheses for market testing — '
                          'no payment is charged in this version.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_mine.isNotEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.star,
                                color: Color(0xFF6B9C7A)),
                            title: Text(
                              'Your plan: ${_planDisplayName(currentId)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                                'Status: ${_mine['status']?.toString() ?? 'active'}'),
                            trailing: currentId.isNotEmpty
                                ? TextButton(
                                    onPressed: _cancel,
                                    child: const Text('Cancel'),
                                  )
                                : null,
                          ),
                        ),
                      if (_mine.isNotEmpty) const SizedBox(height: 12),
                      if (_plans.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('No plans listed yet'),
                            subtitle: Text(
                                'Plans are set by the Vaidra team — check back later.'),
                          ),
                        )
                      else
                        ..._plans.map((raw) {
                          final plan = raw is Map
                              ? Map<String, dynamic>.from(raw)
                              : <String, dynamic>{};
                          final id = plan['plan']?.toString() ?? '';
                          final isCurrent =
                              id.isNotEmpty && id == currentId;
                          final features = _features(plan);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _planDisplayName(
                                              plan['plan']?.toString() ?? ''),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (isCurrent)
                                        Chip(
                                          label: const Text('Current plan'),
                                          backgroundColor:
                                              Colors.green.shade100,
                                        ),
                                    ],
                                  ),
                                  if (_priceText(plan).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _priceText(plan),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                  if (plan['description'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(plan['description'].toString()),
                                  ],
                                  if (features.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...features.map((f) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('•  '),
                                              Expanded(child: Text(f)),
                                            ],
                                          ),
                                        )),
                                  ],
                                  const SizedBox(height: 12),
                                  if (!isCurrent)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _subscribe(plan),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6B9C7A),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Subscribe'),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: _cancel,
                                        child: const Text('Cancel plan'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
