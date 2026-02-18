import 'package:inline_logger/inline_logger.dart';

import '../models/scan_result.dart';
import 'ai_service.dart';

/// PhishingService - Hybrid rule-based + AI phishing detection service
///
/// Analyzes URLs for phishing risk using multiple detection strategies:
/// - Suspicious keyword detection
/// - Domain structure analysis
/// - Security protocol checks
/// - Trusted domain whitelist
/// - **AI-powered threat analysis via Llama 3.3 70B (open-source LLM)**
class PhishingService {
  final AiService _aiService;

  PhishingService({AiService? aiService})
    : _aiService = aiService ?? AiService();

  /// List of suspicious keywords that indicate potential phishing
  static const List<String> _suspiciousKeywords = [
    'bank',
    'paypal',
    'verify',
    'login',
    'secure',
    'account',
    'update',
    'suspended',
    'confirm',
    'signin',
    'password',
    'credential',
    'wallet',
  ];

  /// Trusted domains that are whitelisted
  static const List<String> _trustedDomains = [
    'google.com',
    'facebook.com',
    'microsoft.com',
    'amazon.com',
    'apple.com',
    'twitter.com',
    'linkedin.com',
    'github.com',
    'stackoverflow.com',
    'reddit.com',
    'wikipedia.org',
    'youtube.com',
  ];

  /// URL shortener domains to check
  static const List<String> _urlShorteners = [
    'bit.ly',
    'tinyurl.com',
    'goo.gl',
    'ow.ly',
    't.co',
  ];

  /// Main method to analyze a URL for phishing risk
  ///
  /// Returns a [ScanResult] containing risk score, classification,
  /// heuristic reasoning, and AI-powered threat analysis.
  Future<ScanResult> analyzeUrl(String url) async {
    // Normalize URL
    String normalizedUrl = url.trim().toLowerCase();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    Uri? parsedUrl;
    try {
      parsedUrl = Uri.parse(normalizedUrl);

      // Uri.parse is very lenient - validate the host has a valid format
      final host = parsedUrl.host;
      if (host.isEmpty ||
          host.contains(' ') ||
          !RegExp(r'^[a-zA-Z0-9\-\.]+$').hasMatch(host)) {
        throw FormatException('Invalid host: $host');
      }
    } catch (e) {
      // Invalid URL
      return ScanResult(
        url: url,
        riskScore: 100,
        classification: 'Malicious',
        reason: 'Invalid URL format',
        timestamp: DateTime.now(),
      );
    }

    // Calculate heuristic risk score with breakdown
    final (riskScore, scoreBreakdown) = _calculateRiskScore(parsedUrl);
    final classification = _getClassification(riskScore);
    final reason = _generateReason(parsedUrl, riskScore);

    // Run AI analysis (non-blocking, graceful fallback)
    String? aiAnalysis;
    try {
      final aiResult = await _aiService.analyzeUrl(
        url: url,
        heuristicScore: riskScore,
        heuristicClassification: classification,
        heuristicReason: reason,
      );
      aiAnalysis = aiResult?.toFormattedString();
    } catch (e) {
      Logger.error('AI analysis failed gracefully - $e', 'PhishingService');
    }

    return ScanResult(
      url: url,
      riskScore: riskScore,
      classification: classification,
      reason: reason,
      timestamp: DateTime.now(),
      aiAnalysis: aiAnalysis,
      scoreBreakdown: scoreBreakdown,
    );
  }

