import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'profile_service.dart';

class FdrService {
  final http.Client client;
  FdrService({http.Client? client}) : client = client ?? http.Client();
  void close() => client.close();
  Future<Map<String, dynamic>> request(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.membershipUrl}/fdr$path');
      final headers = {
        ...await ProfileService.headers(),
        'Content-Type': 'application/json'
      };
      final response = body == null
          ? await client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30))
          : await client
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 30));
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          result['success'] == true) return result;
      final errors = result['errors'];
      return {
        'success': false,
        'message': errors is Map && errors.isNotEmpty
            ? (errors.values.first as List).first.toString()
            : result['message'] ??
                'Unable to process FDR. Please sign in again or contact your branch.'
      };
    } catch (_) {
      return {
        'success': false,
        'message':
            'Connection failed. Retry the same request to check its result.'
      };
    }
  }
}
