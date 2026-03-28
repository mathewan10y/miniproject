import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isSfxEnabled;
  const SettingsState({this.isSfxEnabled = true});

  SettingsState copyWith({bool? isSfxEnabled}) {
    return SettingsState(isSfxEnabled: isSfxEnabled ?? this.isSfxEnabled);
  }
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _sfxKey = 'is_sfx_enabled';

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final isSfxEnabled = prefs.getBool(_sfxKey) ?? true;
    return SettingsState(isSfxEnabled: isSfxEnabled);
  }

  Future<void> toggleSfx() async {
    final currentState = state.valueOrNull ?? const SettingsState();
    final newValue = !currentState.isSfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, newValue);
    state = AsyncData(currentState.copyWith(isSfxEnabled: newValue));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
