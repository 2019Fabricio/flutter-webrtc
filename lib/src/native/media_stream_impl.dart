import 'dart:async';

import 'package:project_01/webrtc_native_bridge.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

import 'factory_impl.dart';
import 'media_stream_track_impl.dart';
import 'utils.dart';

class MediaStreamNative extends MediaStream {
  MediaStreamNative(super.streamId, super.ownerTag);

  factory MediaStreamNative.fromMap(Map<dynamic, dynamic> map) {
    return MediaStreamNative(map['streamId'], map['ownerTag'])
      ..setMediaTracks(map['audioTracks'], map['videoTracks']);
  }

    static Future<MediaStreamNative?> createFromCustomSource(String moduleType) async {
  final String? streamId = await WebRTCNativeBridge.createAndRegisterCustomStream(moduleType);

  if (streamId != null) {
    final stream = MediaStreamNative(streamId, 'custom');
    await stream.getMediaTracks(); // Fetch the tracks for this stream
    return stream;
  }

  return null;
}

bool get isCustomStream => ownerTag == 'custom';

  final _audioTracks = <MediaStreamTrack>[];
  final _videoTracks = <MediaStreamTrack>[];

  void setMediaTracks(List<dynamic> audioTracks, List<dynamic> videoTracks) {
    _audioTracks.clear();

    for (var track in audioTracks) {
      _audioTracks.add(MediaStreamTrackNative(track['id'], track['label'],
          track['kind'], track['enabled'], ownerTag, track['settings'] ?? {}));
    }

    _videoTracks.clear();
    for (var track in videoTracks) {
      _videoTracks.add(MediaStreamTrackNative(track['id'], track['label'],
          track['kind'], track['enabled'], ownerTag, track['settings'] ?? {}));
    }
  }

  @override
  List<MediaStreamTrack> getTracks() {
    return <MediaStreamTrack>[..._audioTracks, ..._videoTracks];
  }

  @override
Future getMediaTracks() async {
final response = await WebRTC.invokeMethod(
'mediaStreamGetTracks',
<String, dynamic>{'streamId': id},
);

if (response != null) {
setMediaTracks(
response['audioTracks'] ?? [],
response['videoTracks'] ?? [],
);
} else {
// Handle the case where we couldn't get track information
print('Failed to get media tracks for stream $id');
}
}

  @override
  Future<void> addTrack(MediaStreamTrack track,
      {bool addToNative = true}) async {
    if (track.kind == 'audio') {
      _audioTracks.add(track);
    } else {
      _videoTracks.add(track);
    }

    if (addToNative) {
      await WebRTC.invokeMethod('mediaStreamAddTrack',
          <String, dynamic>{'streamId': id, 'trackId': track.id});
    }
  }

  @override
  Future<void> removeTrack(MediaStreamTrack track,
      {bool removeFromNative = true}) async {
    if (track.kind == 'audio') {
      _audioTracks.removeWhere((it) => it.id == track.id);
    } else {
      _videoTracks.removeWhere((it) => it.id == track.id);
    }

    if (removeFromNative) {
      await WebRTC.invokeMethod('mediaStreamRemoveTrack',
          <String, dynamic>{'streamId': id, 'trackId': track.id});
    }
  }

  @override
  List<MediaStreamTrack> getAudioTracks() {
    return _audioTracks;
  }

  @override
  List<MediaStreamTrack> getVideoTracks() {
    return _videoTracks;
  }

  @override
  Future<void> dispose() async {
    await WebRTC.invokeMethod(
      'streamDispose',
      <String, dynamic>{'streamId': id},
    );
  }

  @override
  // TODO(cloudwebrtc): Implement
  bool get active => throw UnimplementedError();

  @override
  Future<MediaStream> clone() async {
    final cloneStream = await createLocalMediaStream(id);
    for (var track in [..._audioTracks, ..._videoTracks]) {
      await cloneStream.addTrack(track);
    }
    return cloneStream;
  }
}
