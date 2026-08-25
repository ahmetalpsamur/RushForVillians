import 'package:flutter/material.dart';

/// 100x100 piksel karakter GIF'lerini tuvaldeki geniş şeffaf boşluktan
/// arındırılmış gibi göstermek için merkezden büyütür.
class PixelSprite extends StatelessWidget {
  final String asset;
  final double scale;
  final BoxFit fit;
  final Key? imageKey;
  final Offset offset;

  const PixelSprite({
    super.key,
    required this.asset,
    required this.scale,
    this.fit = BoxFit.contain,
    this.imageKey,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Image.asset(
            asset,
            key: imageKey,
            fit: fit,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
            gaplessPlayback: false,
            errorBuilder:
                (_, _, _) => const Center(
                  child: Icon(
                    Icons.person_off_outlined,
                    size: 52,
                    color: Colors.white54,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
