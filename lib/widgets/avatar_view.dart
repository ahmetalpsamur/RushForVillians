import 'package:flutter/material.dart';

import '../models/avatar_profile.dart';

class AvatarView extends StatelessWidget {
  final AvatarProfile avatar;
  final double size;
  final bool showBackground;

  const AvatarView({
    super.key,
    required this.avatar,
    this.size = 180,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          showBackground
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.14),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF39325E), Color(0xFF171521)],
                ),
                border: Border.all(color: Colors.white12),
              )
              : null,
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        avatar.characterAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder:
            (_, _, _) => const Center(
              child: Icon(
                Icons.person_off_outlined,
                size: 52,
                color: Colors.white54,
              ),
            ),
      ),
    );
  }
}
