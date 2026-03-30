import '../entities/vos/tax_code_vo.dart';
import '../local_db/local_db_dao.dart';
import '../utils/global_var_utils.dart';

/// Result of tax calculation containing both exclusive and inclusive prices
class TaxCalculationResult {
  final double exPrice;
  final double incPrice;
  final double taxAmount;
  final String taxCode;
  final double percentage;
  final int taxType;

  TaxCalculationResult({
    required this.exPrice,
    required this.incPrice,
    required this.taxAmount,
    required this.taxCode,
    required this.percentage,
    required this.taxType,
  });

  /// Creates a result with no tax applied
  factory TaxCalculationResult.noTax(double price) {
    return TaxCalculationResult(
      exPrice: price,
      incPrice: price,
      taxAmount: 0,
      taxCode: '',
      percentage: 0,
      taxType: 0,
    );
  }
}

/// Utility for calculating tax based on tax codes stored in local database
class TaxCalculationUtils {
  TaxCalculationUtils._();

  /// Calculate tax for a given price using the specified tax code.
  /// 
  /// [basePrice] - The price from stock (could be ex or inc depending on tax_type)
  /// [taxCodeString] - The tax code string (e.g., "GST", "FRE")
  /// [shopfront] - The shopfront to look up tax codes for
  /// 
  /// Returns a [TaxCalculationResult] with both ex and inc prices.
  /// 
  /// Logic:
  /// - If tax_type == 0 or 1: basePrice is Ex-tax, calculate Inc = Ex * (1 + percentage/100)
  /// - If tax_type >= 2: basePrice is Inc-tax, calculate Ex = Inc / (1 + percentage/100)
  static Future<TaxCalculationResult> calculateTax({
    required double basePrice,
    required String? taxCodeString,
    String? shopfront,
  }) async {
    final shop = shopfront ?? AppGlobals.instance.shopfront ?? '';
    
    // If no tax code provided, return no tax
    if (taxCodeString == null || taxCodeString.isEmpty) {
      return TaxCalculationResult.noTax(basePrice);
    }

    // Look up tax code in local database
    final taxCode = await LocalDbDAO.instance.getTaxCodeByCode(
      taxCodeString,
      shop,
    );

    // If tax code not found, return no tax
    if (taxCode == null) {
      return TaxCalculationResult.noTax(basePrice);
    }

    return _calculateFromTaxCode(basePrice, taxCode);
  }

  /// Calculate tax using an already loaded TaxCodeVO
  static TaxCalculationResult _calculateFromTaxCode(
    double basePrice,
    TaxCodeVO taxCode,
  ) {
    final percentage = taxCode.percentage;
    
    // If percentage is 0, no tax to calculate
    if (percentage == 0) {
      return TaxCalculationResult(
        exPrice: basePrice,
        incPrice: basePrice,
        taxAmount: 0,
        taxCode: taxCode.code,
        percentage: 0,
        taxType: taxCode.taxType,
      );
    }

    final multiplier = 1 + (percentage / 100);

    double exPrice;
    double incPrice;
    double taxAmount;

    if (taxCode.taxType == 0 || taxCode.taxType == 1) {
      // tax_type == 0 or 1: basePrice is Ex-tax (exclusive)
      // Calculate inclusive price
      exPrice = basePrice;
      incPrice = basePrice * multiplier;
      taxAmount = incPrice - exPrice;
    } else {
      // tax_type >= 2: basePrice is Inc-tax (inclusive)
      // Calculate exclusive price
      incPrice = basePrice;
      exPrice = basePrice / multiplier;
      taxAmount = incPrice - exPrice;
    }

    return TaxCalculationResult(
      exPrice: exPrice,
      incPrice: incPrice,
      taxAmount: taxAmount,
      taxCode: taxCode.code,
      percentage: percentage,
      taxType: taxCode.taxType,
    );
  }

  /// Calculate tax for stock cost (uses goods_tax)
  /// Falls back to default stock (stockID = 0) if goods_tax is empty
  static Future<TaxCalculationResult> calculateCostTax({
    required double cost,
    required String? goodsTax,
    String? shopfront,
  }) async {
    String? taxCode = goodsTax;
    
    // If empty, try to get from default stock (stockID = 0)
    if (taxCode == null || taxCode.isEmpty) {
      taxCode = await _getDefaultStockTaxCode(
        isGoodsTax: true,
        shopfront: shopfront,
      );
    }

    return calculateTax(
      basePrice: cost,
      taxCodeString: taxCode,
      shopfront: shopfront,
    );
  }

  /// Calculate tax for stock sell price (uses sales_tax)
  /// Falls back to default stock (stockID = 0) if sales_tax is empty
  static Future<TaxCalculationResult> calculateSellTax({
    required double sell,
    required String? salesTax,
    String? shopfront,
  }) async {
    String? taxCode = salesTax;
    
    // If empty, try to get from default stock (stockID = 0)
    if (taxCode == null || taxCode.isEmpty) {
      taxCode = await _getDefaultStockTaxCode(
        isGoodsTax: false,
        shopfront: shopfront,
      );
    }

    return calculateTax(
      basePrice: sell,
      taxCodeString: taxCode,
      shopfront: shopfront,
    );
  }

  /// Get tax code from default stock (stockID = 0)
  static Future<String?> _getDefaultStockTaxCode({
    required bool isGoodsTax,
    String? shopfront,
  }) async {
    final shop = shopfront ?? AppGlobals.instance.shopfront ?? '';
    if (shop.isEmpty) return null;

    try {
      final defaultStock = await LocalDbDAO.instance.getStockById(0, shop);
      if (defaultStock == null) return null;
      
      return isGoodsTax ? defaultStock.goodsTax : defaultStock.salesTax;
    } catch (_) {
      return null;
    }
  }

  /// Synchronous calculation when TaxCodeVO is already available
  static TaxCalculationResult calculateFromTaxCode(
    double basePrice,
    TaxCodeVO taxCode,
  ) {
    return _calculateFromTaxCode(basePrice, taxCode);
  }

  /// Calculate inclusive price from exclusive price
  static double calculateInclusivePrice(double exPrice, double percentage) {
    return exPrice * (1 + percentage / 100);
  }

  /// Calculate exclusive price from inclusive price
  static double calculateExclusivePrice(double incPrice, double percentage) {
    return incPrice / (1 + percentage / 100);
  }
}
