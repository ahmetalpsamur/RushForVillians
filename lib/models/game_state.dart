import 'daily_engagement.dart';
import '../core/utils/game_clock.dart';
import '../data/enemy_catalog.dart';
import 'adventure_quest.dart';
import 'avatar_profile.dart';
import 'daily_progress.dart';
import 'daily_step_record.dart';
import 'user_profile.dart';

/// Uygulama kapansa bile korunması gereken oyun durumunun tamamı.
///
/// Sınıf bilinçli olarak "verinin nerede saklandığından" bağımsızdır: dışarıya
/// yalnızca düz bir `Map<String, dynamic>` verir ve aynı haritadan geri okunur.
/// Bugün bu haritayı [GameStorage] SharedPreferences'a yazıyor; ileride
/// Firebase eklendiğinde aynı harita doğrudan bir Firestore dokümanı olarak
/// gönderilebilir ve yerel depo "cache" rolüne geçebilir — model katmanında
/// hiçbir şey değişmez.
///
/// Avatar burada tutulmaz; o [CharacterStorage] tarafından ayrıca saklanır ve
/// okuma sırasında dışarıdan verilir.
class GameState {
  final DailyEngagement? engagement;
  final UserProfile profile;
  final DailyProgress today;
  final AdventureQuest? adventure;
  final List<DailyStepRecord> stepHistory;

  const GameState({
    this.engagement,
    required this.profile,
    required this.today,
    this.adventure,
    this.stepHistory = const [],
  });

  Map<String, Object?> toJson() => {
    'engagement': engagement?.toJson(),
    'profile': profile.toJson(),
    'today': today.toJson(),
    'adventure': adventure?.toJson(),
    'stepHistory': stepHistory.map((record) => record.toJson()).toList(),
  };

  /// Eksik veya tanınmayan alanlar sessizce varsayılana düşer; bozuk kayıt
  /// yüzünden oyuncunun tüm ilerlemesi kaybolmasın diye tolerans yüksek tutuldu.
  factory GameState.fromJson(
    Map<String, dynamic> json, {
    required AvatarProfile avatar,
  }) {
    final profileJson = json['profile'];
    final profile = UserProfile.fromJson(
      profileJson is Map<String, dynamic> ? profileJson : const {},
      avatar: avatar,
    );

    final todayJson = json['today'];
    final today =
        todayJson is Map<String, dynamic>
            ? DailyProgress.fromJson(todayJson)
            : DailyProgress(date: GameClock.now());

    return GameState(
      engagement: DailyEngagement.fromJson(json['engagement']),
      profile: profile,
      today: today,
      adventure: _adventureFromJson(json['adventure']),
      stepHistory: _stepHistoryFromJson(json['stepHistory']),
    );
  }

  static List<DailyStepRecord> _stepHistoryFromJson(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(DailyStepRecord.fromJson)
        .toList();
  }

  /// Düşman kataloğu değişmiş ve kayıtlı kimlik artık yoksa macera atılır;
  /// oyuncunun kalıcı ilerlemesi (seviye, XP, para) korunur.
  static AdventureQuest? _adventureFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final enemyId = value['enemyId'];
    if (enemyId is! String) return null;
    final enemy = EnemyCatalog.byId(enemyId);
    if (enemy == null) return null;
    return AdventureQuest.fromJson(value, enemy: enemy);
  }
}
