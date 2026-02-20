import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'package:vaidra/services/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _uploadHistory = [];
  bool _isLoading = true;

  static const Color primaryGreen = Color(0xFF6BBF8A);
  static const Color lightGreen = Color(0xFFA8D5BA);
  static const Color textDark = Color(0xFF2D3748);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final scans = await ApiService().fetchRecentScans();
      
      setState(() {
        _uploadHistory = scans.map((scan) {
          final result = scan['result'];
          
          DateTime uploadDate = DateTime.now();
          if (scan['created_at'] != null) {
            if (scan['created_at'] is String) {
              uploadDate = DateTime.tryParse(scan['created_at']) ?? DateTime.now();
            } else if (scan['created_at'] is DateTime) {
              uploadDate = scan['created_at'];
            }
          }
          
          return {
            'id': scan['id'].toString(),
            'title': result['condition'] ?? 'Unknown Condition',
            'uploadDate': uploadDate,
            'severity': result['severity'] ?? 'Unknown',
            'confidence': result['confidence']?.toString() ?? '0',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading history: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'URGENT':
        return Colors.red;
      case 'MODERATE':
        return Colors.orange;
      case 'MINOR':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              lang.translate('recent_uploads'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _uploadHistory.isEmpty
                  ? _buildEmptyState(lang)
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _uploadHistory.length,
                        itemBuilder: (context, index) {
                          final item = _uploadHistory[index];
                          return _buildHistoryCard(item);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            lang.translate('no_uploads_yet'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            lang.translate('upload_first_image'),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_services,
                color: primaryGreen,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item['uploadDate']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(item['severity'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['severity'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getSeverityColor(item['severity']),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item['confidence']}% confidence',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
