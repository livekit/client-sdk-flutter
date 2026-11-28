#!/usr/bin/env dart

/*
 * Copyright 2026 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Compares the public API of two package trees with dart-apitool and prints
// `major` when a breaking change is left after dropping the ones confined to
// declarations annotated `@internal`. Prints nothing otherwise. This is the
// contract of `check.api` in verwalter.toml.
//
// dart-apitool follows every type reachable from an exported one, so a class
// like `Transport` that apps never see by name is still analyzed, and it does
// not honour `@internal` on such a class. This script reads the annotations
// itself:
//
// - An entry inside `Class X` is dropped when `X` is `@internal`.
// - An entry inside `Class X` > `Field|Method|Constructor m`, or an entry on
//   `Class X` that removes `m`, is dropped when `m` is `@internal` in `X`.
// - Annotations come from the new tree. A declaration that no longer exists
//   there is looked up in the old tree, so removing an internal member passes.
// - A name declared more than once counts as internal only if every
//   declaration is internal. Anything the script cannot map is kept.
// - A removed interface that the old tree did not export by name (no entry
//   point in `dart-apitool extract`) is dropped. Apps could only reach it
//   through members, and a change to a public one is reported on its own.
//   This is what happens when the last member exposing a proto type is
//   marked `@internal`.
//
// Logs go to stderr. A tool error, a missing or unreadable report, or a
// source file that does not parse exits non-zero, so the check fails
// instead of passing silently.
//
// Usage: dart run scripts/check_api.dart --old <dir> [--new <dir>]

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Future<void> main(List<String> args) async {
  try {
    exitCode = await _run(args);
  } catch (error, stack) {
    stderr.writeln('check_api: $error');
    stderr.writeln(stack);
    exitCode = 2;
  }
}

Future<int> _run(List<String> args) async {
  final options = _parseArgs(args);
  final oldDir = options['old'];
  final newDir = options['new'] ?? '.';
  if (oldDir == null) {
    stderr.writeln('Usage: dart run scripts/check_api.dart --old <dir> [--new <dir>]');
    return 64;
  }
  for (final dir in [oldDir, newDir]) {
    if (!File('$dir/pubspec.yaml').existsSync()) {
      stderr.writeln('check_api: no pubspec.yaml in $dir');
      return 2;
    }
  }

  final tmp = Directory.systemTemp.createTempSync('check_api');
  try {
    final reportFile = File('${tmp.path}/report.json');
    final toolExit = await _apitool([
      'diff',
      '--old',
      oldDir,
      '--new',
      newDir,
      '--version-check-mode',
      'none',
      '--report-format',
      'json',
      '--report-file-path',
      reportFile.path,
    ]);
    if (toolExit != 0) {
      stderr.writeln('check_api: dart-apitool diff exited with $toolExit');
      return toolExit;
    }
    if (!reportFile.existsSync()) {
      stderr.writeln('check_api: dart-apitool wrote no report');
      return 2;
    }

    final breaking = _breakingEntries(jsonDecode(reportFile.readAsStringSync()));
    if (breaking.isEmpty) {
      stderr.writeln('check_api: no breaking changes');
      return 0;
    }

    final newIndex = _InternalIndex.build('$newDir/lib');
    final oldIndex = _InternalIndex.build('$oldDir/lib');
    final candidates = <_Entry>[];
    for (final entry in breaking) {
      if (_isInternal(entry, newIndex, oldIndex)) {
        stderr.writeln('Ignored, internal: $entry');
      } else {
        candidates.add(entry);
      }
    }

    final removedInterfaces = {
      for (final entry in candidates)
        if (entry.path.isEmpty) ?_interfaceRemoval.firstMatch(entry.description)?.group(1),
    };
    var unexported = const <String>{};
    if (removedInterfaces.isNotEmpty) {
      final apiFile = File('${tmp.path}/old_api.json');
      final extractExit = await _apitool(['extract', '--input', oldDir, '--output', apiFile.path]);
      if (extractExit != 0) {
        stderr.writeln('check_api: dart-apitool extract exited with $extractExit');
        return extractExit;
      }
      unexported = _unexportedInterfaces(jsonDecode(apiFile.readAsStringSync()));
    }

    final kept = <_Entry>[];
    for (final entry in candidates) {
      final removed = entry.path.isEmpty ? _interfaceRemoval.firstMatch(entry.description)?.group(1) : null;
      if (removed != null && unexported.contains(removed)) {
        stderr.writeln('Ignored, not exported: $entry');
      } else {
        stderr.writeln('Breaking: $entry');
        kept.add(entry);
      }
    }
    if (kept.isNotEmpty) {
      stdout.writeln('major');
    }
    return 0;
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// Runs dart-apitool with its output on stderr: stdout is reserved for `major`.
Future<int> _apitool(List<String> args) async {
  final process = await Process.start('dart-apitool', args);
  await Future.wait([
    process.stdout.forEach(stderr.add),
    process.stderr.forEach(stderr.add),
  ]);
  return process.exitCode;
}

final _interfaceRemoval = RegExp(r'^Interface "([^"]+)" removed$');

/// Names of the interfaces in a `dart-apitool extract` model that no public
/// library exports by name. A name that is exported anywhere is left out.
Set<String> _unexportedInterfaces(Object? json) {
  if (json is! Map || json['packageApi'] is! Map) {
    throw const FormatException('extract output has no "packageApi" object');
  }
  final interfaces = (json['packageApi'] as Map)['interfaceDeclarations'];
  if (interfaces is! List) {
    throw const FormatException('extract output has no interface list');
  }
  final exported = <String>{};
  final unexported = <String>{};
  for (final interface in interfaces) {
    if (interface is! Map || interface['name'] is! String || interface['entryPoints'] is! List) {
      throw FormatException('unexpected interface: $interface');
    }
    final name = interface['name'] as String;
    ((interface['entryPoints'] as List).isEmpty ? unexported : exported).add(name);
  }
  return unexported.difference(exported);
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if ((arg == '--old' || arg == '--new') && i + 1 < args.length) {
      result[arg.substring(2)] = args[++i];
    } else {
      throw ArgumentError('unknown argument: $arg');
    }
  }
  return result;
}

/// A breaking change: the labels of the nodes above it and its description.
class _Entry {
  final List<String> path;
  final String description;
  final String code;

  _Entry(this.path, this.description, this.code);

  @override
  String toString() => [...path, '$description ($code)'].join(' > ');
}

/// Reads `report.breakingChanges` of the JSON report. Throws on any shape
/// it does not know, so a format change in dart-apitool fails the check.
List<_Entry> _breakingEntries(Object? json) {
  if (json is! Map || json['report'] is! Map) {
    throw const FormatException('report has no "report" object');
  }
  final report = json['report'] as Map;
  final root = report['breakingChanges'];
  if (root == null) {
    if (report['nonBreakingChanges'] == null && report['noChangesDetected'] != true) {
      throw const FormatException('report has no known keys');
    }
    return [];
  }
  final entries = <_Entry>[];
  void walk(Object? node, List<String> path) {
    if (node is! Map) {
      throw FormatException('unexpected node: $node');
    }
    if (node.containsKey('changeDescription')) {
      final description = node['changeDescription'];
      final code = node['changeCode'];
      final isBreaking = node['isBreaking'];
      if (description is! String || code is! String || isBreaking is! bool) {
        throw FormatException('unexpected change: $node');
      }
      if (isBreaking) {
        entries.add(_Entry(path, description, code));
      }
      return;
    }
    final label = node['label'];
    final children = node['children'];
    if (label is! String || children is! List) {
      throw FormatException('unexpected node: $node');
    }
    for (final child in children) {
      walk(child, [...path, label]);
    }
  }

  if (root is! Map || root['children'] is! List) {
    throw const FormatException('unexpected breakingChanges node');
  }
  for (final child in root['children'] as List) {
    walk(child, []);
  }
  return entries;
}

final _memberLabel = RegExp(r'^(Field|Method|Constructor|Function) (\S+)$');
final _removal = RegExp(r'^(Interface|Field|Method|Constructor|Function) "([^"]+)" removed$');

/// The tool prefixes names reached through a prefixed import (`lk_models.TrackInfo`).
String _simpleName(String name) => name.substring(name.lastIndexOf('.') + 1);

bool _isInternal(_Entry entry, _InternalIndex newIndex, _InternalIndex oldIndex) {
  bool? lookup(bool? Function(_InternalIndex) query) => query(newIndex) ?? query(oldIndex);

  final path = entry.path;
  if (path.isEmpty) {
    final removal = _removal.firstMatch(entry.description);
    if (removal == null) return false;
    final name = _simpleName(removal.group(2)!);
    return switch (removal.group(1)) {
      'Interface' => lookup((i) => i.type(name)) ?? false,
      'Function' || 'Field' => lookup((i) => i.topLevel(name)) ?? false,
      _ => false,
    };
  }

  if (path.first.startsWith('Class ')) {
    final type = _simpleName(path.first.substring('Class '.length));
    if (lookup((i) => i.type(type)) ?? false) return true;
    String? member;
    if (path.length >= 2) {
      member = _memberLabel.firstMatch(path[1])?.group(2);
    } else {
      final removal = _removal.firstMatch(entry.description);
      if (removal != null && removal.group(1) != 'Interface') member = removal.group(2);
    }
    if (member == null) return false;
    final name = _simpleName(member);
    return lookup((i) => i.member(type, name)) ?? false;
  }

  // A top-level function, variable or typedef.
  final label = _memberLabel.firstMatch(path.first);
  final name = _simpleName(label?.group(2) ?? path.first);
  return lookup((i) => label == null ? i.type(name) : i.topLevel(name)) ?? false;
}

/// Which declarations under a `lib/` directory are `@internal`. Each query
/// answers null when the name is not declared, true when every declaration
/// of it is internal, false otherwise.
class _InternalIndex {
  final _types = <String, List<bool>>{};
  final _members = <String, List<bool>>{};
  final _topLevel = <String, List<bool>>{};

  bool? type(String name) => _all(_types[name]);
  bool? member(String type, String name) => _all(_members['$type::$name']);
  bool? topLevel(String name) => _all(_topLevel[name]);

  static bool? _all(List<bool>? values) => values?.every((v) => v);

  static _InternalIndex build(String libDir) {
    final index = _InternalIndex();
    final files = Directory(
      libDir,
    ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
    if (files.isEmpty) {
      throw StateError('no Dart files under $libDir');
    }
    for (final file in files) {
      // Throws on a syntax error: a partial tree could hide a declaration.
      final unit = parseString(content: file.readAsStringSync(), path: file.path).unit;
      unit.accept(_Collector(index));
    }
    return index;
  }
}

bool _hasInternal(NodeList<Annotation> metadata) => metadata.any((a) {
  final name = a.name.name;
  return a.arguments == null && (name == 'internal' || name.endsWith('.internal'));
});

class _Collector extends RecursiveAstVisitor<void> {
  final _InternalIndex _index;
  String? _type;
  bool _typeInternal = false;

  _Collector(this._index);

  void _visitType(String? name, NodeList<Annotation> metadata, void Function() visitChildren) {
    if (name == null) return; // An unnamed extension adds no API of its own.
    final internal = _hasInternal(metadata);
    _index._types.putIfAbsent(name, () => []).add(internal);
    _type = name;
    _typeInternal = internal;
    visitChildren();
    _type = null;
    _typeInternal = false;
  }

  void _addMember(String name, NodeList<Annotation> metadata) {
    final internal = _hasInternal(metadata);
    final type = _type;
    if (type == null) {
      _index._topLevel.putIfAbsent(name, () => []).add(internal);
    } else {
      _index._members.putIfAbsent('$type::$name', () => []).add(_typeInternal || internal);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _visitType(node.namePart.typeName.lexeme, node.metadata, () => super.visitClassDeclaration(node));

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _visitType(node.namePart.typeName.lexeme, node.metadata, () => super.visitEnumDeclaration(node));

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _visitType(node.name.lexeme, node.metadata, () => super.visitMixinDeclaration(node));

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) =>
      _visitType(node.name?.lexeme, node.metadata, () => super.visitExtensionDeclaration(node));

  // Not used in this package. Recorded under no name, so nothing in it can
  // be found and every change to it is kept.
  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {}

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) =>
      _index._types.putIfAbsent(node.name.lexeme, () => []).add(_hasInternal(node.metadata));

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) =>
      _index._types.putIfAbsent(node.name.lexeme, () => []).add(_hasInternal(node.metadata));

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _addMember(node.name.lexeme, node.metadata);

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final variable in node.variables.variables) {
      _addMember(variable.name.lexeme, node.metadata);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _addMember(node.name.lexeme, node.metadata);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (final variable in node.fields.variables) {
      _addMember(variable.name.lexeme, node.metadata);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _addMember(node.name?.lexeme ?? 'new', node.metadata);

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) => _addMember(node.name.lexeme, node.metadata);
}
