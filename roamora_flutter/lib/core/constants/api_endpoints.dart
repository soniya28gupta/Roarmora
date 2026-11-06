class ApiEndpoints {
  // Base API configuration (Render backend by default)
static const String defaultBaseUrl =
    'https://roarmora-api.onrender.com/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  // Profile, Onboarding & Verification
  static const String profile = '/profile';
  static const String profileCompletion = '/profile/completion';
  static const String profilePhotos = '/profile/photos';
  static const String onboardingComplete = '/profile/onboarding-complete';
  static const String livenessSession = '/verification/liveness/session';
  static const String livenessVerify = '/verification/liveness/verify';
  static const String preferences = '/preferences';
  static const String account = '/account';

  // Discover & Swipes
  static const String profiles = '/profiles';
  static const String swipes = '/swipes';

  // Matches & Chat
  static const String matches = '/matches';
  static String matchMessages(String matchId) => '/matches/$matchId/messages';

  // Calls (WebRTC)
  static const String callsActive = '/calls/active';
  static const String callInitiate = '/calls/initiate';
  static String callAnswer(String callId) => '/calls/$callId/answer';
  static String callCandidate(String callId) => '/calls/$callId/candidate';
  static String callCandidates(String callId) => '/calls/$callId/candidates';
  static String callEnd(String callId) => '/calls/$callId/end';
  static String callDecline(String callId) => '/calls/$callId/decline';
  static String callSkipAndMatch(String callId) => '/calls/$callId/skip-and-match';

  // Games
  static const String gamesStart = '/games/start';
  static const String gamesInvite = '/games/invite';
  static const String gamesInvites = '/games/invites';
  static String gameSession(String sessionId) => '/games/$sessionId';
  static String gameAction(String sessionId) => '/games/$sessionId/action';
  static String gameAccept(String sessionId) => '/games/$sessionId/accept';
  static String gameDecline(String sessionId) => '/games/$sessionId/decline';
  static const String quizDaily = '/quiz/daily';
  static const String quizSubmit = '/quiz/submit';

  // Map, Places & Drops
  static const String places = '/places';
  static const String drops = '/drops';
  static String dropCollect(String dropId) => '/drops/$dropId/collect';

  // Inventory & Collectibles
  static const String collectibles = '/collectibles';
  static const String inventory = '/inventory';
  static const String achievements = '/achievements';

  // Blocks & Safety
  static const String blocks = '/blocks';
  static String unblock(String userId) => '/blocks/$userId';
  static const String reports = '/reports';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
}

