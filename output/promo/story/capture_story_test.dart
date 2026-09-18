import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';

void main() {
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(() async {
  for (final entry in {'Roboto':'roboto-regular.ttf','MaterialIcons':'materialicons-regular.otf'}.entries) {
   final loader=FontLoader(entry.key);
   loader.addFont(File('C:/Users/ASUS/flutter/bin/cache/artifacts/material_fonts/${entry.value}').readAsBytes().then((b)=>ByteData.sublistView(b)));
   await loader.load();
  }
 });
 testWidgets('Capture actual English adventure selection', (tester) async {
  tester.view.physicalSize=const Size(390,844);
  tester.view.devicePixelRatio=1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
   debugShowCheckedModeBanner:false,
   locale:const Locale('en'),localizationsDelegates:AppLocalizations.localizationsDelegates,
   supportedLocales:AppLocalizations.supportedLocales,
   theme:AppTheme.dark.copyWith(textTheme:AppTheme.dark.textTheme.apply(fontFamily:'Roboto')),
   home:AdventureScreen(adventure:null,roundSerial:0,
    avatar:const AvatarProfile(name:'Pinky',age:22,weight:60,gender:'Female',characterClass:'Knight',
     characterAsset:'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Idle.gif'),
    today:DailyProgress(date:DateTime(2026,9,16),steps:0,stepGoal:1000),
    onAdventureSelected:(_){},onStartRevival:(){},onChooseNewAdventure:(){},onAdventureUpdated:(){},
   ),
  ));
  await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:600)));
  for(var i=0;i<4;i++){await tester.pump(const Duration(milliseconds:200));}
  await tester.tap(find.text('500 steps'));
  await tester.pump(const Duration(milliseconds:400));
  final wheel=tester.widget<ListWheelScrollView>(find.byType(ListWheelScrollView));
  (wheel.controller! as FixedExtentScrollController).jumpToItem(1);
  await tester.pump(const Duration(milliseconds:300));
  await tester.tap(find.byType(FilledButton).last);
  await tester.pump(const Duration(milliseconds:400));
  for(var i=0;i<5;i++){await tester.pump(const Duration(milliseconds:150));}
  await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:400)));
  await tester.pump();
  await expectLater(find.byType(MaterialApp),matchesGoldenFile('screens/adventure.png'));
  await tester.tap(find.text('Ash Guardian'));
  await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:500)));
  await tester.pump(const Duration(milliseconds:400));
  for(var i=0;i<5;i++){await tester.pump(const Duration(milliseconds:150));}
  await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:400)));
  await tester.pump();
  expect(find.text('Start Adventure'),findsOneWidget);
  await expectLater(find.byType(MaterialApp),matchesGoldenFile('screens/start-adventure.png'));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds:3));
 });
}
