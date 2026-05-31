class AppConstants {

  static const String appName = 'Seshlly';

  static const int apiTimeout = 30;

  //static const String apiBaseUrl = 'https://api.fitconnect.app/api/v1';
  static const String apiBaseUrl = 'https://social-api-5kko.onrender.com/api/v1';
  static const String socketUrl  = 'https://api.fitconnect.app';


  // Storage keys
  static const String kAccessToken   = 'access_token';
  static const String kRefreshToken  = 'refresh_token';
  static const String kUserId        = 'user_id';
  static const String kOnboarded     = 'onboarded';
  static const String kUserData      = 'user_data';

  // Pagination
  static const int pageSize = 20;

  // Match
  static const double maxBuddyDistanceKm = 50.0;
  static const int    dailySwipesFree    = 5;
  static const int    dailySwipesPro     = 999;

  // Chat tokens
  static const int tokenPack10Price = 29;
  static const int tokenPack20Price = 49;
  static const int tokenPack50Price = 99;

  // Activities
  static const List<Map<String,dynamic>> activities = [
    { 'id':'gym',      'label':'Gym',      'emoji':'🏋️', 'color':0xFFBAEE0B },
    { 'id':'running',  'label':'Running',  'emoji':'🏃', 'color':0xFF4DAAFF },
    { 'id':'cycling',  'label':'Cycling',  'emoji':'🚴', 'color':0xFFFFB020 },
    { 'id':'swimming', 'label':'Swimming', 'emoji':'🏊', 'color':0xFF0ABFCE },
    { 'id':'boxing',   'label':'Boxing',   'emoji':'🥊', 'color':0xFFFF6B35 },
    { 'id':'yoga',     'label':'Yoga',     'emoji':'🧘', 'color':0xFFFF6B9D },
    { 'id':'hyrox',    'label':'Hyrox',    'emoji':'⚡', 'color':0xFFB57BFF },
    { 'id':'crossfit', 'label':'CrossFit', 'emoji':'🔥', 'color':0xFFFF4D4D },
    { 'id':'climbing', 'label':'Climbing', 'emoji':'🧗', 'color':0xFF2DDAAD },
    { 'id':'tennis',   'label':'Tennis',   'emoji':'🎾', 'color':0xFFD4F53C },
  ];

  // Experience levels
  static const List<Map<String,String>> levels = [
    { 'id':'beginner',     'label':'Beginner',     'desc':'< 1 year' },
    { 'id':'intermediate', 'label':'Intermediate', 'desc':'1–3 years' },
    { 'id':'advanced',     'label':'Advanced',     'desc':'3–5 years' },
    { 'id':'elite',        'label':'Elite',        'desc':'5+ years' },
  ];

  // Goals
  static const List<Map<String,String>> goals = [
    { 'id':'weight_loss',   'label':'Weight Loss',    'emoji':'⚡' },
    { 'id':'muscle_gain',   'label':'Muscle Gain',    'emoji':'💪' },
    { 'id':'endurance',     'label':'Endurance',      'emoji':'🏃' },
    { 'id':'strength',      'label':'Strength',       'emoji':'🏋️' },
    { 'id':'flexibility',   'label':'Flexibility',    'emoji':'🧘' },
    { 'id':'sports_perf',   'label':'Sports Perf.',   'emoji':'🏆' },
    { 'id':'general_fit',   'label':'General Fitness','emoji':'❤️' },
    { 'id':'competition',   'label':'Competition',    'emoji':'🥇' },
  ];

  // XP per action
  static const Map<String,int> xpRewards = {
    'session_uploaded': 50,
    'buddy_matched':    30,
    'streak_7':        100,
    'streak_30':       500,
    'profile_complete': 25,
    'first_checkin':    20,
  };



  // Level thresholds  new
  static const List<int> levelThresholds = [0,100,300,600,1000,1500,2200,3000,4000,5500];
  static const List<String> levelNames   = ['Newbie','Rookie','Regular','Athlete','Pro','Elite','Champion','Legend','Icon','GOAT'];

}