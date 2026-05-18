// ignore_for_file: avoid_print

import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final inputPath = 'assets/images/appicon.png';
  final outputPath = 'assets/images/appicon_rounded.png';
  
  // Read the original image
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  final width = image.width;
  final height = image.height;
  
  // Corner radius as percentage of smaller dimension (20% gives nice rounded corners)
  final radius = (width < height ? width : height) * 0.20;
  
  // Create a new image with transparency
  final rounded = img.Image(width: width, height: height, numChannels: 4);
  
  // Copy pixels, making corners transparent
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (_isInsideRoundedRect(x, y, width, height, radius)) {
        rounded.setPixel(x, y, image.getPixel(x, y));
      } else {
        // Transparent pixel
        rounded.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  
  // Save the rounded image
  final pngBytes = img.encodePng(rounded);
  await File(outputPath).writeAsBytes(pngBytes);
  
  print('Rounded icon saved to: $outputPath');
  print('Now update pubspec.yaml to use appicon_rounded.png and run:');
  print('  dart run flutter_launcher_icons');
}

bool _isInsideRoundedRect(int x, int y, int width, int height, double radius) {
  // Check if point is in the main rectangle (excluding corners)
  if (x >= radius && x < width - radius) return true;
  if (y >= radius && y < height - radius) return true;
  
  // Check corners
  // Top-left corner
  if (x < radius && y < radius) {
    final dx = x - radius;
    final dy = y - radius;
    return dx * dx + dy * dy <= radius * radius;
  }
  
  // Top-right corner
  if (x >= width - radius && y < radius) {
    final dx = x - (width - radius);
    final dy = y - radius;
    return dx * dx + dy * dy <= radius * radius;
  }
  
  // Bottom-left corner
  if (x < radius && y >= height - radius) {
    final dx = x - radius;
    final dy = y - (height - radius);
    return dx * dx + dy * dy <= radius * radius;
  }
  
  // Bottom-right corner
  if (x >= width - radius && y >= height - radius) {
    final dx = x - (width - radius);
    final dy = y - (height - radius);
    return dx * dx + dy * dy <= radius * radius;
  }
  
  return false;
}
