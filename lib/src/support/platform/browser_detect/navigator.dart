// Copyright 2017 Workiva Inc.
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

/// Abstraction over window.navigator so we can run tests in the VM
abstract class NavigatorProvider {
  String get vendor;
  String get appVersion;
  String get appName;
  String get userAgent;
}

/// Simple implementation that enables ease of unit testing
class TestNavigator implements NavigatorProvider {
  @override
  String vendor = '';
  @override
  String appVersion = '';
  @override
  String appName = '';
  @override
  String userAgent = '';
}
