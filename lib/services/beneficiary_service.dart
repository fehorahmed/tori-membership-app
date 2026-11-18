import 'dart:convert';
import 'send_money_service.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class BeneficiaryService extends SendMoneyService {
  BeneficiaryService({super.client});
  Future<Map<String, dynamic>> list(String lang) => send('beneficiaries', lang);
  Future<Map<String, dynamic>> lookup(String code, String lang) =>
      send('beneficiaries/lookup', lang, body: {'recipient': code});
  Future<Map<String, dynamic>> save(int id, String nickname, String lang) =>
      send('beneficiaries', lang,
          body: {'recipient_id': id, 'nickname': nickname});
  Future<Map<String, dynamic>> change(int id, String lang,
      {String? nickname}) async {
    try {
      final uri = Uri.parse('${ApiConfig.membershipUrl}/beneficiaries/$id');
      final headers = {
        ...await ProfileService.headers(language: lang),
        'Content-Type': 'application/json'
      };
      final response = await (nickname == null
              ? client.delete(uri, headers: headers)
              : client.patch(uri,
                  headers: headers, body: jsonEncode({'nickname': nickname})))
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': false,
        'message': lang == 'bn' ? 'আবার চেষ্টা করুন।' : 'Please try again.'
      };
    }
  }
}
