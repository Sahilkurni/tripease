import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Base64Image extends StatefulWidget {
  final String? base64String;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final IconData fallbackIcon;

  const Base64Image({
    super.key,
    this.base64String,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.fallbackIcon = Icons.image_rounded,
  });

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  Uint8List? _bytes;
  String? _lastBase64;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.base64String != oldWidget.base64String) {
      _decode();
    }
  }

  void _decode() {
    if (widget.base64String == null || widget.base64String!.trim().isEmpty) {
      _bytes = null;
      _lastBase64 = widget.base64String;
      return;
    }
    try {
      final String cleanBase64 = widget.base64String!.replaceAll(RegExp(r'\s+'), '');
      _bytes = base64Decode(cleanBase64);
      _lastBase64 = widget.base64String;
    } catch (e) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return _buildFallback();
    }

      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        cacheWidth: widget.cacheWidth,
        cacheHeight: widget.cacheHeight,
        gaplessPlayback: true,
        filterQuality: FilterQuality.none, // Fastest possible rendering
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
  }

  Widget _buildFallback() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          widget.fallbackIcon,
          color: Colors.grey[400],
          size: (widget.width != null && widget.height != null)
              ? (widget.width! < widget.height! ? widget.width! / 2 : widget.height! / 2)
              : 40,
        ),
      ),
    );
  }
}
