import 'package:flutter/material.dart';
import 'package:musemend/app/theme/muse_colors.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MuseColors.lavender,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.collections_bookmark_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Bộ sưu tập',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tỉnh, địa danh, món ăn và vật phẩm đã mở khóa sẽ xuất hiện tại đây.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
