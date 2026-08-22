import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../supabase/supabase.dart';
import 'push_notification_events.dart';

export 'push_notifications_handler.dart';
export 'serialization_util.dart';

/// This is deliberately a new channel id. Android notification-channel sound
/// settings are immutable once created, so reusing the old (silent) channel
/// would leave existing installations muted forever.
const gymFeedNotificationChannelId = 'gymfeed_alerts_v2';
const _gymFeedNotificationChannelName = 'GymFeed alerts';

const _androidChannel = AndroidNotificationChannel(
  gymFeedNotificationChannelId,
  _gymFeedNotificationChannelName,
  description: 'Messages, follows, likes, comments and GymFeed updates.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();
bool _pushNotificationsInitialized = false;

@pragma('vm:entry-point')
Future<void> gymFeedFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Notification payloads are rendered by Android/iOS while the app is in the
  // background. Initialising Firebase here also keeps data payload handling
  // safe from release-mode tree shaking.
  await Firebase.initializeApp();
}

/// Creates the audible Android channel and enables foreground presentation.
/// This does not show a permission dialog; permission is requested only after
/// a user signs in and their token is ready to be registered.
Future<void> initializePushNotifications() async {
  if (_pushNotificationsInitialized || kIsWeb) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;

  FirebaseMessaging.onBackgroundMessage(
    gymFeedFirebaseMessagingBackgroundHandler,
  );

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@drawable/ic_stat_gymfeed'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await _localNotifications.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          emitLocalNotificationTap(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (error) {
        debugPrint('Could not decode notification payload: $error');
      }
    },
  );

  if (Platform.isAndroid) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Android does not display a notification payload while Flutter is in the
  // foreground. Render it locally on the same high-priority audible channel.
  FirebaseMessaging.onMessage.listen((message) {
    if (Platform.isAndroid) {
      unawaited(_showForegroundAndroidNotification(message));
    }
  });
  _pushNotificationsInitialized = true;
}

Future<void> _showForegroundAndroidNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ??
      message.data['title'] ??
      message.data['notification_title'];
  final body = notification?.body ??
      message.data['body'] ??
      message.data['notification_text'];
  if ((title ?? '').toString().isEmpty && (body ?? '').toString().isEmpty) {
    return;
  }

  await _localNotifications.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title?.toString(),
    body?.toString(),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        gymFeedNotificationChannelId,
        _gymFeedNotificationChannelName,
        channelDescription:
            'Messages, follows, likes, comments and GymFeed updates.',
        icon: '@drawable/ic_stat_gymfeed',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.social,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

bool get _supportsMobilePush =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Requests alert/badge/sound permission, obtains the device FCM token, and
/// atomically associates it with the signed-in Supabase user.
Future<bool> registerCurrentDeviceForPush({String? refreshedToken}) async {
  if (!_supportsMobilePush || supabase.auth.currentUser == null) return false;

  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!allowed) {
      debugPrint('Push notification permission is not enabled.');
      return false;
    }

    final token = refreshedToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;

    await supabase.rpc(
      'register_fcm_token',
      params: {
        'p_token': token,
        'p_device_type': Platform.isIOS ? 'iOS' : 'Android',
      },
    );
    return true;
  } catch (error, stackTrace) {
    debugPrint('FCM token registration failed: $error\n$stackTrace');
    return false;
  }
}

/// Keeps the server token current after Firebase rotates it.
Stream<bool> get fcmTokenRefreshStream => !_supportsMobilePush
    ? const Stream<bool>.empty()
    : FirebaseMessaging.instance.onTokenRefresh.asyncMap(
        (token) => registerCurrentDeviceForPush(refreshedToken: token));

Future<void> _wakePushWorker() async {
  try {
    await supabase.functions.invoke('push-worker');
  } catch (error) {
    debugPrint('Push worker wake-up failed (cron will retry): $error');
  }
}

/// Nudges the server worker after legacy call sites create a like/comment/
/// follow. The authoritative database trigger constructs the notification,
/// recipients and content; the client cannot forge those details.
void triggerPushNotification({
  required String? notificationTitle,
  required String? notificationText,
  String? notificationImageUrl,
  DateTime? scheduledTime,
  String? notificationSound,
  required List<DocumentReference> userRefs,
  required String initialPageName,
  required Map<String, dynamic> parameterData,
}) {
  if (supabase.auth.currentUser == null) return;
  unawaited(_wakePushWorker());
}
