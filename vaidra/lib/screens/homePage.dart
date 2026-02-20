import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:vaidra/services/api_service.dart';
import 'package:vaidra/screens/resultPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isUploading = false;
  bool _isLoadingHistory = true;
  List<HistoryItem> _uploadHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final scans = await ApiService().fetchRecentScans();
      debugPrint("Fetched ${scans.length} scans from backend");
      
      setState(() {
        _uploadHistory = scans.map((scan) {
          final result = scan['result'];
          
          // Parse the created_at field - handle both string and DateTime
          DateTime uploadDate = DateTime.now();
          if (scan['created_at'] != null) {
            if (scan['created_at'] is String) {
              uploadDate = DateTime.tryParse(scan['created_at']) ?? DateTime.now();
            } else if (scan['created_at'] is DateTime) {
              uploadDate = scan['created_at'];
            }
          }
          
          return HistoryItem(
            id: scan['id'].toString(),
            title: result['condition'] ?? 'Unknown Condition',
            uploadDate: uploadDate,
            imageUrl: 'assets/images/placeholder.png',
            status: 'Analyzed',
            result: '${result['severity']} - ${(result['confidence'] as num).toInt()}%',
          );
        }).toList();
        _isLoadingHistory = false;
      });
      
      debugPrint("Updated history with ${_uploadHistory.length} items");
    } catch (e) {
      debugPrint("Error loading history: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
      setState(() => _isLoadingHistory = false);
    }
  }

  static const Color primaryGreen = Color(0xFF6B9C7A);
  static const Color lightGreen = Color(0xFFE8F4EA);
  static const Color darkGreen = Color(0xFF4A7C59);
  static const Color backgroundColor = Color(0xFFF5F7F5);
  static const Color textDark = Color(0xFF2D3E2D);
  static const Color textLight = Color(0xFF6B7B6B);

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      _processImage(pickedFile);
    }
  }

  Future<void> _selectFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      _processImage(pickedFile);
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() => _isUploading = true);
    
    try {
      // Call backend API
      final response = await ApiService().uploadScan(image, null);
      
      if (mounted) {
        setState(() => _isUploading = false);
        _fetchHistory(); // Refresh list
        
        // Parse result
        final result = response['result'];
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              imageFile: image,
              condition: result['condition'] ?? "Unknown",
              confidence: (result['confidence'] ?? 0).toInt(),
              severity: result['severity'] ?? "Minor",
              steps: result['steps'] ?? [],
              warnings: result['warnings'] ?? [],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${e.toString()}")),
        );
      }
    }
  }

  void _showUploadOptions(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(lang.translate('upload_medical_image'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Text(lang.translate('choose_upload'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: textLight)),
            const SizedBox(height: 24),

            ListTile(
              onTap: () { Navigator.pop(context); _takePhoto(); },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt, color: primaryGreen, size: 24),
              ),
              title: Text(lang.translate('take_photo'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark)),
              subtitle: Text(lang.translate('capture_camera'), style: const TextStyle(color: textLight, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, color: textLight),
            ),
            const Divider(),
            ListTile(
              onTap: () { Navigator.pop(context); _selectFromGallery(); },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library, color: primaryGreen, size: 24),
              ),
              title: Text(lang.translate('choose_from_gallery'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark)),
              subtitle: Text(lang.translate('select_from_photos'), style: const TextStyle(color: textLight, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, color: textLight),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _viewHistoryItem(HistoryItem item) {
    Navigator.pushNamed(context, '/result', arguments: {
      'historyItem': item,
      'uploadId': item.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(builder: (context, lang, _) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(width: 32, height: 32, decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                child: Image.asset('assets/translations/vaidra.png', width: 18, height: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Vaidra', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined, color: textDark), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person_outline, color: textDark), onPressed: () => Navigator.pushNamed(context, '/profile')),
          ],
        ),
        body: _isUploading ? _buildUploadingScreen(lang) : _buildMainContent(lang),
        floatingActionButton: _isUploading ? null : FloatingActionButton.extended(
          onPressed: () => _showUploadOptions(lang),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(lang.translate('upload')),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    });
  }

  Widget _buildUploadingScreen(LanguageProvider lang) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: lightGreen.withOpacity(0.3), shape: BoxShape.circle),
          child: Container(margin: const EdgeInsets.all(16), decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
            child: const CircularProgressIndicator(color: primaryGreen, strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 24),
        Text(lang.translate('processing_image'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark)),
        const SizedBox(height: 8),
        Text(lang.translate('analyzing_ai'), style: const TextStyle(fontSize: 16, color: textLight)),
      ]),
    );
  }

  Widget _buildMainContent(LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryGreen.withOpacity(0.1), lightGreen.withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang.translate('home_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            Text(lang.translate('home_subtitle'), style: const TextStyle(fontSize: 16, color: textLight)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _buildQuickActionCard(lang, Icons.camera_alt, 'take_photo', 'camera', _takePhoto)),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickActionCard(lang, Icons.photo_library, 'gallery', 'select_file', _selectFromGallery)),
            ]),
          ]),
        ),
        const SizedBox(height: 32),
        Text(lang.translate('what_can_upload'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildUploadTypeCard(lang, Icons.description, 'lab_reports', 'blood_urine')),
          const SizedBox(width: 12),
          Expanded(child: _buildUploadTypeCard(lang, Icons.receipt, 'prescriptions', 'medicine_lists')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildUploadTypeCard(lang, Icons.healing, 'xrays_scans', 'medical_imaging')),
          const SizedBox(width: 12),
          Expanded(child: _buildUploadTypeCard(lang, Icons.photo_camera, 'symptoms', 'affected_areas')),
        ]),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lang.translate('recent_uploads'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/history'),
            child: Text(lang.translate('view_all'), style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w200)),
          ),
        ]),
        const SizedBox(height: 16),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator())
        else if (_uploadHistory.isEmpty) 
          _buildEmptyHistory(lang) 
        else ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: _uploadHistory.length > 3 ? 3 : _uploadHistory.length,
          itemBuilder: (context, index) => _buildHistoryCard(_uploadHistory[index]),
        ),
        const SizedBox(height: 100),
      ]),
    );
  }

  Widget _buildQuickActionCard(LanguageProvider lang, IconData icon, String titleKey, String subtitleKey, VoidCallback onTap) {
    return GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Column(children: [
          Icon(icon, color: primaryGreen, size: 32),
          const SizedBox(height: 8),
          Text(lang.translate(titleKey), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
          Text(lang.translate(subtitleKey), style: const TextStyle(fontSize: 12, color: textLight)),
        ]),
      ),
    );
  }

  Widget _buildUploadTypeCard(LanguageProvider lang, IconData icon, String titleKey, String subtitleKey) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: primaryGreen, size: 28),
        const SizedBox(height: 12),
        Text(lang.translate(titleKey), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark)),
        Text(lang.translate(subtitleKey), style: const TextStyle(fontSize: 12, color: textLight)),
      ]),
    );
  }

  Widget _buildEmptyHistory(LanguageProvider lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(Icons.history, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(lang.translate('no_uploads_yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text(lang.translate('upload_first_image'), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return Provider.of<LanguageProvider>(context, listen: false).translate('today');
    } else if (difference.inDays == 1) {
      return Provider.of<LanguageProvider>(context, listen: false).translate('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${Provider.of<LanguageProvider>(context, listen: false).translate('days_ago')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewHistoryItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.insert_drive_file, color: primaryGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark)),
              const SizedBox(height: 4),
              Text(item.result, style: const TextStyle(fontSize: 14, color: textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(_formatDate(item.uploadDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: item.status == 'Analyzed' ? lightGreen : Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text(item.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: item.status == 'Analyzed' ? primaryGreen : Colors.orange.shade800)),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right, color: textLight, size: 20),
            ]),
          ]),
        ),
      ),
    );
  }
}

class HistoryItem {
  final String id;
  final String title;
  final DateTime uploadDate;
  final String imageUrl;
  final String status;
  final String result;

  HistoryItem({
    required this.id,
    required this.title,
    required this.uploadDate,
    required this.imageUrl,
    required this.status,
    required this.result,
  });
}
