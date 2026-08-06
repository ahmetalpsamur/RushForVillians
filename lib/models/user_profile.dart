import '../core/constants/game_constants.dart';

/// Oyuncunun genel ilerlemesi: can, seviye, XP, streak ve para birimi.
class UserProfile {
  final String name;
  int hp;
  int maxHp;
  int level;
  int xp;
  int coins;
  int streakDays;
  DateTime? lastActiveDay;

  UserProfile({
    required this.name,
    int? hp,
    int? maxHp,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.streakDays = 0,
    this.lastActiveDay,
  }) : hp = hp ?? GameConstants.baseHp,
       maxHp = maxHp ?? GameConstants.baseHp;

  /// Bir sonraki seviyeye geçmek için gereken toplam XP.
  int get xpToNextLevel => GameConstants.baseXpPerLevel * level;

  double get xpProgress => (xp / xpToNextLevel).clamp(0, 1);

  double get hpProgress => (hp / maxHp).clamp(0, 1);

  /// XP ekler, gerekiyorsa seviye atlatır. Kaç seviye atlandığını döner.
  int addXp(int amount) {
    xp += amount;
    var levelsGained = 0;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      levelsGained++;
    }
    return levelsGained;
  }
}
