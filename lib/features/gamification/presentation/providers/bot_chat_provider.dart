import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import '../../../../core/services/gemini_service.dart';

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
  final List<ChatMessage> auraMessages;
  final List<ChatMessage> crashMessages;
  final BotType? activeBot; // Null means chat is closed

  BotChatState({
    this.auraMessages = const [],
    this.crashMessages = const [],
    this.activeBot,
  });

  bool get isChatOpen => activeBot != null;
  
  List<ChatMessage> get currentMessages {
    if (activeBot == BotType.crash) return crashMessages;
    return auraMessages;
  }

  BotChatState copyWith({
    List<ChatMessage>? auraMessages,
    List<ChatMessage>? crashMessages,
    BotType? activeBot,
    bool forceClose = false,
  }) {
    return BotChatState(
      auraMessages: auraMessages ?? this.auraMessages,
      crashMessages: crashMessages ?? this.crashMessages,
      activeBot: forceClose ? null : (activeBot ?? this.activeBot),
    );
  }
}

class BotChatNotifier extends StateNotifier<BotChatState> {
  final GeminiService _geminiService = GeminiService();

  BotChatNotifier() : super(BotChatState()) {
    _initGemini();
  }

  Future<void> _initGemini() async {
    await _geminiService.initialize();
    // Initialize both logs with unique system messages
    _addToHistory(BotType.aura, ChatMessage(text: "SYSTEM: AURA_CORE v9.0 // STANDBY", isUser: false, botType: null));
    _addToHistory(BotType.crash, ChatMessage(text: "SYSTEM: CRASH_OVERRIDE // UNAUTHORIZED ACCESS", isUser: false, botType: null));
  }

  void openChat(BotType bot) {
    if (state.activeBot == bot) {
      closeChat();
    } else {
      state = state.copyWith(activeBot: bot);
    }
  }

  void closeChat() {
    state = state.copyWith(forceClose: true);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty || state.activeBot == null) return;

    final currentBot = state.activeBot!;

    // 1. Add User Message to CURRENT history
    _addToHistory(currentBot, ChatMessage(text: text, isUser: true));

    // 2. Handle Response
    _handleBotResponse(text, currentBot);
  }

  void _addToHistory(BotType historyOwner, ChatMessage message) {
    if (historyOwner == BotType.aura) {
      state = state.copyWith(auraMessages: [...state.auraMessages, message]);
    } else {
      state = state.copyWith(crashMessages: [...state.crashMessages, message]);
    }
  }

  Future<void> _handleBotResponse(String input, BotType responder) async {
    final otherBot = responder == BotType.aura ? BotType.crash : BotType.aura;
    
    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 600)); 
    
    // 1. Generate Primary Response
    // IMPORTANT: The responder IS the active bot context.
    final responseText = await _geminiService.generateResponse(input, responder);
    _addToHistory(responder, ChatMessage(text: responseText, isUser: false, botType: responder));

    // 2. Interruption Logic (20% chance)
    if (Random().nextDouble() < 0.20) {
      await Future.delayed(const Duration(milliseconds: 2000));
      
      final interruptText = await _geminiService.generateInterruption(
        input, 
        responseText, 
        otherBot
      );
      
      if (interruptText.isNotEmpty) {
        // Add the interruption to the RESPONDER'S history (the active chat)
        _addToHistory(responder, ChatMessage(text: interruptText, isUser: false, botType: otherBot));
      }
    }
  }
}

final botChatProvider = StateNotifierProvider<BotChatNotifier, BotChatState>((ref) {
  return BotChatNotifier();
});