  /// Calculate risk score based on various heuristics
  /// Returns (totalScore, breakdown) where breakdown maps check names to their scores
  (int, Map<String, int>) _calculateRiskScore(Uri url) {
    int score = 0;
    Map<String, int> breakdown = {};

    final String fullUrl = url.toString().toLowerCase();
    final String domain = url.host.toLowerCase();
    final String path = url.path.toLowerCase();

    // Check if domain is trusted FIRST (-40 points)
    // Only apply if it's an exact match or proper subdomain
    bool isTrusted = _trustedDomains.any((trusted) {
      return domain == trusted || domain.endsWith('.$trusted');
    });

    if (isTrusted) {
      breakdown['Trusted Domain'] = -40;
      score -= 40;
    } else {
      breakdown['Trusted Domain'] = 0;
    }

    // Check for suspicious keywords in DOMAIN NAME (+40 points)
    List<String> domainKeywords = _suspiciousKeywords
        .where((keyword) => domain.contains(keyword))
        .toList();
    if (domainKeywords.isNotEmpty) {
      breakdown['Suspicious Keywords (Domain)'] = 40;
      score += 40;
    } else {
      breakdown['Suspicious Keywords (Domain)'] = 0;
    }

    // Check for suspicious keywords in PATH/QUERY (+20 points)
    List<String> pathKeywords = _suspiciousKeywords
        .where(
          (keyword) => path.contains(keyword) || url.query.contains(keyword),
        )
        .toList();
    if (pathKeywords.isNotEmpty && domainKeywords.isEmpty) {
      breakdown['Suspicious Keywords (Path)'] = 20;
      score += 20;
    } else {
      breakdown['Suspicious Keywords (Path)'] = 0;
    }

    // Check for non-HTTPS (+25 points)
    if (url.scheme == 'http') {
      breakdown['HTTPS Security'] = 25;
      score += 25;
    } else {
      breakdown['HTTPS Security'] = 0;
    }

    // Check domain length (+30 points for long domains)
    if (domain.length > 30) {
      breakdown['Domain Length'] = 30;
      score += 30;
    } else {
      breakdown['Domain Length'] = 0;
    }

    // Check for multiple subdomains (+20 points)
    final int subdomainCount = domain.split('.').length - 2;
    if (subdomainCount > 2) {
      breakdown['Subdomain Complexity'] = 20;
      score += 20;
    } else {
      breakdown['Subdomain Complexity'] = 0;
    }

    // Check for IP address in URL (+35 points)
    final ipPattern = RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}');
    if (ipPattern.hasMatch(domain)) {
      breakdown['IP Address Usage'] = 35;
      score += 35;
    } else {
      breakdown['IP Address Usage'] = 0;
    }

    // Check for @ symbol in URL (+30 points)
    if (fullUrl.contains('@')) {
      breakdown['URL Obfuscation (@)'] = 30;
      score += 30;
    } else {
      breakdown['URL Obfuscation (@)'] = 0;
    }

    // Check for excessive dashes (+20 points)
    if (domain.split('-').length > 3) {
      breakdown['Excessive Dashes'] = 20;
      score += 20;
    } else {
      breakdown['Excessive Dashes'] = 0;
    }

    // Check for URL shorteners
    bool isShortener = _urlShorteners.any(
      (shortener) => domain.contains(shortener),
    );
    if (isShortener && path.length < 10) {
      breakdown['URL Shortener'] = 25;
      score += 25;
    } else {
      breakdown['URL Shortener'] = 0;
    }

    // Check for suspicious TLDs (+25 points)
    List<String> suspiciousTLDs = [
      '.tk',
      '.ml',
      '.ga',
      '.cf',
      '.gq',
      '.xyz',
      '.top',
      '.click',
      '.link',
    ];
    if (suspiciousTLDs.any((tld) => domain.endsWith(tld))) {
      breakdown['Suspicious TLD'] = 25;
      score += 25;
    } else {
      breakdown['Suspicious TLD'] = 0;
    }

    // Check for brand impersonation patterns
    List<String> brandNames = [
      'paypal',
      'facebook',
      'google',
      'amazon',
      'apple',
      'microsoft',
      'bank',
    ];
    bool brandImpersonation = false;
    for (var brand in brandNames) {
      if (domain.contains(brand) &&
          !domain.endsWith('$brand.com') &&
          !domain.endsWith('.$brand.com')) {
        breakdown['Brand Impersonation'] = 35;
        score += 35;
        brandImpersonation = true;
        break;
      }
    }
    if (!brandImpersonation) {
      breakdown['Brand Impersonation'] = 0;
    }

