import 'package:inline_logger/inline_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// DeviceIdService - Generates and persists a unique device identifier
///
/// Uses SharedPreferences to store a UUID that persists across sessions.
/// When authentication is added later, this device ID can be used to
/// migrate anonymous scan history to the authenticated user.
class DeviceIdService {
  static const _deviceIdKey = 'trustprobe_device_id';

  String? _deviceId;

  /// The current device ID. Must call [initialize] first.
  String get deviceId {
    assert(_deviceId != null, 'DeviceIdService not initialized');
    return _deviceId!;
  }

  /// Initialize the service: load existing device ID or generate a new one
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);

      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await prefs.setString(_deviceIdKey, _deviceId!);
        Logger.info('Generated new device ID: $_deviceId', 'DeviceIdService');
      } else {
        Logger.info('Loaded existing device ID: $_deviceId', 'DeviceIdService');
      }
    } catch (e) {
      // Fallback: generate a non-persistent ID so the app still works
      _deviceId = const Uuid().v4();
      Logger.error(
        'Error initializing device ID, using fallback: $e',
        'DeviceIdService',
      );
    }
  }
}
