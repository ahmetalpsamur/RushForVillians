enum TutorialGuideVariant {
  mavili(
    id: 'mavili',
    label: 'Mavili',
    description: 'Sakin, cesur ve güvenilir.',
    folder: 'Mavili',
    assetPrefix: 'Dude_Monster',
  ),
  pinky(
    id: 'pinky',
    label: 'Pinky',
    description: 'Neşeli, hızlı ve meraklı.',
    folder: 'Pinky',
    assetPrefix: 'Pink_Monster',
  ),
  kupkuzu(
    id: 'kupkuzu',
    label: 'Küpkuzu',
    description: 'Küçük, bilge ve gözü pek.',
    folder: 'Kupkuzu',
    assetPrefix: 'Owlet_Monster',
  );

  final String id;
  final String label;
  final String description;
  final String folder;
  final String assetPrefix;

  const TutorialGuideVariant({
    required this.id,
    required this.label,
    required this.description,
    required this.folder,
    required this.assetPrefix,
  });

  String get assetBase => 'lib/Tutorial_Guy/$folder/$assetPrefix';
  String get idleAsset => '${assetBase}_Idle_4.gif';

  static TutorialGuideVariant fromId(String? id) {
    for (final guide in values) {
      if (guide.id == id) return guide;
    }
    return mavili;
  }
}
