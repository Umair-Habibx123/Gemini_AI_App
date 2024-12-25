import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ImagePreviewList extends StatelessWidget {
  final List<XFile> images;
  final void Function(int) onRemoveImage;

  const ImagePreviewList({super.key, required this.images, required this.onRemoveImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2B2D42), // Updated background to a modern dark theme.
      height: 85, // Slightly increased height for better visuals.
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              children: [
                // Image Container
                ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Rounded corners.
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 3), // Subtle shadow for depth.
                        ),
                      ],
                    ),
                    child: Image.file(
                      File(images[index].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Remove Button
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: const BoxDecoration(
                        color: Colors.black54, // Semi-transparent black background.
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onRemoveImage(index),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

