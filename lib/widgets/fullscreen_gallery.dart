import 'dart:convert';
import 'package:flutter/material.dart';

/// Full-screen image gallery viewer.
/// Pass [images] as base64 strings and [initialIndex] to start from.
class FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late final PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Image PageView ──────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.images.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(
                  base64Decode(widget.images[i]),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 72,
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Close
                  _pill(
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  // Counter
                  if (widget.images.length > 1)
                    _pill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(
                          '${_index + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Dot indicators (bottom) ──────────────────────────────────
          if (widget.images.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == i ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? Colors.white
                          : Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
        ),
        child: child,
      ),
    );
  }
}

/// Pushes a [FullscreenGallery] modal route.
void openFullscreenGallery(
  BuildContext context,
  List<String> images, {
  int initialIndex = 0,
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => FullscreenGallery(
        images: images,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
