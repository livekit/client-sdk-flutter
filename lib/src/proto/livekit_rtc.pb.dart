///
//  Generated code. Do not modify.
//  source: livekit_rtc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

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
  updateLayers,
  subscriptionPermission,
  syncState,
  simulate,
  notSet
}

class SignalRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SignalRequest_Message>
      _SignalRequest_MessageByTag = {
    1: SignalRequest_Message.offer,
    2: SignalRequest_Message.answer,
    3: SignalRequest_Message.trickle,
    4: SignalRequest_Message.addTrack,
    5: SignalRequest_Message.mute,
    6: SignalRequest_Message.subscription,
    7: SignalRequest_Message.trackSetting,
    8: SignalRequest_Message.leave,
    10: SignalRequest_Message.updateLayers,
    11: SignalRequest_Message.subscriptionPermission,
    12: SignalRequest_Message.syncState,
    13: SignalRequest_Message.simulate,
    0: SignalRequest_Message.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SignalRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13])
    ..aOM<SessionDescription>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'offer',
        subBuilder: SessionDescription.create)
    ..aOM<SessionDescription>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'answer',
        subBuilder: SessionDescription.create)
    ..aOM<TrickleRequest>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trickle',
        subBuilder: TrickleRequest.create)
    ..aOM<AddTrackRequest>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'addTrack',
        subBuilder: AddTrackRequest.create)
    ..aOM<MuteTrackRequest>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mute',
        subBuilder: MuteTrackRequest.create)
    ..aOM<UpdateSubscription>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscription',
        subBuilder: UpdateSubscription.create)
    ..aOM<UpdateTrackSettings>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSetting',
        subBuilder: UpdateTrackSettings.create)
    ..aOM<LeaveRequest>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'leave',
        subBuilder: LeaveRequest.create)
    ..aOM<UpdateVideoLayers>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'updateLayers',
        subBuilder: UpdateVideoLayers.create)
    ..aOM<SubscriptionPermission>(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscriptionPermission',
        subBuilder: SubscriptionPermission.create)
    ..aOM<SyncState>(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'syncState',
        subBuilder: SyncState.create)
    ..aOM<SimulateScenario>(
        13,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'simulate',
        subBuilder: SimulateScenario.create)
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
    UpdateVideoLayers? updateLayers,
    SubscriptionPermission? subscriptionPermission,
    SyncState? syncState,
    SimulateScenario? simulate,
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
    if (updateLayers != null) {
      _result.updateLayers = updateLayers;
    }
    if (subscriptionPermission != null) {
      _result.subscriptionPermission = subscriptionPermission;
    }
    if (syncState != null) {
      _result.syncState = syncState;
    }
    if (simulate != null) {
      _result.simulate = simulate;
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
  static $pb.PbList<SignalRequest> createRepeated() =>
      $pb.PbList<SignalRequest>();
  @$core.pragma('dart2js:noInline')
  static SignalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignalRequest>(create);
  static SignalRequest? _defaultInstance;

  SignalRequest_Message whichMessage() =>
      _SignalRequest_MessageByTag[$_whichOneof(0)]!;
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

  @$pb.TagNumber(10)
  UpdateVideoLayers get updateLayers => $_getN(8);
  @$pb.TagNumber(10)
  set updateLayers(UpdateVideoLayers v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasUpdateLayers() => $_has(8);
  @$pb.TagNumber(10)
  void clearUpdateLayers() => clearField(10);
  @$pb.TagNumber(10)
  UpdateVideoLayers ensureUpdateLayers() => $_ensure(8);

  @$pb.TagNumber(11)
  SubscriptionPermission get subscriptionPermission => $_getN(9);
  @$pb.TagNumber(11)
  set subscriptionPermission(SubscriptionPermission v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasSubscriptionPermission() => $_has(9);
  @$pb.TagNumber(11)
  void clearSubscriptionPermission() => clearField(11);
  @$pb.TagNumber(11)
  SubscriptionPermission ensureSubscriptionPermission() => $_ensure(9);

  @$pb.TagNumber(12)
  SyncState get syncState => $_getN(10);
  @$pb.TagNumber(12)
  set syncState(SyncState v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasSyncState() => $_has(10);
  @$pb.TagNumber(12)
  void clearSyncState() => clearField(12);
  @$pb.TagNumber(12)
  SyncState ensureSyncState() => $_ensure(10);

  @$pb.TagNumber(13)
  SimulateScenario get simulate => $_getN(11);
  @$pb.TagNumber(13)
  set simulate(SimulateScenario v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasSimulate() => $_has(11);
  @$pb.TagNumber(13)
  void clearSimulate() => clearField(13);
  @$pb.TagNumber(13)
  SimulateScenario ensureSimulate() => $_ensure(11);
}

enum SignalResponse_Message {
  join,
  answer,
  offer,
  trickle,
  update,
  trackPublished,
  leave,
  mute,
  speakersChanged,
  roomUpdate,
  connectionQuality,
  streamStateUpdate,
  subscribedQualityUpdate,
  subscriptionPermissionUpdate,
  refreshToken,
  trackUnpublished,
  notSet
}

class SignalResponse extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SignalResponse_Message>
      _SignalResponse_MessageByTag = {
    1: SignalResponse_Message.join,
    2: SignalResponse_Message.answer,
    3: SignalResponse_Message.offer,
    4: SignalResponse_Message.trickle,
    5: SignalResponse_Message.update,
    6: SignalResponse_Message.trackPublished,
    8: SignalResponse_Message.leave,
    9: SignalResponse_Message.mute,
    10: SignalResponse_Message.speakersChanged,
    11: SignalResponse_Message.roomUpdate,
    12: SignalResponse_Message.connectionQuality,
    13: SignalResponse_Message.streamStateUpdate,
    14: SignalResponse_Message.subscribedQualityUpdate,
    15: SignalResponse_Message.subscriptionPermissionUpdate,
    16: SignalResponse_Message.refreshToken,
    17: SignalResponse_Message.trackUnpublished,
    0: SignalResponse_Message.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SignalResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17])
    ..aOM<JoinResponse>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'join',
        subBuilder: JoinResponse.create)
    ..aOM<SessionDescription>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'answer',
        subBuilder: SessionDescription.create)
    ..aOM<SessionDescription>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'offer',
        subBuilder: SessionDescription.create)
    ..aOM<TrickleRequest>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trickle',
        subBuilder: TrickleRequest.create)
    ..aOM<ParticipantUpdate>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'update',
        subBuilder: ParticipantUpdate.create)
    ..aOM<TrackPublishedResponse>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackPublished',
        subBuilder: TrackPublishedResponse.create)
    ..aOM<LeaveRequest>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'leave',
        subBuilder: LeaveRequest.create)
    ..aOM<MuteTrackRequest>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'mute',
        subBuilder: MuteTrackRequest.create)
    ..aOM<SpeakersChanged>(
        10,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'speakersChanged',
        subBuilder: SpeakersChanged.create)
    ..aOM<RoomUpdate>(
        11,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'roomUpdate',
        subBuilder: RoomUpdate.create)
    ..aOM<ConnectionQualityUpdate>(
        12,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'connectionQuality',
        subBuilder: ConnectionQualityUpdate.create)
    ..aOM<StreamStateUpdate>(
        13,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'streamStateUpdate',
        subBuilder: StreamStateUpdate.create)
    ..aOM<SubscribedQualityUpdate>(
        14,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscribedQualityUpdate',
        subBuilder: SubscribedQualityUpdate.create)
    ..aOM<SubscriptionPermissionUpdate>(
        15,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscriptionPermissionUpdate',
        subBuilder: SubscriptionPermissionUpdate.create)
    ..aOS(
        16,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'refreshToken')
    ..aOM<TrackUnpublishedResponse>(
        17,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackUnpublished',
        subBuilder: TrackUnpublishedResponse.create)
    ..hasRequiredFields = false;

  SignalResponse._() : super();
  factory SignalResponse({
    JoinResponse? join,
    SessionDescription? answer,
    SessionDescription? offer,
    TrickleRequest? trickle,
    ParticipantUpdate? update,
    TrackPublishedResponse? trackPublished,
    LeaveRequest? leave,
    MuteTrackRequest? mute,
    SpeakersChanged? speakersChanged,
    RoomUpdate? roomUpdate,
    ConnectionQualityUpdate? connectionQuality,
    StreamStateUpdate? streamStateUpdate,
    SubscribedQualityUpdate? subscribedQualityUpdate,
    SubscriptionPermissionUpdate? subscriptionPermissionUpdate,
    $core.String? refreshToken,
    TrackUnpublishedResponse? trackUnpublished,
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
    if (leave != null) {
      _result.leave = leave;
    }
    if (mute != null) {
      _result.mute = mute;
    }
    if (speakersChanged != null) {
      _result.speakersChanged = speakersChanged;
    }
    if (roomUpdate != null) {
      _result.roomUpdate = roomUpdate;
    }
    if (connectionQuality != null) {
      _result.connectionQuality = connectionQuality;
    }
    if (streamStateUpdate != null) {
      _result.streamStateUpdate = streamStateUpdate;
    }
    if (subscribedQualityUpdate != null) {
      _result.subscribedQualityUpdate = subscribedQualityUpdate;
    }
    if (subscriptionPermissionUpdate != null) {
      _result.subscriptionPermissionUpdate = subscriptionPermissionUpdate;
    }
    if (refreshToken != null) {
      _result.refreshToken = refreshToken;
    }
    if (trackUnpublished != null) {
      _result.trackUnpublished = trackUnpublished;
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
  static $pb.PbList<SignalResponse> createRepeated() =>
      $pb.PbList<SignalResponse>();
  @$core.pragma('dart2js:noInline')
  static SignalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignalResponse>(create);
  static SignalResponse? _defaultInstance;

  SignalResponse_Message whichMessage() =>
      _SignalResponse_MessageByTag[$_whichOneof(0)]!;
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

  @$pb.TagNumber(8)
  LeaveRequest get leave => $_getN(6);
  @$pb.TagNumber(8)
  set leave(LeaveRequest v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLeave() => $_has(6);
  @$pb.TagNumber(8)
  void clearLeave() => clearField(8);
  @$pb.TagNumber(8)
  LeaveRequest ensureLeave() => $_ensure(6);

  @$pb.TagNumber(9)
  MuteTrackRequest get mute => $_getN(7);
  @$pb.TagNumber(9)
  set mute(MuteTrackRequest v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasMute() => $_has(7);
  @$pb.TagNumber(9)
  void clearMute() => clearField(9);
  @$pb.TagNumber(9)
  MuteTrackRequest ensureMute() => $_ensure(7);

  @$pb.TagNumber(10)
  SpeakersChanged get speakersChanged => $_getN(8);
  @$pb.TagNumber(10)
  set speakersChanged(SpeakersChanged v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasSpeakersChanged() => $_has(8);
  @$pb.TagNumber(10)
  void clearSpeakersChanged() => clearField(10);
  @$pb.TagNumber(10)
  SpeakersChanged ensureSpeakersChanged() => $_ensure(8);

  @$pb.TagNumber(11)
  RoomUpdate get roomUpdate => $_getN(9);
  @$pb.TagNumber(11)
  set roomUpdate(RoomUpdate v) {
    setField(11, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasRoomUpdate() => $_has(9);
  @$pb.TagNumber(11)
  void clearRoomUpdate() => clearField(11);
  @$pb.TagNumber(11)
  RoomUpdate ensureRoomUpdate() => $_ensure(9);

  @$pb.TagNumber(12)
  ConnectionQualityUpdate get connectionQuality => $_getN(10);
  @$pb.TagNumber(12)
  set connectionQuality(ConnectionQualityUpdate v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasConnectionQuality() => $_has(10);
  @$pb.TagNumber(12)
  void clearConnectionQuality() => clearField(12);
  @$pb.TagNumber(12)
  ConnectionQualityUpdate ensureConnectionQuality() => $_ensure(10);

  @$pb.TagNumber(13)
  StreamStateUpdate get streamStateUpdate => $_getN(11);
  @$pb.TagNumber(13)
  set streamStateUpdate(StreamStateUpdate v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasStreamStateUpdate() => $_has(11);
  @$pb.TagNumber(13)
  void clearStreamStateUpdate() => clearField(13);
  @$pb.TagNumber(13)
  StreamStateUpdate ensureStreamStateUpdate() => $_ensure(11);

  @$pb.TagNumber(14)
  SubscribedQualityUpdate get subscribedQualityUpdate => $_getN(12);
  @$pb.TagNumber(14)
  set subscribedQualityUpdate(SubscribedQualityUpdate v) {
    setField(14, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasSubscribedQualityUpdate() => $_has(12);
  @$pb.TagNumber(14)
  void clearSubscribedQualityUpdate() => clearField(14);
  @$pb.TagNumber(14)
  SubscribedQualityUpdate ensureSubscribedQualityUpdate() => $_ensure(12);

  @$pb.TagNumber(15)
  SubscriptionPermissionUpdate get subscriptionPermissionUpdate => $_getN(13);
  @$pb.TagNumber(15)
  set subscriptionPermissionUpdate(SubscriptionPermissionUpdate v) {
    setField(15, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasSubscriptionPermissionUpdate() => $_has(13);
  @$pb.TagNumber(15)
  void clearSubscriptionPermissionUpdate() => clearField(15);
  @$pb.TagNumber(15)
  SubscriptionPermissionUpdate ensureSubscriptionPermissionUpdate() =>
      $_ensure(13);

  @$pb.TagNumber(16)
  $core.String get refreshToken => $_getSZ(14);
  @$pb.TagNumber(16)
  set refreshToken($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasRefreshToken() => $_has(14);
  @$pb.TagNumber(16)
  void clearRefreshToken() => clearField(16);

  @$pb.TagNumber(17)
  TrackUnpublishedResponse get trackUnpublished => $_getN(15);
  @$pb.TagNumber(17)
  set trackUnpublished(TrackUnpublishedResponse v) {
    setField(17, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasTrackUnpublished() => $_has(15);
  @$pb.TagNumber(17)
  void clearTrackUnpublished() => clearField(17);
  @$pb.TagNumber(17)
  TrackUnpublishedResponse ensureTrackUnpublished() => $_ensure(15);
}

class AddTrackRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'AddTrackRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'cid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..e<$0.TrackType>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type',
        $pb.PbFieldType.OE,
        defaultOrMaker: $0.TrackType.AUDIO,
        valueOf: $0.TrackType.valueOf,
        enumValues: $0.TrackType.values)
    ..a<$core.int>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'width',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'height',
        $pb.PbFieldType.OU3)
    ..aOB(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'muted')
    ..aOB(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'disableDtx')
    ..e<$0.TrackSource>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'source',
        $pb.PbFieldType.OE,
        defaultOrMaker: $0.TrackSource.UNKNOWN,
        valueOf: $0.TrackSource.valueOf,
        enumValues: $0.TrackSource.values)
    ..pc<$0.VideoLayer>(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'layers',
        $pb.PbFieldType.PM,
        subBuilder: $0.VideoLayer.create)
    ..hasRequiredFields = false;

  AddTrackRequest._() : super();
  factory AddTrackRequest({
    $core.String? cid,
    $core.String? name,
    $0.TrackType? type,
    $core.int? width,
    $core.int? height,
    $core.bool? muted,
    $core.bool? disableDtx,
    $0.TrackSource? source,
    $core.Iterable<$0.VideoLayer>? layers,
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
    if (disableDtx != null) {
      _result.disableDtx = disableDtx;
    }
    if (source != null) {
      _result.source = source;
    }
    if (layers != null) {
      _result.layers.addAll(layers);
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
  static $pb.PbList<AddTrackRequest> createRepeated() =>
      $pb.PbList<AddTrackRequest>();
  @$core.pragma('dart2js:noInline')
  static AddTrackRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddTrackRequest>(create);
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

  @$pb.TagNumber(7)
  $core.bool get disableDtx => $_getBF(6);
  @$pb.TagNumber(7)
  set disableDtx($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDisableDtx() => $_has(6);
  @$pb.TagNumber(7)
  void clearDisableDtx() => clearField(7);

  @$pb.TagNumber(8)
  $0.TrackSource get source => $_getN(7);
  @$pb.TagNumber(8)
  set source($0.TrackSource v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasSource() => $_has(7);
  @$pb.TagNumber(8)
  void clearSource() => clearField(8);

  @$pb.TagNumber(9)
  $core.List<$0.VideoLayer> get layers => $_getList(8);
}

class TrickleRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrickleRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'candidateInit',
        protoName: 'candidateInit')
    ..e<SignalTarget>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'target',
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
  static $pb.PbList<TrickleRequest> createRepeated() =>
      $pb.PbList<TrickleRequest>();
  @$core.pragma('dart2js:noInline')
  static TrickleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrickleRequest>(create);
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
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'MuteTrackRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sid')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'muted')
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
  static $pb.PbList<MuteTrackRequest> createRepeated() =>
      $pb.PbList<MuteTrackRequest>();
  @$core.pragma('dart2js:noInline')
  static MuteTrackRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MuteTrackRequest>(create);
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

class JoinResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'JoinResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOM<$0.Room>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'room',
        subBuilder: $0.Room.create)
    ..aOM<$0.ParticipantInfo>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participant',
        subBuilder: $0.ParticipantInfo.create)
    ..pc<$0.ParticipantInfo>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'otherParticipants',
        $pb.PbFieldType.PM,
        subBuilder: $0.ParticipantInfo.create)
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'serverVersion')
    ..pc<ICEServer>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'iceServers',
        $pb.PbFieldType.PM,
        subBuilder: ICEServer.create)
    ..aOB(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscriberPrimary')
    ..aOS(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'alternativeUrl')
    ..aOM<$0.ClientConfiguration>(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'clientConfiguration',
        subBuilder: $0.ClientConfiguration.create)
    ..aOS(
        9,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'serverRegion')
    ..hasRequiredFields = false;

  JoinResponse._() : super();
  factory JoinResponse({
    $0.Room? room,
    $0.ParticipantInfo? participant,
    $core.Iterable<$0.ParticipantInfo>? otherParticipants,
    $core.String? serverVersion,
    $core.Iterable<ICEServer>? iceServers,
    $core.bool? subscriberPrimary,
    $core.String? alternativeUrl,
    $0.ClientConfiguration? clientConfiguration,
    $core.String? serverRegion,
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
    if (subscriberPrimary != null) {
      _result.subscriberPrimary = subscriberPrimary;
    }
    if (alternativeUrl != null) {
      _result.alternativeUrl = alternativeUrl;
    }
    if (clientConfiguration != null) {
      _result.clientConfiguration = clientConfiguration;
    }
    if (serverRegion != null) {
      _result.serverRegion = serverRegion;
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
  static $pb.PbList<JoinResponse> createRepeated() =>
      $pb.PbList<JoinResponse>();
  @$core.pragma('dart2js:noInline')
  static JoinResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinResponse>(create);
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

  @$pb.TagNumber(6)
  $core.bool get subscriberPrimary => $_getBF(5);
  @$pb.TagNumber(6)
  set subscriberPrimary($core.bool v) {
    $_setBool(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSubscriberPrimary() => $_has(5);
  @$pb.TagNumber(6)
  void clearSubscriberPrimary() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get alternativeUrl => $_getSZ(6);
  @$pb.TagNumber(7)
  set alternativeUrl($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasAlternativeUrl() => $_has(6);
  @$pb.TagNumber(7)
  void clearAlternativeUrl() => clearField(7);

  @$pb.TagNumber(8)
  $0.ClientConfiguration get clientConfiguration => $_getN(7);
  @$pb.TagNumber(8)
  set clientConfiguration($0.ClientConfiguration v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasClientConfiguration() => $_has(7);
  @$pb.TagNumber(8)
  void clearClientConfiguration() => clearField(8);
  @$pb.TagNumber(8)
  $0.ClientConfiguration ensureClientConfiguration() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.String get serverRegion => $_getSZ(8);
  @$pb.TagNumber(9)
  set serverRegion($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasServerRegion() => $_has(8);
  @$pb.TagNumber(9)
  void clearServerRegion() => clearField(9);
}

class TrackPublishedResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrackPublishedResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'cid')
    ..aOM<$0.TrackInfo>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'track',
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
  TrackPublishedResponse clone() =>
      TrackPublishedResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackPublishedResponse copyWith(
          void Function(TrackPublishedResponse) updates) =>
      super.copyWith((message) => updates(message as TrackPublishedResponse))
          as TrackPublishedResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackPublishedResponse create() => TrackPublishedResponse._();
  TrackPublishedResponse createEmptyInstance() => create();
  static $pb.PbList<TrackPublishedResponse> createRepeated() =>
      $pb.PbList<TrackPublishedResponse>();
  @$core.pragma('dart2js:noInline')
  static TrackPublishedResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackPublishedResponse>(create);
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

class TrackUnpublishedResponse extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrackUnpublishedResponse',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSid')
    ..hasRequiredFields = false;

  TrackUnpublishedResponse._() : super();
  factory TrackUnpublishedResponse({
    $core.String? trackSid,
  }) {
    final _result = create();
    if (trackSid != null) {
      _result.trackSid = trackSid;
    }
    return _result;
  }
  factory TrackUnpublishedResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackUnpublishedResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackUnpublishedResponse clone() =>
      TrackUnpublishedResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackUnpublishedResponse copyWith(
          void Function(TrackUnpublishedResponse) updates) =>
      super.copyWith((message) => updates(message as TrackUnpublishedResponse))
          as TrackUnpublishedResponse; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackUnpublishedResponse create() => TrackUnpublishedResponse._();
  TrackUnpublishedResponse createEmptyInstance() => create();
  static $pb.PbList<TrackUnpublishedResponse> createRepeated() =>
      $pb.PbList<TrackUnpublishedResponse>();
  @$core.pragma('dart2js:noInline')
  static TrackUnpublishedResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackUnpublishedResponse>(create);
  static TrackUnpublishedResponse? _defaultInstance;

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
}

class SessionDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SessionDescription',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sdp')
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
  static $pb.PbList<SessionDescription> createRepeated() =>
      $pb.PbList<SessionDescription>();
  @$core.pragma('dart2js:noInline')
  static SessionDescription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionDescription>(create);
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
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ParticipantUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pc<$0.ParticipantInfo>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participants',
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
  static $pb.PbList<ParticipantUpdate> createRepeated() =>
      $pb.PbList<ParticipantUpdate>();
  @$core.pragma('dart2js:noInline')
  static ParticipantUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ParticipantUpdate>(create);
  static ParticipantUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$0.ParticipantInfo> get participants => $_getList(0);
}

class UpdateSubscription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UpdateSubscription',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSids')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscribe')
    ..pc<$0.ParticipantTracks>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantTracks',
        $pb.PbFieldType.PM,
        subBuilder: $0.ParticipantTracks.create)
    ..hasRequiredFields = false;

  UpdateSubscription._() : super();
  factory UpdateSubscription({
    $core.Iterable<$core.String>? trackSids,
    $core.bool? subscribe,
    $core.Iterable<$0.ParticipantTracks>? participantTracks,
  }) {
    final _result = create();
    if (trackSids != null) {
      _result.trackSids.addAll(trackSids);
    }
    if (subscribe != null) {
      _result.subscribe = subscribe;
    }
    if (participantTracks != null) {
      _result.participantTracks.addAll(participantTracks);
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
  static $pb.PbList<UpdateSubscription> createRepeated() =>
      $pb.PbList<UpdateSubscription>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubscription>(create);
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

  @$pb.TagNumber(3)
  $core.List<$0.ParticipantTracks> get participantTracks => $_getList(2);
}

class UpdateTrackSettings extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UpdateTrackSettings',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSids')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'disabled')
    ..e<$0.VideoQuality>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'quality',
        $pb.PbFieldType.OE,
        defaultOrMaker: $0.VideoQuality.LOW,
        valueOf: $0.VideoQuality.valueOf,
        enumValues: $0.VideoQuality.values)
    ..a<$core.int>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'width',
        $pb.PbFieldType.OU3)
    ..a<$core.int>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'height',
        $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  UpdateTrackSettings._() : super();
  factory UpdateTrackSettings({
    $core.Iterable<$core.String>? trackSids,
    $core.bool? disabled,
    $0.VideoQuality? quality,
    $core.int? width,
    $core.int? height,
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
    if (width != null) {
      _result.width = width;
    }
    if (height != null) {
      _result.height = height;
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
  static $pb.PbList<UpdateTrackSettings> createRepeated() =>
      $pb.PbList<UpdateTrackSettings>();
  @$core.pragma('dart2js:noInline')
  static UpdateTrackSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateTrackSettings>(create);
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
  $0.VideoQuality get quality => $_getN(2);
  @$pb.TagNumber(4)
  set quality($0.VideoQuality v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasQuality() => $_has(2);
  @$pb.TagNumber(4)
  void clearQuality() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get width => $_getIZ(3);
  @$pb.TagNumber(5)
  set width($core.int v) {
    $_setUnsignedInt32(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasWidth() => $_has(3);
  @$pb.TagNumber(5)
  void clearWidth() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get height => $_getIZ(4);
  @$pb.TagNumber(6)
  set height($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasHeight() => $_has(4);
  @$pb.TagNumber(6)
  void clearHeight() => clearField(6);
}

class LeaveRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'LeaveRequest',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'canReconnect')
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
  static $pb.PbList<LeaveRequest> createRepeated() =>
      $pb.PbList<LeaveRequest>();
  @$core.pragma('dart2js:noInline')
  static LeaveRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaveRequest>(create);
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

class UpdateVideoLayers extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'UpdateVideoLayers',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSid')
    ..pc<$0.VideoLayer>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'layers',
        $pb.PbFieldType.PM,
        subBuilder: $0.VideoLayer.create)
    ..hasRequiredFields = false;

  UpdateVideoLayers._() : super();
  factory UpdateVideoLayers({
    $core.String? trackSid,
    $core.Iterable<$0.VideoLayer>? layers,
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
  factory UpdateVideoLayers.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UpdateVideoLayers.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UpdateVideoLayers clone() => UpdateVideoLayers()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UpdateVideoLayers copyWith(void Function(UpdateVideoLayers) updates) =>
      super.copyWith((message) => updates(message as UpdateVideoLayers))
          as UpdateVideoLayers; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateVideoLayers create() => UpdateVideoLayers._();
  UpdateVideoLayers createEmptyInstance() => create();
  static $pb.PbList<UpdateVideoLayers> createRepeated() =>
      $pb.PbList<UpdateVideoLayers>();
  @$core.pragma('dart2js:noInline')
  static UpdateVideoLayers getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateVideoLayers>(create);
  static UpdateVideoLayers? _defaultInstance;

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
  $core.List<$0.VideoLayer> get layers => $_getList(1);
}

class ICEServer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ICEServer',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pPS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'urls')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'username')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'credential')
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

class SpeakersChanged extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SpeakersChanged',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pc<$0.SpeakerInfo>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'speakers',
        $pb.PbFieldType.PM,
        subBuilder: $0.SpeakerInfo.create)
    ..hasRequiredFields = false;

  SpeakersChanged._() : super();
  factory SpeakersChanged({
    $core.Iterable<$0.SpeakerInfo>? speakers,
  }) {
    final _result = create();
    if (speakers != null) {
      _result.speakers.addAll(speakers);
    }
    return _result;
  }
  factory SpeakersChanged.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SpeakersChanged.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SpeakersChanged clone() => SpeakersChanged()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SpeakersChanged copyWith(void Function(SpeakersChanged) updates) =>
      super.copyWith((message) => updates(message as SpeakersChanged))
          as SpeakersChanged; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SpeakersChanged create() => SpeakersChanged._();
  SpeakersChanged createEmptyInstance() => create();
  static $pb.PbList<SpeakersChanged> createRepeated() =>
      $pb.PbList<SpeakersChanged>();
  @$core.pragma('dart2js:noInline')
  static SpeakersChanged getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SpeakersChanged>(create);
  static SpeakersChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$0.SpeakerInfo> get speakers => $_getList(0);
}

class RoomUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'RoomUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOM<$0.Room>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'room',
        subBuilder: $0.Room.create)
    ..hasRequiredFields = false;

  RoomUpdate._() : super();
  factory RoomUpdate({
    $0.Room? room,
  }) {
    final _result = create();
    if (room != null) {
      _result.room = room;
    }
    return _result;
  }
  factory RoomUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RoomUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RoomUpdate clone() => RoomUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RoomUpdate copyWith(void Function(RoomUpdate) updates) =>
      super.copyWith((message) => updates(message as RoomUpdate))
          as RoomUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RoomUpdate create() => RoomUpdate._();
  RoomUpdate createEmptyInstance() => create();
  static $pb.PbList<RoomUpdate> createRepeated() => $pb.PbList<RoomUpdate>();
  @$core.pragma('dart2js:noInline')
  static RoomUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomUpdate>(create);
  static RoomUpdate? _defaultInstance;

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
}

class ConnectionQualityInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ConnectionQualityInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantSid')
    ..e<$0.ConnectionQuality>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'quality',
        $pb.PbFieldType.OE,
        defaultOrMaker: $0.ConnectionQuality.POOR,
        valueOf: $0.ConnectionQuality.valueOf,
        enumValues: $0.ConnectionQuality.values)
    ..a<$core.double>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'score',
        $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  ConnectionQualityInfo._() : super();
  factory ConnectionQualityInfo({
    $core.String? participantSid,
    $0.ConnectionQuality? quality,
    $core.double? score,
  }) {
    final _result = create();
    if (participantSid != null) {
      _result.participantSid = participantSid;
    }
    if (quality != null) {
      _result.quality = quality;
    }
    if (score != null) {
      _result.score = score;
    }
    return _result;
  }
  factory ConnectionQualityInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConnectionQualityInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConnectionQualityInfo clone() =>
      ConnectionQualityInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConnectionQualityInfo copyWith(
          void Function(ConnectionQualityInfo) updates) =>
      super.copyWith((message) => updates(message as ConnectionQualityInfo))
          as ConnectionQualityInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConnectionQualityInfo create() => ConnectionQualityInfo._();
  ConnectionQualityInfo createEmptyInstance() => create();
  static $pb.PbList<ConnectionQualityInfo> createRepeated() =>
      $pb.PbList<ConnectionQualityInfo>();
  @$core.pragma('dart2js:noInline')
  static ConnectionQualityInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionQualityInfo>(create);
  static ConnectionQualityInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  @$pb.TagNumber(2)
  $0.ConnectionQuality get quality => $_getN(1);
  @$pb.TagNumber(2)
  set quality($0.ConnectionQuality v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasQuality() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuality() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get score => $_getN(2);
  @$pb.TagNumber(3)
  set score($core.double v) {
    $_setFloat(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasScore() => $_has(2);
  @$pb.TagNumber(3)
  void clearScore() => clearField(3);
}

class ConnectionQualityUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'ConnectionQualityUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pc<ConnectionQualityInfo>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'updates',
        $pb.PbFieldType.PM,
        subBuilder: ConnectionQualityInfo.create)
    ..hasRequiredFields = false;

  ConnectionQualityUpdate._() : super();
  factory ConnectionQualityUpdate({
    $core.Iterable<ConnectionQualityInfo>? updates,
  }) {
    final _result = create();
    if (updates != null) {
      _result.updates.addAll(updates);
    }
    return _result;
  }
  factory ConnectionQualityUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ConnectionQualityUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ConnectionQualityUpdate clone() =>
      ConnectionQualityUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ConnectionQualityUpdate copyWith(
          void Function(ConnectionQualityUpdate) updates) =>
      super.copyWith((message) => updates(message as ConnectionQualityUpdate))
          as ConnectionQualityUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ConnectionQualityUpdate create() => ConnectionQualityUpdate._();
  ConnectionQualityUpdate createEmptyInstance() => create();
  static $pb.PbList<ConnectionQualityUpdate> createRepeated() =>
      $pb.PbList<ConnectionQualityUpdate>();
  @$core.pragma('dart2js:noInline')
  static ConnectionQualityUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConnectionQualityUpdate>(create);
  static ConnectionQualityUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<ConnectionQualityInfo> get updates => $_getList(0);
}

class StreamStateInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StreamStateInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantSid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSid')
    ..e<StreamState>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'state',
        $pb.PbFieldType.OE,
        defaultOrMaker: StreamState.ACTIVE,
        valueOf: StreamState.valueOf,
        enumValues: StreamState.values)
    ..hasRequiredFields = false;

  StreamStateInfo._() : super();
  factory StreamStateInfo({
    $core.String? participantSid,
    $core.String? trackSid,
    StreamState? state,
  }) {
    final _result = create();
    if (participantSid != null) {
      _result.participantSid = participantSid;
    }
    if (trackSid != null) {
      _result.trackSid = trackSid;
    }
    if (state != null) {
      _result.state = state;
    }
    return _result;
  }
  factory StreamStateInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StreamStateInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StreamStateInfo clone() => StreamStateInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StreamStateInfo copyWith(void Function(StreamStateInfo) updates) =>
      super.copyWith((message) => updates(message as StreamStateInfo))
          as StreamStateInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StreamStateInfo create() => StreamStateInfo._();
  StreamStateInfo createEmptyInstance() => create();
  static $pb.PbList<StreamStateInfo> createRepeated() =>
      $pb.PbList<StreamStateInfo>();
  @$core.pragma('dart2js:noInline')
  static StreamStateInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamStateInfo>(create);
  static StreamStateInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get trackSid => $_getSZ(1);
  @$pb.TagNumber(2)
  set trackSid($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTrackSid() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackSid() => clearField(2);

  @$pb.TagNumber(3)
  StreamState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(StreamState v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => clearField(3);
}

class StreamStateUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'StreamStateUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..pc<StreamStateInfo>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'streamStates',
        $pb.PbFieldType.PM,
        subBuilder: StreamStateInfo.create)
    ..hasRequiredFields = false;

  StreamStateUpdate._() : super();
  factory StreamStateUpdate({
    $core.Iterable<StreamStateInfo>? streamStates,
  }) {
    final _result = create();
    if (streamStates != null) {
      _result.streamStates.addAll(streamStates);
    }
    return _result;
  }
  factory StreamStateUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StreamStateUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StreamStateUpdate clone() => StreamStateUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StreamStateUpdate copyWith(void Function(StreamStateUpdate) updates) =>
      super.copyWith((message) => updates(message as StreamStateUpdate))
          as StreamStateUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StreamStateUpdate create() => StreamStateUpdate._();
  StreamStateUpdate createEmptyInstance() => create();
  static $pb.PbList<StreamStateUpdate> createRepeated() =>
      $pb.PbList<StreamStateUpdate>();
  @$core.pragma('dart2js:noInline')
  static StreamStateUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamStateUpdate>(create);
  static StreamStateUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<StreamStateInfo> get streamStates => $_getList(0);
}

class SubscribedQuality extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubscribedQuality',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..e<$0.VideoQuality>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'quality',
        $pb.PbFieldType.OE,
        defaultOrMaker: $0.VideoQuality.LOW,
        valueOf: $0.VideoQuality.valueOf,
        enumValues: $0.VideoQuality.values)
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'enabled')
    ..hasRequiredFields = false;

  SubscribedQuality._() : super();
  factory SubscribedQuality({
    $0.VideoQuality? quality,
    $core.bool? enabled,
  }) {
    final _result = create();
    if (quality != null) {
      _result.quality = quality;
    }
    if (enabled != null) {
      _result.enabled = enabled;
    }
    return _result;
  }
  factory SubscribedQuality.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubscribedQuality.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubscribedQuality clone() => SubscribedQuality()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubscribedQuality copyWith(void Function(SubscribedQuality) updates) =>
      super.copyWith((message) => updates(message as SubscribedQuality))
          as SubscribedQuality; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubscribedQuality create() => SubscribedQuality._();
  SubscribedQuality createEmptyInstance() => create();
  static $pb.PbList<SubscribedQuality> createRepeated() =>
      $pb.PbList<SubscribedQuality>();
  @$core.pragma('dart2js:noInline')
  static SubscribedQuality getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribedQuality>(create);
  static SubscribedQuality? _defaultInstance;

  @$pb.TagNumber(1)
  $0.VideoQuality get quality => $_getN(0);
  @$pb.TagNumber(1)
  set quality($0.VideoQuality v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasQuality() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuality() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => clearField(2);
}

class SubscribedQualityUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubscribedQualityUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSid')
    ..pc<SubscribedQuality>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscribedQualities',
        $pb.PbFieldType.PM,
        subBuilder: SubscribedQuality.create)
    ..hasRequiredFields = false;

  SubscribedQualityUpdate._() : super();
  factory SubscribedQualityUpdate({
    $core.String? trackSid,
    $core.Iterable<SubscribedQuality>? subscribedQualities,
  }) {
    final _result = create();
    if (trackSid != null) {
      _result.trackSid = trackSid;
    }
    if (subscribedQualities != null) {
      _result.subscribedQualities.addAll(subscribedQualities);
    }
    return _result;
  }
  factory SubscribedQualityUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubscribedQualityUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubscribedQualityUpdate clone() =>
      SubscribedQualityUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubscribedQualityUpdate copyWith(
          void Function(SubscribedQualityUpdate) updates) =>
      super.copyWith((message) => updates(message as SubscribedQualityUpdate))
          as SubscribedQualityUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubscribedQualityUpdate create() => SubscribedQualityUpdate._();
  SubscribedQualityUpdate createEmptyInstance() => create();
  static $pb.PbList<SubscribedQualityUpdate> createRepeated() =>
      $pb.PbList<SubscribedQualityUpdate>();
  @$core.pragma('dart2js:noInline')
  static SubscribedQualityUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribedQualityUpdate>(create);
  static SubscribedQualityUpdate? _defaultInstance;

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
  $core.List<SubscribedQuality> get subscribedQualities => $_getList(1);
}

class TrackPermission extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'TrackPermission',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantSid')
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'allTracks')
    ..pPS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSids')
    ..hasRequiredFields = false;

  TrackPermission._() : super();
  factory TrackPermission({
    $core.String? participantSid,
    $core.bool? allTracks,
    $core.Iterable<$core.String>? trackSids,
  }) {
    final _result = create();
    if (participantSid != null) {
      _result.participantSid = participantSid;
    }
    if (allTracks != null) {
      _result.allTracks = allTracks;
    }
    if (trackSids != null) {
      _result.trackSids.addAll(trackSids);
    }
    return _result;
  }
  factory TrackPermission.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TrackPermission.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TrackPermission clone() => TrackPermission()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TrackPermission copyWith(void Function(TrackPermission) updates) =>
      super.copyWith((message) => updates(message as TrackPermission))
          as TrackPermission; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TrackPermission create() => TrackPermission._();
  TrackPermission createEmptyInstance() => create();
  static $pb.PbList<TrackPermission> createRepeated() =>
      $pb.PbList<TrackPermission>();
  @$core.pragma('dart2js:noInline')
  static TrackPermission getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrackPermission>(create);
  static TrackPermission? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get allTracks => $_getBF(1);
  @$pb.TagNumber(2)
  set allTracks($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasAllTracks() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllTracks() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get trackSids => $_getList(2);
}

