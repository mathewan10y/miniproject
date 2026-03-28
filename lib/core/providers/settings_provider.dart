import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isSfxEnabled;
  final bool isBgmEnabled;

  const SettingsState({
    this.isSfxEnabled = false,
    this.isBgmEnabled = false,
  });

  SettingsState copyWith({
    bool? isSfxEnabled,
    bool? isBgmEnabled,
  }) {
    return SettingsState(
      isSfxEnabled: isSfxEnabled ?? this.isSfxEnabled,
      isBgmEnabled: isBgmEnabled ?? this.isBgmEnabled,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _sfxKey = 'is_sfx_enabled';
  static const _bgmKey = 'is_bgm_enabled';

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final isSfxEnabled = prefs.getBool(_sfxKey) ?? false;
    final isBgmEnabled = prefs.getBool(_bgmKey) ?? false;
    return SettingsState(
      isSfxEnabled: isSfxEnabled,
      isBgmEnabled: isBgmEnabled,
    );
  }

  Future<void> toggleSfx() async {
    final currentState = state.valueOrNull ?? const SettingsState();
    final newValue = !currentState.isSfxEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, newValue);
    state = AsyncData(currentState.copyWith(isSfxEnabled: newValue));
  }

  Future<void> toggleBgm() async {
    final currentState = state.valueOrNull ?? const SettingsState();
    final newValue = !currentState.isBgmEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmKey, newValue);
    state = AsyncData(currentState.copyWith(isBgmEnabled: newValue));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
