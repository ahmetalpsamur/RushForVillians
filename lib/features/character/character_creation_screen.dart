import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/item_rules.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/content_localizations.dart';
import '../../models/avatar_profile.dart';
import '../../models/character_class.dart';
import '../../models/item.dart';
import '../../services/character_catalog.dart';
import '../../services/item_catalog.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/pixel_sprite.dart';

class CharacterCreationScreen extends StatefulWidget {
  final AvatarProfile? initialAvatar;
  final ValueChanged<AvatarProfile> onCompleted;

  const CharacterCreationScreen({
    super.key,
    this.initialAvatar,
    required this.onCompleted,
  });

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen>
    with SingleTickerProviderStateMixin {
  static const _stepCount = 6;

  late final TextEditingController _nameController;
  late int _age;
  late int _weight;
  late String _gender;
  late final FixedExtentScrollController _ageController;
  late final FixedExtentScrollController _weightController;
  List<CharacterClass> _classes = const [];
  String? _selectedClassId;
  String? _selectedAsset;

  /// Sınıf, tanıtım ekranında bilerek onaylandı mı.
  ///
  /// Katalog yüklenirken bir sınıf **varsayılan olarak** seçili geliyor; bu
  /// bayrak olmadan oyuncu hiçbir karta dokunmadan "DEVAM ET"e basıp
  /// habersizce ilk sınıfa razı olabiliyordu. Düzenleme modunda kayıtlı sınıf
  /// zaten bir karar olduğu için onaylı sayılır.
  bool _classConfirmed = false;
  String? _catalogError;
  String? _nameError;
  int _step = 0;
  bool _transitioning = false;
  CharacterClass? _revealedClass;
  String? _revealedAttackAsset;
  List<Item> _revealedItems = const [];
  int _revealSerial = 0;
  late final AnimationController _equipmentBobController;

  @override
  void initState() {
    super.initState();
    final avatar = widget.initialAvatar;
    _nameController = TextEditingController(text: avatar?.name ?? '');
    _age = avatar?.age ?? 24;
    _weight = avatar?.weight ?? 72;
    _gender = avatar?.gender ?? 'Erkek';
    _ageController = FixedExtentScrollController(initialItem: _age - 16);
    _weightController = FixedExtentScrollController(initialItem: _weight - 40);
    _equipmentBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final classes = await CharacterCatalog.load();
      await ItemCatalog.load();
      if (!mounted) return;
      if (classes.isEmpty) {
        setState(() => _catalogError = context.l10n.characterCatalogEmpty);
        return;
      }
      final initial = widget.initialAvatar;
      final selectedClass = classes.firstWhere(
        (item) => item.id == initial?.characterClass,
        orElse: () => classes.first,
      );
      final selectedAsset = selectedClass.walkingAsset;
      setState(() {
        _classes = classes;
        _selectedClassId = selectedClass.id;
        _selectedAsset = selectedAsset;
        _classConfirmed = initial?.characterClass == selectedClass.id;
        _catalogError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _catalogError = context.l10n.characterCatalogLoadFailed);
      }
    }
  }

  @override
  void dispose() {
    _revealSerial++;
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _equipmentBobController.dispose();
    super.dispose();
  }

  CharacterClass? get _selectedClass {
    for (final characterClass in _classes) {
      if (characterClass.id == _selectedClassId) return characterClass;
    }
    return null;
  }

  AvatarProfile? get _avatar {
    if (_selectedClassId == null || _selectedAsset == null) return null;
    return AvatarProfile(
      name: _nameController.text.trim(),
      age: _age,
      weight: _weight,
      gender: _gender,
      characterClass: _selectedClassId!,
      characterAsset: _selectedAsset!,
    );
  }

  Color get _neonColor => _colorForClass(_selectedClassId ?? '');

