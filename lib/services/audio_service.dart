import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AudioEffect {
  timerStart('timer_start.mp3'),
  timerPause('timer_pause.mp3'),
  timerStop('timer_stop.mp3'),
  timerComplete('timer_complete.mp3'),
  taskComplete('task_complete.mp3'),
  achievementUnlock('achievement_unlock.mp3');

  const AudioEffect(this.fileName);
  final String fileName;
}

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  Future<void> playEffect(AudioEffect effect) async {
    if (!_enabled) return;
    
    try {
      // Use a new player for each effect to allow overlapping sounds if needed,
      // or just reuse the main one for simple effects. 
      // For short effects, reuse is usually fine.
      await _player.stop();
      await _player.play(AssetSource('audio/${effect.fileName}'));
    } catch (e) {
      debugPrint('AudioService: Failed to play ${effect.fileName}. '
          'Make sure the file exists in assets/audio/');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
