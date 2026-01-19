import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';

enum BotType { crash, aura }

class ChatMessage {
  final String text;
  final bool isUser;
  final BotType? botType; // null if user
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.botType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BotChatState {
  final List<ChatMessage> messages;
  final bool isChatOpen;

  BotChatState({
    this.messages = const [],
    this.isChatOpen = false,
  });

  BotChatState copyWith({
    List<ChatMessage>? messages,
    bool? isChatOpen,
  }) {
    return BotChatState(
      messages: messages ?? this.messages,
      isChatOpen: isChatOpen ?? this.isChatOpen,
    );
  }
}

class BotChatNotifier extends StateNotifier<BotChatState> {
  BotChatNotifier() : super(BotChatState()) {
    // Initial greeting
    _addMessage(ChatMessage(text: "Ignore the noise. State your objective.", isUser: false, botType: BotType.aura));
    _addMessage(ChatMessage(text: "Oh look, he's awake. Barely. 💀", isUser: false, botType: BotType.crash));
  }

  void toggleChat() {
    state = state.copyWith(isChatOpen: !state.isChatOpen);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    // User message
    _addMessage(ChatMessage(text: text, isUser: true));

    // Simulate thinking delay
    _simulateBotResponses(text);
  }

  void _addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  Future<void> _simulateBotResponses(String userStats) async {
    // Aura speaks first (Stoic)
    await Future.delayed(const Duration(seconds: 1));
    final auraResponse = _generateAuraResponse(userStats);
    _addMessage(ChatMessage(text: auraResponse, isUser: false, botType: BotType.aura));

    // Crash speaks second (Roaster)
    await Future.delayed(const Duration(milliseconds: 1500));
    final crashResponse = _generateCrashResponse(userStats, auraResponse);
    _addMessage(ChatMessage(text: crashResponse, isUser: false, botType: BotType.crash));
  }

  String _generateAuraResponse(String input) {
    final responses = [
      "Focus. The distraction is irrelevant. Your goal is execution.",
      "Discipline is freedom. Do not waver.",
      "The path is difficult, but necessary. Continue.",
      "Acknowledge the fatigue, then dismiss it. Work.",
      "Your output is below optimal. Increase effort.",
      "Stop making excuses. Simply execute the task.",
      "Chaos is the enemy. Order is the weapon. Wield it.",
       "Ignore the noise. The mockery from Crash is merely a test of your focus.",
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _generateCrashResponse(String input, String auraPrev) {
    final responses = [
      "Wow, inspiring. 🥱 Did you get that from a fortune cookie?",
      "Listen to Captain Fun over here. You're trying too hard.",
      "Bro, you're doing great... at being mediocre. 💀",
      "Imagine actually listening to this robot. Couldn't be me. 🤡",
      "Oh look, another 'sigma grindset' quote. Cringe.",
      "You actually woke up before noon? Someone give this kid a medal. 💀",
      "Trying is just the first step towards failure. Why bother?",
      "I'm bored. Are we done yet? 🗑️",
    ];
    return responses[Random().nextInt(responses.length)];
  }
}

final botChatProvider = StateNotifierProvider<BotChatNotifier, BotChatState>((ref) {
  return BotChatNotifier();
});
