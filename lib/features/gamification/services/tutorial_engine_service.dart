import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final tutorialEngineProvider = Provider<TutorialEngineService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TutorialEngineService(prefs);
});

class TutorialEngineService extends ChangeNotifier {
  final SharedPreferences _prefs;

  TutorialEngineService(this._prefs);

  // Contextual Onboarding Tracking
  bool get hasSeenReactorTutorial => _prefs.getBool('tut_reactor') ?? false;
  Future<void> markReactorTutorialSeen() async {
    await _prefs.setBool('tut_reactor', true);
    notifyListeners();
  }

  bool get hasSeenFlightDeckTutorial => _prefs.getBool('tut_flight') ?? false;
  Future<void> markFlightDeckTutorialSeen() async {
    await _prefs.setBool('tut_flight', true);
    notifyListeners();
  }

  bool get hasSeenLogisticsTutorial => _prefs.getBool('tut_logistics') ?? false;
  Future<void> markLogisticsTutorialSeen() async {
    await _prefs.setBool('tut_logistics', true);
    notifyListeners();
  }

  // Phase 1 Onboarding
  bool get hasSeenPhase1 => _prefs.getBool('hasSeenPhase1') ?? false;
  Future<void> markPhase1Seen() => _prefs.setBool('hasSeenPhase1', true);

  // Phase 2 On-Demand Codex
  bool hasSeenCodexLevel(int level) => _prefs.getBool('hasSeenCodexLevel_$level') ?? false;
  Future<void> markCodexLevelSeen(int level) => _prefs.setBool('hasSeenCodexLevel_$level', true);

  // Phase 3 Applied Micro-learning
  bool get hasSeenLevel1Applied => _prefs.getBool('hasSeenLevel1Applied') ?? false;
  Future<void> markLevel1AppliedSeen() => _prefs.setBool('hasSeenLevel1Applied', true);

  bool get hasSeenLevel2Applied => _prefs.getBool('hasSeenLevel2Applied') ?? false;
  Future<void> markLevel2AppliedSeen() => _prefs.setBool('hasSeenLevel2Applied', true);

  bool get hasSeenLevel3Applied => _prefs.getBool('hasSeenLevel3Applied') ?? false;
  Future<void> markLevel3AppliedSeen() => _prefs.setBool('hasSeenLevel3Applied', true);

  bool get hasSeenLevel4Applied => _prefs.getBool('hasSeenLevel4Applied') ?? false;
  Future<void> markLevel4AppliedSeen() => _prefs.setBool('hasSeenLevel4Applied', true);

  bool get hasSeenLevel5Applied => _prefs.getBool('hasSeenLevel5Applied') ?? false;
  Future<void> markLevel5AppliedSeen() => _prefs.setBool('hasSeenLevel5Applied', true);

  bool get hasSeenLevel6Applied => _prefs.getBool('hasSeenLevel6Applied') ?? false;
  Future<void> markLevel6AppliedSeen() => _prefs.setBool('hasSeenLevel6Applied', true);

  // Dev tool to wipe all tutorial states
  Future<void> clearAllTutorialStates() async {
    final keys = _prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('hasSeenPhase') || 
          key.startsWith('hasSeenCodex') || 
          key.startsWith('hasSeenLevel') ||
          key.startsWith('codex_sublevels_') ||
          key.startsWith('boss_fight_completed_') ||
          key.startsWith('tut_')) { // Add contextual tutorial keys
        await _prefs.remove(key);
      }
    }
  }

  // Phase 2: Codex Sub-Level Tracking
  List<String> getCompletedSubLevels(int levelId) => _prefs.getStringList('codex_sublevels_$levelId') ?? [];
  
  List<String> getFailedSubLevels(int levelId) => _prefs.getStringList('codex_failed_$levelId') ?? [];
  
  Future<void> markSubLevelCompleted(int levelId, String subLevelId) async {
     final current = getCompletedSubLevels(levelId);
     if (!current.contains(subLevelId)) {
        current.add(subLevelId);
        await _prefs.setStringList('codex_sublevels_$levelId', current);
        
        // Remove from failed list if it was there
        final failed = getFailedSubLevels(levelId);
        if (failed.contains(subLevelId)) {
          failed.remove(subLevelId);
          await _prefs.setStringList('codex_failed_$levelId', failed);
        }
     }
  }
  
  Future<void> markSubLevelFailed(int levelId, String subLevelId) async {
     final failed = getFailedSubLevels(levelId);
     if (!failed.contains(subLevelId)) {
        failed.add(subLevelId);
        await _prefs.setStringList('codex_failed_$levelId', failed);
     }
  }
  
  // Boss fight completion tracking
  bool isBossFightCompleted(int levelId) => _prefs.getBool('boss_fight_completed_$levelId') ?? false;
  
  Future<void> markBossFightCompleted(int levelId) async {
    await _prefs.setBool('boss_fight_completed_$levelId', true);
  }
}
