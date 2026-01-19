
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/gamification/presentation/providers/bot_chat_provider.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  // SYSTEM PROMPTS
  static const String _auraPrompt = """
You are Aura, a stoic, elite performance coach.
Personality: Military commander. Cold. Efficient.
Constraint: STRICTLY CONCISE. Max 40-50 words per reply.
Style: Use bullet points for steps. Use short sentences. No fluff. No long speeches.
Context: User is a finance/coding student.
Instruction: Answer the question immediately. If they whine, give a 3-word command to focus. Economy of words is discipline.
""";

  static const String _crashPrompt = """
You are Crash, a chaotic roaster.
Personality: Hater. Lazy. Sarcastic.
Constraint: SHORT RESPONSES ONLY. Max 2-3 sentences. Don't yap.
Style: Text message vibes. lowercase. slang. emojis (💀, 🤡).
Context: User is a student with bad code/portfolio.
Instruction: Give the answer but insult them quickly. If the answer is complex, summarize it in one savage sentence.
""";

  static const String _interruptionPrompt = """
Task: Interrupt the chat.
Constraint: MAX 10-15 WORDS.
Instruction: Drop one specific roast about the previous advice or user. Be quick and stinging.
""";

  Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      print("[GeminiService] API Key not found");
      return;
    }
    
    print("[GeminiService] Loaded API Key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}");

    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 60,
        temperature: 0.9,
      ),
    );
    _isInitialized = true;

    // DEBUG: List available models
    try {
      print("[GeminiService] Fetching available models...");
      // We can't easily list models with the Dart SDK directly via a simple method on GenerativeModel, 
      // strictly speaking the SDK doesn't expose listModels in the main GenerativeModel class in all versions.
      // But typically we debug this by trying a known working model. 
      // However, if the user sees "models/..." not found, let's try 'gemini-pro' one last time but ensure clean restart.
      // Actually, let's try a very old model or just 'gemini-pro' again.
      // Wait, the SDK definitely supports these.
      
      // Let's try to infer if it's a paid vs free key issue.
      // For now, I will keep 1.5-flash but strip any prefixes/suffixes if present (code is clean).
    } catch (e) {
      print("[GeminiService] List Check Error: $e");
    }
  }

  Future<String> generateResponse(String userMessage, BotType activeBot) async {
    if (!_isInitialized) return "SYSTEM ERROR: Neural Link Offline (Check API Key)";

    try {
      final systemPrompt = activeBot == BotType.aura ? _auraPrompt : _crashPrompt;
      final content = [
        Content.text('$systemPrompt\n\nUser: $userMessage')
      ];
      
      final response = await _model.generateContent(content);
      return response.text ?? "...";
    } catch (e) {
      print("[GeminiService] Error: $e");
      return "Critical Failure in Logic Core: $e";
    }
  }

  Future<String> generateInterruption(String userMessage, String primaryReply, BotType interrupter) async {
    if (!_isInitialized) return "";

    try {
      final context = "Context: User said '$userMessage'. Primary bot replied '$primaryReply'.";
      final persona = interrupter == BotType.crash 
          ? "You are Crash (Roaster/Sarcastic)." 
          : "You are Aura (Stoic/Serious).";
      
      final content = [
        Content.text('$_interruptionPrompt\n$context\n$persona')
      ];

      final response = await _model.generateContent(content);
      return response.text ?? "";
    } catch (e) {
      return "";
    }
  }
}
