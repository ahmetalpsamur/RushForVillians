import 'dart:io';

void main() {
  final root = Directory('lib/Rewards');
  if (!root.existsSync()) {
    stderr.writeln('lib/Rewards bulunamadı.');
    exitCode = 1;
    return;
  }

  final paths =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll('\\', '/'))
          .where((path) => path.toLowerCase().endsWith('.png'))
          .toList()
        ..sort();

  final duplicatePaths = paths.toSet().length != paths.length;
  if (duplicatePaths || paths.length != 1244) {
    stderr.writeln(
      'Katalog üretilemedi: ${paths.length} PNG bulundu; 1244 bekleniyor.',
    );
    exitCode = 2;
    return;
  }

  final output =
      StringBuffer()
        ..writeln('// GENERATED FILE — scripts/generate_reward_assets.dart')
        ..writeln('// Elle düzenlemeyin.')
        ..writeln('const rewardAssetPaths = <String>[');
  for (final path in paths) {
    output.writeln("  '$path',");
  }
  output
    ..writeln('];')
    ..writeln('const expectedRewardAssetCount = 1244;');

  File('lib/data/reward_assets.g.dart').writeAsStringSync(output.toString());
  stdout.writeln('${paths.length} ödül asset yolu üretildi.');
}
