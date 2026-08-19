import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Ödüllerin nadirlik seviyesi. Görev performansına göre belirlenir
/// (ör. hedefin ne kadar üstüne çıkıldığı, kalori hedefinin tutturulup
/// tutturulmadığı vb.).
enum RewardRarity { common, uncommon, rare, epic, legendary }

extension RewardRarityX on RewardRarity {
  String get label => switch (this) {
    RewardRarity.common => 'Sıradan',
    RewardRarity.uncommon => 'Az Bulunur',
    RewardRarity.rare => 'Nadir',
    RewardRarity.epic => 'Epik',
    RewardRarity.legendary => 'Efsanevi',
  };

  Color get color => switch (this) {
    RewardRarity.common => AppColors.rarityCommon,
    RewardRarity.uncommon => AppColors.rarityUncommon,
    RewardRarity.rare => AppColors.rarityRare,
    RewardRarity.epic => AppColors.rarityEpic,
    RewardRarity.legendary => AppColors.rarityLegendary,
  };
}