class SubscriptionPermission extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubscriptionPermission',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'allParticipants')
    ..pc<TrackPermission>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackPermissions',
        $pb.PbFieldType.PM,
        subBuilder: TrackPermission.create)
    ..hasRequiredFields = false;

  SubscriptionPermission._() : super();
  factory SubscriptionPermission({
    $core.bool? allParticipants,
    $core.Iterable<TrackPermission>? trackPermissions,
  }) {
    final _result = create();
    if (allParticipants != null) {
      _result.allParticipants = allParticipants;
    }
    if (trackPermissions != null) {
      _result.trackPermissions.addAll(trackPermissions);
    }
    return _result;
  }
  factory SubscriptionPermission.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubscriptionPermission.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubscriptionPermission clone() =>
      SubscriptionPermission()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubscriptionPermission copyWith(
          void Function(SubscriptionPermission) updates) =>
      super.copyWith((message) => updates(message as SubscriptionPermission))
          as SubscriptionPermission; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubscriptionPermission create() => SubscriptionPermission._();
  SubscriptionPermission createEmptyInstance() => create();
  static $pb.PbList<SubscriptionPermission> createRepeated() =>
      $pb.PbList<SubscriptionPermission>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionPermission getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionPermission>(create);
  static SubscriptionPermission? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get allParticipants => $_getBF(0);
  @$pb.TagNumber(1)
  set allParticipants($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAllParticipants() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllParticipants() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<TrackPermission> get trackPermissions => $_getList(1);
}

