class SyncMetadata {
  final int count;
  final int minId;
  final int maxId;
  final int checksum;

  const SyncMetadata({
    required this.count,
    required this.minId,
    required this.maxId,
    required this.checksum,
  });

  bool matches(SyncMetadata other) {
    return count == other.count &&
        minId == other.minId &&
        maxId == other.maxId &&
        checksum == other.checksum;
  }
}
