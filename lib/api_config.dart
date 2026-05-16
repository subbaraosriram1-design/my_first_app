/// Configuration for AI APIs.
/// Keys are now managed via Firebase Firestore for security.
class ApiConfig {
  // Use FirebaseService.instance.getGrokApiKey() instead.
  static const String grokApiKey = 'MANAGED_BY_FIREBASE';
}
