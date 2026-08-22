import 'package:flutter/material.dart';

import '/ai_workout/nutrition_diary/nutrition_diary_widget.dart';
import '/ai_workout/premium/ai_usage_gate.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/supabase/repositories/coach_vision_repository.dart';
import '/backend/supabase/repositories/meal_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';

const _bg = Color(0xFF090909);
const _surface = Color(0xFF151515);
const _border = Color(0xFF282828);
const _muted = Color(0xFF8A8A8A);
const _green = Color(0xFF1FE276);

TextStyle _text({
  double size = 14,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w400,
  double height = 1.35,
}) =>
    TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );

num _num(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

String _mime(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  return 'image/jpeg';
}

enum _Stage { camera, details, breakdown }

class CoachFoodScannerExperience extends StatefulWidget {
  const CoachFoodScannerExperience({
    super.key,
    this.initialLogDate,
    this.useGate,
    this.refundUse,
    this.upgradeOpener,
    this.visionRepository,
    this.mealRepository,
  });

  final DateTime? initialLogDate;
  final Future<AiUseDecision> Function()? useGate;
  final Future<void> Function()? refundUse;
  final Future<void> Function()? upgradeOpener;
  final CoachVisionRepository? visionRepository;
  final MealRepository? mealRepository;

  @override
  State<CoachFoodScannerExperience> createState() =>
      _CoachFoodScannerExperienceState();
}

class _CoachFoodScannerExperienceState
    extends State<CoachFoodScannerExperience> {
  _Stage _stage = _Stage.camera;
  Uint8List? _image;
  String? _photoUrl;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _ingredients = [];
  String _mealType = 'Lunch';
  bool _loading = false;
  bool _logged = false;

  CoachVisionRepository get _vision =>
      widget.visionRepository ?? CoachVisionRepository();
  MealRepository get _meals => widget.mealRepository ?? MealRepository();

  Future<void> _capture(MediaSource source) async {
    if (_loading) return;
    final files = await selectMedia(
      mediaSource: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (files == null || files.isEmpty || !mounted) return;
    final file = files.first;
    final decision = await (widget.useGate?.call() ?? AiUsageGate().claimUse());
    if (!mounted ||
        !await handleDeniedAiUse(
          context,
          decision,
          upgradeOpener: widget.upgradeOpener,
        )) return;

    setState(() {
      _image = file.bytes;
      _stage = _Stage.camera;
      _loading = true;
      _logged = false;
    });
    try {
      final url = await uploadData(file.storagePath, file.bytes);
      if (url == null || url.isEmpty) throw StateError('Image upload failed.');
      final scan = await _vision.analyzeFood(
        imageBytes: file.bytes,
        imageUrl: url,
        mimeType: _mime(file.storagePath),
      );
      final data = scan.persistedData;
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _result = data;
        _ingredients = (data['ingredients'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _mealType = _mealTypeForHour(DateTime.now().hour);
        _loading = false;
        _stage = _Stage.details;
      });
    } catch (error) {
      debugPrint('Coach food scan failed: $error');
      if (decision.consumedFreeUse) {
        await (widget.refundUse?.call() ?? AiUsageGate().refundUse());
      }
      if (!mounted) return;
      setState(() {
        _image = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('The meal could not be analyzed. Please try again.'),
      ));
    }
  }

  void _reset() => setState(() {
        _stage = _Stage.camera;
        _image = null;
        _photoUrl = null;
        _result = null;
        _ingredients = [];
        _loading = false;
        _logged = false;
      });

  void _setNumber(String key, String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed != null) _result?[key] = parsed;
  }

  double _grams(Map<String, dynamic> ingredient) {
    final value = ingredient['grams'];
    return value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _logMeal() async {
    final data = _result;
    if (data == null || _logged) return;
    try {
      final selected = widget.initialLogDate;
      final now = DateTime.now();
      final scannedAt = selected == null
          ? now
          : DateTime(selected.year, selected.month, selected.day, now.hour,
              now.minute, now.second);
      final description = _ingredients
          .where((item) => (item['name'] ?? '').toString().trim().isNotEmpty)
          .map((item) {
        final name = item['name'].toString().trim();
        final grams = _grams(item).round();
        return grams > 0 ? '$name (${grams}g)' : name;
      }).join(', ');
      await _meals.save(
        foodName: (data['name'] ?? 'Scanned meal').toString().trim(),
        description: description,
        calories: _num(data, 'calories').toDouble(),
        proteinG: _num(data, 'protein_g').toDouble(),
        carbsG: _num(data, 'carbs_g').toDouble(),
        fatG: _num(data, 'fat_g').toDouble(),
        portionSize: '${_num(data, 'total_weight_g').round()} g',
        photoUrl: _photoUrl,
        mealType: _mealType,
        scannedAt: scannedAt,
        analysis: {
          ...data,
          'ingredients': _ingredients,
          'meal_type': _mealType,
        },
      );
      if (!mounted) return;
      setState(() => _logged = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added to your diary.')),
      );
    } catch (error) {
      debugPrint('Logging scanned meal failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add this meal to your diary.')),
      );
    }
  }

  String _mealTypeForHour(int hour) {
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 18) return 'Snack';
    return 'Dinner';
  }

  Future<void> _openDiary() async {
    if (widget.initialLogDate != null) {
      context.safePop();
      return;
    }
    final date = widget.initialLogDate ?? DateTime.now();
    await context.pushNamed(
      NutritionDiaryWidget.routeName,
      queryParameters: {
        'date': serializeParam(
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  Widget _header() => SizedBox(
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('coach-tool-back'),
                tooltip: 'Back',
                onPressed: () => context.safePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 21),
              ),
            ),
            Text('Scan food', style: _text(size: 17, weight: FontWeight.w700)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('open-nutrition-diary'),
                onPressed: _openDiary,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: _border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text('Diary',
                    style: _text(size: 11, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

  Widget _cameraButton({required VoidCallback? onTap, bool gallery = false}) =>
      InkWell(
        key: ValueKey(gallery ? 'gallery-button' : 'capture-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(gallery ? 24 : 38),
        child: Container(
          width: gallery ? 48 : 76,
          height: gallery ? 48 : 76,
          padding: EdgeInsets.all(gallery ? 0 : 8),
          decoration: BoxDecoration(
            color: gallery ? _surface : const Color(0xFFC8FFE0),
            shape: BoxShape.circle,
          ),
          child: gallery
              ? const Icon(Icons.photo_library_outlined,
                  color: Color(0xFFC9C9C9), size: 19)
              : Container(
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      );

  Widget _camera() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 9),
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF181818), Color(0xFF101010)],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_image != null)
                      Image.memory(_image!, fit: BoxFit.cover),
                    CustomPaint(painter: _ScanCornerPainter()),
                    Center(
                      child: _loading
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                    color: _green, strokeWidth: 3),
                                const SizedBox(height: 18),
                                Text('Analyzing your plate…',
                                    style: _text(
                                        size: 14, weight: FontWeight.w600)),
                                const SizedBox(height: 7),
                                Text('Identifying ingredients & portions',
                                    style: _text(size: 11, color: _muted)),
                              ],
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 46),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_camera_outlined,
                                      size: 48, color: Color(0xFF444444)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Point at your plate and keep the food inside the frame',
                                    textAlign: TextAlign.center,
                                    style: _text(size: 12, color: _muted),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _cameraButton(
                    gallery: true,
                    onTap: _loading
                        ? null
                        : () => _capture(MediaSource.photoGallery)),
                const SizedBox(width: 34),
                _cameraButton(
                    onTap:
                        _loading ? null : () => _capture(MediaSource.camera)),
                const SizedBox(width: 34),
                InkWell(
                  key: const ValueKey('camera-button'),
                  onTap: _loading ? null : () => _capture(MediaSource.camera),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: _surface, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_camera_outlined,
                        size: 19, color: Color(0xFFC9C9C9)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  InputDecoration _inputDecoration({String? suffix}) => InputDecoration(
        suffixText: suffix,
        suffixStyle: _text(size: 11, color: _muted),
        filled: true,
        fillColor: const Color(0xFF121212),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green),
        ),
      );

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(value, style: _text(size: 11, color: _muted)),
      );

  Widget _details() {
    final data = _result!;
    final match =
        (_num(data, 'confidence').toDouble() * 100).clamp(0, 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        _header(),
        const SizedBox(height: 9),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Image.memory(_image!, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                    color: _green, borderRadius: BorderRadius.circular(16)),
                child: Text('$match% match',
                    style: _text(
                        size: 10,
                        color: const Color(0xFF08240F),
                        weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Meal name'),
        TextFormField(
          key: const ValueKey('scan-meal-name'),
          initialValue: (data['name'] ?? '').toString(),
          onChanged: (value) => data['name'] = value,
          textCapitalization: TextCapitalization.sentences,
          style: _text(size: 14, weight: FontWeight.w600),
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Total weight'),
                  TextFormField(
                    key: const ValueKey('scan-meal-weight'),
                    initialValue: '${_num(data, 'total_weight_g').round()}',
                    onChanged: (value) => _setNumber('total_weight_g', value),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: _text(size: 14, weight: FontWeight.w600),
                    decoration: _inputDecoration(suffix: 'g'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Calories'),
                  TextFormField(
                    key: const ValueKey('scan-meal-calories'),
                    initialValue: '${_num(data, 'calories').round()}',
                    onChanged: (value) => _setNumber('calories', value),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: _text(size: 14, weight: FontWeight.w600),
                    decoration: _inputDecoration(suffix: 'kcal'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ingredients', style: _text(size: 11, color: _muted)),
            Text('AI detected', style: _text(size: 10, color: _green)),
          ],
        ),
        const SizedBox(height: 9),
        ...List.generate(_ingredients.length, _ingredientRow),
        OutlinedButton.icon(
          key: const ValueKey('add-scan-ingredient'),
          onPressed: () =>
              setState(() => _ingredients.add({'name': '', 'grams': 0.0})),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            side: const BorderSide(color: _border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          icon: const Icon(Icons.add_rounded, color: _green, size: 18),
          label: Text('Add ingredient',
              style: _text(size: 12, color: _green, weight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        _label('Meal type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other']
              .map((type) => ChoiceChip(
                    key: ValueKey('scan-meal-type-$type'),
                    label: Text(type),
                    selected: _mealType == type,
                    onSelected: (_) => setState(() => _mealType = type),
                    showCheckmark: false,
                    selectedColor: _green,
                    backgroundColor: _surface,
                    side: const BorderSide(color: _border),
                    labelStyle: _text(
                      size: 10,
                      color:
                          _mealType == type ? const Color(0xFF08240F) : _muted,
                      weight: FontWeight.w600,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        _bottomActions(
          secondaryLabel: 'Rescan',
          onSecondary: _reset,
          primaryLabel: 'See breakdown',
          onPrimary: () => setState(() => _stage = _Stage.breakdown),
        ),
      ],
    );
  }

  Widget _ingredientRow(int index) {
    final ingredient = _ingredients[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 5, 5, 5),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1C1C1C)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('scan-ingredient-name-$index'),
                initialValue: (ingredient['name'] ?? '').toString(),
                onChanged: (value) => ingredient['name'] = value,
                style: _text(size: 12, weight: FontWeight.w500),
                decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true),
              ),
            ),
            SizedBox(
              width: 76,
              child: TextFormField(
                key: ValueKey('scan-ingredient-grams-$index'),
                initialValue: '${_grams(ingredient).round()}',
                onChanged: (value) => ingredient['grams'] =
                    double.tryParse(value.replaceAll(',', '.')) ?? 0,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: _text(size: 12, weight: FontWeight.w600),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: 'g',
                  suffixStyle: _text(size: 10, color: _muted),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            IconButton(
              key: ValueKey('remove-scan-ingredient-$index'),
              tooltip: 'Remove ingredient',
              onPressed: () => setState(() => _ingredients.removeAt(index)),
              icon: const Icon(Icons.close_rounded, color: _muted, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions({
    required String secondaryLabel,
    required VoidCallback onSecondary,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) =>
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
              ),
              child: Text(secondaryLabel,
                  style: _text(size: 13, weight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
              ),
              child: Text(primaryLabel,
                  style: _text(
                      size: 13,
                      color: const Color(0xFF08240F),
                      weight: FontWeight.w700)),
            ),
          ),
        ],
      );

  Widget _macroCard(String label, String key, Color color, int multiplier) {
    final grams = _num(_result!, key).toDouble();
    final macroCalories = grams * multiplier;
    final calories = _num(_result!, 'calories').toDouble();
    final fraction =
        calories <= 0 ? 0.0 : (macroCalories / calories).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF212121)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(label,
                      style: _text(size: 13, weight: FontWeight.w600))),
              Text('${grams.round()}g',
                  style: _text(size: 18, weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('${macroCalories.round()} kcal',
                  style: _text(size: 10, color: _muted)),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: const Color(0xFF1A1A1A),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${(fraction * 100).round()}% of calories',
                style: _text(size: 10, color: _muted)),
          ),
        ],
      ),
    );
  }

  Widget _breakdown() {
    final data = _result!;
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _header()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text((data['name'] ?? 'Scanned meal').toString(),
                  textAlign: TextAlign.center,
                  style: _text(size: 21, weight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('${_num(data, 'total_weight_g').round()} g serving',
                  textAlign: TextAlign.center,
                  style: _text(size: 11, color: _muted)),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: .82,
                          strokeWidth: 12,
                          backgroundColor: Color(0xFF1A1A1A),
                          valueColor: AlwaysStoppedAnimation(_green),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${_num(data, 'calories').round()}',
                              style: _text(
                                  size: 38,
                                  weight: FontWeight.w700,
                                  height: 1)),
                          const SizedBox(height: 5),
                          Text('kcal', style: _text(size: 11, color: _muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 23),
              _macroCard('Protein', 'protein_g', _green, 4),
              const SizedBox(height: 11),
              _macroCard('Carbs', 'carbs_g', const Color(0xFF4A9EFF), 4),
              const SizedBox(height: 11),
              _macroCard('Fat', 'fat_g', const Color(0xFFFFB84A), 9),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: _bottomActions(
            secondaryLabel: 'Edit',
            onSecondary: () => setState(() => _stage = _Stage.details),
            primaryLabel: _logged ? 'View diary' : 'Log to diary',
            onPrimary: _logged ? _openDiary : _logMeal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: switch (_stage) {
            _Stage.camera => _camera(),
            _Stage.details => _details(),
            _Stage.breakdown => _breakdown(),
          },
        ),
      ),
    );
  }
}

class _ScanCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const inset = 27.0;
    const length = 34.0;
    final paths = [
      Path()
        ..moveTo(inset, inset + length)
        ..lineTo(inset, inset)
        ..lineTo(inset + length, inset),
      Path()
        ..moveTo(size.width - inset - length, inset)
        ..lineTo(size.width - inset, inset)
        ..lineTo(size.width - inset, inset + length),
      Path()
        ..moveTo(inset, size.height - inset - length)
        ..lineTo(inset, size.height - inset)
        ..lineTo(inset + length, size.height - inset),
      Path()
        ..moveTo(size.width - inset - length, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset - length),
    ];
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
