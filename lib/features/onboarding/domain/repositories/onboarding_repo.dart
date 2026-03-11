abstract class OnboardingRepo {
  Future<bool> getTermsAccepted();
  Future<void> setTermsAccepted(bool accepted);
}
