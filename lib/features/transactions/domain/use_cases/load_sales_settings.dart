import '../../../../local_db/local_db_dao.dart';
import '../../../../local_db/sqlite/sqlite_constants.dart';

/// Result containing all sales settings
class SalesSettingsResult {
  final bool scanIndividualUnits;
  final bool skipSellPrice;
  final bool promptForEmailAtSale;
  final bool autoRemindLowStock;
  final bool preventAddIfNoStock;
  final bool preventFinaliseIfOutOfStock;
  final bool displayCustomerMessagesAsPrompt;
  final bool scanIndividualUnitsForFractional;
  final bool promptScanIndividualFractional;

  SalesSettingsResult({
    required this.scanIndividualUnits,
    required this.skipSellPrice,
    required this.promptForEmailAtSale,
    required this.autoRemindLowStock,
    required this.preventAddIfNoStock,
    required this.preventFinaliseIfOutOfStock,
    required this.displayCustomerMessagesAsPrompt,
    required this.scanIndividualUnitsForFractional,
    required this.promptScanIndividualFractional,
  });
}

/// Use case for loading all sales settings
class LoadSalesSettings {
  /// Load all sales settings from local database
  Future<SalesSettingsResult> call() async {
    final scanIndividualUnits = await LocalDbDAO.instance.getAppConfig(
      kSalesScanIndividualUnitsKey,
    );
    final skipSellPrice = await LocalDbDAO.instance.getAppConfig(
      kSalesSkipSellPriceKey,
    );
    final promptForEmail = await LocalDbDAO.instance.getAppConfig(
      kSalesPromptForEmailKey,
    );
    final autoRemindLowStock = await LocalDbDAO.instance.getAppConfig(
      kSalesAutoRemindLowStockKey,
    );
    final preventAddIfNoStock = await LocalDbDAO.instance.getAppConfig(
      kSalesPreventAddIfNoStockKey,
    );
    final preventFinaliseIfOutOfStock = await LocalDbDAO.instance.getAppConfig(
      kSalesPreventFinaliseIfOutOfStockKey,
    );
    final displayCustomerMessages = await LocalDbDAO.instance.getAppConfig(
      kSalesDisplayCustomerMessagesKey,
    );
    final scanIndividualUnitsForFractional = await LocalDbDAO.instance.getAppConfig(
      kSalesScanIndividualUnitsForFractionalKey,
    );
    final promptScanIndividualFractional = await LocalDbDAO.instance.getAppConfig(
      kSalesPromptScanIndividualFractionalKey,
    );

    return SalesSettingsResult(
      scanIndividualUnits: scanIndividualUnits == 'true',
      skipSellPrice: skipSellPrice == 'true',
      promptForEmailAtSale: promptForEmail == 'true',
      autoRemindLowStock: autoRemindLowStock == 'true',
      preventAddIfNoStock: preventAddIfNoStock == 'true',
      preventFinaliseIfOutOfStock: preventFinaliseIfOutOfStock == 'true',
      displayCustomerMessagesAsPrompt: displayCustomerMessages == 'true',
      scanIndividualUnitsForFractional: scanIndividualUnitsForFractional == 'true',
      promptScanIndividualFractional: promptScanIndividualFractional == 'true',
    );
  }
}
