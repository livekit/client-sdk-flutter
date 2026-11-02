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

import 'dart:collection';

import 'package:collection/collection.dart';

import '../participant/participant.dart';

/// Small helper for participant lookups by identity and sid.
class ParticipantCollection<T extends Participant> extends IterableBase<T> {
  final Map<String, T> _byIdentity = {};

  // Read-only view of the collection
  UnmodifiableMapView<String, T> get byIdentity => UnmodifiableMapView(_byIdentity);

  // Searches by each participant's current sid. A takeover changes the sid in place, so a sid index would go stale.
  T? findBySid(String sid) => _byIdentity.values.firstWhereOrNull((participant) => participant.sid == sid);

  // Update methods
  void set(T participant) {
    _byIdentity[participant.identity] = participant;
  }

  // Contains methods
  bool containsIdentity(String identity) => _byIdentity.containsKey(identity);

  void clear() {
    _byIdentity.clear();
  }

  T? removeByIdentity(String identity) => _byIdentity.remove(identity);

  @override
  Iterator<T> get iterator => _byIdentity.values.iterator;
}
