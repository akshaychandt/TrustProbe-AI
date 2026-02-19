import 'package:inline_logger/inline_logger.dart';

import 'package:stacked/stacked.dart';
import 'package:trustprobe_ai/app/app.locator.dart';
import 'package:trustprobe_ai/services/device_id_service.dart';
import 'package:trustprobe_ai/services/phishing_service.dart';
import 'package:trustprobe_ai/services/firestore_service.dart';
import 'package:trustprobe_ai/models/scan_result.dart';

/// HomeViewModel - Business logic for the home screen
///
/// Manages URL analysis, state, and Firestore operations
class HomeViewModel extends BaseViewModel {
  final _phishingService = locator<PhishingService>();
  final _firestoreService = locator<FirestoreService>();
  final _deviceIdService = locator<DeviceIdService>();

  // State variables
  String _urlInput = '';
  ScanResult? _currentResult;
  String? _errorMessage;

  // Getters
  String get urlInput => _urlInput;
  ScanResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _currentResult != null;
  @override
  bool get hasError => _errorMessage != null;

  /// Stream of previous scan results from Firestore, cached to avoid
  /// recreating on every rebuild (which causes the loading spinner to flash)
  late final Stream<List<ScanResult>> previousScans = _firestoreService
      .getPreviousScans(deviceId: _deviceIdService.deviceId);

  /// Update URL input
  void updateUrlInput(String value) {
    _urlInput = value;
    _errorMessage = null;
    notifyListeners();
  }

  /// Analyze the entered URL
  Future<void> analyzeUrl() async {
    // Clear previous results and errors
    _currentResult = null;
    _errorMessage = null;

    // Validate input
    if (_urlInput.trim().isEmpty) {
      _errorMessage = 'Please enter a URL to analyze';
      notifyListeners();
      return;
    }

    // Set loading state
    setBusy(true);
    notifyListeners();

    try {
      // Analyze URL using PhishingService
      final result = await _phishingService.analyzeUrl(_urlInput);

      // Attach device ID and update current result
      _currentResult = result.copyWith(deviceId: _deviceIdService.deviceId);

      // Save to Firestore (non-blocking, with timeout)
      // Don't await - let it save in background
      _firestoreService
          .saveScanResult(_currentResult!)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              Logger.warning(
                'Firestore save timed out - Firebase may not be configured',
                'HomeViewModel',
              );
            },
          )
          .catchError((error) {
            Logger.error('Firestore save error: $error', 'HomeViewModel');
          });

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to analyze URL: ${e.toString()}';
      _currentResult = null;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  /// Clear current result and reset form
  void clearResult() {
    _currentResult = null;
    _urlInput = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Show a previous scan result (when clicked from history)
  void showPreviousScan(ScanResult result) {
    _currentResult = result;
    _urlInput = result.url;
    _errorMessage = null;
    notifyListeners();
  }
}
