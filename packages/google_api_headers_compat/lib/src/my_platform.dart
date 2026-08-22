import 'dart:io';

abstract class MyPlatform {
  bool get isAndroid;
  bool get isIos;
  bool get isDesktop;
}

class MyPlatformImp implements MyPlatform {
  const MyPlatformImp();

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIos => Platform.isIOS;

  @override
  bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
