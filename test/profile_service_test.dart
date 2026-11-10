import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tori_mfi_bank/services/auth_service.dart';
import 'package:tori_mfi_bank/services/profile_service.dart';
import 'package:tori_mfi_bank/state.dart';
import 'package:tori_mfi_bank/profile_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(
      {ApiConfig.tokenKey: 'test-token'}));

  test('Profile update sends member token, language and editable fields only',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/membership/v1/profile');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(request.headers['Accept-Language'], 'bn');
      expect(jsonDecode(request.body),
          {'name': 'Member', 'email': '', 'address': 'Dhaka'});
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {'name': 'Member'}
          }),
          200);
    });
    final result = await ProfileService(client: client).update(
        name: ' Member ', email: '', address: ' Dhaka ', language: 'bn');
    expect(result['success'], true);
  });

  test('KYC sends selfie, NID front and NID back as separate multipart fields',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/membership/v1/kyc');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(
          request.headers['Content-Type'], startsWith('multipart/form-data;'));
      final body = utf8.decode(request.bodyBytes);
      for (final field in ['selfie', 'nid_front', 'nid_back', 'nid_number']) {
        expect(body, contains('name="$field"'));
      }
      expect(body, contains('1234567890'));
      return http.Response('{"success":true,"data":{"status":"Pending"}}', 201);
    });
    final file =
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'test.jpg');
    final result = await ProfileService(client: client).submitKyc(
        nidNumber: '1234567890', selfie: file, front: file, back: file);
    expect(result['success'], true);
    expect(result['data']['status'], 'Pending');
  });

  test('Expired authentication does not produce a successful profile save',
      () async {
    final client = MockClient(
        (_) async => http.Response('{"message":"Unauthenticated."}', 401));
    final result = await ProfileService(client: client).fetch(language: 'bn');
    expect(result['success'], false);
    expect(result['message'], 'আবার লগইন করুন।');
  });

  test('Server profile replaces demo KYC and removes stale review messages',
      () {
    final state = ToriState();
    state.applyMemberProfile({
      'name': 'Real Member',
      'mobile_no': '01900000000',
      'is_verified': false,
      'kyc': {'status': 'Rejected', 'reviewer_message': 'Unclear photo'}
    });
    expect(state.profile.fullName, 'Real Member');
    expect(state.profile.isVerified, false);
    expect(state.kyc.reviewerMessage, 'Unclear photo');
    state.applyMemberProfile({
      'name': 'Real Member',
      'kyc': {'status': 'Pending'}
    });
    expect(state.kyc.reviewerMessage, isNull);
    expect(state.kyc.nidFrontUrl, isEmpty);
    expect(state.profile.kycStatus, 'Pending');
  });

  testWidgets('KYC offers camera selfie and separate camera/gallery NID inputs',
      (tester) async {
    final service = ProfileService(
        client: MockClient((_) async => http.Response(
            '{"success":true,"data":{"name":"Member","kyc":{"status":"Not submitted"}}}',
            200)));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: KycSetupPage(state: ToriState(), service: service))));
    await tester.pumpAndSettle();
    expect(find.text('Take selfie'), findsOneWidget);
    expect(find.text('Take photo'), findsNWidgets(2));
    expect(find.text('Upload from gallery'), findsNWidgets(2));
    expect(find.text('NID — Front'), findsOneWidget);
    expect(find.text('NID — Back'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
