import '../repositories/onboarding_repo.dart';

class SetTermsAccepted {
  final OnboardingRepo repository;

  SetTermsAccepted(this.repository);

  Future<void> call(bool accepted) async {
    try {
      await repository.setTermsAccepted(accepted);
    } catch (e) {
      return Future.error("Failed to save terms acceptance: $e");
    }
  }
}
