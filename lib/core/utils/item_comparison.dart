import '../../models/item.dart';
import '../../models/item_effect.dart';

/// İki item arasındaki tek bir stat farkı.
///
/// Envanterde "kuşansam ne değişir" sorusunun cevabı bu satırlardan kurulur:
/// `+8 saldırı`, `-%3 savunma`.
class ItemStatDelta {
  final ItemStat stat;
  final ItemEffectMode mode;

  /// Aday item eksi mevcut item. Sıfır olan farklar üretilmez.
  final double delta;

  const ItemStatDelta({
    required this.stat,
    required this.mode,
    required this.delta,
  });

  /// Fark oyuncunun lehine mi.
  ///
  /// [ItemStatX.isReduction] statlarında (seri eşiği) **artış** iyidir, çünkü
  /// alan değer eşikten düşülüyor; diğerlerinde artış iyidir zaten. Tek
  /// istisna yok gibi görünse de ayrım burada açık tutuluyor: ileride
  /// "eksildikçe iyileşen" bir stat eklenirse tek yer burası.
  bool get isGain => delta > 0;

  /// Kullanıcıya gösterilen satır: `+8 saldırı`, `-%3 savunma`.
  String get label {
    final magnitude = delta.abs();
    if (mode == ItemEffectMode.percent) {
      final sign = delta > 0 ? '+' : '-';
      return '$sign%${ItemEffect.formatPercent(magnitude)} ${stat.label}';
    }
    final rounded = magnitude.round();
    if (stat.isReduction) {
      // Eşik **düştükçe** iyileşiyor: artı bir fark eksi olarak yazılır,
      // [ItemEffect] etiketleriyle aynı okuma.
      final sign = delta > 0 ? '-' : '+';
      return '${stat.label} $sign$rounded${stat.flatUnit}';
    }
    return '+$rounded ${stat.label}${stat.flatUnit}'.replaceFirst(
      '+',
      delta > 0 ? '+' : '-',
    );
  }

  @override
  String toString() => label;
}

/// Aday item ile o slotta kuşanılı olan item arasındaki farklar.
///
/// Yalnızca **koşulsuz** etkiler ([ItemEffect.isPassive]) karşılaştırılır:
/// koşullu bir etkiyi sayıya indirgeyip "+%40 saldırı" demek yanıltıcı olurdu.
/// Koşullu etkilerin kazancı ve kaybı ayrı listelenir
/// ([ItemComparison.gainedConditions] / [ItemComparison.lostConditions]).
///
/// [current] `null` ise slot boş demektir: adayın bütün etkileri kazanç olur.
ItemComparison compareItems({required Item candidate, Item? current}) {
  final candidateTotals = _passiveTotals(candidate);
  final currentTotals = current == null ? _empty() : _passiveTotals(current);

  final deltas = <ItemStatDelta>[];
  for (final stat in ItemStat.values) {
    for (final mode in ItemEffectMode.values) {
      final key = (stat, mode);
      final delta = (candidateTotals[key] ?? 0) - (currentTotals[key] ?? 0);
      if (delta.abs() < 1e-9) continue;
      deltas.add(ItemStatDelta(stat: stat, mode: mode, delta: delta));
    }
  }

  final candidateConditions = _conditionLabels(candidate);
  final currentConditions =
      current == null ? <String>{} : _conditionLabels(current);

  return ItemComparison(
    deltas: deltas,
    gainedConditions:
        candidateConditions.difference(currentConditions).toList()..sort(),
    lostConditions:
        currentConditions.difference(candidateConditions).toList()..sort(),
  );
}

/// [compareItems] sonucu.
class ItemComparison {
  /// Sayısal farklar. Boşsa iki item koşulsuz etkiler açısından denk.
  final List<ItemStatDelta> deltas;

  /// Adayın getirdiği, mevcutta olmayan koşullu/tetiklenen etkiler.
  final List<String> gainedConditions;

  /// Adaya geçince kaybedilecek koşullu/tetiklenen etkiler.
  final List<String> lostConditions;

  const ItemComparison({
    required this.deltas,
    required this.gainedConditions,
    required this.lostConditions,
  });

  static const none = ItemComparison(
    deltas: [],
    gainedConditions: [],
    lostConditions: [],
  );

  bool get isEmpty =>
      deltas.isEmpty && gainedConditions.isEmpty && lostConditions.isEmpty;

  /// Kazanç satırları (önce), sonra kayıp satırları. Sıra kararlı.
  List<ItemStatDelta> get ordered => [
    ...deltas.where((delta) => delta.isGain),
    ...deltas.where((delta) => !delta.isGain),
  ];
}

Map<(ItemStat, ItemEffectMode), double> _empty() => {};

Map<(ItemStat, ItemEffectMode), double> _passiveTotals(Item item) {
  final totals = <(ItemStat, ItemEffectMode), double>{};
  for (final effect in item.buff.effects) {
    if (!effect.isPassive) continue;
    final key = (effect.stat, effect.mode);
    totals[key] = (totals[key] ?? 0) + effect.value;
  }
  return totals;
}

Set<String> _conditionLabels(Item item) => {
  for (final effect in item.buff.effects)
    if (!effect.isPassive) effect.label,
};
