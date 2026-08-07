import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/avatar_profile.dart';
import '../../models/character_class.dart';
import '../../services/character_catalog.dart';
import '../../widgets/avatar_view.dart';

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

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  static const _stepCount = 7;

  late final TextEditingController _nameController;
  late int _age;
  late int _weight;
  late String _gender;
  List<CharacterClass> _classes = const [];
  String? _selectedClassId;
  String? _selectedAsset;
  String? _catalogError;
  String? _nameError;
  int _step = 0;
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    final avatar = widget.initialAvatar;
    _nameController = TextEditingController(text: avatar?.name ?? '');
    _age = avatar?.age ?? 24;
    _weight = avatar?.weight ?? 72;
    _gender = avatar?.gender ?? 'Erkek';
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final classes = await CharacterCatalog.load();
      if (!mounted) return;
      if (classes.isEmpty) {
        setState(
          () => _catalogError = 'Characters klasöründe karakter bulunamadı.',
        );
        return;
      }
      final initial = widget.initialAvatar;
      final selectedClass = classes.firstWhere(
        (item) => item.id == initial?.characterClass,
        orElse: () => classes.first,
      );
      final selectedAsset =
          selectedClass.characterAssets.contains(initial?.characterAsset)
              ? initial!.characterAsset
              : selectedClass.characterAssets.first;
      setState(() {
        _classes = classes;
        _selectedClassId = selectedClass.id;
        _selectedAsset = selectedAsset;
        _catalogError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _catalogError = 'Karakter dosyaları yüklenemedi.');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Color get _neonColor => switch (_selectedClassId) {
    'Archer' => const Color(0xFF38F59B),
    'DarkMagic' => const Color(0xFFD65CFF),
    'Faith' => const Color(0xFFFFD95C),
    'Magic' => const Color(0xFF4DDCFF),
    'Nature' => const Color(0xFF77FF66),
    'Paladin' => const Color(0xFFFFB84D),
    'SwordMan' => const Color(0xFF5C8CFF),
    'Thief' => const Color(0xFFFF4F91),
    _ => AppColors.primary,
  };

  Future<void> _goToStep(int nextStep) async {
    if (_transitioning || nextStep == _step) return;
    FocusScope.of(context).unfocus();
    await HapticFeedback.mediumImpact();
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
      setState(() => _nameError = 'Kahramanın adı en az 2 karakter olmalı.');
      return;
    }
    if (_step == 4 && _selectedClass == null) return;
    if (_step == 5 && _selectedAsset == null) return;
    _goToStep(_step + 1);
  }

  void _selectClass(CharacterClass characterClass) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedClassId = characterClass.id;
      _selectedAsset = characterClass.characterAssets.first;
    });
  }

  Future<void> _complete() async {
    final avatar = _avatar;
    if (avatar == null) return;
    await HapticFeedback.heavyImpact();
    widget.onCompleted(avatar);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialAvatar != null;
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
        ],
      ),
    );
  }

  bool get _canContinue => switch (_step) {
    0 => _nameController.text.trim().length >= 2,
    4 => _selectedClass != null,
    5 => _selectedAsset != null,
    6 => _avatar != null,
    _ => true,
  };

  Widget _buildStep() => switch (_step) {
    0 => _nameStep(),
    1 => _genderStep(),
    2 => _numberStep(
      eyebrow: 'KADERİNİN İKİNCİ SATIRI',
      title: 'Kaç yaşındasın?',
      subtitle: 'Yaş, kahramanının hikâyesine yön verir.',
      value: _age,
      suffix: 'yaş',
      min: 16,
      max: 80,
      onChanged: (value) => setState(() => _age = value),
    ),
    3 => _numberStep(
      eyebrow: 'BEDENİNİ TANIMLA',
      title: 'Kilon kaç?',
      subtitle: 'Bu bilgi karakter profilinin bir parçası olacak.',
      value: _weight,
      suffix: 'kg',
      min: 40,
      max: 160,
      onChanged: (value) => setState(() => _weight = value),
    ),
    4 => _classStep(),
    5 => _characterStep(),
    _ => _summaryStep(),
  };

  Widget _nameStep() {
    return _QuestionFrame(
      eyebrow: 'KADERİNİN İLK SATIRI',
      title: 'Sana nasıl hitap edelim?',
      subtitle: 'Bu isim düşmanlarının hafızasına kazınacak.',
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
          hintText: 'Kahramanının adı',
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
    const options = [
      ('Kadın', Icons.female),
      ('Erkek', Icons.male),
      ('Diğer', Icons.person_outline),
    ];
    return _QuestionFrame(
      eyebrow: 'KİMLİĞİNİ BELİRLE',
      title: 'Kahramanın kim?',
      subtitle: 'Seni en iyi ifade eden seçeneği seç.',
      child: Column(
        children:
            options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NeonOption(
                  label: option.$1,
                  icon: option.$2,
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
    required ValueChanged<int> onChanged,
  }) {
    return _QuestionFrame(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          Container(
            width: 170,
            height: 170,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.09),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.42),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(suffix, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (next) => onChanged(next.round()),
            onChangeEnd: (_) => HapticFeedback.selectionClick(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('$min $suffix'), Text('$max $suffix')],
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
      eyebrow: 'GÜCÜNÜ SEÇ',
      title: 'Hangi sınıfa aitsin?',
      subtitle: 'Her sınıf farklı bir savaş yolunu temsil eder.',
      wide: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _classes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, index) {
          final characterClass = _classes[index];
          final selected = characterClass.id == _selectedClassId;
          return _NeonOption(
            label: characterClass.name,
            caption: '${characterClass.characterAssets.length} kahraman',
            icon: _classIcon(characterClass.id),
            selected: selected,
            color:
                selected
                    ? _colorForClass(characterClass.id)
                    : AppColors.primary,
            compact: true,
            onTap: () => _selectClass(characterClass),
          );
        },
      ),
    );
  }

  Widget _characterStep() {
    final characterClass = _selectedClass;
    if (characterClass == null) return const SizedBox.shrink();
    return _QuestionFrame(
      eyebrow: '${characterClass.name.toUpperCase()} SINIFI',
      title: 'Kahramanını seç',
      subtitle: 'Savaş alanında seni temsil edecek görünümü belirle.',
      wide: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: characterClass.characterAssets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, index) {
          final asset = characterClass.characterAssets[index];
          return _CharacterTile(
            asset: asset,
            selected: asset == _selectedAsset,
            color: _neonColor,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedAsset = asset);
            },
          );
        },
      ),
    );
  }

  Widget _summaryStep() {
    final avatar = _avatar;
    if (avatar == null) return const SizedBox.shrink();
    return _QuestionFrame(
      eyebrow: 'KADERİN MÜHÜRLENİYOR',
      title: '${avatar.name}, hazır mısın?',
      subtitle: 'Seçimlerini onayla ve Rush for Villains dünyasına adım at.',
      child: Column(
        children: [
          _NeonAvatar(avatar: avatar, color: _neonColor),
          const SizedBox(height: 24),
          Text(
            avatar.characterClassLabel.toUpperCase(),
            style: TextStyle(
              color: _neonColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${avatar.age} yaş  •  ${avatar.weight} kg  •  ${avatar.gender}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Color _colorForClass(String id) => switch (id) {
    'Archer' => const Color(0xFF38F59B),
    'DarkMagic' => const Color(0xFFD65CFF),
    'Faith' => const Color(0xFFFFD95C),
    'Magic' => const Color(0xFF4DDCFF),
    'Nature' => const Color(0xFF77FF66),
    'Paladin' => const Color(0xFFFFB84D),
    'SwordMan' => const Color(0xFF5C8CFF),
    'Thief' => const Color(0xFFFF4F91),
    _ => AppColors.primary,
  };

  IconData _classIcon(String id) => switch (id) {
    'Archer' => Icons.gps_fixed,
    'DarkMagic' => Icons.dark_mode,
    'Faith' => Icons.church,
    'Magic' => Icons.auto_fix_high,
    'Nature' => Icons.park,
    'Paladin' => Icons.shield,
    'SwordMan' => Icons.sports_martial_arts,
    'Thief' => Icons.visibility_off,
    _ => Icons.person,
  };
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

  const _QuestionFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.wide = false,
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
        const SizedBox(height: 36),
        child,
      ],
    );
  }
}

class _NeonOption extends StatelessWidget {
  final String label;
  final String? caption;
  final IconData icon;
  final bool selected;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _NeonOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
    this.caption,
    this.compact = false,
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
              padding: EdgeInsets.all(compact ? 14 : 18),
              child:
                  compact
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            color: selected ? color : Colors.white54,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (caption != null)
                            Text(
                              caption!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                        ],
                      )
                      : Row(
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

class _CharacterTile extends StatelessWidget {
  final String asset;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CharacterTile({
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
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
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
      child: AvatarView(avatar: avatar, size: 230),
    );
  }
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
              tooltip: 'Geri',
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: enabled ? onNext : null,
              icon: Icon(last ? Icons.bolt : Icons.arrow_forward),
              label: Text(
                last
                    ? (editing ? 'DEĞİŞİKLİKLERİ MÜHÜRLE' : 'MACERAYA BAŞLA')
                    : 'DEVAM ET',
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
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}
