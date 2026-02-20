import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // For XFile

class ApiService {
  // IMPORTANT: Update this URL to your production backend before releasing
  // Example: 'https://api.vaidra.com' or 'https://your-backend.railway.app'
  static const String productionUrl = 'https://YOUR-APP-NAME.onrender.com'; // ← Replace with your Render URL
  
  // Development URLs for testing
  static String get _devUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  
  // Automatically use production URL in release builds
  static String get baseUrl => kReleaseMode ? productionUrl : _devUrl;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  String? _token;

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token'; // Fixed header
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _dio.options.baseUrl = baseUrl; // Ensure base URL is set
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': email, 
        'password': password,
      }, options: Options(contentType: Headers.formUrlEncodedContentType));
      
      final data = response.data;
      setToken(data['access_token']);
      return data;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Changed to accept XFile for Web compatibility
  Future<Map<String, dynamic>> uploadScan(XFile file, int? userId) async {
    _dio.options.baseUrl = baseUrl;
    try {
      String fileName = file.name;
      
      // For Web, we must read bytes. For Mobile, path works but bytes also work and are safer context-wise here.
      // Actually Dio supports XFile or bytes.
      // Safest cross-platform way with Dio usually involves bytes or MultipartFile.fromBytes
      
      final bytes = await file.readAsBytes();
      
      FormData formData = FormData.fromMap({
        "scan_image": MultipartFile.fromBytes(bytes, filename: fileName),
        if (userId != null) "user_id": userId,
      });

      final response = await _dio.post('/scans/analyze', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }
  Future<List<dynamic>> fetchRecentScans() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/scans/recent');
      return response.data;
    } catch (e) {
      debugPrint('Failed to fetch recent scans: $e');
      return [];
    }
  }

  // Fetch current user profile
  Future<Map<String, dynamic>> getProfile() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/auth/profile');
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.put('/auth/profile', data: profileData);
      return response.data;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}
