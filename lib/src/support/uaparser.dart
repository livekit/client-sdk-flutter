import 'package:meta/meta.dart';

import 'uaparser/stub.dart'
    if (dart.library.io) 'uaparser/io.dart'
    if (dart.library.html) 'uaparser/web.dart';

abstract class UAParser {
  static UAParser create([String? userAgent]) {
    return uaParserForPlatform(userAgent);
  }

  Browser getBrowser();
  Device getDevice();
  Engine getEngine();
  OS getOS();
  CPU getCPU();
  Result getResult();
  String getUA();
  void setUA([String userAgent]);
}

@immutable
abstract class Result {
  String get ua;
  Browser get browser;
  CPU get cpu;
  Device get device;
  Engine get engine;
  OS get os;
}

@immutable
abstract class Browser {
  String get name;
  String get version;
}

@immutable
abstract class Device {
  String get model;
  String get type;
  String get vendor;
}

@immutable
abstract class Engine {
  String get name;
  String get version;
}

@immutable
abstract class OS {
  String get name;
  String get version;
}

@immutable
abstract class CPU {
  String get architecture;
}
