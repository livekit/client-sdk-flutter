import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  File pubspec = File('pubspec.yaml');
  var doc = loadYaml(pubspec.readAsStringSync());
  var version = doc['version'];

  var files = [
    'ios/livekit_client.podspec',
    'macos/livekit_client.podspec',
    'lib/src/livekit.dart'
  ];

  for (var file in files) {
    var content = File(file).readAsStringSync();
    if (!content.contains(version)) {
      RegExp exp = RegExp(r'(\d+\.\d+\.\d+)');
      RegExpMatch? match = exp.firstMatch(content);
      // ignore: avoid_print
      print(
          'Version mismatch in $file, pubspec.yaml version is $version != ${match![0]} in $file, please update');
      exit(1);
    }
  }
}
