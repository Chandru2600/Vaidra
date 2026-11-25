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

  // True once login has stored a token for this app session.
  // The token is held in memory only; the app starts at the welcome screen,
  // so login is required again after a restart.
  bool get isLoggedIn => _token != null;

  String _detail(Object e, String fallback) {
    if (e is DioException) {
      if (e.response?.statusCode == 404) {
        return 'This feature is not available on the server yet.';
      }
      if (e.response?.statusCode == 401) {
        return 'Please log in again.';
      }
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Cannot reach the server. Check your connection.';
      }
    }
    return fallback;
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

  // ---- LifeCard (emergency medical profile) ----

  Future<Map<String, dynamic>> getLifeCard() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/lifecard');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not load LifeCard'));
    }
  }

  Future<Map<String, dynamic>> updateLifeCard(Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.put('/lifecard', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not save LifeCard'));
    }
  }

  // ---- Emergency contacts ----

  Future<List<dynamic>> getEmergencyContacts() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/emergency-contacts');
      final data = response.data;
      if (data is List) return data;
      return <dynamic>[];
    } catch (e) {
      throw Exception(_detail(e, 'Could not load emergency contacts'));
    }
  }

  Future<Map<String, dynamic>> addEmergencyContact(Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/emergency-contacts', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not add emergency contact'));
    }
  }

  Future<Map<String, dynamic>> updateEmergencyContact(
      int id, Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.put('/emergency-contacts/$id', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not update emergency contact'));
    }
  }

  Future<void> deleteEmergencyContact(int id) async {
    _dio.options.baseUrl = baseUrl;
    try {
      await _dio.delete('/emergency-contacts/$id');
    } catch (e) {
      throw Exception(_detail(e, 'Could not delete emergency contact'));
    }
  }

  // ---- First-aid guides (server copy; bundled JSON is the offline fallback) ----

  Future<List<dynamic>> getFirstAidGuides() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/first-aid/guides');
      final data = response.data;
      if (data is List) return data;
      if (data is Map && data['guides'] is List) {
        return List<dynamic>.from(data['guides'] as List);
      }
      return <dynamic>[];
    } catch (e) {
      throw Exception(_detail(e, 'Could not load first-aid guides'));
    }
  }

  // ---- Emergency triage (no login needed) ----

  Future<Map<String, dynamic>> triageEmergency(String description) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/emergency/triage', data: {
        'description': description,
        'symptoms': <String>[],
      });
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      throw Exception(_detail(e, 'Could not reach the first-aid assistant'));
    }
  }

  // ---- Nearby discovery (live OpenStreetMap data via the backend) ----

  Future<List<dynamic>> discoverHospitals({double? lat, double? lng}) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/discover/hospitals', queryParameters: <String, dynamic>{
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      return _asResultList(response.data);
    } catch (e) {
      throw Exception(_detail(e, 'Could not load hospitals'));
    }
  }

  Future<List<dynamic>> discoverPharmacies({double? lat, double? lng}) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/discover/pharmacies', queryParameters: <String, dynamic>{
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      return _asResultList(response.data);
    } catch (e) {
      throw Exception(_detail(e, 'Could not load medical shops'));
    }
  }

  // ---- Single scan (history detail) ----
  // GET /scans/{id} is part of the round-2 backend work; if the server does
  // not have it yet, _detail maps the 404 to a friendly message.

  Future<Map<String, dynamic>> getScanById(String id) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/scans/$id');
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      throw Exception(_detail(e, 'Could not load this scan'));
    }
  }

  // ---- More discovery types (ambulances, blood banks, diagnostics) ----

  Future<List<dynamic>> _discover(String path, String fallback) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get(path);
      return _asResultList(response.data);
    } catch (e) {
      throw Exception(_detail(e, fallback));
    }
  }

  Future<List<dynamic>> discoverAmbulances({double? lat, double? lng}) async {
    return _discover(
      '/discover/ambulances${_latLngQuery(lat, lng)}',
      'Could not load ambulances',
    );
  }

  Future<List<dynamic>> discoverBloodBanks({double? lat, double? lng}) async {
    return _discover(
      '/discover/blood-banks${_latLngQuery(lat, lng)}',
      'Could not load blood banks',
    );
  }

  Future<List<dynamic>> discoverDiagnostics({double? lat, double? lng}) async {
    return _discover(
      '/discover/diagnostics${_latLngQuery(lat, lng)}',
      'Could not load diagnostic centres',
    );
  }

  String _latLngQuery(double? lat, double? lng) {
    final params = <String>[];
    if (lat != null) params.add('lat=$lat');
    if (lng != null) params.add('lng=$lng');
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  // ---- Family Relay ----
  // Endpoint paths are the RESTful contract used by the app; if the backend
  // differs, _detail turns a 404 into "not available on the server yet".

  Future<List<dynamic>> getFamilyGroups() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/family/groups');
      final data = response.data;
      if (data is List) return data;
      if (data is Map && data['groups'] is List) {
        return List<dynamic>.from(data['groups'] as List);
      }
      return <dynamic>[];
    } catch (e) {
      throw Exception(_detail(e, 'Could not load family groups'));
    }
  }

  Future<Map<String, dynamic>> createFamilyGroup(String name) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/family/groups', data: {'name': name});
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not create family group'));
    }
  }

  Future<Map<String, dynamic>> joinFamilyGroup(String inviteCode) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/family/groups/join', data: {'invite_code': inviteCode});
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not join family group'));
    }
  }

  Future<List<dynamic>> getGroupIncidents(int groupId) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/family/groups/$groupId/incidents');
      final data = response.data;
      if (data is List) return data;
      if (data is Map && data['incidents'] is List) {
        return List<dynamic>.from(data['incidents'] as List);
      }
      return <dynamic>[];
    } catch (e) {
      throw Exception(_detail(e, 'Could not load incidents'));
    }
  }

  Future<Map<String, dynamic>> createIncident(
      int groupId, Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/family/groups/$groupId/incidents', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not create incident'));
    }
  }

  Future<Map<String, dynamic>> addIncidentUpdate(
      int incidentId, String message) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/family/incidents/$incidentId/updates',
          data: {'message': message});
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not add status update'));
    }
  }

  Future<void> resolveIncident(int incidentId) async {
    _dio.options.baseUrl = baseUrl;
    try {
      await _dio.post('/family/incidents/$incidentId/resolve');
    } catch (e) {
      throw Exception(_detail(e, 'Could not resolve incident'));
    }
  }

  Future<void> setLocationSharing(int groupId, bool share) async {
    _dio.options.baseUrl = baseUrl;
    try {
      await _dio.put('/family/groups/$groupId/location-sharing',
          data: {'share_location': share});
    } catch (e) {
      throw Exception(_detail(e, 'Could not update location sharing'));
    }
  }

  // ---- Subscriptions ----
  // Plans are hypotheses for market testing — no payment is charged in this
  // version; subscribe only records intent (status pending_payment).

  Future<List<dynamic>> getPlans() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/subscriptions/plans');
      final data = response.data;
      if (data is List) return data;
      if (data is Map && data['plans'] is List) {
        return List<dynamic>.from(data['plans'] as List);
      }
      return <dynamic>[];
    } catch (e) {
      throw Exception(_detail(e, 'Could not load plans'));
    }
  }

  Future<Map<String, dynamic>> getMySubscription() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/subscriptions/me');
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return <String, dynamic>{}; // No subscription yet — Basic is default.
      }
      throw Exception(_detail(e, 'Could not load your subscription'));
    }
  }

  Future<Map<String, dynamic>> subscribePlan(String planId) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/subscriptions/subscribe', data: {'plan': planId});
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not subscribe to this plan'));
    }
  }

  Future<void> cancelSubscription() async {
    _dio.options.baseUrl = baseUrl;
    try {
      await _dio.post('/subscriptions/cancel');
    } catch (e) {
      throw Exception(_detail(e, 'Could not cancel subscription'));
    }
  }

  // ---- Partner registration (hospital / pharmacy) ----

  Future<Map<String, dynamic>> registerPartner(Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.post('/partners/register', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not register as a partner'));
    }
  }

  Future<Map<String, dynamic>> getMyPartner() async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.get('/partners/me');
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return <String, dynamic>{}; // No partner record yet — show the form.
      }
      throw Exception(_detail(e, 'Could not load partner profile'));
    }
  }

  Future<Map<String, dynamic>> updateMyPartner(Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.put('/partners/me', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not update partner profile'));
    }
  }

  Future<Map<String, dynamic>> updatePartnerAvailability(
      Map<String, dynamic> data) async {
    _dio.options.baseUrl = baseUrl;
    try {
      final response = await _dio.put('/partners/me/availability', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      throw Exception(_detail(e, 'Could not update availability'));
    }
  }

  List<dynamic> _asResultList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) {
      return List<dynamic>.from(data['results'] as List);
    }
    return <dynamic>[];
  }
}
