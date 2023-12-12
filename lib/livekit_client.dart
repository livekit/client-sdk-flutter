// Copyright 2023 LiveKit, Inc.
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

/// Flutter Client SDK to LiveKit.
library livekit_client;

export 'src/constants.dart';
export 'src/core/room.dart';
export 'src/events.dart';
export 'src/exceptions.dart';
export 'src/e2ee/e2ee_manager.dart';
export 'src/e2ee/events.dart';
export 'src/e2ee/options.dart';
export 'src/e2ee/key_provider.dart';
export 'src/extensions.dart' show WidgetsBindingCompatible;
export 'src/hardware/hardware.dart';
export 'src/livekit.dart';
export 'src/logger.dart';
export 'src/managers/event.dart';
export 'src/options.dart';
export 'src/participant/local.dart';
export 'src/participant/participant.dart';
export 'src/participant/remote.dart';
export 'src/proto/livekit_models.pb.dart' show TrackType, VideoQuality;
export 'src/publication/local.dart';
export 'src/publication/remote.dart';
export 'src/publication/track_publication.dart';
export 'src/support/platform.dart';
export 'src/track/local/audio.dart';
export 'src/track/local/local.dart';
export 'src/track/local/video.dart';
export 'src/track/options.dart';
export 'src/track/remote/audio.dart';
export 'src/track/remote/remote.dart';
export 'src/track/remote/video.dart';
export 'src/track/track.dart';
export 'src/types/other.dart';
export 'src/types/participant_permissions.dart';
export 'src/types/video_dimensions.dart';
export 'src/types/video_encoding.dart';
export 'src/types/video_parameters.dart';
export 'src/widgets/screen_select_dialog.dart';
export 'src/widgets/video_track_renderer.dart';
