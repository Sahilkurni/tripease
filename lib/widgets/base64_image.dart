import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Base64Image extends StatelessWidget {
  final String? base64String;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  const Base64Image({
    super.key,
    this.base64String,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = Icons.image_rounded,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.trim().isEmpty) {
      return _buildFallback();
    }

    try {
      final String cleanBase64 = base64String!.replaceAll(RegExp(r'\s+'), '');
      final Uint8List bytes = base64Decode(cleanBase64);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } catch (e) {
      return _buildFallback();
    }
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          fallbackIcon,
          color: Colors.grey[400],
          size: (width != null && height != null) ? (width! < height! ? width! / 2 : height! / 2) : 40,
        ),
      ),
    );
  }
}
