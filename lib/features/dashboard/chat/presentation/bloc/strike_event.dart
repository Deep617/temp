// ─────────────────────────────────────────────────────────
//  bloc/strike/strike_event.dart
// ─────────────────────────────────────────────────────────
part of 'strike_bloc.dart';

abstract class StrikeEvent extends Equatable {
  const StrikeEvent();
  @override List<Object?> get props => [];
}

// Load pending strikes + streak for a match
class StrikeLoadRequested extends StrikeEvent {
  const StrikeLoadRequested({   this.matchId,   this.buddyId });
  final String? matchId;
  final String? buddyId;
  @override List<Object?> get props => [matchId, buddyId];
}

// User taps ⚡ in chat → open camera page
class StrikeCameraOpened extends StrikeEvent {
  const StrikeCameraOpened();
}

// User swipes back or taps X → close camera
class StrikeCameraClosed extends StrikeEvent {
  const StrikeCameraClosed();
}

// User captures photo (File path)
class StrikePhotoCaptured extends StrikeEvent {
  const StrikePhotoCaptured({ required this.imagePath });
  final String imagePath;
  @override List<Object?> get props => [imagePath];
}

// User clears preview (retake)
class StrikePreviewCleared extends StrikeEvent {
  const StrikePreviewCleared();
}

// User sets caption
class StrikeCaptionChanged extends StrikeEvent {
  const StrikeCaptionChanged({ required this.caption });
  final String caption;
  @override List<Object?> get props => [caption];
}

// User taps "Send Strike"
class StrikeSendRequested extends StrikeEvent {
  const StrikeSendRequested({
    required this.matchId,
    required this.receiverId,
    required this.imageFile,
    this.caption,
  });
  final String  matchId;
  final String  receiverId;
  final dynamic imageFile; // File
  final String? caption;
  @override List<Object?> get props => [matchId, receiverId, caption];
}

// User taps Strike card in chat → view it
class StrikeViewRequested extends StrikeEvent {
  const StrikeViewRequested({ required this.strikeId });
  final String strikeId;
  @override List<Object?> get props => [strikeId];
}

// User reacts to a Strike with emoji
class StrikeReactionSent extends StrikeEvent {
  const StrikeReactionSent({ required this.strikeId, required this.emoji });
  final String strikeId;
  final String emoji;
  @override List<Object?> get props => [strikeId, emoji];
}

// Reset after send success (go back to chat)
class StrikeReset extends StrikeEvent {
  const StrikeReset();
}
