import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class AudioService {
  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();

  AudioService(this._ref);

  Future<void> playSound(String fileName) async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    if (settings != null && settings.isSfxEnabled) {
      try {
        await _player.play(AssetSource('audio/$fileName'));
      } catch (e) {
        print('Error playing audio: $e');
      }
    }
  }
  
  void dispose() {
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
