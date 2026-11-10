import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProfileService {
  final http.Client client;
  ProfileService({http.Client? client}) : client = client ?? http.Client();
  void close() => client.close();

  static Future<Map<String, String>> headers({String language = 'en'}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required');
    }
    return {
      'Accept': 'application/json',
      'Accept-Language': language,
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> decode(http.Response response, String language) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body['success'] == true) return body;
    return {
      'success': false,
      'message': response.statusCode == 401
          ? (language == 'bn' ? 'আবার লগইন করুন।' : 'Please sign in again.')
          : body['message'] ?? failure(language),
    };
  }

  static String failure(String language) => language == 'bn'
      ? 'তথ্য সংরক্ষণ বা লোড করা যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।'
      : 'Unable to save or load your details. Check your connection and try again.';

  Future<Map<String, dynamic>> fetch({String language = 'en'}) async {
    try {
      return decode(
          await client
              .get(
                Uri.parse('${ApiConfig.membershipUrl}/profile'),
                headers: await headers(language: language),
              )
              .timeout(const Duration(seconds: 30)),
          language);
    } catch (_) {
      return {'success': false, 'message': failure(language)};
    }
  }

  Future<Map<String, dynamic>> fetchCard({String language = 'en'}) async {
    try {
      return decode(
          await client
              .get(Uri.parse('${ApiConfig.membershipUrl}/card'),
                  headers: await headers(language: language))
              .timeout(const Duration(seconds: 30)),
          language);
    } catch (_) {
      return {'success': false, 'message': failure(language)};
    }
  }

  Future<Map<String, dynamic>> update(
      {required String name,
      required String email,
      required String address,
      String language = 'en'}) async {
    try {
      return decode(
          await client
              .put(
                Uri.parse('${ApiConfig.membershipUrl}/profile'),
                headers: {
                  ...await headers(language: language),
                  'Content-Type': 'application/json'
                },
                body: jsonEncode({
                  'name': name.trim(),
                  'email': email.trim(),
                  'address': address.trim()
                }),
              )
              .timeout(const Duration(seconds: 30)),
          language);
    } catch (_) {
      return {'success': false, 'message': failure(language)};
    }
  }

  Future<Map<String, dynamic>> submitKyc(
      {required String nidNumber,
      required XFile selfie,
      required XFile front,
      required XFile back,
      String language = 'en'}) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('${ApiConfig.membershipUrl}/kyc'));
      request.headers.addAll(await headers(language: language));
      request.fields['nid_number'] = nidNumber;
      for (final entry
          in {'selfie': selfie, 'nid_front': front, 'nid_back': back}.entries) {
        final bytes = await entry.value.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          return {
            'success': false,
            'message': language == 'bn'
                ? 'প্রতিটি ছবি সর্বোচ্চ ৫ এমবি হতে পারবে।'
                : 'Each image must be 5 MB or smaller.'
          };
        }
        request.files.add(http.MultipartFile.fromBytes(entry.key, bytes,
            filename: entry.value.name));
      }
      return decode(
          await http.Response.fromStream(
              await client.send(request).timeout(const Duration(seconds: 60))),
          language);
    } catch (_) {
      return {'success': false, 'message': failure(language)};
    }
  }
}
