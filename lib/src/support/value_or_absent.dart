// Copyright 2026 LiveKit, Inc.
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

/// Distinguishes an omitted copy value from an explicit replacement value.
///
/// This is useful for `copyWith` methods where a nullable field must be able to
/// keep its current value, change to a non-null value, or change to `null`.
///
/// ```dart
/// class Example {
///   const Example({this.name});
///
///   final String? name;
///
///   Example copyWith({
///     ValueOrAbsent<String?> name = const Absent(),
///   }) =>
///       Example(name: name.valueOr(this.name));
/// }
///
/// example.copyWith(); // keep existing name
/// example.copyWith(name: Value('room')); // set name
/// example.copyWith(name: Value(null)); // clear name
/// ```
sealed class ValueOrAbsent<T> {
  const ValueOrAbsent();

  /// Creates an explicit replacement value.
  const factory ValueOrAbsent.value(T value) = Value<T>;

  /// Creates an omitted value that preserves the current field.
  const factory ValueOrAbsent.absent() = Absent<T>;

  /// Returns the explicit value, or [other] when this value is absent.
  T valueOr(T other);
}

/// An explicit replacement value, including `null`.
final class Value<T> extends ValueOrAbsent<T> {
  const Value(this.value);

  final T value;

  @override
  T valueOr(T other) => value;
}

/// An omitted value that keeps the current field.
final class Absent<T> extends ValueOrAbsent<T> {
  const Absent();

  @override
  T valueOr(T other) => other;
}
