// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'messages.g.dart';

/// An Android implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [VideoPlayerApi].
class AndroidVideoPlayer extends VideoPlayerPlatform {
  final AndroidVideoPlayerApi _api = AndroidVideoPlayerApi();

  static const MethodChannel _tracksChannel = MethodChannel(
    'flutter.io/videoPlayer/tracks',
  );

  /// Registers this class as the default instance of [PathProviderPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = AndroidVideoPlayer();
  }

  @override
  Future<void> init() {
    return _api.initialize();
  }

  @override
  Future<void> dispose(int textureId) {
    return _api.dispose(textureId);
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    String? asset;
    String? packageName;
    String? uri;
    String? formatHint;
    Map<String, String> httpHeaders = <String, String>{};
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        packageName = dataSource.package;
      case DataSourceType.network:
        uri = dataSource.uri;
        formatHint = _videoFormatStringMap[dataSource.formatHint];
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.file:
        uri = dataSource.uri;
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.contentUri:
        uri = dataSource.uri;
    }
    final CreateMessage message = CreateMessage(
      asset: asset,
      packageName: packageName,
      uri: uri,
      httpHeaders: httpHeaders,
      formatHint: formatHint,
    );

    return _api.create(message);
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
    return _api.setLooping(textureId, looping);
  }

  @override
  Future<void> play(int textureId) {
    return _api.play(textureId);
  }

  @override
  Future<void> pause(int textureId) {
    return _api.pause(textureId);
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    return _api.setVolume(textureId, volume);
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    assert(speed > 0);

    return _api.setPlaybackSpeed(textureId, speed);
  }

  @override
  Future<void> seekTo(int textureId, Duration position) {
    return _api.seekTo(textureId, position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    final int position = await _api.position(textureId);
    return Duration(milliseconds: position);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0,
                (map['height'] as num?)?.toDouble() ?? 0.0),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
          );
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;

          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int textureId) {
    return Texture(textureId: textureId);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api.setMixWithOthers(mixWithOthers);
  }

  @override
  bool isAudioTrackSupportAvailable() => true;

  @override
  bool isVideoTrackSupportAvailable() => true;

  @override
  Future<List<VideoAudioTrack>> getAudioTracks(int playerId) async {
    final List<dynamic>? raw = await _tracksChannel
        .invokeMethod<List<dynamic>>('getAudioTracks', <String, dynamic>{
      'playerId': playerId,
    });
    if (raw == null) {
      return <VideoAudioTrack>[];
    }
    return raw.map<VideoAudioTrack>((dynamic entry) {
      final Map<Object?, Object?> map = entry as Map<Object?, Object?>;
      return VideoAudioTrack(
        id: map['id']! as String,
        label: map['label'] as String?,
        language: map['language'] as String?,
        isSelected: map['isSelected'] as bool? ?? false,
        bitrate: map['bitrate'] as int?,
        sampleRate: map['sampleRate'] as int?,
        channelCount: map['channelCount'] as int?,
        codec: map['codec'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> selectAudioTrack(int playerId, String trackId) {
    return _tracksChannel.invokeMethod<void>(
      'selectAudioTrack',
      <String, dynamic>{
        'playerId': playerId,
        'trackId': trackId,
      },
    );
  }

  @override
  Future<List<VideoTrack>> getVideoTracks(int playerId) async {
    final List<dynamic>? raw = await _tracksChannel
        .invokeMethod<List<dynamic>>('getVideoTracks', <String, dynamic>{
      'playerId': playerId,
    });
    if (raw == null) {
      return <VideoTrack>[];
    }
    return raw.map<VideoTrack>((dynamic entry) {
      final Map<Object?, Object?> map = entry as Map<Object?, Object?>;
      return VideoTrack(
        id: map['id']! as String,
        isSelected: map['isSelected'] as bool? ?? false,
        label: map['label'] as String?,
        bitrate: map['bitrate'] as int?,
        width: map['width'] as int?,
        height: map['height'] as int?,
        frameRate: map['frameRate'] as double?,
        codec: map['codec'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> selectVideoTrack(int playerId, VideoTrack? track) {
    return _tracksChannel.invokeMethod<void>(
      'selectVideoTrack',
      <String, dynamic>{
        'playerId': playerId,
        if (track != null)
          'track': <String, dynamic>{
            'id': track.id,
            'isSelected': track.isSelected,
            'label': track.label,
            'bitrate': track.bitrate,
            'width': track.width,
            'height': track.height,
            'frameRate': track.frameRate,
            'codec': track.codec,
          },
      },
    );
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
  }

  static const Map<VideoFormat, String> _videoFormatStringMap =
      <VideoFormat, String>{
    VideoFormat.ss: 'ss',
    VideoFormat.hls: 'hls',
    VideoFormat.dash: 'dash',
    VideoFormat.other: 'other',
  };

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }
}
