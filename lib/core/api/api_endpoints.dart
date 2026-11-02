class ApiEndpoints {
  //static const String apiBaseUrl = 'https://api.fitconnect.app/api/v1';
  static const String apiBaseUrl = 'https://api.seshlly.com/api/v1';
  // Socket.io runs on the same server as the REST API (server.js)
  // (was 'https://api.fitconnect.app' — old domain, sockets never connected)
  static const String socketUrl = 'https://api.seshlly.com';

  //static const String baseUrl = 'https://dummyjson.com';
  //static const String recipes = '/recipes';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/upload';
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
}
