import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:oneverse/services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _audioService.play(
      "https://cdn.islamic.network/quran/audio/64/ar.alafasy/1.mp3",
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSeekBar(),
        const SizedBox(height: 10),
        _buildPlayerControls(context),
      ],
    );
  }

  Widget _buildSeekBar() {
    return StreamBuilder<Duration?>(
      stream: _audioService.audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _audioService.audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) position = duration;
            return Column(
              children: [
                Slider(
                  value: position.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _audioService.audioPlayer
                        .seek(Duration(milliseconds: value.round()));
                  },
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10),
          iconSize: 40,
          onPressed: () {
            final current = _audioService.audioPlayer.position.inSeconds;
            _audioService.audioPlayer
                .seek(Duration(seconds: (current - 10).clamp(0, current)));
          },
        ),
        const SizedBox(width: 20),
        StreamBuilder<PlayerState>(
          stream: _audioService.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing ?? false;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return const CircularProgressIndicator();
            } else if (!playing) {
              return IconButton(
                icon: const Icon(Icons.play_circle_fill),
                iconSize: 64,
                color: Theme.of(context).primaryColor,
                onPressed: _audioService.audioPlayer.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause_circle_filled),
                iconSize: 64,
                color: Theme.of(context).primaryColor,
                onPressed: _audioService.audioPlayer.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay_circle_filled),
                iconSize: 64,
                color: Theme.of(context).primaryColor,
                onPressed: () =>
                    _audioService.audioPlayer.seek(Duration.zero),
              );
            }
          },
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.forward_10),
          iconSize: 40,
          onPressed: () {
            final current = _audioService.audioPlayer.position.inSeconds;
            final duration =
                _audioService.audioPlayer.duration ?? Duration.zero;
            final newPosition = (current + 10).clamp(0, duration.inSeconds);
            _audioService.audioPlayer
                .seek(Duration(seconds: newPosition));
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}