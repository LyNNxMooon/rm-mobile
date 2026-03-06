class FilterCriteria {
  final String? dept;
  final String? cat1;
  final String? cat2;
  final String? cat3;
  final String? supplier;
  final String? custom1;
  final String? custom2;
  final String? state;
  final String? suburb;
  final String? postcode;

  FilterCriteria({
    this.dept,
    this.cat1,
    this.cat2,
    this.cat3,
    this.supplier,
    this.custom1,
    this.custom2,
    this.state,
    this.suburb,
    this.postcode,
  });

  // Helper to check if any filter is active
  bool get hasFilters =>
      dept != null ||
      cat1 != null ||
      cat2 != null ||
      cat3 != null ||
      (supplier != null && supplier!.isNotEmpty) ||
      (custom1 != null && custom1!.isNotEmpty) ||
      (custom2 != null && custom2!.isNotEmpty) ||
      (state != null && state!.isNotEmpty) ||
      (suburb != null && suburb!.isNotEmpty) ||
      (postcode != null && postcode!.isNotEmpty);
}
