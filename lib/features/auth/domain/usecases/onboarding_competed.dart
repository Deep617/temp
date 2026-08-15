import '../repositories/auth_repository.dart';

class OnboardingCompeted {
  final AuthRepository repository;

  OnboardingCompeted(this.repository);

  Future<void> markWalkthroughSeen() {
    return repository.markWalkthroughSeen();
  }
}
