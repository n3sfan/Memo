class ImageCompressionLimits {
  const ImageCompressionLimits({
    required this.maxWidth,
    required this.maxHeight,
    required this.maxBytes,
  });

  final int maxWidth;
  final int maxHeight;
  final int maxBytes;
}
