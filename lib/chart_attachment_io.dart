import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveChartImage(XFile image, String tradeId) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory(
    '${documents.path}${Platform.pathSeparator}chart_images',
  );
  await directory.create(recursive: true);
  final extension = image.name.contains('.')
      ? image.name.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
      : 'jpg';
  final path = '${directory.path}${Platform.pathSeparator}$tradeId.$extension';
  await image.saveTo(path);
  return path;
}

Future<void> deleteChartImage(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

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
  Widget build(BuildContext context) => Image.file(
    File(imagePath),
    height: height,
    width: width,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => SizedBox(
      height: height,
      width: width,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54),
      ),
    ),
  );
}
