// ─────────────────────────────────────────────────────────
//  bloc/strike/strike_state.dart
// ─────────────────────────────────────────────────────────
part of 'strike_bloc.dart';

enum StrikeStatus {
  initial,
  loading,
  // Camera flow
  cameraOpen,
  photoPreview,
  sending,
  sent,
  // View flow
  viewing,
  // Error
  error,
}

class StrikeState extends Equatable {
  const StrikeState({
    this.status        = StrikeStatus.initial,
    this.streak        = 0,
    this.pendingCount  = 0,
    this.imagePath,
    this.caption       = '',
    this.errorMessage,
    this.viewingStrike,
  });

  final StrikeStatus status;
  final int          streak;        // Current buddy strike streak
  final int          pendingCount;  // Unviewed strikes from buddy
  final String?      imagePath;     // Captured photo path
  final String       caption;       // User typed caption
  final String?      errorMessage;
  final dynamic      viewingStrike; // BuddyStrike model when viewing

  bool get isCameraOpen   => status == StrikeStatus.cameraOpen;
  bool get hasPhoto       => imagePath != null;
  bool get isSending      => status == StrikeStatus.sending;
  bool get isSent         => status == StrikeStatus.sent;

  StrikeState copyWith({
    StrikeStatus? status,
    int?          streak,
    int?          pendingCount,
    String?       imagePath,
    String?       caption,
    String?       errorMessage,
    dynamic       viewingStrike,
    bool          clearImage = false,
    bool          clearError = false,
  }) => StrikeState(
    status:        status        ?? this.status,
    streak:        streak        ?? this.streak,
    pendingCount:  pendingCount  ?? this.pendingCount,
    imagePath:     clearImage    ? null : (imagePath ?? this.imagePath),
    caption:       caption       ?? this.caption,
    errorMessage:  clearError    ? null : (errorMessage ?? this.errorMessage),
    viewingStrike: viewingStrike ?? this.viewingStrike,
  );

  @override
  List<Object?> get props => [
    status, streak, pendingCount, imagePath, caption, errorMessage,
  ];
}
