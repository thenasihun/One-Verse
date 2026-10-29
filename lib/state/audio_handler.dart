import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Commands from the notification, lock screen, headset and car.
abstract class PlayerCommands {
  Future<void> cmdPlay();
  Future<void> cmdPause();
  Future<void> cmdNext();
  Future<void> cmdPrevious();
  Future<void> cmdStop();
  Future<void> cmdSeek(Duration position);
  Future<void> cmdToggleRepeat();
  int get repeatSetting;
}

/// Bridges just_audio to the system media session, so the notification and
/// lock screen show the full player with repeat, previous, play, next and stop.
class OvAudioHandler extends BaseAudioHandler with SeekHandler {
  OvAudioHandler(this.player) {
    player.playbackEventStream.listen((_) => _broadcast(), onError: (Object _, StackTrace _) {});
    player.playingStream.listen((_) => _broadcast());
  }

  final AudioPlayer player;
  PlayerCommands? commands;

  void refresh() => _broadcast();

  /// Removes the notification without unloading the player.
  void dismiss() => playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));

  void _broadcast() {
    final playing = player.playing;
    final repeat = commands?.repeatSetting ?? 0;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.custom(
          androidIcon: repeat == 0 ? 'drawable/ic_ov_repeat' : 'drawable/ic_ov_repeat_on',
          label: 'Repeat ayah',
          name: 'repeat',
        ),
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.custom(androidIcon: 'drawable/ic_ov_close', label: 'Stop', name: 'stop'),
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      repeatMode: repeat == 0 ? AudioServiceRepeatMode.none : AudioServiceRepeatMode.one,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: player.currentIndex,
    ));
  }

  @override
  Future<void> play() async => commands?.cmdPlay();
  @override
  Future<void> pause() async => commands?.cmdPause();
  @override
  Future<void> skipToNext() async => commands?.cmdNext();
  @override
  Future<void> skipToPrevious() async => commands?.cmdPrevious();
  @override
  Future<void> stop() async => commands?.cmdStop();
  @override
  Future<void> seek(Duration position) async => commands?.cmdSeek(position);
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async => commands?.cmdToggleRepeat();
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'repeat') return commands?.cmdToggleRepeat();
    if (name == 'stop') return commands?.cmdStop();
  }
}
