import '../../../local_db/local_db_dao.dart';
import '../../../local_db/sqlite/sqlite_constants.dart';
import '../domain/repositories/onboarding_repo.dart';

class OnboardingModels implements OnboardingRepo {
  @override
  Future<bool> getTermsAccepted() async {
    try {
      final String? value = await LocalDbDAO.instance.getAppConfig(
        kTermsAcceptedKey,
      );
      return value == "1";
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> setTermsAccepted(bool accepted) async {
    try {
      await LocalDbDAO.instance.saveAppConfig(
        kTermsAcceptedKey,
        accepted ? "1" : "0",
      );
    } catch (e) {
      return Future.error(e);
    }
  }
}
