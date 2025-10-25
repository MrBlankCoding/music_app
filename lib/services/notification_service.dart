import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      iOS: darwinSettings,
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initSettings);

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  Future<void> showDownloadQueued({
    required String videoId,
    required String title,
  }) async {
    if (!_initialized) await initialize();

    final details = _progressDetails();
    await _plugin.show(
      _idFor(videoId),
      'Added to downloads',
      title,
      details,
      payload: videoId,
    );
  }

  Future<void> showDownloadProgress({
    required String videoId,
    required String title,
    required double progress,
  }) async {
    if (!_initialized) await initialize();

    final clamped = (progress.clamp(0.0, 1.0) * 100).round();

    final details = _progressDetails();
    await _plugin.show(
      _idFor(videoId),
      'Downloading',
      '$title • $clamped%',
      details,
      payload: videoId,
    );
  }

  Future<void> showDownloadComplete({
    required String videoId,
    required String title,
  }) async {
    if (!_initialized) await initialize();

    final details = _completedDetails();
    await _plugin.show(
      _idFor(videoId),
      'Download complete',
      title,
      details,
      payload: videoId,
    );
  }

  Future<void> showDownloadFailed({
    required String videoId,
    required String title,
  }) async {
    if (!_initialized) await initialize();

    final details = _failedDetails();
    await _plugin.show(
      _idFor(videoId),
      'Download failed',
      title,
      details,
      payload: videoId,
    );
  }

  Future<void> cancel(String videoId) async {
    if (!_initialized) return;
    await _plugin.cancel(_idFor(videoId));
  }

  NotificationDetails _progressDetails() {
    return const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'downloads',
        categoryIdentifier: 'download-progress',
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'downloads',
        categoryIdentifier: 'download-progress',
      ),
    );
  }

  NotificationDetails _completedDetails() {
    return const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.passive,
        threadIdentifier: 'downloads',
        categoryIdentifier: 'download-complete',
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.passive,
        threadIdentifier: 'downloads',
        categoryIdentifier: 'download-complete',
      ),
    );
  }

  NotificationDetails _failedDetails() {
    return const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'downloads',
        categoryIdentifier: 'download-failed',
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        threadIdentifier: 'downloads',
        categoryIdentifier: 'download-failed',
      ),
    );
  }

  int _idFor(String videoId) => videoId.hashCode;
}
