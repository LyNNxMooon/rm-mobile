import '../repositories/onboarding_repo.dart';

class GetTermsAccepted {
  final OnboardingRepo repository;

  GetTermsAccepted(this.repository);

  Future<bool> call() async {
    try {
      return await repository.getTermsAccepted();
    } catch (e) {
      return Future.error("Failed to load terms acceptance: $e");
    }
  }
}
