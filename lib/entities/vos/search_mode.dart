enum SearchMode {
  partial,
  prefix;

  String get displayName {
    switch (this) {
      case SearchMode.partial:
        return 'Partial Search';
      case SearchMode.prefix:
        return 'Prefix Search';
    }
  }
}