class SubscriptionPermissionUpdate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SubscriptionPermissionUpdate',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'participantSid')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'trackSid')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'allowed')
    ..hasRequiredFields = false;

  SubscriptionPermissionUpdate._() : super();
  factory SubscriptionPermissionUpdate({
    $core.String? participantSid,
    $core.String? trackSid,
    $core.bool? allowed,
  }) {
    final _result = create();
    if (participantSid != null) {
      _result.participantSid = participantSid;
    }
    if (trackSid != null) {
      _result.trackSid = trackSid;
    }
    if (allowed != null) {
      _result.allowed = allowed;
    }
    return _result;
  }
  factory SubscriptionPermissionUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SubscriptionPermissionUpdate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SubscriptionPermissionUpdate clone() =>
      SubscriptionPermissionUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SubscriptionPermissionUpdate copyWith(
          void Function(SubscriptionPermissionUpdate) updates) =>
      super.copyWith(
              (message) => updates(message as SubscriptionPermissionUpdate))
          as SubscriptionPermissionUpdate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SubscriptionPermissionUpdate create() =>
      SubscriptionPermissionUpdate._();
  SubscriptionPermissionUpdate createEmptyInstance() => create();
  static $pb.PbList<SubscriptionPermissionUpdate> createRepeated() =>
      $pb.PbList<SubscriptionPermissionUpdate>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionPermissionUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionPermissionUpdate>(create);
  static SubscriptionPermissionUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get participantSid => $_getSZ(0);
  @$pb.TagNumber(1)
  set participantSid($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParticipantSid() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipantSid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get trackSid => $_getSZ(1);
  @$pb.TagNumber(2)
  set trackSid($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTrackSid() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrackSid() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get allowed => $_getBF(2);
  @$pb.TagNumber(3)
  set allowed($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasAllowed() => $_has(2);
  @$pb.TagNumber(3)
  void clearAllowed() => clearField(3);
}

class SyncState extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SyncState',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOM<SessionDescription>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'answer',
        subBuilder: SessionDescription.create)
    ..aOM<UpdateSubscription>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'subscription',
        subBuilder: UpdateSubscription.create)
    ..pc<TrackPublishedResponse>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'publishTracks',
        $pb.PbFieldType.PM,
        subBuilder: TrackPublishedResponse.create)
    ..pc<DataChannelInfo>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dataChannels',
        $pb.PbFieldType.PM,
        subBuilder: DataChannelInfo.create)
    ..hasRequiredFields = false;

  SyncState._() : super();
  factory SyncState({
    SessionDescription? answer,
    UpdateSubscription? subscription,
    $core.Iterable<TrackPublishedResponse>? publishTracks,
    $core.Iterable<DataChannelInfo>? dataChannels,
  }) {
    final _result = create();
    if (answer != null) {
      _result.answer = answer;
    }
    if (subscription != null) {
      _result.subscription = subscription;
    }
    if (publishTracks != null) {
      _result.publishTracks.addAll(publishTracks);
    }
    if (dataChannels != null) {
      _result.dataChannels.addAll(dataChannels);
    }
    return _result;
  }
  factory SyncState.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SyncState.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SyncState clone() => SyncState()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SyncState copyWith(void Function(SyncState) updates) =>
      super.copyWith((message) => updates(message as SyncState))
          as SyncState; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SyncState create() => SyncState._();
  SyncState createEmptyInstance() => create();
  static $pb.PbList<SyncState> createRepeated() => $pb.PbList<SyncState>();
  @$core.pragma('dart2js:noInline')
  static SyncState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncState>(create);
  static SyncState? _defaultInstance;

  @$pb.TagNumber(1)
  SessionDescription get answer => $_getN(0);
  @$pb.TagNumber(1)
  set answer(SessionDescription v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasAnswer() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnswer() => clearField(1);
  @$pb.TagNumber(1)
  SessionDescription ensureAnswer() => $_ensure(0);

  @$pb.TagNumber(2)
  UpdateSubscription get subscription => $_getN(1);
  @$pb.TagNumber(2)
  set subscription(UpdateSubscription v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSubscription() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscription() => clearField(2);
  @$pb.TagNumber(2)
  UpdateSubscription ensureSubscription() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<TrackPublishedResponse> get publishTracks => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<DataChannelInfo> get dataChannels => $_getList(3);
}

class DataChannelInfo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'DataChannelInfo',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'label')
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'id',
        $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  DataChannelInfo._() : super();
  factory DataChannelInfo({
    $core.String? label,
    $core.int? id,
  }) {
    final _result = create();
    if (label != null) {
      _result.label = label;
    }
    if (id != null) {
      _result.id = id;
    }
    return _result;
  }
  factory DataChannelInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory DataChannelInfo.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  DataChannelInfo clone() => DataChannelInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  DataChannelInfo copyWith(void Function(DataChannelInfo) updates) =>
      super.copyWith((message) => updates(message as DataChannelInfo))
          as DataChannelInfo; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DataChannelInfo create() => DataChannelInfo._();
  DataChannelInfo createEmptyInstance() => create();
  static $pb.PbList<DataChannelInfo> createRepeated() =>
      $pb.PbList<DataChannelInfo>();
  @$core.pragma('dart2js:noInline')
  static DataChannelInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DataChannelInfo>(create);
  static DataChannelInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get id => $_getIZ(1);
  @$pb.TagNumber(2)
  set id($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);
}

