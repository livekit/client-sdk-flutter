import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  File pubspec = File('pubspec.yaml');
  var doc = loadYaml(pubspec.readAsStringSync());
  var versionStr = doc['version'];

  RegExpMatch? match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(versionStr);

  var version = match?[0];

  if (version == null) {
    // ignore: avoid_print
    print('Could not find version in pubspec.yaml');
    exit(1);
  }

  print('Checking version $version');

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
