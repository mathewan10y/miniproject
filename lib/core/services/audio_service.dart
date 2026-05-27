import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class AudioService {
  final Ref _ref;
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  // Track if BGM should be playing
  bool _isBgmPlaying = false;

  AudioService(this._ref) {
    _initBgm();
  }

  void _initBgm() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Listen to settings to auto-play/stop BGM
    _ref.listen<AsyncValue<SettingsState>>(
      settingsProvider,
      (previous, next) {
        final state = next.valueOrNull;
        if (state != null) {
          if (state.isBgmEnabled && !_isBgmPlaying) {
            playBgm();
          } else if (!state.isBgmEnabled && _isBgmPlaying) {
            stopBgm();
          }
        }
      },
    );
  }

  Future<void> playBgm() async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    if (settings != null && settings.isBgmEnabled) {
      try {
        await _bgmPlayer.play(AssetSource('audio/background.mp3'));
        _isBgmPlaying = true;
      } catch (e) {
        print('Error playing BGM: $e');
      }
    }
  }

  void stopBgm() {
    _bgmPlayer.stop();
    _isBgmPlaying = false;
  }

  Future<void> playSound(String fileName) async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    // If settings are still loading (null), treat as enabled.
    // If explicitly disabled, skip.
    final sfxEnabled = settings?.isSfxEnabled ?? true;
    if (!sfxEnabled) return;

    try {
      final player = AudioPlayer();
      print('[AudioService] Playing: audio/$fileName');
      await player.play(AssetSource('audio/$fileName'));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      print('[AudioService] Error playing audio/$fileName: $e');
    }
  }
  
  void dispose() {
    _bgmPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
