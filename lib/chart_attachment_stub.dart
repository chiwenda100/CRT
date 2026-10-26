import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String> saveChartImage(XFile image, String tradeId) =>
    Future.error(UnsupportedError('Chart screenshots are not supported here.'));

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
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: width,
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white54),
    ),
  );
}
