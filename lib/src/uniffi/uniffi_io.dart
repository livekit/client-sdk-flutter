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

import 'package:livekit_uniffi/livekit_uniffi.dart' as uniffi;

// The telemetry integration (`telemetry/telemetry_io.dart`) reaches the
// bindings through this file, so this stays the SDK's single import site.
export 'package:livekit_uniffi/livekit_telemetry.dart'
    show
        AnswerSentSpanStep,
        AppState,
        AttemptSpanStep,
        Attribute,
        AttributeValue,
        AudioOutput,
        AudioRouteChangedDeviceEvent,
        AudioRouteReason,
        BoolAttributeValue,
        CaptureDevice,
        CaptureFailedDeviceEvent,
        CaptureFailure,
        ConnectSpanName,
        CustomSpanName,
        DeviceState,
        DisconnectReason,
        DoubleAttributeValue,
        EngineSpanStep,
        ExportResponse,
        Instrument,
        IntAttributeValue,
        JoinRecvSpanStep,
        LogRecord,
        LogSource,
        MemoryPressure,
        NetworkType,
        OfferSentSpanStep,
        PcConnectedSpanStep,
        PcCreatedSpanStep,
        PublishSpanName,
        ReconnectReason,
        ReconnectSpanName,
        RetryableExportException,
        RoomConnectedSpanStep,
        RoomIdentity,
        RtcStat,
        Sdk,
        Severity,
        SignalSpanStep,
        SpanName,
        SpanOutcome,
        SpanTrack,
        StrAttributeValue,
        StreamDirection,
        TelemetryConfig,
        TelemetryInstrument,
        TelemetryResource,
        ThermalState,
        TrackKind,
        TrackSource,
        WsOpenSpanStep;
export 'package:livekit_uniffi/livekit_uniffi.dart';

/// Native implementation of [LiveKitUniffi]. See `uniffi.dart`.
///
/// This is the only file in the SDK that may import the generated bindings:
/// the conditional import in `uniffi.dart` keeps it out of web builds.
const bool isAvailable = true;

String buildVersion() => uniffi.buildVersion();
