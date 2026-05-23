import 'package:flutter/material.dart';
import 'base64_image.dart';

class TravelImagePlaceholder extends StatefulWidget {
  final String imageUrl;
  final List<String>? images;
  final IconData icon;
  final List<Color> colors;

  const TravelImagePlaceholder({
    super.key,
    required this.imageUrl,
    this.images,
    required this.icon,
    required this.colors,
  });

  @override
  State<TravelImagePlaceholder> createState() => TravelImagePlaceholderState();
}

class TravelImagePlaceholderState extends State<TravelImagePlaceholder> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = (widget.images != null && widget.images!.isNotEmpty)
        ? widget.images!
        : (widget.imageUrl.trim().isNotEmpty ? [widget.imageUrl] : <String>[]);

    if (displayImages.isNotEmpty) {
      if (displayImages.length == 1) {
        return Base64Image(
          base64String: displayImages.first,
          fit: BoxFit.cover,
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: displayImages.length,
            itemBuilder: (context, index) {
              return Base64Image(
                base64String: displayImages[index],
                fit: BoxFit.cover,
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentIndex == index ? 6 : 4,
                  height: _currentIndex == index ? 6 : 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withAlpha(128),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(widget.icon, color: Colors.white.withAlpha(210), size: 54),
      ),
    );
  }
}
