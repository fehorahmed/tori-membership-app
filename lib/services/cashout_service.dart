import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class CashoutService {
  final http.Client client;
  CashoutService({http.Client? client}) : client = client ?? http.Client();
  void close() => client.close();

  static String newKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
  }

  Future<Map<String, dynamic>> send(String path, String language,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.membershipUrl}/$path');
      final headers = {
        ...await ProfileService.headers(language: language),
        'Content-Type': 'application/json'
      };
      final response = await (body == null
              ? client.get(uri, headers: headers)
              : client.post(uri, headers: headers, body: jsonEncode(body)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 500) throw StateError('Unknown result');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      return {
        'success': false,
        'message': response.statusCode == 401
            ? (language == 'bn' ? 'আবার লগইন করুন।' : 'Please sign in again.')
            : data['message'] ??
                (language == 'bn'
                    ? 'অনুরোধ গ্রহণ করা যায়নি।'
                    : 'The request was not accepted.')
      };
    } catch (_) {
      return {
        'success': false,
        'uncertain': true,
        'message': language == 'bn'
            ? 'ফলাফল নিশ্চিত করা যায়নি। রিফ্রেশ করুন অথবা একই অনুরোধ আবার চেষ্টা করুন।'
            : 'Unable to confirm the result. Refresh or retry the same request.'
      };
    }
  }

  Future<Map<String, dynamic>> load(String language) =>
      send('cashout', language);
  Future<Map<String, dynamic>> quote(
          String code, String amount, String language) =>
      send('cashout/quote', language,
          body: {'qr_code': code, 'amount': amount});
  Future<Map<String, dynamic>> cancel(int id, String language) =>
      send('cashouts/$id/cancel', language, body: {});

  Future<Map<String, dynamic>?> pending(int customer) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('cashout_pending_$customer');
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> clear(int customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cashout_pending_$customer');
  }

  Future<Map<String, dynamic>> create(int customer, Map<String, dynamic> quote,
      String pin, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await pending(customer);
    if (saved != null && saved['quote_data']['quote'] != quote['quote']) {
      return {
        'success': false,
        'uncertain': true,
        'message': language == 'bn'
            ? 'আগের অনুরোধের ফলাফল আগে নিশ্চিত করুন।'
            : 'Confirm the outcome of the earlier request first.'
      };
    }
    final request = saved ?? {'quote_data': quote, 'key': newKey()};
    // Keep the same request key across timeouts/restarts. Never persist the PIN.
    await prefs.setString('cashout_pending_$customer', jsonEncode(request));
    final result = await send('cashouts', language, body: {
      'quote': request['quote_data']['quote'],
      'idempotency_key': request['key'],
      'pin': pin
    });
    if (result['success'] == true || result['uncertain'] != true)
      await clear(customer);
    return result;
  }
}
