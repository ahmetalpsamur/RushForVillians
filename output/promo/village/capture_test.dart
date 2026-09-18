import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/game_clock.dart';
import 'package:rush_for_villains/data/enemy_catalog.dart';
import 'package:rush_for_villains/features/adventure/adventure_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/models/adventure_quest.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/daily_progress.dart';

void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(() async {
  for(final e in {'Roboto':'roboto-regular.ttf','MaterialIcons':'materialicons-regular.otf'}.entries){
   final f=FontLoader(e.key);f.addFont(File('C:/Users/ASUS/flutter/bin/cache/artifacts/material_fonts/${e.value}').readAsBytes().then((b)=>ByteData.sublistView(b)));await f.load();
  }
 });
 testWidgets('Capture real app states for village film',(tester) async {
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.reset);addTearDown(GameClock.reset);
  final now=DateTime(2026,9,17,10);GameClock.useSource(()=>now);
  final enemy=EnemyCatalog.byId('ash_guardian')!;
  for(final entry in <String,int>{'steps-742':742,'steps-891':891,'steps-1000':1000,'battle':1000,'victory':1000}.entries){
   final win=entry.key=='victory'||entry.key=='battle';
   final quest=AdventureQuest(enemy:enemy,stepGoal:1000,startedAt:now,
    battleOutcome:win?AdventureBattleOutcome.victory:AdventureBattleOutcome.active,
    deathAnimationPlayed:entry.key=='victory',xpAwarded:win,victoryXpReward:100,victoryCoinReward:25,victorySteps:win?1000:-1,victoryRounds:win?1:0,
    roundOutcomeSerial:entry.key=='battle'?1:0,lastRoundWon:win,lastResolvedRound:win?1:0,enemyHealthBeforeLastRound:13,lastPlayerDamage:13);
   await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner:false,locale:const Locale('en'),
    localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales,
    theme:AppTheme.dark.copyWith(textTheme:AppTheme.dark.textTheme.apply(fontFamily:'Roboto')),
    home:AdventureScreen(key:ValueKey(entry.key),adventure:quest,roundSerial:0,
     avatar:const AvatarProfile(name:'Pinky',age:22,weight:60,gender:'Female',characterClass:'Knight',characterAsset:'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Idle.gif'),
     today:DailyProgress(date:now,steps:entry.value,stepGoal:1000),onAdventureSelected:(_){},onStartRevival:(){},onChooseNewAdventure:(){},onAdventureUpdated:(){})));
   await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:600)));
   if(entry.key=='battle'){
    for(var j=0;j<120;j++){
     await tester.pump(const Duration(milliseconds:33));
     await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:10)));
     await expectLater(find.byType(MaterialApp),matchesGoldenFile('screens/combat-${j.toString().padLeft(3,'0')}.png'));
    }
   }else{for(var j=0;j<4;j++){await tester.pump(const Duration(milliseconds:150));}}
   await expectLater(find.byType(MaterialApp),matchesGoldenFile('screens/${entry.key}.png'));
   await tester.pumpWidget(const SizedBox.shrink());await tester.pump(const Duration(seconds:2));
  }
 });
}
