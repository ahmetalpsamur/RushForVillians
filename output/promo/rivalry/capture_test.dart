import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush_for_villains/core/theme/app_theme.dart';
import 'package:rush_for_villains/core/utils/item_rules.dart';
import 'package:rush_for_villains/core/utils/item_leveling.dart';
import 'package:rush_for_villains/core/utils/equipped_buffs.dart';
import 'package:rush_for_villains/core/utils/title_rules.dart';
import 'package:rush_for_villains/models/avatar_profile.dart';
import 'package:rush_for_villains/models/owned_item.dart';
import 'package:rush_for_villains/models/user_profile.dart';
import 'package:rush_for_villains/models/collection_reward.dart';
import 'package:rush_for_villains/services/item_catalog.dart';
import 'package:rush_for_villains/data/reward_catalog.dart';
import 'package:rush_for_villains/features/inventory/inventory_screen.dart';
import 'package:rush_for_villains/features/inventory/blacksmith_screen.dart';
import 'package:rush_for_villains/features/titles/titles_screen.dart';
import 'package:rush_for_villains/features/rewards/rewards_screen.dart';
import 'package:rush_for_villains/l10n/app_localizations.dart';
import 'package:rush_for_villains/l10n/app_localizations_en.dart';
import 'package:rush_for_villains/l10n/content_localizations.dart';

const avatar=AvatarProfile(name:'Pinky',age:22,weight:60,gender:'Female',characterClass:'Knight',characterAsset:'lib/All_Assets/Avatars/Classes/Characters(100x100 split)/Knight/Knight/Knight_Idle.gif');
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();
 setUpAll(() async {
  for(final entry in {'Roboto':'roboto-regular.ttf','MaterialIcons':'materialicons-regular.otf'}.entries){
   final loader=FontLoader(entry.key);
   loader.addFont(File('C:/Users/ASUS/flutter/bin/cache/artifacts/material_fonts/${entry.value}').readAsBytes().then((v)=>ByteData.sublistView(v)));
   await loader.load();
  }
 });
 testWidgets('Capture actual progression screens for advertisement',(tester)async{
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;addTearDown(tester.view.reset);
  final revision=ValueNotifier<int>(0);addTearDown(revision.dispose);
  Future<void> warm()async{
   await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:600)));
   for(var i=0;i<8;i++){await tester.pump(const Duration(milliseconds:100));}
  }
  Future<void> open(Widget screen)async{
   await tester.pumpWidget(MaterialApp(key:UniqueKey(),debugShowCheckedModeBanner:false,locale:const Locale('en'),
    localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales,
    theme:AppTheme.dark.copyWith(textTheme:AppTheme.dark.textTheme.apply(fontFamily:'Roboto')),home:screen));await warm();
  }
  Future<void> save(String name)async{await warm();await expectLater(find.byType(MaterialApp),matchesGoldenFile('screens/$name.png'));}
  final bases=['lib/Items/swords/aqua_sword.png','lib/Items/shields/blue_round_shield.png'].map((p)=>flavorForClass(buildItemFromAsset(p)!,'Knight')).toList();
  ItemCatalog.reset(bases);addTearDown(ItemCatalog.reset);
  var level=3;
  InventoryState state(){
   final owned=[OwnedItem(instanceId:1,itemId:bases[0].id,level:level,equipped:true),OwnedItem(instanceId:2,itemId:bases[1].id,level:3,equipped:true)];
   final entries=[for(var i=0;i<2;i++) InventoryEntry(owned[i],resolveOwnedItem(bases[i],owned[i],characterClass:'Knight'))];
   final items=entries.map((e)=>e.item).toList();
   return InventoryState(profile:UserProfile(avatar:avatar,level:25,coins:4000,ownedItems:owned,nextItemInstanceId:3),entries:entries,equippedItems:items,buffs:EquippedBuffs.from(items));
  }
  await open(InventoryScreen(revision:revision,readState:state,onEquip:(_){},onUnequip:(_){},onSell:(_){},onUpgrade:(_){},onMerge:(_,__){}));
  File('output/promo/rivalry/stats.json').writeAsStringSync(jsonEncode({for(final lv in [3,4]) '$lv':[for(final e in resolveOwnedItem(bases[0],OwnedItem(instanceId:1,itemId:bases[0].id,level:lv),characterClass:'Knight').buff.effects){'stat':e.stat.name,'value':e.value,'mode':e.mode.name}]}));
  await save('equipment');
  await open(BlacksmithScreen(revision:revision,readState:state,onUpgrade:(_){level++;revision.value++;},onMerge:(_,__){}));
  await save('upgrade-before');level=4;revision.value++;await save('upgrade-after');
  await open(TitlesScreen(revision:revision,readState:()=>const TitlesScreenState(
   ownedIds:{'living_legend','forge_master','storm_walker','first_step','coin_sniffer'},equippedId:'living_legend',
   progress:TitleProgress(level:80,totalSteps:2000000,longestStreak:100,enemiesDefeated:1000,adventuresCompleted:500,ownedItemCount:80,maxItemLevel:20,wheelSpins:100,itemsMerged:50,lifetimeCoins:100000),coins:3400),onEquip:(_){}));
  await save('titles');
  final rewards=<CollectionReward>[];
  for(final folder in ['Armor/Helmets','Books','Crystals','Jewelry','Potions','Weapons']){
   final matches=RewardCatalog.all.where((r)=>r.assetPath.contains('/$folder/'));
   if(matches.isNotEmpty)rewards.add(matches.first);
  }
  for(final index in [80,230,450,760,900,1100]){if(rewards.length<6)rewards.add(RewardCatalog.all[index]);}
  final l10n=AppLocalizationsEn();
  File('output/promo/rivalry/rewards.json').writeAsStringSync(jsonEncode([for(final r in rewards){'id':r.id,'name':l10n.collectionRewardName(r),'asset':r.assetPath}]));
  await open(RewardsScreen(rewards:rewards,statistics:const RewardStatistics(),earnedRewardDates:{for(final r in rewards)r.id:DateTime.utc(2026,9,1)},pinnedRewardIds:rewards.take(3).map((r)=>r.id).toList(),onTogglePinned:(_){}));
  await tester.tap(find.text('Showcase'));await save('showcase');
  await tester.drag(find.byKey(const ValueKey('reward-showcase-scroll')),const Offset(0,-330));await save('showcase-lower');
  await tester.drag(find.byKey(const ValueKey('reward-showcase-scroll')),const Offset(0,500));await save('showcase');
  await tester.pumpWidget(const SizedBox.shrink());await tester.pump(const Duration(seconds:3));
 });
}
