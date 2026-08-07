class AvatarProfile {
  final String name;
  final int age;
  final int weight;
  final String gender;
  final String characterClass;
  final String characterAsset;

  const AvatarProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.gender,
    required this.characterClass,
    required this.characterAsset,
  });

  static const classLabels = {
    'Archer': 'Okçu',
    'DarkMagic': 'Kara Büyücü',
    'Faith': 'İnanç Şövalyesi',
    'Magic': 'Büyücü',
    'Nature': 'Doğa Muhafızı',
    'Paladin': 'Paladin',
    'SwordMan': 'Kılıç Ustası',
    'Thief': 'Hırsız',
  };

  String get characterClassLabel =>
      classLabels[characterClass] ?? characterClass;

  Map<String, Object> toJson() => {
    'name': name,
    'age': age,
    'weight': weight,
    'gender': gender,
    'characterClass': characterClass,
    'characterAsset': characterAsset,
  };

  factory AvatarProfile.fromJson(Map<String, dynamic> json) {
    return AvatarProfile(
      name: json['name'] as String,
      age: json['age'] as int,
      weight: json['weight'] as int,
      gender: json['gender'] as String,
      characterClass: json['characterClass'] as String,
      characterAsset: json['characterAsset'] as String,
    );
  }
}
