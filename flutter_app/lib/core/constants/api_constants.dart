class ApiConstants {
  ApiConstants._();

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String userProfile = '/user/profile';
  static const String userPreferences = '/user/preferences';
  static const String userStats = '/user/stats';
  static const String entries = '/entries';
  static String entryId(String id) => '/entries/$id';
  static const String entriesDrafts = '/entries/drafts';
  static const String entriesFavorites = '/entries/favorites';
  static const String entriesCalendar = '/entries/calendar';
  static const String entriesOnThisDay = '/entries/on-this-day';
  static const String search = '/search';
  static const String aiGeneratePrompt = '/ai/generate-prompt';
  static const String aiImproveText = '/ai/improve-text';
  static const String aiChat = '/ai/chat';
  static const String aiConversationHistory = '/ai/conversation-history';
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsStreaks = '/analytics/streaks';
  static const String analyticsMoodTrends = '/analytics/mood-trends';
  static const String analyticsWritingStats = '/analytics/writing-stats';
}