  Future<void> _goToStep(int nextStep) async {
    if (_transitioning || nextStep == _step) return;
    FocusScope.of(context).unfocus();
    // Haptik **beklenmez**: dokunsal geri bildirim bir süstür, adım geçişini
    // ona bağlamak titreşim kanalının yanıt vermediği cihazda sihirbazı
    // kilitler.
    HapticFeedback.mediumImpact();
    setState(() => _transitioning = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() => _step = nextStep.clamp(0, _stepCount - 1));
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) setState(() => _transitioning = false);
  }

  void _next() {
    if (_step == 0 && _nameController.text.trim().length < 2) {
      HapticFeedback.heavyImpact();
      setState(() => _nameError = context.l10n.heroNameTooShort);
      return;
    }
    if (_step == 4 && _selectedClass == null) return;
    _goToStep(_step + 1);
  }

  void _selectClass(CharacterClass characterClass) {
    HapticFeedback.heavyImpact();
    final attacks = characterClass.attackAssets;
    setState(() {
      _revealSerial++;
      _revealedClass = characterClass;
      _revealedAttackAsset =
          attacks[stableSpread(characterClass.id, attacks.length)];
      _revealedItems = _showcaseEquipmentFor(characterClass);
    });
  }

  /// Tanıtım ekranında gösterilecek örnek ekipman.
  ///
  /// Seçim **kararlı**: aynı sınıf her açılışta aynı silahları gösterir.
  /// Eskiden tohumsuz `Random` kullanılıyordu; sınıfın kimlik kartı her
  /// açılışta değişince sınıf keyfî görünüyor ve ekran golden ile
  /// doğrulanamıyordu (proje kuralı: kimliğe dönüşen rastgelelik tohumlu
  /// olmalı — bkz. GD8/GD18).
  List<Item> _showcaseEquipmentFor(CharacterClass characterClass) {
    final result = <Item>[];
    for (final category in ItemCategory.values) {
      if (!category.characterClasses.contains(characterClass.id)) continue;
      final pool =
          ItemCatalog.items
              .where(
                (item) =>
                    item.category == category &&
                    item.isUsableBy(characterClass.id),
              )
              .toList();
      if (pool.isEmpty) continue;
      final index = stableSpread(
        '${characterClass.id}|${category.folder}',
        pool.length,
      );
      result.add(pool[index]);
    }
    return result;
  }

  /// Tanıtım ekranını seçim yapmadan kapatır.
  void _dismissClassReveal() {
    if (_revealedClass == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _revealSerial++;
      _revealedClass = null;
      _revealedAttackAsset = null;
      _revealedItems = const [];
    });
  }

  /// Tanıtım ekranındaki tek onay.
  ///
  /// Eskiden burada yalnızca seçim işaretleniyor, oyuncu ızgaraya dönüp bir de
  /// "DEVAM ET"e basıyordu. Karar karakteri incelediği yerde verilsin diye
  /// onay doğrudan özet adımına ilerletiyor.
  void _confirmClassReveal() {
    final characterClass = _revealedClass;
    if (characterClass == null) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedClassId = characterClass.id;
      _selectedAsset = characterClass.walkingAsset;
      _classConfirmed = true;
      _revealedClass = null;
      _revealedAttackAsset = null;
      _revealedItems = const [];
    });
    _goToStep(_step + 1);
  }

  /// Donanım geri tuşunun karşılığı.
  ///
  /// Sırasıyla: açık tanıtım ekranını kapat, değilse bir önceki adıma dön.
  /// İkisi de yoksa rotanın kendisi kapanır.
  bool _handleBack() {
    if (_revealedClass != null) {
      _dismissClassReveal();
      return true;
    }
    if (_step > 0) {
      _goToStep(_step - 1);
      return true;
    }
    return false;
  }

  void _complete() {
    final avatar = _avatar;
    if (avatar == null) return;
    // Aynı gerekçe: kaydı haptik yanıtına bağlamıyoruz.
    HapticFeedback.heavyImpact();
    widget.onCompleted(avatar);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialAvatar != null;
    return PopScope(
      // Tanıtım ekranı açıkken ya da ilk adımda değilken geri tuşu rotayı
      // kapatmaz; önce ekran içi bir adım geri alınır.
      canPop: _revealedClass == null && _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: _buildBody(editing),
    );
  }

  Widget _buildBody(bool editing) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _EpicBackground()),
          SafeArea(
            child: Column(
              children: [
                _WizardHeader(
                  step: _step,
                  stepCount: _stepCount,
                  editing: editing,
                  onClose: editing ? () => Navigator.of(context).pop() : null,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(),
                    ),
                  ),
                ),
                _BottomControls(
                  step: _step,
                  stepCount: _stepCount,
                  enabled: !_transitioning && _canContinue,
                  onBack: _step == 0 ? null : () => _goToStep(_step - 1),
                  onNext: _step == _stepCount - 1 ? _complete : _next,
                  editing: editing,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _transitioning ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child:
                  _revealedClass == null
                      ? const SizedBox.shrink()
                      : _ClassReveal(
                        key: ValueKey(_revealSerial),
                        characterClass: _revealedClass!,
                        attackAsset: _revealedAttackAsset!,
                        color: _colorForClass(_revealedClass!.id),
                        revealSerial: _revealSerial,
                        equipment: _revealedItems,
                        bobAnimation: _equipmentBobController,
                        onSelect: _confirmClassReveal,
                        onBack: _dismissClassReveal,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canContinue => switch (_step) {
    0 => _nameController.text.trim().length >= 2,
    4 => _selectedClass != null && _classConfirmed,
    5 => _avatar != null,
    _ => true,
  };

  Widget _buildStep() => switch (_step) {
    0 => _nameStep(),
    1 => _genderStep(),
    2 => _numberStep(
      eyebrow: context.l10n.fateSecondLine,
      title: context.l10n.ageQuestion,
      subtitle: context.l10n.ageDescription,
      value: _age,
      suffix: context.l10n.ageSuffix,
      min: 16,
      max: 80,
      controller: _ageController,
      onChanged: (value) => setState(() => _age = value),
    ),
    3 => _numberStep(
      eyebrow: context.l10n.defineBody,
      title: context.l10n.weightQuestion,
      subtitle: context.l10n.weightDescription,
      value: _weight,
      suffix: 'kg',
      min: 40,
      max: 160,
      controller: _weightController,
      onChanged: (value) => setState(() => _weight = value),
    ),
    4 => _classStep(),
    _ => _summaryStep(),
  };

  Widget _nameStep() {
    return _QuestionFrame(
      eyebrow: context.l10n.fateFirstLine,
      title: context.l10n.nameQuestion,
      subtitle: context.l10n.nameDescription,
      child: TextField(
        controller: _nameController,
        autofocus: widget.initialAvatar == null,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        maxLength: 20,
        onSubmitted: (_) => _next(),
        onChanged: (_) => setState(() => _nameError = null),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: context.l10n.heroNameHint,
          errorText: _nameError,
          prefixIcon: const Icon(Icons.edit_note, color: AppColors.primary),
          filled: true,
          fillColor: Colors.black38,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _genderStep() {
    final options = [
      ('Kadın', context.l10n.genderFemale, Icons.female),
      ('Erkek', context.l10n.genderMale, Icons.male),
      ('Diğer', context.l10n.genderOther, Icons.person_outline),
    ];
    return _QuestionFrame(
      eyebrow: context.l10n.defineIdentity,
      title: context.l10n.identityQuestion,
      subtitle: context.l10n.identityDescription,
      child: Column(
        children:
            options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NeonOption(
                  label: option.$2,
                  icon: option.$3,
                  selected: _gender == option.$1,
                  color: AppColors.primary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _gender = option.$1);
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _numberStep({
    required String eyebrow,
    required String title,
    required String subtitle,
    required int value,
    required String suffix,
    required int min,
    required int max,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onChanged,
  }) {
    return _QuestionFrame(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          _NumberWheel(
            value: value,
            suffix: suffix,
            min: min,
            max: max,
            controller: controller,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _classStep() {
    if (_catalogError != null) {
      return _CatalogError(message: _catalogError!, onRetry: _loadCatalog);
    }
    if (_classes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return _QuestionFrame(
      eyebrow: context.l10n.choosePower,
      title: context.l10n.classQuestion,
      subtitle: context.l10n.classDescription,
      wide: true,
      // Kilitli/edilgen kontrol sessiz kalmaz: onay verilmeden "DEVAM ET"
      // kapalı, sebebi burada yazılı.
      hint: _classConfirmed ? null : context.l10n.classSelectionHint,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _classes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (context, index) {
          final characterClass = _classes[index];
          // Vurgu yalnızca **onaylanmış** seçimi gösterir; katalog yüklenirken
          // gelen varsayılan seçim, oyuncu hiçbir şey yapmamışken "seçtin"
          // demiş gibi görünmemeli.
          final selected =
              _classConfirmed && characterClass.id == _selectedClassId;
          return _ClassTile(
            label: context.l10n.characterClassName(characterClass.id),
            asset: characterClass.walkingAsset,
            selected: selected,
            color:
                selected
                    ? _colorForClass(characterClass.id)
                    : AppColors.primary,
            onTap: () => _selectClass(characterClass),
          );
        },
      ),
    );
  }

  Widget _summaryStep() {
    final avatar = _avatar;
    if (avatar == null) return const SizedBox.shrink();
    return _QuestionFrame(
      eyebrow: context.l10n.fateSealed,
      title: context.l10n.heroReadyQuestion(avatar.name),
      subtitle: context.l10n.confirmHeroDescription,
      child: Column(
        children: [
          _NeonAvatar(avatar: avatar, color: _neonColor),
          const SizedBox(height: 24),
          Text(
            context.l10n
                .characterClassName(avatar.characterClass)
                .toUpperCase(),
            style: TextStyle(
              color: _neonColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.profileDetails(
              avatar.age,
              avatar.weight,
              switch (avatar.gender) {
                'Kadın' => context.l10n.genderFemale,
                'Erkek' => context.l10n.genderMale,
                _ => context.l10n.genderOther,
              },
            ),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Color _colorForClass(String id) => switch (id) {
    'Archer' => const Color(0xFF38F59B),
    'Armored Axeman' || 'Werebear' => const Color(0xFFFF9D4D),
    'Armored Orc' || 'Elite Orc' || 'Orc' => const Color(0xFFFF5C5C),
    'Armored Skeleton' ||
    'Greatsword Skeleton' ||
    'Skeleton' => const Color(0xFFB7C9E2),
    'Bat' || 'Necromancer' => const Color(0xFFD65CFF),
    'Knight' || 'Soldier' || 'Swordsman' => const Color(0xFF5C8CFF),
    'Knight Templar' || 'Priest' => const Color(0xFFFFD95C),
    'Lancer' || 'Wizard' => const Color(0xFF4DDCFF),
    'Orc rider' || 'Slime' => const Color(0xFF77FF66),
    'Skeleton Archer' || 'Werewolf' => const Color(0xFFFF4F91),
    _ => AppColors.primary,
  };
}

class _NumberWheel extends StatelessWidget {
  final int value;
  final String suffix;
  final int min;
  final int max;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;

  const _NumberWheel({
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 330,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0, 0.2, 0.8, 1],
                      ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller,
                    itemExtent: 74,
                    diameterRatio: 1.45,
                    perspective: 0.0025,
                    physics: const FixedExtentScrollPhysics(),
                    useMagnifier: true,
                    magnification: 1.16,
                    overAndUnderCenterOpacity: 0.32,
                    onSelectedItemChanged: (index) {
                      final nextValue = min + index;
                      if (nextValue == value) return;
                      HapticFeedback.selectionClick();
                      onChanged(nextValue);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: max - min + 1,
                      builder: (context, index) {
                        final itemValue = min + index;
                        final selected = itemValue == value;
                        return Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 140),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: selected ? 46 : 29,
                              fontWeight:
                                  selected ? FontWeight.w900 : FontWeight.w500,
                              shadows:
                                  selected
                                      ? [
                                        const Shadow(
                                          color: AppColors.primary,
                                          blurRadius: 18,
                                        ),
                                        Shadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.7,
                                          ),
                                          blurRadius: 34,
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Text('$itemValue'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: 78,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 48,
                child: IgnorePointer(
                  child: Text(
                    suffix,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          context.l10n.scrollToChangeValue,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.unfold_more, size: 18, color: Colors.white38),
            const SizedBox(width: 6),
            Text(
              '$min–$max $suffix',
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final int step;
  final int stepCount;
  final bool editing;
  final VoidCallback? onClose;

  const _WizardHeader({
    required this.step,
    required this.stepCount,
    required this.editing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          if (onClose != null)
            IconButton(onPressed: onClose, icon: const Icon(Icons.close))
          else
            const Icon(Icons.bolt, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (step + 1) / stepCount,
                minHeight: 5,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${step + 1}/$stepCount',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _QuestionFrame extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final bool wide;

  /// Başlığın altında duran açıklama; devam düğmesi kapalıysa nedenini söyler.
  ///
  /// Bilerek **içeriğin üstünde**: 18 sınıflık ızgaranın altına konsaydı
  /// oyuncu nedeni görmek için listeyi sonuna kadar kaydırmak zorunda kalırdı.
  final String? hint;

  const _QuestionFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.wide = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 16 : 24, 28, wide ? 16 : 24, 24),
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, height: 1.4),
        ),
        if (hint != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint!,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 36),
        child,
      ],
    );
  }
}

class _NeonOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _NeonOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.025 : 1,
      duration: const Duration(milliseconds: 180),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.13) : Colors.black26,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.white12,
            width: selected ? 2 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 42,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? color : Colors.white54,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color,
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ClassTile({
    required this.label,
    required this.asset,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.035 : 1,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white12,
            width: selected ? 3 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.62),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.24),
                      blurRadius: 42,
                      spreadRadius: 4,
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final shortestSide = math.min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final scale = (shortestSide / 62).clamp(2.5, 3.1);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: PixelSprite(
                          asset: asset,
                          scale: scale.toDouble(),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  color: Colors.black26,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? color : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassReveal extends StatelessWidget {
  final CharacterClass characterClass;
  final String attackAsset;
  final Color color;
  final int revealSerial;
  final List<Item> equipment;
  final Animation<double> bobAnimation;
  final VoidCallback onSelect;
  final VoidCallback onBack;

  const _ClassReveal({
    super.key,
    required this.characterClass,
    required this.attackAsset,
    required this.color,
    required this.revealSerial,
    required this.equipment,
    required this.bobAnimation,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.94),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    tooltip: context.l10n.backToClassList,
                  ),
                  Expanded(
                    child: Text(
                      context.l10n
                          .characterClassName(characterClass.id)
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        shadows: [Shadow(color: color, blurRadius: 18)],
                      ),
                    ),
                  ),
                  // Başlığın gerçekten ortada kalması için geri butonuyla
                  // aynı genişlikte görünmez bir denge.
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 250,
                    maxHeight: 250,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withValues(alpha: 0.26),
                            color.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 55,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: PixelSprite(
                        asset: attackAsset,
                        scale: 3,
                        imageKey: ValueKey(
                          '${characterClass.id}-$revealSerial',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (equipment.isNotEmpty) ...[
                Text(
                  context.l10n.usableItemTypes,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(height: 112, child: _buildEquipmentStrip()),
                const SizedBox(height: 8),
              ],
              Text(
                '“${context.l10n.characterClassSlogan(characterClass.id, characterClass.selectionSlogan)}”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(context.l10n.chooseThisClass),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Eşya şeridi: sığdığında **ortalanır**, sığmadığında yatay kayar.
  ///
  /// Düz bir yatay `ListView` içeriği sığsa bile sola yaslıyor ve üç eşyalı
  /// sınıflarda görseller ekranın solunda kalıyordu. `minWidth` kısıtı satırı
  /// en az görüntü kadar geniş yapıp ortalamayı mümkün kılıyor; içerik
  /// taşarsa satır kendi genişliğine çıkıyor ve kaydırma devreye giriyor.
  Widget _buildEquipmentStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En dar destekli ekranda (320 dp) üç kart tam sığsın diye kart
        // genişliği görüntüden türetiliyor. Dörtten fazla kategori gören
        // sınıflarda şerit yine kayar; kırpılan kart "devamı var" işaretidir.
        const gap = 8.0;
        const visibleTarget = 3;
        final slots = math.min(equipment.length, visibleTarget);
        final available = constraints.maxWidth - gap * (slots - 1);
        final itemWidth = (available / slots).clamp(64.0, 92.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < equipment.length; index++) ...[
                  if (index > 0) const SizedBox(width: gap),
                  _RevealEquipmentItem(
                    item: equipment[index],
                    index: index,
                    animation: bobAnimation,
                    color: color,
                    width: itemWidth,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RevealEquipmentItem extends StatelessWidget {
  final Item item;
  final int index;
  final Animation<double> animation;
  final Color color;
  final double width;

  const _RevealEquipmentItem({
    required this.item,
    required this.index,
    required this.animation,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(
            context.l10n.itemCategoryName(item.category).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final phase = animation.value * math.pi * 2 + index * 0.85;
                return Transform.translate(
                  offset: Offset(0, math.sin(phase) * 5),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.42)),
                ),
                child: Image.asset(
                  item.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonAvatar extends StatelessWidget {
  final AvatarProfile avatar;
  final Color color;
  const _NeonAvatar({required this.avatar, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 34,
            spreadRadius: 3,
          ),
        ],
      ),
      child: AvatarView(
        key: const ValueKey('character-summary-avatar'),
        avatar: avatar,
        size: 230,
        // 100x100 GIF tuvalindeki görünür pikseller her sınıfta tam merkeze
        // oturmuyor. Özet karesi tuvali değil karakteri ortalar.
        spriteOffset: _summarySpriteOffset(avatar.characterClass),
      ),
    );
  }

  Offset _summarySpriteOffset(String characterClass) =>
      switch (characterClass) {
        'Archer' => const Offset(-3, 4.5),
        'Armored Axeman' => const Offset(-10.5, 9),
        'Armored Orc' => const Offset(-13.5, 7.5),
        'Armored Skeleton' => const Offset(-15, 12),
        'Elite Orc' => const Offset(-18, 13.5),
        'Greatsword Skeleton' => const Offset(16.5, 6),
        'Knight' => const Offset(-12, 6),
        'Knight Templar' => const Offset(-19.5, 6),
        'Orc' => const Offset(-15, 1.5),
        'Priest' => const Offset(-6, 6),
        'Skeleton' => const Offset(-18, 3),
        'Skeleton Archer' => const Offset(-7.5, 4.5),
        'Slime' => const Offset(3, -1.5),
        'Soldier' => const Offset(1.5, 3),
        'Swordsman' => const Offset(-12, 1.5),
        'Werebear' => const Offset(-7.5, 4.5),
        'Werewolf' => const Offset(-18, 3),
        'Wizard' => const Offset(-4.5, 4.5),
        _ => Offset.zero,
      };
}

class _BottomControls extends StatelessWidget {
  final int step;
  final int stepCount;
  final bool enabled;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool editing;

  const _BottomControls({
    required this.step,
    required this.stepCount,
    required this.enabled,
    required this.onBack,
    required this.onNext,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    final last = step == stepCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: context.l10n.back,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: enabled ? onNext : null,
              icon: Icon(last ? Icons.bolt : Icons.arrow_forward),
              label: Text(
                last
                    ? (editing
                        ? context.l10n.sealChanges
                        : context.l10n.startAdventureAction)
                    : context.l10n.continueAction,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpicBackground extends StatelessWidget {
  const _EpicBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.45),
          radius: 1.2,
          colors: [Color(0xFF302655), Color(0xFF13111C), Color(0xFF08070D)],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CatalogError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: AppColors.accent),
          const SizedBox(height: 8),
          Text(message),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
