/// AI Configuration for TrustProbe AI
///
/// Configure your Groq API key and model settings here.
/// Get a free API key from: https://console.groq.com
class AiConfig {
  AiConfig._(); // Prevent instantiation

  /// Your Groq API key - Replace with your actual key
  /// Get a free key from: https://console.groq.com
  static const groqApiKey = 'YOUR_GROQ_API_KEY_HERE';

  /// Groq API base URL
  static const baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Open-source LLM model to use
  /// Options: llama-3.3-70b-versatile, mixtral-8x7b-32768, gemma2-9b-it
  static const model = 'llama-3.3-70b-versatile';

  /// Request timeout in seconds
  static const timeoutSeconds = 15;

  /// Maximum tokens for AI response
  static const maxTokens = 1024;

  /// Whether AI analysis is enabled
  static bool get isConfigured =>
      groqApiKey != 'YOUR_GROQ_API_KEY_HERE' && groqApiKey.isNotEmpty;
}
