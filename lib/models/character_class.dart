class CharacterClass {
  final String id;
  final String name;
  final String walkingAsset;
  final List<String> attackAssets;
  final String selectionSlogan;

  const CharacterClass({
    required this.id,
    required this.name,
    required this.walkingAsset,
    required this.attackAssets,
    required this.selectionSlogan,
  });

  String get attackAsset => attackAssets.first;
}
