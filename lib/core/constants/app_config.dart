class AppConfig {
  static const String appName = 'Kanji Sensei';
  static const String apiBaseUrl = 'https://kanjiapi.dev/v1/';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String flashcardsCollection = 'flashcards';
  static const String decksCollection = 'decks';

  // Local Storage Keys
  static const String themeKey = 'theme_mode';
  static const String lastSyncKey = 'last_sync';

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);
}
