class NetworkServerVO {
  final String ipAddress;
  final String? hostName;
  final int? port;

  const NetworkServerVO({
    required this.ipAddress,
    required this.hostName,
    this.port,
  });
}
