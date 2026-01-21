class FilterCriteria {
  final String? dept;
  final String? cat1;
  final String? cat2;
  final String? cat3;
  final String? supplier;
  final String? custom1;
  final String? custom2;

  FilterCriteria({
    this.dept,
    this.cat1,
    this.cat2,
    this.cat3,
    this.supplier,
    this.custom1,
    this.custom2,
  });

  // Helper to check if any filter is active
  bool get hasFilters =>
      dept != null ||
      cat1 != null ||
      cat2 != null ||
      cat3 != null ||
      (supplier != null && supplier!.isNotEmpty) ||
      (custom1 != null && custom1!.isNotEmpty) ||
      (custom2 != null && custom2!.isNotEmpty);
}