    // Normalize score to 0-100 range
    score = score.clamp(0, 100);

    return (score, breakdown);
  }

  /// Determine classification based on risk score
  String _getClassification(int riskScore) => switch (riskScore) {
    <= 40 => 'Safe',
    <= 70 => 'Suspicious',
    _ => 'Malicious',
  };

  /// Generate human-readable reason for the classification
  String _generateReason(Uri url, int riskScore) {
    List<String> reasons = [];

    final String fullUrl = url.toString().toLowerCase();
    final String domain = url.host.toLowerCase();
    final String path = url.path.toLowerCase();

    // Check trusted domains
    final isTrusted = _trustedDomains.any(
      (trusted) => domain == trusted || domain.endsWith('.$trusted'),
    );
    if (isTrusted) {
      reasons.add('Recognized as a trusted domain');
      return reasons.join('. ');
    }

    // Check suspicious keywords in domain
    List<String> domainKeywords = _suspiciousKeywords
        .where((keyword) => domain.contains(keyword))
        .toList();
    if (domainKeywords.isNotEmpty) {
      reasons.add(
        'Domain contains suspicious keywords: ${domainKeywords.take(3).join(", ")}',
      );
    }

    // Check suspicious keywords in path
    List<String> pathKeywords = _suspiciousKeywords
        .where(
          (keyword) => path.contains(keyword) || url.query.contains(keyword),
        )
        .toList();
    if (pathKeywords.isNotEmpty && domainKeywords.isEmpty) {
      reasons.add(
        'URL path contains suspicious keywords: ${pathKeywords.take(2).join(", ")}',
      );
    }

    // Check protocol
    if (url.scheme == 'http') {
      reasons.add('Uses insecure HTTP protocol instead of HTTPS');
    }

    // Check domain structure
    if (domain.length > 30) {
      reasons.add(
        'Domain name is unusually long (${domain.length} characters)',
      );
    }

    final int subdomainCount = domain.split('.').length - 2;
    if (subdomainCount > 2) {
      reasons.add('Complex subdomain structure with $subdomainCount levels');
    }

    // Check for IP address
    final ipPattern = RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}');
    if (ipPattern.hasMatch(domain)) {
      reasons.add('Uses IP address instead of a proper domain name');
    }

    // Check for @ symbol
    if (fullUrl.contains('@')) {
      reasons.add('Contains @ symbol, often used for URL obfuscation');
    }

    // Check for excessive dashes
    int dashCount = domain.split('-').length - 1;
    if (dashCount > 3) {
      reasons.add('Contains excessive dashes in domain ($dashCount dashes)');
    }

    // Check for brand impersonation
    List<String> brandNames = [
      'paypal',
      'facebook',
      'google',
      'amazon',
      'apple',
      'microsoft',
      'bank',
    ];
    for (var brand in brandNames) {
      if (domain.contains(brand) &&
          !domain.endsWith('$brand.com') &&
          !domain.endsWith('.$brand.com')) {
        reasons.add('Possible impersonation of "$brand" brand');
        break;
      }
    }

    // Check for suspicious TLDs
    List<String> suspiciousTLDs = [
      '.tk',
      '.ml',
      '.ga',
      '.cf',
      '.gq',
      '.xyz',
      '.top',
      '.click',
      '.link',
    ];
    for (var tld in suspiciousTLDs) {
      if (domain.endsWith(tld)) {
        reasons.add('Uses suspicious top-level domain ($tld)');
        break;
      }
    }

    // Default reasons based on score if nothing specific found
    if (reasons.isEmpty) {
      if (riskScore <= 30) {
        reasons.add('No significant risk indicators detected');
        reasons.add('URL structure appears normal');
      } else if (riskScore <= 70) {
        reasons.add('Some minor risk indicators present');
        reasons.add('Exercise caution when visiting');
      } else {
        reasons.add('Multiple risk indicators detected');
        reasons.add('High likelihood of malicious intent');
      }
    }

    return reasons.join('. ');
  }
}
