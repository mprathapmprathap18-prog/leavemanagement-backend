import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Change to your backend URL
  static const String baseUrl = 'https://leavemanagement-backend-7.onrender.com/api';

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _getHeaders({bool requireAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (requireAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _getHeaders(requireAuth: false),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  // ==================== STUDENT ENDPOINTS ====================

  // Submit Leave Request (your table structure)
  Future<Map<String, dynamic>> submitLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/leaves/submit'),
      headers: _getHeaders(),
      body: jsonEncode({
        'leave_type': leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      }),
    );

    if (response.statusCode == 201) {
      return {
        'success': true,
        'message': jsonDecode(response.body)['message'],
      };
    } else {
      return {
        'success': false,
        'error': jsonDecode(response.body)['error'],
      };
    }
  }

  // Get My Leaves (matches your leave_requests table)
  Future<Map<String, dynamic>> getMyLeaves() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaves/my-leaves'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'leaves': data['leaves'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch leaves',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  // ==================== MANAGER ENDPOINTS ====================

  Future<Map<String, dynamic>> getManagerPendingLeaves() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/manager/pending-leaves'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'leaves': data['leaves'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch leaves',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> approveLeaveByManager({
    required int leaveId,
    required String status,
    String? comments, // ✅ ADD THIS
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/manager/approve-leave/$leaveId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'status': status,
          'comments': comments ?? "", // ✅ NOW OK
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Failed to process request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }
  // ==================== TUTOR ENDPOINTS ====================

  Future<Map<String, dynamic>> getTutorPendingLeaves() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tutor/pending-leaves'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'leaves': data['leaves'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch leaves',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> approveLeaveByTutor({
    required int leaveId,
    required String status,
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tutor/approve-leave/$leaveId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Failed to process request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: $e',
      };
    }
  }
}
