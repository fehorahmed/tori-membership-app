import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'send_money_service.dart';

class ReferralService extends SendMoneyService {
  ReferralService({http.Client? client}) : super(client: client);

  @override
  Future<Map<String, dynamic>> load(String language) =>
      send('referrals', language);

  @override
  Future<Map<String, dynamic>?> pending(int customer) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('referral_redemption_pending_$customer');
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  @override
  Future<void> clear(int customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('referral_redemption_pending_$customer');
  }

  Future<Map<String, dynamic>> redeem(int customer, int points, String rate,
      String pin, String language) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await pending(customer);
    final request = saved ??
        {
          'points': points,
          'point_value': rate,
          'request_key': SendMoneyService.newKey()
        };
    // Keep the identical request after an uncertain network result. Never persist the PIN.
    await prefs.setString(
        'referral_redemption_pending_$customer', jsonEncode(request));
    final result = await send('referrals/redeem', language,
        body: {...request, 'pin': pin});
    if (result['success'] == true || result['uncertain'] != true)
      await clear(customer);
    return result;
  }
}
