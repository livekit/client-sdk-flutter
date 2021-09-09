///
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'livekit_models.pb.dart' as $0;

import 'livekit_models.pbenum.dart' as $0;
import 'livekit_rtc.pbenum.dart';

export 'livekit_rtc.pbenum.dart';

enum SignalRequest_Message {
  offer,
  answer,
  trickle,
  addTrack,
  mute,
  subscription,
  trackSetting,
  leave,
  simulcast,
  notSet
}

class SignalRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SignalRequest_Message> _SignalRequest_MessageByTag = {
    1: SignalRequest_Message.offer,
    2: SignalRequest_Message.answer,
    3: SignalRequest_Message.trickle,
    4: SignalRequest_Message.addTrack,
    5: SignalRequest_Message.mute,
    6: SignalRequest_Message.subscription,
    7: SignalRequest_Message.trackSetting,
    8: SignalRequest_Message.leave,
    9: SignalRequest_Message.simulcast,
    0: SignalRequest_Message.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SignalRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    ..aOM<SessionDescription>(
        1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'offer',
        subBuilder: SessionDescription.create)
    ..aOM<SessionDescription>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'answer',
        subBuilder: SessionDescription.create)
    ..aOM<TrickleRequest>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trickle',
        subBuilder: TrickleRequest.create)
    ..aOM<AddTrackRequest>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'addTrack',
        subBuilder: AddTrackRequest.create)
    ..aOM<MuteTrackRequest>(
        5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mute',
        subBuilder: MuteTrackRequest.create)
    ..aOM<UpdateSubscription>(
        6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subscription',
        subBuilder: UpdateSubscription.create)
    ..aOM<UpdateTrackSettings>(
        7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackSetting',
        subBuilder: UpdateTrackSettings.create)
    ..aOM<LeaveRequest>(
        8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'leave',
        subBuilder: LeaveRequest.create)
    ..aOM<SetSimulcastLayers>(
        9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'simulcast',
        subBuilder: SetSimulcastLayers.create)
    ..hasRequiredFields = false;

  SignalRequest._() : super();
  factory SignalRequest({
    SessionDescription? offer,
    SessionDescription? answer,
    TrickleRequest? trickle,
    AddTrackRequest? addTrack,
    MuteTrackRequest? mute,
    UpdateSubscription? subscription,
    UpdateTrackSettings? trackSetting,
    LeaveRequest? leave,
    SetSimulcastLayers? simulcast,
  }) {
    final _result = create();
    if (offer != null) {
      _result.offer = offer;
    }
    if (answer != null) {
      _result.answer = answer;
    }
    if (trickle != null) {
      _result.trickle = trickle;
    }
    if (addTrack != null) {
      _result.addTrack = addTrack;
    }
    if (mute != null) {
      _result.mute = mute;
    }
    if (subscription != null) {
      _result.subscription = subscription;
    }
    if (trackSetting != null) {
      _result.trackSetting = trackSetting;
    }
    if (leave != null) {
      _result.leave = leave;
    }
    if (simulcast != null) {
      _result.simulcast = simulcast;
    }
    return _result;
  }
  factory SignalRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SignalRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SignalRequest clone() => SignalRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SignalRequest copyWith(void Function(SignalRequest) updates) =>
      super.copyWith((message) => updates(message as SignalRequest))
          as SignalRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SignalRequest create() => SignalRequest._();
  SignalRequest createEmptyInstance() => create();
  static $pb.PbList<SignalRequest> createRepeated() => $pb.PbList<SignalRequest>();
  @$core.pragma('dart2js:noInline')
  static SignalRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignalRequest>(create);
  static SignalRequest? _defaultInstance;

  SignalRequest_Message whichMessage() => _SignalRequest_MessageByTag[$_whichOneof(0)]!;
  void clearMessage() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SessionDescription get offer => $_getN(0);
  @$pb.TagNumber(1)
  set offer(SessionDescription v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasOffer() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffer() => clearField(1);
  @$pb.TagNumber(1)
  SessionDescription ensureOffer() => $_ensure(0);

  @$pb.TagNumber(2)
  SessionDescription get answer => $_getN(1);
  @$pb.TagNumber(2)
  set answer(SessionDescription v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAnswer() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnswer() => clearField(2);
  @$pb.TagNumber(2)
  SessionDescription ensureAnswer() => $_ensure(1);

  @$pb.TagNumber(3)
  TrickleRequest get trickle => $_getN(2);
  @$pb.TagNumber(3)
  set trickle(TrickleRequest v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTrickle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrickle() => clearField(3);
  @$pb.TagNumber(3)
  TrickleRequest ensureTrickle() => $_ensure(2);

  @$pb.TagNumber(4)
  AddTrackRequest get addTrack => $_getN(3);
  @$pb.TagNumber(4)
  set addTrack(AddTrackRequest v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAddTrack() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddTrack() => clearField(4);
  @$pb.TagNumber(4)
  AddTrackRequest ensureAddTrack() => $_ensure(3);

  @$pb.TagNumber(5)
  MuteTrackRequest get mute => $_getN(4);
  @$pb.TagNumber(5)
  set mute(MuteTrackRequest v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasMute() => $_has(4);
  @$pb.TagNumber(5)
  void clearMute() => clearField(5);
  @$pb.TagNumber(5)
  MuteTrackRequest ensureMute() => $_ensure(4);

  @$pb.TagNumber(6)
  UpdateSubscription get subscription => $_getN(5);
  @$pb.TagNumber(6)
  set subscription(UpdateSubscription v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSubscription() => $_has(5);
  @$pb.TagNumber(6)
  void clearSubscription() => clearField(6);
  @$pb.TagNumber(6)
  UpdateSubscription ensureSubscription() => $_ensure(5);

  @$pb.TagNumber(7)
  UpdateTrackSettings get trackSetting => $_getN(6);
  @$pb.TagNumber(7)
  set trackSetting(UpdateTrackSettings v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasTrackSetting() => $_has(6);
  @$pb.TagNumber(7)
  void clearTrackSetting() => clearField(7);
  @$pb.TagNumber(7)
  UpdateTrackSettings ensureTrackSetting() => $_ensure(6);

  @$pb.TagNumber(8)
  LeaveRequest get leave => $_getN(7);
  @$pb.TagNumber(8)
  set leave(LeaveRequest v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLeave() => $_has(7);
  @$pb.TagNumber(8)
  void clearLeave() => clearField(8);
  @$pb.TagNumber(8)
  LeaveRequest ensureLeave() => $_ensure(7);

  @$pb.TagNumber(9)
  SetSimulcastLayers get simulcast => $_getN(8);
  @$pb.TagNumber(9)
  set simulcast(SetSimulcastLayers v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasSimulcast() => $_has(8);
  @$pb.TagNumber(9)
  void clearSimulcast() => clearField(9);
  @$pb.TagNumber(9)
  SetSimulcastLayers ensureSimulcast() => $_ensure(8);
}

enum SignalResponse_Message {
  join,
  answer,
  offer,
  trickle,
  update,
  trackPublished,
  speaker,
  leave,
  mute,
  notSet
}

class SignalResponse extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SignalResponse_Message> _SignalResponse_MessageByTag = {
    1: SignalResponse_Message.join,
    2: SignalResponse_Message.answer,
    3: SignalResponse_Message.offer,
    4: SignalResponse_Message.trickle,
    5: SignalResponse_Message.update,
    6: SignalResponse_Message.trackPublished,
    7: SignalResponse_Message.speaker,
    8: SignalResponse_Message.leave,
    9: SignalResponse_Message.mute,
    0: SignalResponse_Message.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SignalResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    ..aOM<JoinResponse>(
        1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'join',
        subBuilder: JoinResponse.create)
    ..aOM<SessionDescription>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'answer',
        subBuilder: SessionDescription.create)
    ..aOM<SessionDescription>(
        3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'offer',
        subBuilder: SessionDescription.create)
    ..aOM<TrickleRequest>(
        4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trickle',
        subBuilder: TrickleRequest.create)
    ..aOM<ParticipantUpdate>(
        5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'update',
        subBuilder: ParticipantUpdate.create)
    ..aOM<TrackPublishedResponse>(
        6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackPublished',
        subBuilder: TrackPublishedResponse.create)
    ..aOM<$0.ActiveSpeakerUpdate>(
        7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'speaker',
        subBuilder: $0.ActiveSpeakerUpdate.create)
    ..aOM<LeaveRequest>(
        8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'leave',
        subBuilder: LeaveRequest.create)
    ..aOM<MuteTrackRequest>(
        9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mute',
        subBuilder: MuteTrackRequest.create)
    ..hasRequiredFields = false;

  SignalResponse._() : super();
  factory SignalResponse({
    JoinResponse? join,
    SessionDescription? answer,
    SessionDescription? offer,
    TrickleRequest? trickle,
    ParticipantUpdate? update,
    TrackPublishedResponse? trackPublished,
    $0.ActiveSpeakerUpdate? speaker,
    LeaveRequest? leave,
    MuteTrackRequest? mute,
  }) {
    final _result = create();
    if (join != null) {
      _result.join = join;
    }
    if (answer != null) {
      _result.answer = answer;
    }
    if (offer != null) {
      _result.offer = offer;
    }
    if (trickle != null) {
      _result.trickle = trickle;
    }
    if (update != null) {
      _result.update = update;
    }
    if (trackPublished != null) {
      _result.trackPublished = trackPublished;
    }
    if (speaker != null) {
      _result.speaker = speaker;
    }
    if (leave != null) {
      _result.leave = leave;
    }
    if (mute != null) {
      _result.mute = mute;
    }
    return _result;
  }
  factory SignalResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SignalResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SignalResponse clone() => SignalResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SignalResponse copyWith(void Function(SignalResponse) updates) =>
      super.copyWith((message) => updates(message as SignalResponse))
          as SignalResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SignalResponse create() => SignalResponse._();
  SignalResponse createEmptyInstance() => create();
  static $pb.PbList<SignalResponse> createRepeated() => $pb.PbList<SignalResponse>();
  @$core.pragma('dart2js:noInline')
  static SignalResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignalResponse>(create);
  static SignalResponse? _defaultInstance;

  SignalResponse_Message whichMessage() => _SignalResponse_MessageByTag[$_whichOneof(0)]!;
  void clearMessage() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  JoinResponse get join => $_getN(0);
  @$pb.TagNumber(1)
  set join(JoinResponse v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasJoin() => $_has(0);
  @$pb.TagNumber(1)
  void clearJoin() => clearField(1);
  @$pb.TagNumber(1)
  JoinResponse ensureJoin() => $_ensure(0);

  @$pb.TagNumber(2)
  SessionDescription get answer => $_getN(1);
  @$pb.TagNumber(2)
  set answer(SessionDescription v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAnswer() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnswer() => clearField(2);
  @$pb.TagNumber(2)
  SessionDescription ensureAnswer() => $_ensure(1);

  @$pb.TagNumber(3)
  SessionDescription get offer => $_getN(2);
  @$pb.TagNumber(3)
  set offer(SessionDescription v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasOffer() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffer() => clearField(3);
  @$pb.TagNumber(3)
  SessionDescription ensureOffer() => $_ensure(2);

  @$pb.TagNumber(4)
  TrickleRequest get trickle => $_getN(3);
  @$pb.TagNumber(4)
  set trickle(TrickleRequest v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTrickle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTrickle() => clearField(4);
  @$pb.TagNumber(4)
  TrickleRequest ensureTrickle() => $_ensure(3);

  @$pb.TagNumber(5)
  ParticipantUpdate get update => $_getN(4);
  @$pb.TagNumber(5)
  set update(ParticipantUpdate v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearUpdate() => clearField(5);
  @$pb.TagNumber(5)
  ParticipantUpdate ensureUpdate() => $_ensure(4);

  @$pb.TagNumber(6)
  TrackPublishedResponse get trackPublished => $_getN(5);
  @$pb.TagNumber(6)
  set trackPublished(TrackPublishedResponse v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTrackPublished() => $_has(5);
  @$pb.TagNumber(6)
  void clearTrackPublished() => clearField(6);
  @$pb.TagNumber(6)
  TrackPublishedResponse ensureTrackPublished() => $_ensure(5);

  @$pb.TagNumber(7)
  $0.ActiveSpeakerUpdate get speaker => $_getN(6);
  @$pb.TagNumber(7)
  set speaker($0.ActiveSpeakerUpdate v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasSpeaker() => $_has(6);
  @$pb.TagNumber(7)
  void clearSpeaker() => clearField(7);
  @$pb.TagNumber(7)
  $0.ActiveSpeakerUpdate ensureSpeaker() => $_ensure(6);

  @$pb.TagNumber(8)
  LeaveRequest get leave => $_getN(7);
  @$pb.TagNumber(8)
  set leave(LeaveRequest v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLeave() => $_has(7);
  @$pb.TagNumber(8)
  void clearLeave() => clearField(8);
  @$pb.TagNumber(8)
  LeaveRequest ensureLeave() => $_ensure(7);

  @$pb.TagNumber(9)
  MuteTrackRequest get mute => $_getN(8);
  @$pb.TagNumber(9)
  set mute(MuteTrackRequest v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasMute() => $_has(8);
  @$pb.TagNumber(9)
  void clearMute() => clearField(9);
  @$pb.TagNumber(9)
  MuteTrackRequest ensureMute() => $_ensure(8);
}

class AddTrackRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'AddTrackRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cid')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<$0.TrackType>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type',
        $pb.PbFieldType.OE,
        defaultOrMaker: $0.TrackType.AUDIO,
        valueOf: $0.TrackType.valueOf,
        enumValues: $0.TrackType.values)
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'width',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height',
        $pb.PbFieldType.OU3)
    ..aOB(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'muted')
    ..hasRequiredFields = false;

  AddTrackRequest._() : super();
  factory AddTrackRequest({
    $core.String? cid,
    $core.String? name,
    $0.TrackType? type,
    $core.int? width,
    $core.int? height,
    $core.bool? muted,
  }) {
    final _result = create();
    if (cid != null) {
      _result.cid = cid;
    }
    if (name != null) {
      _result.name = name;
    }
    if (type != null) {
      _result.type = type;
    }
    if (width != null) {
      _result.width = width;
    }
    if (height != null) {
      _result.height = height;
    }
    if (muted != null) {
      _result.muted = muted;
    }
    return _result;
  }
  factory AddTrackRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory AddTrackRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  AddTrackRequest clone() => AddTrackRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  AddTrackRequest copyWith(void Function(AddTrackRequest) updates) =>
      super.copyWith((message) => updates(message as AddTrackRequest))
          as AddTrackRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AddTrackRequest create() => AddTrackRequest._();
  AddTrackRequest createEmptyInstance() => create();
  static $pb.PbList<AddTrackRequest> createRepeated() => $pb.PbList<AddTrackRequest>();
  @$core.pragma('dart2js:noInline')
  static AddTrackRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddTrackRequest>(create);
  static AddTrackRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cid => $_getSZ(0);
  @$pb.TagNumber(1)
  set cid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCid() => $_has(0);
  @$pb.TagNumber(1)
  void clearCid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $0.TrackType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type($0.TrackType v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get width => $_getIZ(3);
  @$pb.TagNumber(4)
  set width($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearWidth() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get height => $_getIZ(4);
  @$pb.TagNumber(5)
  set height($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeight() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get muted => $_getBF(5);
  @$pb.TagNumber(6)
  set muted($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasMuted() => $_has(5);
  @$pb.TagNumber(6)
  void clearMuted() => clearField(6);
}

class TrickleRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TrickleRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'candidateInit',
        protoName: 'candidateInit')
    ..e<SignalTarget>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'target',
        $pb.PbFieldType.OE,
        defaultOrMaker: SignalTarget.PUBLISHER,
        valueOf: SignalTarget.valueOf,
        enumValues: SignalTarget.values)
    ..hasRequiredFields = false;

  TrickleRequest._() : super();
  factory TrickleRequest({
    $core.String? candidateInit,
    SignalTarget? target,
  }) {
    final _result = create();
    if (candidateInit != null) {
      _result.candidateInit = candidateInit;
    }
    if (target != null) {
      _result.target = target;
    }
    return _result;
  }
  factory TrickleRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrickleRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrickleRequest clone() => TrickleRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrickleRequest copyWith(void Function(TrickleRequest) updates) =>
      super.copyWith((message) => updates(message as TrickleRequest))
          as TrickleRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrickleRequest create() => TrickleRequest._();
  TrickleRequest createEmptyInstance() => create();
  static $pb.PbList<TrickleRequest> createRepeated() => $pb.PbList<TrickleRequest>();
  @$core.pragma('dart2js:noInline')
  static TrickleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrickleRequest>(create);
  static TrickleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get candidateInit => $_getSZ(0);
  @$pb.TagNumber(1)
  set candidateInit($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCandidateInit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCandidateInit() => clearField(1);

  @$pb.TagNumber(2)
  SignalTarget get target => $_getN(1);
  @$pb.TagNumber(2)
  set target(SignalTarget v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTarget() => $_has(1);
  @$pb.TagNumber(2)
  void clearTarget() => clearField(2);
}

class MuteTrackRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MuteTrackRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sid')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'muted')
    ..hasRequiredFields = false;

  MuteTrackRequest._() : super();
  factory MuteTrackRequest({
    $core.String? sid,
    $core.bool? muted,
  }) {
    final _result = create();
    if (sid != null) {
      _result.sid = sid;
    }
    if (muted != null) {
      _result.muted = muted;
    }
    return _result;
  }
  factory MuteTrackRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory MuteTrackRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  MuteTrackRequest clone() => MuteTrackRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  MuteTrackRequest copyWith(void Function(MuteTrackRequest) updates) =>
      super.copyWith((message) => updates(message as MuteTrackRequest))
          as MuteTrackRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MuteTrackRequest create() => MuteTrackRequest._();
  MuteTrackRequest createEmptyInstance() => create();
  static $pb.PbList<MuteTrackRequest> createRepeated() => $pb.PbList<MuteTrackRequest>();
  @$core.pragma('dart2js:noInline')
  static MuteTrackRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MuteTrackRequest>(create);
  static MuteTrackRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sid => $_getSZ(0);
  @$pb.TagNumber(1)
  set sid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get muted => $_getBF(1);
  @$pb.TagNumber(2)
  set muted($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMuted() => $_has(1);
  @$pb.TagNumber(2)
  void clearMuted() => clearField(2);
}

class SetSimulcastLayers extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SetSimulcastLayers',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackSid')
    ..pc<VideoQuality>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'layers',
        $pb.PbFieldType.PE,
        valueOf: VideoQuality.valueOf,
        enumValues: VideoQuality.values)
    ..hasRequiredFields = false;

  SetSimulcastLayers._() : super();
  factory SetSimulcastLayers({
    $core.String? trackSid,
    $core.Iterable<VideoQuality>? layers,
  }) {
    final _result = create();
    if (trackSid != null) {
      _result.trackSid = trackSid;
    }
    if (layers != null) {
      _result.layers.addAll(layers);
    }
    return _result;
  }
  factory SetSimulcastLayers.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SetSimulcastLayers.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SetSimulcastLayers clone() => SetSimulcastLayers()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SetSimulcastLayers copyWith(void Function(SetSimulcastLayers) updates) =>
      super.copyWith((message) => updates(message as SetSimulcastLayers))
          as SetSimulcastLayers; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SetSimulcastLayers create() => SetSimulcastLayers._();
  SetSimulcastLayers createEmptyInstance() => create();
  static $pb.PbList<SetSimulcastLayers> createRepeated() => $pb.PbList<SetSimulcastLayers>();
  @$core.pragma('dart2js:noInline')
  static SetSimulcastLayers getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetSimulcastLayers>(create);
  static SetSimulcastLayers? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get trackSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set trackSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTrackSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrackSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<VideoQuality> get layers => $_getList(1);
}

class JoinResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'JoinResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOM<$0.Room>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'room',
        subBuilder: $0.Room.create)
    ..aOM<$0.ParticipantInfo>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'participant',
        subBuilder: $0.ParticipantInfo.create)
    ..pc<$0.ParticipantInfo>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'otherParticipants',
        $pb.PbFieldType.PM,
        subBuilder: $0.ParticipantInfo.create)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serverVersion')
    ..pc<ICEServer>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'iceServers',
        $pb.PbFieldType.PM,
        subBuilder: ICEServer.create)
    ..hasRequiredFields = false;

  JoinResponse._() : super();
  factory JoinResponse({
    $0.Room? room,
    $0.ParticipantInfo? participant,
    $core.Iterable<$0.ParticipantInfo>? otherParticipants,
    $core.String? serverVersion,
    $core.Iterable<ICEServer>? iceServers,
  }) {
    final _result = create();
    if (room != null) {
      _result.room = room;
    }
    if (participant != null) {
      _result.participant = participant;
    }
    if (otherParticipants != null) {
      _result.otherParticipants.addAll(otherParticipants);
    }
    if (serverVersion != null) {
      _result.serverVersion = serverVersion;
    }
    if (iceServers != null) {
      _result.iceServers.addAll(iceServers);
    }
    return _result;
  }
  factory JoinResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory JoinResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  JoinResponse clone() => JoinResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  JoinResponse copyWith(void Function(JoinResponse) updates) =>
      super.copyWith((message) => updates(message as JoinResponse))
          as JoinResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static JoinResponse create() => JoinResponse._();
  JoinResponse createEmptyInstance() => create();
  static $pb.PbList<JoinResponse> createRepeated() => $pb.PbList<JoinResponse>();
  @$core.pragma('dart2js:noInline')
  static JoinResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinResponse>(create);
  static JoinResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Room get room => $_getN(0);
  @$pb.TagNumber(1)
  set room($0.Room v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRoom() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoom() => clearField(1);
  @$pb.TagNumber(1)
  $0.Room ensureRoom() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ParticipantInfo get participant => $_getN(1);
  @$pb.TagNumber(2)
  set participant($0.ParticipantInfo v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasParticipant() => $_has(1);
  @$pb.TagNumber(2)
  void clearParticipant() => clearField(2);
  @$pb.TagNumber(2)
  $0.ParticipantInfo ensureParticipant() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$0.ParticipantInfo> get otherParticipants => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get serverVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set serverVersion($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasServerVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerVersion() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<ICEServer> get iceServers => $_getList(4);
}

class TrackPublishedResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrackPublishedResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cid')
    ..aOM<$0.TrackInfo>(
        2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'track',
        subBuilder: $0.TrackInfo.create)
    ..hasRequiredFields = false;

  TrackPublishedResponse._() : super();
  factory TrackPublishedResponse({
    $core.String? cid,
    $0.TrackInfo? track,
  }) {
    final _result = create();
    if (cid != null) {
      _result.cid = cid;
    }
    if (track != null) {
      _result.track = track;
    }
    return _result;
  }
  factory TrackPublishedResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackPublishedResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackPublishedResponse clone() => TrackPublishedResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackPublishedResponse copyWith(void Function(TrackPublishedResponse) updates) =>
      super.copyWith((message) => updates(message as TrackPublishedResponse))
          as TrackPublishedResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackPublishedResponse create() => TrackPublishedResponse._();
  TrackPublishedResponse createEmptyInstance() => create();
  static $pb.PbList<TrackPublishedResponse> createRepeated() =>
      $pb.PbList<TrackPublishedResponse>();
  @$core.pragma('dart2js:noInline')
  static TrackPublishedResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrackPublishedResponse>(create);
  static TrackPublishedResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cid => $_getSZ(0);
  @$pb.TagNumber(1)
  set cid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCid() => $_has(0);
  @$pb.TagNumber(1)
  void clearCid() => clearField(1);

  @$pb.TagNumber(2)
  $0.TrackInfo get track => $_getN(1);
  @$pb.TagNumber(2)
  set track($0.TrackInfo v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTrack() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrack() => clearField(2);
  @$pb.TagNumber(2)
  $0.TrackInfo ensureTrack() => $_ensure(1);
}

class SessionDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SessionDescription',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'type')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sdp')
    ..hasRequiredFields = false;

  SessionDescription._() : super();
  factory SessionDescription({
    $core.String? type,
    $core.String? sdp,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (sdp != null) {
      _result.sdp = sdp;
    }
    return _result;
  }
  factory SessionDescription.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SessionDescription.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SessionDescription clone() => SessionDescription()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SessionDescription copyWith(void Function(SessionDescription) updates) =>
      super.copyWith((message) => updates(message as SessionDescription))
          as SessionDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SessionDescription create() => SessionDescription._();
  SessionDescription createEmptyInstance() => create();
  static $pb.PbList<SessionDescription> createRepeated() => $pb.PbList<SessionDescription>();
  @$core.pragma('dart2js:noInline')
  static SessionDescription getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionDescription>(create);
  static SessionDescription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get sdp => $_getSZ(1);
  @$pb.TagNumber(2)
  set sdp($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSdp() => $_has(1);
  @$pb.TagNumber(2)
  void clearSdp() => clearField(2);
}

class ParticipantUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ParticipantUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..pc<$0.ParticipantInfo>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'participants',
        $pb.PbFieldType.PM,
        subBuilder: $0.ParticipantInfo.create)
    ..hasRequiredFields = false;

  ParticipantUpdate._() : super();
  factory ParticipantUpdate({
    $core.Iterable<$0.ParticipantInfo>? participants,
  }) {
    final _result = create();
    if (participants != null) {
      _result.participants.addAll(participants);
    }
    return _result;
  }
  factory ParticipantUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ParticipantUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ParticipantUpdate clone() => ParticipantUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ParticipantUpdate copyWith(void Function(ParticipantUpdate) updates) =>
      super.copyWith((message) => updates(message as ParticipantUpdate))
          as ParticipantUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ParticipantUpdate create() => ParticipantUpdate._();
  ParticipantUpdate createEmptyInstance() => create();
  static $pb.PbList<ParticipantUpdate> createRepeated() => $pb.PbList<ParticipantUpdate>();
  @$core.pragma('dart2js:noInline')
  static ParticipantUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParticipantUpdate>(create);
  static ParticipantUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$0.ParticipantInfo> get participants => $_getList(0);
}

class UpdateSubscription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateSubscription',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackSids')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subscribe')
    ..hasRequiredFields = false;

  UpdateSubscription._() : super();
  factory UpdateSubscription({
    $core.Iterable<$core.String>? trackSids,
    $core.bool? subscribe,
  }) {
    final _result = create();
    if (trackSids != null) {
      _result.trackSids.addAll(trackSids);
    }
    if (subscribe != null) {
      _result.subscribe = subscribe;
    }
    return _result;
  }
  factory UpdateSubscription.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UpdateSubscription.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UpdateSubscription clone() => UpdateSubscription()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UpdateSubscription copyWith(void Function(UpdateSubscription) updates) =>
      super.copyWith((message) => updates(message as UpdateSubscription))
          as UpdateSubscription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateSubscription create() => UpdateSubscription._();
  UpdateSubscription createEmptyInstance() => create();
  static $pb.PbList<UpdateSubscription> createRepeated() => $pb.PbList<UpdateSubscription>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscription getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateSubscription>(create);
  static UpdateSubscription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get trackSids => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get subscribe => $_getBF(1);
  @$pb.TagNumber(2)
  set subscribe($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSubscribe() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscribe() => clearField(2);
}

class UpdateTrackSettings extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateTrackSettings',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'trackSids')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disabled')
    ..e<VideoQuality>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'quality',
        $pb.PbFieldType.OE,
        defaultOrMaker: VideoQuality.LOW,
        valueOf: VideoQuality.valueOf,
        enumValues: VideoQuality.values)
    ..hasRequiredFields = false;

  UpdateTrackSettings._() : super();
  factory UpdateTrackSettings({
    $core.Iterable<$core.String>? trackSids,
    $core.bool? disabled,
    VideoQuality? quality,
  }) {
    final _result = create();
    if (trackSids != null) {
      _result.trackSids.addAll(trackSids);
    }
    if (disabled != null) {
      _result.disabled = disabled;
    }
    if (quality != null) {
      _result.quality = quality;
    }
    return _result;
  }
  factory UpdateTrackSettings.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UpdateTrackSettings.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UpdateTrackSettings clone() => UpdateTrackSettings()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UpdateTrackSettings copyWith(void Function(UpdateTrackSettings) updates) =>
      super.copyWith((message) => updates(message as UpdateTrackSettings))
          as UpdateTrackSettings; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateTrackSettings create() => UpdateTrackSettings._();
  UpdateTrackSettings createEmptyInstance() => create();
  static $pb.PbList<UpdateTrackSettings> createRepeated() => $pb.PbList<UpdateTrackSettings>();
  @$core.pragma('dart2js:noInline')
  static UpdateTrackSettings getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateTrackSettings>(create);
  static UpdateTrackSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get trackSids => $_getList(0);

  @$pb.TagNumber(3)
  $core.bool get disabled => $_getBF(1);
  @$pb.TagNumber(3)
  set disabled($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDisabled() => $_has(1);
  @$pb.TagNumber(3)
  void clearDisabled() => clearField(3);

  @$pb.TagNumber(4)
  VideoQuality get quality => $_getN(2);
  @$pb.TagNumber(4)
  set quality(VideoQuality v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasQuality() => $_has(2);
  @$pb.TagNumber(4)
  void clearQuality() => clearField(4);
}

class LeaveRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'LeaveRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'canReconnect')
    ..hasRequiredFields = false;

  LeaveRequest._() : super();
  factory LeaveRequest({
    $core.bool? canReconnect,
  }) {
    final _result = create();
    if (canReconnect != null) {
      _result.canReconnect = canReconnect;
    }
    return _result;
  }
  factory LeaveRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LeaveRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LeaveRequest clone() => LeaveRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LeaveRequest copyWith(void Function(LeaveRequest) updates) =>
      super.copyWith((message) => updates(message as LeaveRequest))
          as LeaveRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LeaveRequest create() => LeaveRequest._();
  LeaveRequest createEmptyInstance() => create();
  static $pb.PbList<LeaveRequest> createRepeated() => $pb.PbList<LeaveRequest>();
  @$core.pragma('dart2js:noInline')
  static LeaveRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeaveRequest>(create);
  static LeaveRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get canReconnect => $_getBF(0);
  @$pb.TagNumber(1)
  set canReconnect($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCanReconnect() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanReconnect() => clearField(1);
}

class ICEServer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ICEServer',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'livekit'),
      createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'urls')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'username')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'credential')
    ..hasRequiredFields = false;

  ICEServer._() : super();
  factory ICEServer({
    $core.Iterable<$core.String>? urls,
    $core.String? username,
    $core.String? credential,
  }) {
    final _result = create();
    if (urls != null) {
      _result.urls.addAll(urls);
    }
    if (username != null) {
      _result.username = username;
    }
    if (credential != null) {
      _result.credential = credential;
    }
    return _result;
  }
  factory ICEServer.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ICEServer.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ICEServer clone() => ICEServer()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ICEServer copyWith(void Function(ICEServer) updates) =>
      super.copyWith((message) => updates(message as ICEServer))
          as ICEServer; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ICEServer create() => ICEServer._();
  ICEServer createEmptyInstance() => create();
  static $pb.PbList<ICEServer> createRepeated() => $pb.PbList<ICEServer>();
  @$core.pragma('dart2js:noInline')
  static ICEServer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ICEServer>(create);
  static ICEServer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get urls => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get credential => $_getSZ(2);
  @$pb.TagNumber(3)
  set credential($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCredential() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredential() => clearField(3);
}
