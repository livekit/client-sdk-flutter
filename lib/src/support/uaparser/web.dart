// JS Interop for ua-parser-js
// https://github.com/faisalman/ua-parser-js

@JS()
library ua_parser_js;

import 'package:flutter/material.dart';
import 'package:js/js.dart';

import '../uaparser.dart';

UAParser uaParserForPlatform([String? userAgent]) => UAParserWeb(userAgent);

@JS('UAParser')
class UAParserWeb implements UAParser {
  external UAParserWeb([String? userAgent]);
  @override
  external BrowserWeb getBrowser();
  @override
  external DeviceWeb getDevice();
  @override
  external EngineWeb getEngine();
  @override
  external OSWeb getOS();
  @override
  external CPUWeb getCPU();
  @override
  external ResultWeb getResult();
  @override
  external String getUA();
  @override
  external void setUA([String userAgent]);
}

@JS()
@anonymous
@immutable
class ResultWeb implements Result {
  @override
  external String get ua;
  @override
  external BrowserWeb get browser;
  @override
  external CPUWeb get cpu;
  @override
  external DeviceWeb get device;
  @override
  external EngineWeb get engine;
  @override
  external OSWeb get os;
  external const factory ResultWeb({
    String ua,
    BrowserWeb browser,
    CPUWeb cpu,
    DeviceWeb device,
    EngineWeb engine,
    OSWeb os,
  });
}

@JS()
@anonymous
@immutable
class BrowserWeb implements Browser {
  @override
  external String? get name;
  @override
  external String? get version;
  external const factory BrowserWeb({
    String? name,
    String? version,
  });
}

@JS()
@anonymous
@immutable
class DeviceWeb implements Device {
  @override
  external String? get model;
  @override
  external String? get type;
  @override
  external String? get vendor;
  external const factory DeviceWeb({
    String? model,
    String? type,
    String? vendor,
  });
}

@JS()
@anonymous
@immutable
class EngineWeb implements Engine {
  @override
  external String? get name;
  @override
  external String? get version;
  external const factory EngineWeb({
    String? name,
    String? version,
  });
}

@JS()
@anonymous
@immutable
class OSWeb implements OS {
  @override
  external String? get name;
  @override
  external String? get version;
  external const factory OSWeb({
    String? name,
    String? version,
  });
}

@JS()
@anonymous
@immutable
class CPUWeb implements CPU {
  @override
  external String? get architecture;
  external const factory CPUWeb({
    String? architecture,
  });
}
