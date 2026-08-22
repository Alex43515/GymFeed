import 'dart:async';

final StreamController<Map<String, dynamic>> _localNotificationTaps =
    StreamController<Map<String, dynamic>>.broadcast();

Stream<Map<String, dynamic>> get localNotificationTapStream =>
    _localNotificationTaps.stream;

void emitLocalNotificationTap(Map<String, dynamic> data) =>
    _localNotificationTaps.add(data);
