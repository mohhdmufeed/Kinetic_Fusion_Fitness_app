import 'package:flutter/material.dart';

class MiniMusicPlayer extends StatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  bool _isPlaying = true;
  int _currentTrack = 0;

  final List<Map<String, String>> _playlist = const [
    {'title': 'High Energy Workout Mix', 'artist': 'Power Beat Radio', 'icon': '🎵'},
    {'title': 'Electro Cardio Run 175 BPM', 'artist': 'Pace Masters', 'icon': '⚡'},
    {'title': 'Heavy Bass Gym Motivation', 'artist': 'Beast Mode Audio', 'icon': '🔥'},
    {'title': 'Endurance Trail Vibes', 'artist': 'Acoustic Beats', 'icon': '🎧'},
  ];

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _nextTrack() {
    setState(() => _currentTrack = (_currentTrack + 1) % _playlist.length);
  }

  void _prevTrack() {
    setState(() => _currentTrack = (_currentTrack - 1 + _playlist.length) % _playlist.length);
  }

  @override
  Widget build(BuildContext context) {
    final track = _playlist[_currentTrack];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(track['icon']!, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track['artist']!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 22),
            onPressed: _prevTrack,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: const Color(0xFF38BDF8),
              size: 32,
            ),
            onPressed: _togglePlay,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 22),
            onPressed: _nextTrack,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ],
      ),
    );
  }
}
