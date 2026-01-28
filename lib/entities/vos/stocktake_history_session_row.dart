class StocktakeHistorySessionRow {
  final String sessionId;
  final String shopfront;
  final String mobileDeviceId;
  final String mobileDeviceName;
  final int totalStocks;
  final DateTime dateStarted;
  final DateTime dateEnded;
  final DateTime createdAt;

  StocktakeHistorySessionRow({
    required this.sessionId,
    required this.shopfront,
    required this.mobileDeviceId,
    required this.mobileDeviceName,
    required this.totalStocks,
    required this.dateStarted,
    required this.dateEnded,
    required this.createdAt,
  });

  factory StocktakeHistorySessionRow.fromMap(Map<String, dynamic> m) {
    return StocktakeHistorySessionRow(
      sessionId: m['session_id'].toString(),
      shopfront: m['shopfront'].toString(),
      mobileDeviceId: m['mobile_device_id'].toString(),
      mobileDeviceName: m['mobile_device_name'].toString(),
      totalStocks: (m['total_stocks'] as num).toInt(),
      dateStarted: DateTime.parse(m['date_started'].toString()),
      dateEnded: DateTime.parse(m['date_ended'].toString()),
      createdAt: DateTime.parse(m['created_at'].toString()),
    );
  }
}
