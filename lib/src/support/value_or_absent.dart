// Copyright 2024 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Allows distinguishing between setting null and no-op in copyWith operations.
///
/// Example usage:
/// ```dart
/// class MyClass {
///   final String? name;
///   MyClass({this.name});
///
///   MyClass copyWith({ValueOrAbsent<String?> name = const Absent()}) =>
///       MyClass(name: name.valueOr(this.name));
/// }
///
/// // Usage:
/// obj.copyWith(name: Value(null));     // explicitly set to null
/// obj.copyWith(name: Value('test'));   // set to a value
/// obj.copyWith();                       // keep existing (absent)
/// ```
sealed class ValueOrAbsent<T> {
  const ValueOrAbsent();

  /// Returns the contained value if present, otherwise returns [other].
  T valueOr(T other);
}

/// Represents an explicitly provided value (including null).
class Value<T> extends ValueOrAbsent<T> {
  final T value;
  const Value(this.value);

  @override
  T valueOr(T other) => value;
}

/// Represents the absence of a value (use existing).
class Absent<T> extends ValueOrAbsent<T> {
  const Absent();

  @override
  T valueOr(T other) => other;
}
