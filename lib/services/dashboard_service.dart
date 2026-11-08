import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DashboardService {
  /// Fetch real Dashboard Data for the authenticated customer
  static Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'টোকেন পাওয়া যায়নি। পুনরায় লগইন করুন।'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.membershipUrl}/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'তথ্য লোড করতে ব্যর্থ হয়েছে।',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'সার্ভারের সাথে সংযোগ স্থাপন করা যায়নি ($e)',
      };
    }
  }
}

