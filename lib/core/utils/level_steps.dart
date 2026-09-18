import 'dart:math';

/// Step cost from the current level to the next, rounded to the nearest 50.
/// There is no level cap. Invalid legacy inputs are treated as level one.
int calculateRequiredSteps(int currentLevel) {
  final level = max(1, currentLevel);
  final rawValue = 500 * pow(1 + log(level), 1.5);
  return (rawValue / 50).round() * 50;
}
