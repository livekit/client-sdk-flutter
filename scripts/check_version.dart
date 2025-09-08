import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  final File pubspec = File('pubspec.yaml');
  final doc = loadYaml(pubspec.readAsStringSync());
  final versionStr = doc['version'];

  final RegExpMatch? match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(versionStr);

  final version = match?[0];

  if (version == null) {
    // ignore: avoid_print
    print('Could not find version in pubspec.yaml');
    exit(1);
  }

  print('Checking version $version');

  final files = [
    'ios/livekit_client.podspec',
    'macos/livekit_client.podspec',
    'lib/src/livekit.dart'
  ];

  for (var file in files) {
    final content = File(file).readAsStringSync();
    if (!content.contains(version)) {
      final RegExp exp = RegExp(r'(\d+\.\d+\.\d+)');
      final RegExpMatch? match = exp.firstMatch(content);
      // ignore: avoid_print
      print(
          'Version mismatch in $file, pubspec.yaml version is $version != ${match![0]} in $file, please update');
      exit(1);
    }
  }
}
