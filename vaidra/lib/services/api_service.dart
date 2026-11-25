import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // For XFile

class ApiService {
  // Live Public Backend URL for testing on mobile
  static const String productionUrl = 'https://imprudent-overcome-turbofan.ngrok-free.dev';
  
  // Development URLs
  static String get _devUrl {
    if (kIsWeb) {
      return ''; // Relative to the serving host
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Use the live public tunnel so any Android phone connects
        return productionUrl;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      default:
        return 'http://127.0.0.1:8000';
    }
  }
  
  // Automatically use production URL on mobile devices
  static String get baseUrl => (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? productionUrl : _devUrl;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 40),
    headers: {
      'ngrok-skip-browser-warning': 'true',
    },
  ));
  String? _token;

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token'; // Fixed header
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _dio.options.baseUrl = baseUrl; // Ensure base URL is set
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': email.trim().toLowerCase(), 
        'password': password,
      }, options: Options(contentType: Headers.formUrlEncodedContentType));
      
      final data = response.data;
      setToken(data['access_token']);
      return data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Incorrect email or password. Please check your credentials.');
        }
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Cannot connect to server ($baseUrl). Make sure the backend is running.');
        }
        final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
        throw Exception(detail ?? 'Server error (${e.response?.statusCode})');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'Registration failed: Invalid details');
      }
      throw Exception('Registration failed: Connection issue or server error.');
    }
  }

  // Changed to accept XFile for Web compatibility
  Future<Map<String, dynamic>> uploadScan(XFile file, int? userId) async {
    _dio.options.baseUrl = baseUrl;
    try {
      String fileName = file.name;
      if (!fileName.contains('.')) {
        fileName += '.jpg';
      }
      
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
