class ScanResult {
  final String url;
  final int riskScore;
  final String classification;
  final String reason;
  final DateTime timestamp;
  final String? aiAnalysis;
  final String? deviceId;
  final Map<String, int> scoreBreakdown;

  const ScanResult({
    required this.url,
    required this.riskScore,
    required this.classification,
    required this.reason,
    required this.timestamp,
    this.aiAnalysis,
    this.deviceId,
    this.scoreBreakdown = const {},
  });

  /// Create a copy with optional field overrides
  ScanResult copyWith({
    String? url,
    int? riskScore,
    String? classification,
    String? reason,
    DateTime? timestamp,
    String? aiAnalysis,
    String? deviceId,
    Map<String, int>? scoreBreakdown,
  }) => ScanResult(
    url: url ?? this.url,
    riskScore: riskScore ?? this.riskScore,
    classification: classification ?? this.classification,
    reason: reason ?? this.reason,
    timestamp: timestamp ?? this.timestamp,
    aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    deviceId: deviceId ?? this.deviceId,
    scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
  );

  /// Create ScanResult from Firestore DocumentSnapshot
  factory ScanResult.fromFirestore(Map<String, dynamic> data) => ScanResult(
    url: data['url'] as String,
    riskScore: data['riskScore'] as int,
    classification: data['classification'] as String,
    reason: data['reason'] as String,
    timestamp: DateTime.parse(data['timestamp'] as String),
    aiAnalysis: data['aiAnalysis'] as String?,
    deviceId: data['deviceId'] as String?,
    scoreBreakdown:
        (data['scoreBreakdown'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int),
        ) ??
        {},
  );

  /// Convert ScanResult to Map for Firestore
  Map<String, dynamic> toMap() => {
    'url': url,
    'riskScore': riskScore,
    'classification': classification,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
    if (deviceId != null) 'deviceId': deviceId,
    if (scoreBreakdown.isNotEmpty) 'scoreBreakdown': scoreBreakdown,
  };

  /// Get color based on risk score
  String get riskColor => switch (riskScore) {
    <= 30 => 'green',
    <= 70 => 'yellow',
    _ => 'red',
  };

  /// Get risk level label
  String get riskLevel => switch (riskScore) {
    <= 30 => 'Low Risk',
    <= 70 => 'Medium Risk',
    _ => 'High Risk',
  };

  @override
  String toString() =>
      'ScanResult(url: $url, riskScore: $riskScore, classification: $classification)';
}
