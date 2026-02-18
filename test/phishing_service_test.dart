import 'package:flutter_test/flutter_test.dart';
import 'package:trustprobe_ai/services/phishing_service.dart';
import 'package:trustprobe_ai/models/scan_result.dart';

void main() {
  group('PhishingService Tests', () {
    late PhishingService phishingService;

    setUp(() {
      phishingService = PhishingService();
    });

    test('Safe URL - google.com', () async {
      final result = await phishingService.analyzeUrl('google.com');

      expect(result.riskScore, lessThan(40));
      expect(result.classification, equals('Safe'));
      expect(result.reason, contains('Recognized as a trusted domain'));
    });

    test('Safe URL - facebook.com', () async {
      final result = await phishingService.analyzeUrl('facebook.com');

      expect(result.riskScore, lessThan(40));
      expect(result.classification, equals('Safe'));
    });

    test('Malicious URL - with bank keyword', () async {
      final result = await phishingService.analyzeUrl(
        'secure-bank-login.example.com',
      );

      expect(result.riskScore, greaterThan(70));
      expect(result.classification, equals('Malicious'));
      expect(result.reason, contains('bank'));
    });

    test('Malicious URL - with paypal keyword and http', () async {
      final result = await phishingService.analyzeUrl(
        'http://paypal-verify.suspicious.com',
      );

      expect(result.riskScore, greaterThan(60));
      expect(result.classification, isIn(['Suspicious', 'Malicious']));
      expect(result.reason, contains('paypal'));
    });

    test('Malicious URL - IP address', () async {
      final result = await phishingService.analyzeUrl(
        'http://192.168.1.1/login',
      );

      expect(result.riskScore, greaterThan(60));
      expect(result.classification, isNot(equals('Safe')));
      expect(result.reason, contains('IP address'));
    });

    test('Invalid URL format', () async {
      final result = await phishingService.analyzeUrl('not a valid url!!!');

      expect(result.riskScore, equals(100));
      expect(result.classification, equals('Malicious'));
      expect(result.reason, equals('Invalid URL format'));
    });

    test('HTTPS vs HTTP - HTTPS should be safer', () async {
      final httpsResult = await phishingService.analyzeUrl(
        'https://example.com',
      );
      final httpResult = await phishingService.analyzeUrl('http://example.com');

      expect(httpResult.riskScore, greaterThan(httpsResult.riskScore));
    });

    test('Long domain name triggers risk', () async {
      final result = await phishingService.analyzeUrl(
        'this-is-a-very-very-long-suspicious-domain-name.com',
      );

      expect(result.riskScore, greaterThan(20));
    });

    test('Multiple subdomains increase risk', () async {
      final result = await phishingService.analyzeUrl(
        'sub1.sub2.sub3.sub4.example.com',
      );

      expect(result.riskScore, greaterThan(10));
    });
  });

  group('ScanResult Model Tests', () {
    test('Risk color - low risk', () {
      final result = ScanResult(
        url: 'google.com',
        riskScore: 25,
        classification: 'Safe',
        reason: 'Trusted domain',
        timestamp: DateTime.now(),
      );

      expect(result.riskColor, equals('green'));
      expect(result.riskLevel, equals('Low Risk'));
    });

    test('Risk color - medium risk', () {
      final result = ScanResult(
        url: 'example.com',
        riskScore: 55,
        classification: 'Suspicious',
        reason: 'Some risks',
        timestamp: DateTime.now(),
      );

      expect(result.riskColor, equals('yellow'));
      expect(result.riskLevel, equals('Medium Risk'));
    });

    test('Risk color - high risk', () {
      final result = ScanResult(
        url: 'malicious.com',
        riskScore: 85,
        classification: 'Malicious',
        reason: 'Multiple risks',
        timestamp: DateTime.now(),
      );

      expect(result.riskColor, equals('red'));
      expect(result.riskLevel, equals('High Risk'));
    });

    test('toMap and fromFirestore', () {
      final original = ScanResult(
        url: 'test.com',
        riskScore: 50,
        classification: 'Suspicious',
        reason: 'Test reason',
        timestamp: DateTime(2024, 1, 1, 12, 0),
      );

      final map = original.toMap();
      final reconstructed = ScanResult.fromFirestore(map);

      expect(reconstructed.url, equals(original.url));
      expect(reconstructed.riskScore, equals(original.riskScore));
      expect(reconstructed.classification, equals(original.classification));
      expect(reconstructed.reason, equals(original.reason));
    });
  });
}
