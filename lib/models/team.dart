/// Takım üyesi ve o anki yürüyüş durumu.
class TeamMember {
  final String name;
  int steps;
  bool isWalkingNow;

  TeamMember({required this.name, this.steps = 0, this.isWalkingNow = false});
}

/// Takım: üyelerin birlikte, "yan yana" yürümesini gerektiren mod.
///
/// Gerçek uygulamada konum/zaman senkronu ile hesaplanacak; burada
/// demo amacıyla üyelerin `isWalkingNow` bayrağı üzerinden basitçe
/// hesaplanıyor.
class Team {
  final String name;
  final List<TeamMember> members;

  Team({required this.name, required this.members});

  bool get isWalkingSideBySide =>
      members.isNotEmpty && members.every((m) => m.isWalkingNow);

  int get totalSteps => members.fold(0, (sum, m) => sum + m.steps);
}
