import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_api_headers/src/my_platform.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provides the platform headers required for Google APIs with restricted keys.
class GoogleApiHeaders {
  final MyPlatform platform;

  const GoogleApiHeaders([MyPlatform? platform])
      : platform = platform ?? const MyPlatformImp();

  static Map<String, String> _headers = {};
  final MethodChannel _channel = const MethodChannel('google_api_headers');

  @visibleForTesting
  static void clear() => _headers.clear();

  Future<Map<String, String>> getHeaders() async {
    if (_headers.isEmpty && !kIsWeb && !platform.isDesktop) {
      final packageInfo = await PackageInfo.fromPlatform();
      if (platform.isIos) {
        _headers = {'X-Ios-Bundle-Identifier': packageInfo.packageName};
      } else if (platform.isAndroid) {
        try {
          final sha1 = await _channel.invokeMethod<String>(
            'getSigningCertSha1',
            packageInfo.packageName,
          );
          if (sha1 != null && sha1.isNotEmpty) {
            _headers = {
              'X-Android-Package': packageInfo.packageName,
              'X-Android-Cert': sha1,
            };
          }
        } on PlatformException {
          _headers = {};
        }
      }
    }
    return _headers;
  }
}