enum SimulateScenario_Scenario {
  speakerUpdate,
  nodeFailure,
  migration,
  serverLeave,
  notSet
}

class SimulateScenario extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SimulateScenario_Scenario>
      _SimulateScenario_ScenarioByTag = {
    1: SimulateScenario_Scenario.speakerUpdate,
    2: SimulateScenario_Scenario.nodeFailure,
    3: SimulateScenario_Scenario.migration,
    4: SimulateScenario_Scenario.serverLeave,
    0: SimulateScenario_Scenario.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'SimulateScenario',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names')
              ? ''
              : 'livekit'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..a<$core.int>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'speakerUpdate',
        $pb.PbFieldType.O3)
    ..aOB(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'nodeFailure')
    ..aOB(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'migration')
    ..aOB(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'serverLeave')
    ..hasRequiredFields = false;

  SimulateScenario._() : super();
  factory SimulateScenario({
    $core.int? speakerUpdate,
    $core.bool? nodeFailure,
    $core.bool? migration,
    $core.bool? serverLeave,
  }) {
    final _result = create();
    if (speakerUpdate != null) {
      _result.speakerUpdate = speakerUpdate;
    }
    if (nodeFailure != null) {
      _result.nodeFailure = nodeFailure;
    }
    if (migration != null) {
      _result.migration = migration;
    }
    if (serverLeave != null) {
      _result.serverLeave = serverLeave;
    }
    return _result;
  }
  factory SimulateScenario.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SimulateScenario.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SimulateScenario clone() => SimulateScenario()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SimulateScenario copyWith(void Function(SimulateScenario) updates) =>
      super.copyWith((message) => updates(message as SimulateScenario))
          as SimulateScenario; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SimulateScenario create() => SimulateScenario._();
  SimulateScenario createEmptyInstance() => create();
  static $pb.PbList<SimulateScenario> createRepeated() =>
      $pb.PbList<SimulateScenario>();
  @$core.pragma('dart2js:noInline')
  static SimulateScenario getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SimulateScenario>(create);
  static SimulateScenario? _defaultInstance;

  SimulateScenario_Scenario whichScenario() =>
      _SimulateScenario_ScenarioByTag[$_whichOneof(0)]!;
  void clearScenario() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.int get speakerUpdate => $_getIZ(0);
  @$pb.TagNumber(1)
  set speakerUpdate($core.int v) {
    $_setSignedInt32(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSpeakerUpdate() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpeakerUpdate() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get nodeFailure => $_getBF(1);
  @$pb.TagNumber(2)
  set nodeFailure($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNodeFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearNodeFailure() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get migration => $_getBF(2);
  @$pb.TagNumber(3)
  set migration($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMigration() => $_has(2);
  @$pb.TagNumber(3)
  void clearMigration() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get serverLeave => $_getBF(3);
  @$pb.TagNumber(4)
  set serverLeave($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasServerLeave() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerLeave() => clearField(4);
}
