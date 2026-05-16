/// Configuration for AI APIs.
class ApiConfig {
  // Groq Configuration (using the key you provided)
  // Note: gsk_ prefix indicates this is a Groq key, not xAI/Grok.
  static const String apiKey = "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";
  static const String baseUrl = "https://api.groq.com/openai/v1/chat/completions";
  static const String model = "llama-3.3-70b-versatile"; 

  // Set to true to use the hardcoded key above. 
  // Set to false to fetch from Firebase Firestore (for better security).
  static const bool useHardcodedKey = true;

  // Firestore path (if useHardcodedKey is false)
  static const String configCollection = "config";
  static const String apiKeysDocument = "api_keys";
  static const String grokKeyField = "groq_api_key";
}
