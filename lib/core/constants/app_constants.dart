class AppConstants {

  static const String appName = 'Seshlly';

  static const int apiTimeout = 30;


  // Storage keys
  static const String kAccessToken   = 'access_token';
  static const String kRefreshToken  = 'refresh_token';
  static const String kUserId        = 'user_id';
  static const String kOnboarded     = 'onboarded';
  static const String kUserData      = 'user_data';
  static const String kWalkthroughSeen = 'walkthrough_seen';


  // ── Pagination ────────────────────────────────────────
  static const int pageSize = 20;

  // ── Match ─────────────────────────────────────────────
  static const double maxBuddyDistanceKm = 50.0;
  static const int    dailySwipesFree    = 5;
  static const int    dailySwipesPro     = 999;

  // ── Chat tokens ───────────────────────────────────────
  static const int tokenPack10Price = 29;
  static const int tokenPack20Price = 49;
  static const int tokenPack50Price = 99;

  // ── Timeouts ──────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── Activities (mirrors backend constants) ────────────
  // Grouped by category for onboarding UI
  static const List<Map<String, dynamic>> activities = [
    // GYM & WEIGHTS
    {'id': 'gym',          'label': 'Gym',          'emoji': '🏋️', 'color': 0xFF0A84FF, 'category': 'Gym & Weights'},
    {'id': 'powerlifting', 'label': 'Powerlifting', 'emoji': '🏋️', 'color': 0xFF0A84FF, 'category': 'Gym & Weights'},
    {'id': 'bodybuilding', 'label': 'Bodybuilding', 'emoji': '💪',  'color': 0xFFB57BFF, 'category': 'Gym & Weights'},
    {'id': 'kettlebell',   'label': 'Kettlebell',   'emoji': '🔔',  'color': 0xFFFFB547, 'category': 'Gym & Weights'},
    // CARDIO & ENDURANCE
    {'id': 'running',      'label': 'Running',      'emoji': '🏃',  'color': 0xFF4DAAFF, 'category': 'Cardio & Endurance'},
    {'id': 'cycling',      'label': 'Cycling',      'emoji': '🚴',  'color': 0xFFFFB547, 'category': 'Cardio & Endurance'},
    {'id': 'swimming',     'label': 'Swimming',     'emoji': '🏊',  'color': 0xFF0ABFCE, 'category': 'Cardio & Endurance'},
    {'id': 'rowing',       'label': 'Rowing',       'emoji': '🚣',  'color': 0xFF00CFA4, 'category': 'Cardio & Endurance'},
    {'id': 'triathlon',    'label': 'Triathlon',    'emoji': '🏊',  'color': 0xFF00D0A3, 'category': 'Cardio & Endurance'},
    // FUNCTIONAL FITNESS
    {'id': 'hyrox',        'label': 'Hyrox',        'emoji': '⚡',  'color': 0xFFB57BFF, 'category': 'Functional Fitness'},
    {'id': 'crossfit',     'label': 'CrossFit',     'emoji': '🔥',  'color': 0xFFFF5A6B, 'category': 'Functional Fitness'},
    {'id': 'calisthenics', 'label': 'Calisthenics', 'emoji': '🤸',  'color': 0xFF00D0A3, 'category': 'Functional Fitness'},
    {'id': 'hiit',         'label': 'HIIT',         'emoji': '💥',  'color': 0xFFFF6B35, 'category': 'Functional Fitness'},
    {'id': 'climbing',     'label': 'Climbing',     'emoji': '🧗',  'color': 0xFF00CFA4, 'category': 'Functional Fitness'},
    // COMBAT & FLEXIBILITY
    {'id': 'boxing',       'label': 'Boxing',       'emoji': '🥊',  'color': 0xFFFF6B35, 'category': 'Combat & Flexibility'},
    {'id': 'mma',          'label': 'MMA',          'emoji': '🥋',  'color': 0xFFFF5A6B, 'category': 'Combat & Flexibility'},
    {'id': 'yoga',         'label': 'Yoga',         'emoji': '🧘',  'color': 0xFFFF6B9D, 'category': 'Combat & Flexibility'},
    {'id': 'pilates',      'label': 'Pilates',      'emoji': '🩰',  'color': 0xFFFF6B9D, 'category': 'Combat & Flexibility'},
    // RACKET & OTHER
    {'id': 'tennis',       'label': 'Tennis',       'emoji': '🎾',  'color': 0xFF00D0A3, 'category': 'Racket & Other'},
    {'id': 'dance_fit',    'label': 'Dance Fitness','emoji': '💃',  'color': 0xFFB57BFF, 'category': 'Racket & Other'},
  ];

  // ── Activity categories (for grouped display in onboarding) ──
  static const List<String> activityCategories = [
    'Gym & Weights',
    'Cardio & Endurance',
    'Functional Fitness',
    'Combat & Flexibility',
    'Racket & Other',
  ];

  // ── Activity-specific recommended goals (Option A) ────
  // Key = activityId, Value = list of goal IDs to show as recommended
  static const Map<String, List<String>> activityGoals = {
    'gym':          ['muscle_gain', 'strength', 'weight_loss', 'general_fit'],
    'powerlifting': ['strength', 'pr_1rm', 'competition', 'muscle_gain'],
    'bodybuilding': ['muscle_gain', 'stage_ready', 'bulk_cut', 'competition'],
    'kettlebell':   ['strength', 'endurance', 'weight_loss', 'general_fit'],
    'running':      ['5k_complete', '10k_complete', 'half_marathon', 'full_marathon', 'speed_pr'],
    'cycling':      ['50km_ride', '100km_ride', 'speed_pr', 'endurance'],
    'swimming':     ['lap_time', 'endurance', 'general_fit'],
    'rowing':       ['endurance', 'strength', 'general_fit'],
    'triathlon':    ['sprint_tri', 'olympic_tri', 'ironman', 'endurance'],
    'hyrox':        ['sub60_hyrox', 'sub90_hyrox', 'competition', 'endurance'],
    'crossfit':     ['rx_workouts', 'competition', 'strength', 'endurance'],
    'calisthenics': ['muscle_gain', 'strength', 'flexibility', 'general_fit'],
    'hiit':         ['weight_loss', 'endurance', 'general_fit'],
    'climbing':     ['strength', 'flexibility', 'general_fit'],
    'boxing':       ['fight_ready', 'weight_loss', 'endurance', 'competition'],
    'mma':          ['fight_ready', 'competition', 'strength', 'endurance'],
    'yoga':         ['flexibility', 'consistency', 'general_fit'],
    'pilates':      ['flexibility', 'strength', 'general_fit'],
    'tennis':       ['sports_perf', 'endurance', 'competition'],
    'dance_fit':    ['weight_loss', 'endurance', 'consistency', 'general_fit'],
  };

  // ── Experience Levels ─────────────────────────────────
  static const List<Map<String, String>> levels = [
    {'id': 'beginner',     'label': 'Beginner',     'desc': '< 1 year'},
    {'id': 'intermediate', 'label': 'Intermediate', 'desc': '1–3 years'},
    {'id': 'advanced',     'label': 'Advanced',     'desc': '3–5 years'},
    {'id': 'elite',        'label': 'Elite',        'desc': '5+ years'},
  ];

  // ── Goals — common + activity-specific ───────────────
  // Common goals (always shown)
  static const List<Map<String, String>> goals = [
    // Common
    {'id': 'weight_loss',    'label': 'Weight Loss',     'emoji': '⚡'},
    {'id': 'muscle_gain',    'label': 'Muscle Gain',     'emoji': '💪'},
    {'id': 'endurance',      'label': 'Endurance',       'emoji': '🏃'},
    {'id': 'strength',       'label': 'Strength',        'emoji': '🏋️'},
    {'id': 'flexibility',    'label': 'Flexibility',     'emoji': '🧘'},
    {'id': 'general_fit',    'label': 'General Fitness', 'emoji': '❤️'},
    {'id': 'competition',    'label': 'Competition',     'emoji': '🥇'},
    {'id': 'consistency',    'label': 'Consistency',     'emoji': '📅'},
    {'id': 'sports_perf',    'label': 'Sports Perf.',    'emoji': '🏆'},
    // Running specific
    {'id': '5k_complete',    'label': '5K Complete',     'emoji': '🏃'},
    {'id': '10k_complete',   'label': '10K Complete',    'emoji': '🏃'},
    {'id': 'half_marathon',  'label': 'Half Marathon',   'emoji': '🏅'},
    {'id': 'full_marathon',  'label': 'Full Marathon',   'emoji': '🏅'},
    {'id': 'speed_pr',       'label': 'Speed PR',        'emoji': '⚡'},
    // Cycling
    {'id': '50km_ride',      'label': '50km Ride',       'emoji': '🚴'},
    {'id': '100km_ride',     'label': '100km Ride',      'emoji': '🚴'},
    // Powerlifting / Bodybuilding
    {'id': 'pr_1rm',         'label': '1RM PR',          'emoji': '🏋️'},
    {'id': 'stage_ready',    'label': 'Stage Ready',     'emoji': '💪'},
    {'id': 'bulk_cut',       'label': 'Bulk / Cut',      'emoji': '📊'},
    // Hyrox / CrossFit
    {'id': 'sub60_hyrox',    'label': 'Sub 60 Hyrox',    'emoji': '⚡'},
    {'id': 'sub90_hyrox',    'label': 'Sub 90 Hyrox',    'emoji': '⚡'},
    {'id': 'rx_workouts',    'label': 'RX Workouts',     'emoji': '🔥'},
    // Combat
    {'id': 'fight_ready',    'label': 'Fight Ready',     'emoji': '🥊'},
    // Triathlon
    {'id': 'sprint_tri',     'label': 'Sprint Tri',      'emoji': '🏊'},
    {'id': 'olympic_tri',    'label': 'Olympic Tri',     'emoji': '🏊'},
    {'id': 'ironman',        'label': 'Ironman',         'emoji': '🏆'},
    // Swimming
    {'id': 'lap_time',       'label': 'Lap Time PR',     'emoji': '🏊'},
  ];

  // ── XP Rewards ────────────────────────────────────────
  static const Map<String, int> xpRewards = {
    'session_uploaded':  50,
    'buddy_matched':     30,
    'streak_7':         100,
    'streak_30':        500,
    'profile_complete':  25,
    'first_checkin':     20,
  };

  // ── Level Thresholds ──────────────────────────────────
  static const List<int>    levelThresholds = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5500];
  static const List<String> levelNames      = ['Newbie', 'Rookie', 'Regular', 'Athlete', 'Pro', 'Elite', 'Champion', 'Legend', 'Icon', 'GOAT'];
}
