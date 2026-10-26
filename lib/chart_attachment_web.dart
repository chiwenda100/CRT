import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String> saveChartImage(XFile image, String tradeId) async {
  final bytes = await image.readAsBytes();
  if (bytes.length > 3 * 1024 * 1024) {
    throw StateError('Choose a chart screenshot smaller than 3 MB.');
  }
  final mimeType = image.mimeType ?? 'image/jpeg';
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Future<void> deleteChartImage(String path) async {}

class ChartAttachmentImage extends StatelessWidget {
  const ChartAttachmentImage({
    required this.imagePath,
    required this.height,
    required this.width,
    super.key,
  });

  final String imagePath;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final separator = imagePath.indexOf(',');
    if (!imagePath.startsWith('data:') || separator < 0) {
      return SizedBox(
        height: height,
        width: width,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      );
    }
    final Uint8List bytes;
    try {
      bytes = base64Decode(imagePath.substring(separator + 1));
    } on FormatException {
      return SizedBox(
        height: height,
        width: width,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      );
    }
    return Image.memory(bytes, height: height, width: width, fit: BoxFit.cover);
  }
}
