enum UploadStatus { pending, uploading, failed, done }

class RetryQueueItem {
  const RetryQueueItem({
    required this.id,
    required this.status,
    this.nextAttemptAt,
  });

  final String id;
  final UploadStatus status;
  final DateTime? nextAttemptAt;
}

List<RetryQueueItem> selectRetryableItems(
  Iterable<RetryQueueItem> items,
  DateTime now,
) {
  return items.where((item) {
    final due = item.nextAttemptAt == null || !item.nextAttemptAt!.isAfter(now);
    return due &&
        (item.status == UploadStatus.pending ||
            item.status == UploadStatus.failed);
  }).toList(growable: false);
}
