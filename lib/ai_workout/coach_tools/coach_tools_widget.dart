import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/ai_workout/premium/ai_usage_gate.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/supabase/repositories/ai_coach_repository.dart';
import '/backend/supabase/repositories/body_scan_repository.dart';
import '/backend/supabase/repositories/coach_activity_repository.dart';
import '/backend/supabase/repositories/coach_vision_repository.dart';
import '/backend/supabase/repositories/meal_repository.dart';
import 'coach_food_scanner_experience.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import '/workout/routines/workout_routine_flow.dart';
import '/workout/routines/workout_routine_store.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF090909);
const _surface = Color(0xFF161616);
const _border = Color(0xFF282828);
const _muted = Color(0xFF8A8A8A);
const _green = Color(0xFF1FE276);

TextStyle _toolText({
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

String _apiSafe(String value) => value
    .replaceAll('\\', ' ')
    .replaceAll('"', "'")
    .replaceAll('\r', ' ')
    .replaceAll('\n', ' ');

Map<String, dynamic> _decodeObject(String source) {
  var cleaned = source.trim();
  cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
  cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
  final start = cleaned.indexOf('{');
  final end = cleaned.lastIndexOf('}');
  if (start >= 0 && end > start) cleaned = cleaned.substring(start, end + 1);
  final decoded = jsonDecode(cleaned);
  if (decoded is! Map) throw const FormatException('Expected an object');
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

num _number(Map<String, dynamic> data, String key, [num fallback = 0]) {
  final value = data[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

class _ToolHeader extends StatelessWidget {
  const _ToolHeader({
    required this.title,
    this.leading,
    this.subtitle,
    this.action,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          if (action != null)
            Align(alignment: Alignment.centerRight, child: action!),
          if (leading == null)
            Text(title, style: _toolText(size: 17, weight: FontWeight.w700))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Row(
                children: [
                  leading!,
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                _toolText(size: 15, weight: FontWeight.w700)),
                        if (subtitle != null)
                          Row(
                            children: [
                              const SizedBox(
                                width: 6,
                                height: 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: _green, shape: BoxShape.circle),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _toolText(size: 10, color: _muted)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const length = 34.0;
    const inset = 27.0;
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

class _CameraFrame extends StatelessWidget {
  const _CameraFrame({
    required this.icon,
    required this.message,
    this.image,
    this.loading = false,
    this.loadingTitle = 'Analyzing…',
    this.loadingMessage,
  });

  final IconData icon;
  final String message;
  final Uint8List? image;
  final bool loading;
  final String loadingTitle;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.memory(image!, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF181818), Color(0xFF111111)],
                ),
              ),
            ),
          if (image != null) const ColoredBox(color: Color(0x55000000)),
          const CustomPaint(painter: _CornerPainter()),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: loading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                              color: _green, strokeWidth: 3),
                        ),
                        const SizedBox(height: 18),
                        Text(loadingTitle,
                            style: _toolText(
                                size: 14,
                                color: Colors.white,
                                weight: FontWeight.w600)),
                        if (loadingMessage != null) ...[
                          const SizedBox(height: 7),
                          Text(loadingMessage!,
                              textAlign: TextAlign.center,
                              style: _toolText(size: 11, color: _muted)),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 43, color: const Color(0xFF484848)),
                        const SizedBox(height: 18),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: _toolText(size: 13, color: _muted),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _imageMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  return 'image/jpeg';
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onPressed, this.small = false});

  final VoidCallback? onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 48.0 : 76.0;
    return Semantics(
      label: small ? 'Open camera' : 'Take photo',
      button: true,
      child: InkWell(
        key: ValueKey(small ? 'camera-button' : 'capture-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(small ? 0 : 7),
          decoration: BoxDecoration(
            color: small ? _surface : const Color(0xFFC8FFE0),
            shape: BoxShape.circle,
          ),
          child: small
              ? const Icon(Icons.photo_camera_outlined,
                  color: const Color(0xFFC9C9C9), size: 20)
              : Container(
                  decoration: BoxDecoration(
                    color: onPressed == null ? const Color(0xFF277347) : _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2),
                  ),
                ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Choose from gallery',
      button: true,
      child: InkWell(
        key: const ValueKey('gallery-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.photo_library_outlined,
            size: 19,
            color: onPressed == null
                ? const Color(0xFF555555)
                : const Color(0xFFC9C9C9),
          ),
        ),
      ),
    );
  }
}

class CoachFoodScannerWidget extends StatefulWidget {
  const CoachFoodScannerWidget({
    super.key,
    this.initialLogDate,
    this.useGate,
    this.refundUse,
    this.upgradeOpener,
  });

  static String routeName = 'coachFoodScanner';
  static String routePath = 'coachFoodScanner';

  final DateTime? initialLogDate;
  final Future<AiUseDecision> Function()? useGate;
  final Future<void> Function()? refundUse;
  final Future<void> Function()? upgradeOpener;

  @override
  State<CoachFoodScannerWidget> createState() => _CoachFoodScannerHostState();
}

class _CoachFoodScannerHostState extends State<CoachFoodScannerWidget> {
  @override
  Widget build(BuildContext context) => CoachFoodScannerExperience(
        initialLogDate: widget.initialLogDate,
        useGate: widget.useGate,
        refundUse: widget.refundUse,
        upgradeOpener: widget.upgradeOpener,
      );
}

// Kept temporarily for binary/source compatibility with older generated
// routes; the route now mounts the complete multi-stage scanner above.
// ignore: unused_element
class _CoachFoodScannerWidgetState extends State<CoachFoodScannerWidget> {
  Uint8List? _image;
  Map<String, dynamic>? _result;
  String? _photoUrl;
  bool _loading = false;
  bool _logged = false;

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
    if (!mounted) return;
    if (!await handleDeniedAiUse(
      context,
      decision,
      upgradeOpener: widget.upgradeOpener,
    )) {
      return;
    }
    setState(() {
      _image = file.bytes;
      _result = null;
      _loading = true;
      _logged = false;
    });
    try {
      final url = await uploadData(file.storagePath, file.bytes);
      if (url == null || url.isEmpty) throw Exception('Image upload failed');
      final response = await OpenAIAPIGroup.createChatCompletionCall.call(
        query: _apiSafe(
            'Analyze this food photo. Return only valid compact JSON with fields name, ingredients, portion_size, calories, protein_g, carbs_g, fat_g, confidence. Use numbers for calories and grams, short strings for ingredients and portion_size, and no markdown.'),
        imagePath: url,
        assistantId: FFAppState().assistantId,
      );
      if (!response.succeeded) throw Exception('Food analysis failed');
      final raw =
          OpenAIAPIGroup.createChatCompletionCall.resText(response.jsonBody) ??
              '';
      final parsed = _decodeObject(raw);
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _result = parsed;
        _loading = false;
      });
    } catch (_) {
      if (decision.consumedFreeUse) {
        await (widget.refundUse?.call() ?? AiUsageGate().refundUse());
      }
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The meal could not be analyzed. Please try again.')));
    }
  }

  Future<void> _logMeal() async {
    final data = _result;
    if (data == null || _logged) return;
    try {
      final target = widget.initialLogDate;
      final now = DateTime.now();
      final scannedAt = target == null
          ? now
          : DateTime(
              target.year,
              target.month,
              target.day,
              now.hour,
              now.minute,
              now.second,
            );
      await MealRepository().save(
        foodName: (data['name'] ?? 'Scanned meal').toString(),
        description: (data['ingredients'] ?? '').toString(),
        calories: _number(data, 'calories').toDouble(),
        proteinG: _number(data, 'protein_g').toDouble(),
        carbsG: _number(data, 'carbs_g').toDouble(),
        fatG: _number(data, 'fat_g').toDouble(),
        portionSize: data['portion_size']?.toString(),
        photoUrl: _photoUrl,
        mealType: _mealTypeForHour(scannedAt.hour),
        analysis: data,
        scannedAt: scannedAt,
      );
      if (!mounted) return;
      setState(() => _logged = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal added to your diary.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not add this meal to your diary.')));
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

  Widget _diaryAction() => TextButton(
        key: const ValueKey('open-nutrition-diary'),
        onPressed: _openDiary,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _border),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child:
            Text('Diary', style: _toolText(size: 11, weight: FontWeight.w600)),
      );

  Widget _camera() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          children: [
            _ToolHeader(title: 'Scan food', action: _diaryAction()),
            const SizedBox(height: 14),
            Expanded(
              child: _CameraFrame(
                icon: Icons.photo_camera_outlined,
                message:
                    'Point at your plate and keep the food inside the frame',
                image: _image,
                loading: _loading,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _GalleryButton(
                    onPressed: _loading
                        ? null
                        : () => _capture(MediaSource.photoGallery)),
                _CaptureButton(
                    onPressed:
                        _loading ? null : () => _capture(MediaSource.camera)),
                _CaptureButton(
                    small: true,
                    onPressed:
                        _loading ? null : () => _capture(MediaSource.camera)),
              ],
            ),
          ],
        ),
      );

  Widget _macro(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(label, style: _toolText(size: 11, color: _muted)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    _toolText(size: 17, color: color, weight: FontWeight.w700)),
          ],
        ),
      );

  Widget _resultView() {
    final data = _result!;
    final confidence = _number(data, 'confidence', 0);
    final confidenceLabel = confidence > 1
        ? '${confidence.round()}% match'
        : '${(confidence * 100).round()}% match';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        _ToolHeader(title: 'Scan food', action: _diaryAction()),
        const SizedBox(height: 12),
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 230,
              child: Image.memory(_image!, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(confidenceLabel,
                  style: _toolText(
                      size: 11, color: _green, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text((data['name'] ?? 'Scanned meal').toString(),
                  style: _toolText(size: 21, weight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text((data['ingredients'] ?? '').toString(),
                  style: _toolText(size: 12, color: _muted)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_number(data, 'calories').round()}',
                      style: _toolText(
                          size: 38, weight: FontWeight.w700, height: 1)),
                  const SizedBox(width: 7),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child:
                        Text('kcal', style: _toolText(size: 13, color: _muted)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _macro('Protein', '${_number(data, 'protein_g').round()}g',
                      _green),
                  _macro('Carbs', '${_number(data, 'carbs_g').round()}g',
                      const Color(0xFFFFC95C)),
                  _macro('Fat', '${_number(data, 'fat_g').round()}g',
                      const Color(0xFFFF8A72)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _image = null;
                  _result = null;
                }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Scan again',
                    style: _toolText(size: 13, weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _logged ? null : _logMeal,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _green,
                  disabledBackgroundColor: const Color(0xFF267A49),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_logged ? 'Logged' : 'Log to diary',
                    style: _toolText(
                        size: 13, color: _bg, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        if (_logged) ...[
          const SizedBox(height: 10),
          TextButton(
            key: const ValueKey('view-logged-meal'),
            onPressed: _openDiary,
            child: Text('View in nutrition diary',
                style: _toolText(
                    size: 12, color: _green, weight: FontWeight.w600)),
          ),
        ],
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
        body: SafeArea(child: _result == null ? _camera() : _resultView()),
      ),
    );
  }
}

class CoachEquipmentScannerWidget extends StatefulWidget {
  const CoachEquipmentScannerWidget({
    super.key,
    this.useGate,
    this.refundUse,
    this.upgradeOpener,
  });

  static String routeName = 'coachEquipmentScanner';
  static String routePath = 'coachEquipmentScanner';

  final Future<AiUseDecision> Function()? useGate;
  final Future<void> Function()? refundUse;
  final Future<void> Function()? upgradeOpener;

  @override
  State<CoachEquipmentScannerWidget> createState() =>
      _CoachEquipmentScannerWidgetState();
}

class _CoachEquipmentScannerWidgetState
    extends State<CoachEquipmentScannerWidget> {
  Uint8List? _image;
  Map<String, dynamic>? _result;
  bool _loading = false;

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
    if (!mounted) return;
    if (!await handleDeniedAiUse(
      context,
      decision,
      upgradeOpener: widget.upgradeOpener,
    )) {
      return;
    }
    setState(() {
      _image = file.bytes;
      _result = null;
      _loading = true;
    });
    try {
      final url = await uploadData(file.storagePath, file.bytes);
      if (url == null || url.isEmpty) throw Exception('Image upload failed');
      final scan = await CoachVisionRepository().analyzeEquipment(
        imageBytes: file.bytes,
        imageUrl: url,
        mimeType: _imageMimeType(file.storagePath),
      );
      final parsed = scan.persistedData;
      await CoachActivityRepository().recordEquipmentScan(
        photoUrl: url,
        result: parsed,
      );
      if (!mounted) return;
      setState(() {
        _result = parsed;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Equipment scan failed: $error');
      if (decision.consumedFreeUse) {
        await (widget.refundUse?.call() ?? AiUsageGate().refundUse());
      }
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The machine could not be identified. Try again.')));
    }
  }

  List<String> _strings(dynamic value) => value is List
      ? value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList()
      : const [];

  Widget _camera() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          children: [
            const _ToolHeader(title: 'Scan equipment'),
            const SizedBox(height: 14),
            Expanded(
              child: _CameraFrame(
                icon: Icons.fitness_center_rounded,
                message:
                    'Frame the whole machine — we’ll tell you how to use it',
                image: _image,
                loading: _loading,
                loadingTitle: 'Recognizing machine…',
                loadingMessage: 'Matching against known gym equipment',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 48),
                const SizedBox(width: 28),
                _CaptureButton(
                    onPressed:
                        _loading ? null : () => _capture(MediaSource.camera)),
                const SizedBox(width: 28),
                _GalleryButton(
                    onPressed: _loading
                        ? null
                        : () => _capture(MediaSource.photoGallery)),
              ],
            ),
          ],
        ),
      );

  Widget _resultView() {
    final data = _result!;
    final muscles = _strings(data['muscles']);
    final steps = _strings(data['steps']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        const _ToolHeader(title: 'Scan equipment'),
        if (_image != null) ...[
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Image.memory(_image!, fit: BoxFit.cover)),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Identified',
                      style: _toolText(
                          size: 10,
                          color: const Color(0xFF08240F),
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text((data['name'] ?? 'Gym machine').toString(),
            style: _toolText(size: 21, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text((data['type'] ?? 'Exercise equipment').toString(),
            style: _toolText(size: 12, color: _muted)),
        const SizedBox(height: 21),
        Text('Primary muscles',
            style: _toolText(size: 13, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: muscles
              .map((muscle) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1A1FE276),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x4D1FE276)),
                    ),
                    child: Text(muscle,
                        style: _toolText(
                            size: 11, color: _green, weight: FontWeight.w600)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 22),
        Text('How to use it',
            style: _toolText(size: 13, weight: FontWeight.w700)),
        const SizedBox(height: 11),
        ...steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: Text('${entry.key + 1}',
                        style: _toolText(
                            size: 11, color: _green, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(entry.value,
                        style: _toolText(
                            size: 12, color: const Color(0xFFD0D0D0))),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _image = null;
                  _result = null;
                }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Scan again',
                    style: _toolText(size: 13, weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'equipment-to-routine'),
                    builder: (_) => RoutineBuilderWidget(
                      initialExerciseName:
                          (data['name'] ?? 'Gym machine').toString(),
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Add to workout',
                    style: _toolText(
                        size: 12, color: _bg, weight: FontWeight.w700)),
              ),
            ),
          ],
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
        body: SafeArea(child: _result == null ? _camera() : _resultView()),
      ),
    );
  }
}

class _TrainerMessage {
  const _TrainerMessage(
    this.text, {
    this.fromUser = false,
    this.workoutProposal,
    this.proposalStatus = _ProposalStatus.pending,
  });

  final String text;
  final bool fromUser;
  final AiCoachWorkoutProposal? workoutProposal;
  final _ProposalStatus proposalStatus;

  _TrainerMessage copyWith({_ProposalStatus? proposalStatus}) =>
      _TrainerMessage(
        text,
        fromUser: fromUser,
        workoutProposal: workoutProposal,
        proposalStatus: proposalStatus ?? this.proposalStatus,
      );
}

enum _ProposalStatus { pending, implementing, implemented, skipped }

class CoachTrainerWidget extends StatefulWidget {
  const CoachTrainerWidget({
    super.key,
    this.useGate,
    this.refundUse,
    this.upgradeOpener,
    this.conversationLoader,
    this.questionSender,
    this.proposalImplementer,
  });

  static String routeName = 'coachTrainer';
  static String routePath = 'coachTrainer';

  final Future<AiUseDecision> Function()? useGate;
  final Future<void> Function()? refundUse;
  final Future<void> Function()? upgradeOpener;
  final Future<List<AiCoachMessage>> Function()? conversationLoader;
  final Future<AiCoachMessage> Function(String question)? questionSender;
  final Future<void> Function(AiCoachWorkoutProposal proposal)?
      proposalImplementer;

  @override
  State<CoachTrainerWidget> createState() => _CoachTrainerWidgetState();
}

class _CoachTrainerWidgetState extends State<CoachTrainerWidget> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_TrainerMessage> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  String get _greeting {
    final firstName = currentUserDisplayName.trim().split(' ').first;
    final name = firstName.isEmpty ? '' : ' $firstName';
    return 'Hey$name 👋 I’m your AI Coach. I use your workout plan, meal plan, '
        'measurements, goals, and previous coach conversations to help with '
        'training and nutrition.';
  }

  Future<void> _loadConversation() async {
    try {
      final stored = await (widget.conversationLoader?.call() ??
          AiCoachRepository().loadConversation());
      final schedule = await WorkoutRoutineStore.loadSchedule();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(stored.map((message) {
            final proposal = message.workoutProposal;
            final implemented = proposal != null &&
                (schedule[WorkoutRoutineStore.dateKey(
                          proposal.scheduledDate,
                        )] ??
                        const <String>[])
                    .contains(proposal.routine.id);
            return _TrainerMessage(
              message.content,
              fromUser: message.fromUser,
              workoutProposal: proposal,
              proposalStatus: implemented
                  ? _ProposalStatus.implemented
                  : _ProposalStatus.pending,
            );
          }));
        if (_messages.isEmpty) _messages.add(_TrainerMessage(_greeting));
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_messages.isEmpty) _messages.add(_TrainerMessage(_greeting));
        _loadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? suggestion]) async {
    final question = (suggestion ?? _controller.text).trim();
    if (question.isEmpty || _sending) return;
    final decision = await (widget.useGate?.call() ?? AiUsageGate().claimUse());
    if (!mounted) return;
    if (!await handleDeniedAiUse(
      context,
      decision,
      upgradeOpener: widget.upgradeOpener,
    )) {
      return;
    }
    _controller.clear();
    setState(() {
      _messages.add(_TrainerMessage(question, fromUser: true));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final reply = await (widget.questionSender?.call(question) ??
          AiCoachRepository().ask(question));
      if (!mounted) return;
      setState(() => _messages.add(_TrainerMessage(
            reply.content,
            workoutProposal: reply.workoutProposal,
          )));
    } catch (_) {
      if (decision.consumedFreeUse) {
        await (widget.refundUse?.call() ?? AiUsageGate().refundUse());
      }
      if (!mounted) return;
      setState(() => _messages.add(_TrainerMessage(ensureAiCoachDisclosure(
          'I couldn’t reach the coach right now. Please try again in a moment.'))));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Widget _avatar() => Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
        child: const Icon(Icons.auto_awesome_rounded, color: _bg, size: 15),
      );

  Future<void> _implementProposal(int index) async {
    if (index < 0 || index >= _messages.length) return;
    final proposal = _messages[index].workoutProposal;
    if (proposal == null ||
        _messages[index].proposalStatus != _ProposalStatus.pending) {
      return;
    }
    setState(() {
      _messages[index] = _messages[index]
          .copyWith(proposalStatus: _ProposalStatus.implementing);
    });
    try {
      late final AiCoachMessage confirmation;
      final customImplementer = widget.proposalImplementer;
      if (customImplementer != null) {
        await customImplementer(proposal);
        confirmation = AiCoachMessage(
          id: 0,
          role: 'assistant',
          content: 'Done — ${proposal.routine.name} was added to Train for '
              '${WorkoutRoutineStore.dateKey(proposal.scheduledDate)}.',
          createdAt: DateTime.now(),
        );
      } else {
        confirmation = await AiCoachRepository()
            .implementWorkoutProposalAndConfirm(proposal);
      }
      if (!mounted) return;
      setState(() {
        _messages[index] = _messages[index]
            .copyWith(proposalStatus: _ProposalStatus.implemented);
        _messages.add(_TrainerMessage(confirmation.content));
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages[index] =
            _messages[index].copyWith(proposalStatus: _ProposalStatus.pending);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The workout could not be added. Please try again.'),
        ),
      );
    }
  }

  void _skipProposal(int index) {
    if (index < 0 || index >= _messages.length) return;
    if (_messages[index].proposalStatus != _ProposalStatus.pending) return;
    setState(() {
      _messages[index] =
          _messages[index].copyWith(proposalStatus: _ProposalStatus.skipped);
    });
  }

  String _proposalDate(AiCoachWorkoutProposal proposal) {
    final date = proposal.scheduledDate;
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _proposalCard(_TrainerMessage message, int index) {
    final proposal = message.workoutProposal!;
    final status = message.proposalStatus;
    final isBusy = status == _ProposalStatus.implementing;
    return Container(
      key: ValueKey(
          'coach-workout-proposal-${proposal.routine.id}-${proposal.scheduledDate.toIso8601String()}'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101B15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E6C40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WORKOUT SUGGESTION',
              style:
                  _toolText(size: 9, color: _green, weight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(proposal.routine.name,
              style: _toolText(size: 14, weight: FontWeight.w700)),
          Text(
            '${_proposalDate(proposal)} · '
            '${proposal.routine.exercises.length} exercises · '
            '~${proposal.routine.estimatedMinutes} min',
            style: _toolText(size: 10, color: _muted),
          ),
          const SizedBox(height: 10),
          if (status == _ProposalStatus.implemented)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _green, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('Added to your Train calendar',
                      style: _toolText(
                          size: 11, color: _green, weight: FontWeight.w600)),
                ),
              ],
            )
          else if (status == _ProposalStatus.skipped)
            Text('Suggestion skipped',
                style: _toolText(size: 11, color: _muted))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('skip-workout-${proposal.routine.id}'),
                    onPressed: isBusy ? null : () => _skipProposal(index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _border),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('implement-workout-${proposal.routine.id}'),
                    onPressed: isBusy ? null : () => _implementProposal(index),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: _bg,
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _bg,
                            ),
                          )
                        : const Text('Implement'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bubble(_TrainerMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            message.fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.fromUser) ...[_avatar(), const SizedBox(width: 9)],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: message.fromUser ? const Color(0xFF153D25) : _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color:
                        message.fromUser ? const Color(0xFF23683D) : _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text,
                      style:
                          _toolText(size: 13, color: const Color(0xFFF1F1F1))),
                  if (message.workoutProposal != null)
                    _proposalCard(message, index),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const suggestions = [
      'Explain today’s workout',
      'What should I eat today?',
      'Adjust my next session'
    ];
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ToolHeader(
                  title: 'AI Coach',
                  subtitle: 'Your plans · Your history',
                  leading: _avatar(),
                ),
              ),
              const Divider(height: 1, color: _border),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  itemCount: _messages.length +
                      ((_sending || _loadingHistory) ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index == _messages.length) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 42, bottom: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _green),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                  _loadingHistory
                                      ? 'Loading your coach history…'
                                      : 'Reviewing your plans…',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _toolText(size: 11, color: _muted)),
                            ),
                          ],
                        ),
                      );
                    }
                    return _bubble(_messages[index], index);
                  },
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ActionChip(
                    onPressed: (_sending || _loadingHistory)
                        ? null
                        : () => _send(suggestions[index]),
                    label: Text(suggestions[index]),
                    backgroundColor: _surface,
                    disabledColor: _surface,
                    side: const BorderSide(color: _border),
                    labelStyle: _toolText(
                        size: 11,
                        color: const Color(0xFFE5E5E5),
                        weight: FontWeight.w600),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('trainer-input'),
                        controller: _controller,
                        enabled: !_sending && !_loadingHistory,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: _toolText(size: 13),
                        decoration: InputDecoration(
                          hintText: 'Ask your coach…',
                          hintStyle: _toolText(size: 13, color: _muted),
                          filled: true,
                          fillColor: _surface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: _border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: _border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: _green),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      key: const ValueKey('trainer-send'),
                      tooltip: 'Send',
                      onPressed:
                          (_sending || _loadingHistory) ? null : () => _send(),
                      style: IconButton.styleFrom(
                        fixedSize: const Size(50, 50),
                        backgroundColor: _green,
                        disabledBackgroundColor: const Color(0xFF267A49),
                      ),
                      icon:
                          const Icon(Icons.send_rounded, color: _bg, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BodyScanPhase { intro, capturing, analyzing, report }

class _BodySilhouettePainter extends CustomPainter {
  const _BodySilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 60;
    final scaleY = size.height / 120;
    final paint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(30 * scaleX, 14 * scaleY), 9 * scaleX, paint);
    final path = Path()
      ..moveTo(30 * scaleX, 23 * scaleY)
      ..lineTo(30 * scaleX, 63 * scaleY)
      ..moveTo(30 * scaleX, 30 * scaleY)
      ..lineTo(14 * scaleX, 38 * scaleY)
      ..moveTo(30 * scaleX, 30 * scaleY)
      ..lineTo(46 * scaleX, 38 * scaleY)
      ..moveTo(30 * scaleX, 63 * scaleY)
      ..lineTo(20 * scaleX, 109 * scaleY)
      ..moveTo(30 * scaleX, 63 * scaleY)
      ..lineTo(40 * scaleX, 109 * scaleY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BodySilhouettePainter oldDelegate) => false;
}

class CoachBodyScanWidget extends StatefulWidget {
  const CoachBodyScanWidget({
    super.key,
    this.initialResultForTesting,
    this.showAnalyzingForTesting = false,
  });

  final Map<String, dynamic>? initialResultForTesting;
  final bool showAnalyzingForTesting;

  static String routeName = 'coachBodyScan';
  static String routePath = 'coachBodyScan';

  @override
  State<CoachBodyScanWidget> createState() => _CoachBodyScanWidgetState();
}

class _CoachBodyScanWidgetState extends State<CoachBodyScanWidget>
    with SingleTickerProviderStateMixin {
  Uint8List? _image;
  Map<String, dynamic>? _result;
  bool _loading = false;
  _BodyScanPhase _phase = _BodyScanPhase.intro;
  double _captureProgress = 0;
  int _analysisStage = 0;
  Timer? _analysisTimer;
  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.initialResultForTesting != null) {
      _result = widget.initialResultForTesting;
      _phase = _BodyScanPhase.report;
    } else if (widget.showAnalyzingForTesting) {
      _loading = true;
      _analysisStage = 1;
      _phase = _BodyScanPhase.analyzing;
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _scanLineController.dispose();
    super.dispose();
  }

  int _profileAge() {
    final directAge = currentUserDocument?.age ?? 0;
    if (directAge > 0) return directAge;
    final birthday = currentUserDocument?.age2;
    if (birthday == null) return 0;
    final today = DateTime.now();
    var age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age -= 1;
    }
    return age.clamp(0, 120);
  }

  Future<void> _start() async {
    if (_loading) return;
    final files = await selectMediaWithSourceBottomSheet(
      context: context,
      maxWidth: 1600,
      maxHeight: 2000,
      imageQuality: 88,
      allowPhoto: true,
      pickerFontFamily: 'Poppins',
      textColor: Colors.white,
      backgroundColor: _surface,
    );
    if (files == null || files.isEmpty || !mounted) return;
    final file = files.first;
    setState(() {
      _image = file.bytes;
      _loading = true;
      _result = null;
      _phase = _BodyScanPhase.capturing;
      _captureProgress = 0;
      _analysisStage = 0;
    });
    _scanLineController.repeat(reverse: true);
    try {
      for (var step = 1; step <= 12; step++) {
        await Future<void>.delayed(const Duration(milliseconds: 55));
        if (!mounted) return;
        setState(() => _captureProgress = step / 12);
      }
      _scanLineController.stop();
      setState(() => _phase = _BodyScanPhase.analyzing);
      _analysisTimer?.cancel();
      _analysisTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
        if (!mounted || _phase != _BodyScanPhase.analyzing) return;
        if (_analysisStage < 3) {
          setState(() => _analysisStage += 1);
        }
      });

      final url = await uploadData(file.storagePath, file.bytes);
      if (url == null || url.isEmpty) throw Exception('Image upload failed');
      final profile = BodyScanProfileData(
        age: _profileAge(),
        weightKg: (currentUserDocument?.weight ?? 0).toDouble(),
        heightCm: (currentUserDocument?.height ?? 0).toDouble(),
        gender: currentUserDocument?.gender2 ?? '',
        workoutsPerWeek: currentUserDocument?.workouts ?? '',
      );
      final activityRepository = CoachActivityRepository();
      Map<String, dynamic>? previousScan;
      try {
        previousScan = await activityRepository.latestBodyScan();
      } catch (_) {}
      final scan = await BodyScanRepository().analyze(
        imageBytes: file.bytes,
        imageUrl: url,
        profile: profile,
      );
      final parsed = BodyScanRepository.withPreviousScan(
        scan.persistedData,
        previousScan,
      );
      try {
        await activityRepository.recordBodyScan(
          parsed,
          photoUrl: url,
        );
      } catch (error) {
        debugPrint('Body scan history was not saved: $error');
      }
      if (!mounted) return;
      _analysisTimer?.cancel();
      setState(() => _analysisStage = 4);
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() {
        _result = parsed;
        _loading = false;
        _phase = _BodyScanPhase.report;
      });
    } catch (error, stackTrace) {
      debugPrint('Body scan failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _analysisTimer?.cancel();
      _scanLineController.stop();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _phase = _BodyScanPhase.intro;
        _captureProgress = 0;
        _analysisStage = 0;
      });
      final message = error is BodyScanInputException
          ? error.message
          : 'The body scan service could not complete this scan. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Widget _intro() => Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ToolHeader(title: 'Body scan'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const RadialGradient(
                          center: Alignment(0, -.8),
                          radius: 1.25,
                          colors: [Color(0xFF141D17), Color(0xFF0C0C0C)],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 130,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x2422E06B),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 80,
                                height: 150,
                                child: CustomPaint(
                                  painter: _BodySilhouettePainter(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                child: Column(
                                  children: [
                                    Text('Stand 2m back, full body in frame',
                                        textAlign: TextAlign.center,
                                        style: _toolText(
                                            size: 18, weight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Wear fitted clothing and stand straight. Keep your head, hands, legs, and feet visible.',
                                      textAlign: TextAlign.center,
                                      style: _toolText(size: 13, color: _muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      key: const ValueKey('start-body-scan'),
                      onPressed: _loading ? null : _start,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: Text('Start scan',
                          style: _toolText(
                              size: 16, color: _bg, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _capturing() => Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ToolHeader(title: 'Body scan'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_image != null)
                            Image.memory(_image!, fit: BoxFit.cover)
                          else
                            const DecoratedBox(
                              decoration:
                                  BoxDecoration(color: Color(0xFF0C0C0C)),
                            ),
                          const ColoredBox(color: Color(0x66000000)),
                          const CustomPaint(painter: _CornerPainter()),
                          AnimatedBuilder(
                            animation: _scanLineController,
                            builder: (context, _) => LayoutBuilder(
                              builder: (context, constraints) => Positioned(
                                left: 30,
                                right: 30,
                                top: 35 +
                                    (constraints.maxHeight - 70) *
                                        _scanLineController.value,
                                child: Container(
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        _green,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Color(0xAA22E06B),
                                          blurRadius: 14,
                                          spreadRadius: 2),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                'Checking full-body framing… ${(_captureProgress * 100).round()}%',
                                style: _toolText(
                                    size: 14, weight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _captureProgress,
                      backgroundColor: const Color(0xFF1D1D1D),
                      valueColor: const AlwaysStoppedAnimation(_green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _analyzing() {
    const stages = <(String, IconData)>[
      ('Detecting body landmarks', Icons.accessibility_new_rounded),
      ('Estimating composition', Icons.pie_chart_outline_rounded),
      ('Measuring muscle balance', Icons.bar_chart_rounded),
      ('Generating coach insights', Icons.auto_awesome_rounded),
    ];
    final progress = ((25 + _analysisStage * 19).clamp(0, 100)) / 100;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _ToolHeader(title: 'Body scan'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              children: [
                const SizedBox(height: 18),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          backgroundColor: const Color(0xFF161616),
                          valueColor: const AlwaysStoppedAnimation(_green),
                        ),
                      ),
                      const SizedBox(
                        width: 34,
                        height: 60,
                        child: CustomPaint(
                          painter: _BodySilhouettePainter(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Analyzing your scan',
                    style: _toolText(size: 20, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'This usually takes a few seconds · ${(progress * 100).round()}%',
                  style: _toolText(size: 12, color: _muted),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final done = index < _analysisStage;
                      final active = index == _analysisStage;
                      final enabled = done || active;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0x1422E06B)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? _green
                                    : active
                                        ? const Color(0x2922E06B)
                                        : const Color(0xFF161616),
                              ),
                              child: Icon(
                                done ? Icons.check_rounded : stages[index].$2,
                                size: 16,
                                color: done
                                    ? const Color(0xFF08240F)
                                    : active
                                        ? _green
                                        : const Color(0xFF4A4A4A),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Text(stages[index].$1,
                                  style: _toolText(
                                      size: 14,
                                      color: enabled
                                          ? Colors.white
                                          : const Color(0xFF6E6E6E),
                                      weight: active
                                          ? FontWeight.w600
                                          : FontWeight.w500)),
                            ),
                            if (active)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _green,
                                  backgroundColor: Color(0xFF1F1F1F),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value, {bool accent = false}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _toolText(size: 11, color: _muted),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: _toolText(
                      size: 21,
                      color: accent ? _green : Colors.white,
                      weight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _balance(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          children: [
            Expanded(child: Text(label, style: _toolText(size: 12))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF143821),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(value,
                  style: _toolText(
                      size: 10, color: _green, weight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _assessment(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: _toolText(
                    size: 11, color: _green, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: _toolText(size: 12, color: const Color(0xFFD6D6D6))),
          ],
        ),
      );

  Widget _metricGrid(List<Widget> children) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
        children: children,
      );

  Widget _reportRing({
    required double size,
    required double value,
    required Widget child,
    double strokeWidth = 10,
    Color color = _green,
  }) =>
      SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0, 1)),
                duration: const Duration(milliseconds: 950),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) =>
                    CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFF1E1E1E),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            child,
          ],
        ),
      );

  Widget _analysisBar({
    required String label,
    required String value,
    required String zone,
    required double progress,
    Color color = _green,
  }) =>
      Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: _toolText(size: 12))),
              Text(value, style: _toolText(size: 13, weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(zone,
                  style: _toolText(
                      size: 11, color: color, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFF1E1E1E),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      );

  Widget _segmentBar({
    required String label,
    required String value,
    required String status,
    required int score,
  }) {
    final warning = score < 60;
    final color = warning ? const Color(0xFFFFB84A) : _green;
    return _analysisBar(
      label: label,
      value: value,
      zone: status,
      progress: score / 100,
      color: color,
    );
  }

  String _bodyFatZone(double value) {
    if (value < 8) return 'Low';
    if (value <= 25) return 'Optimal';
    if (value <= 32) return 'Elevated';
    return 'High';
  }

  String _valueDelta(
    Map<String, dynamic> data,
    String key, {
    required String suffix,
  }) {
    if (data['has_previous_scan'] != true) return 'First recorded scan';
    final change = _number(data, key).toDouble();
    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(key == 'body_fat_change' ? 1 : 0)}$suffix since last scan';
  }

  // ignore: unused_element
  Widget _legacyReport() {
    final data = _result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        const _ToolHeader(title: 'Body scan'),
        const SizedBox(height: 12),
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
                height: 220, child: Image.memory(_image!, fit: BoxFit.cover)),
          ),
        const SizedBox(height: 16),
        Text('Body composition',
            style: _toolText(size: 19, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        _metricGrid(
          [
            _metric(
                'Body fat', '${_number(data, 'body_fat').toStringAsFixed(1)}%',
                accent: true),
            _metric('Fat mass',
                '${_number(data, 'fat_mass_kg').toStringAsFixed(1)} kg'),
            _metric('Lean mass',
                '${_number(data, 'lean_mass_kg').toStringAsFixed(1)} kg'),
            _metric('Lean mass %',
                '${_number(data, 'lean_mass_percent').toStringAsFixed(1)}%'),
            _metric('Muscle mass',
                '${_number(data, 'muscle_mass').toStringAsFixed(1)} kg'),
            _metric('BMI', _number(data, 'bmi').toStringAsFixed(1)),
            _metric(
                'Body water', '${_number(data, 'water').toStringAsFixed(1)}%'),
            _metric('Weight',
                '${_number(data, 'weight_kg').toStringAsFixed(1)} kg'),
          ],
        ),
        const SizedBox(height: 19),
        Text('Detailed composition',
            style: _toolText(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 11),
        _metricGrid(
          [
            _metric('Essential fat',
                '${_number(data, 'essential_fat_percent').toStringAsFixed(1)}%'),
            _metric('Beneficial fat',
                '${_number(data, 'beneficial_fat_percent').toStringAsFixed(1)}%'),
            _metric('Unbeneficial fat',
                '${_number(data, 'unbeneficial_fat_percent').toStringAsFixed(1)}%'),
            _metric('Lean mass index',
                _number(data, 'lean_mass_index').toStringAsFixed(1)),
            _metric('Fat mass index',
                _number(data, 'fat_mass_index').toStringAsFixed(1)),
            _metric('Resting metabolism',
                '${_number(data, 'resting_metabolic_rate_kcal').round()} kcal'),
          ],
        ),
        const SizedBox(height: 19),
        Text('Energy & profile calculations',
            style: _toolText(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 11),
        _metricGrid(
          [
            _metric('Daily expenditure',
                '${_number(data, 'tdee_kcal').round()} kcal'),
            _metric('Body surface area',
                '${_number(data, 'body_surface_area_m2').toStringAsFixed(2)} m²'),
            _metric('Ideal weight estimate',
                '${_number(data, 'ideal_body_weight_kg').toStringAsFixed(1)} kg'),
            _metric('Scan confidence',
                '${(_number(data, 'confidence') * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 19),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Muscle balance',
                  style: _toolText(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              _balance('Chest & shoulders',
                  (data['chest'] ?? 'Estimated').toString()),
              _balance('Arms', (data['arms'] ?? 'Estimated').toString()),
              _balance('Core', (data['core'] ?? 'Estimated').toString()),
              _balance('Legs', (data['legs'] ?? 'Estimated').toString()),
              _balance('BMI range',
                  (data['bmi_category'] ?? 'Estimated').toString()),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(17, 17, 17, 3),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visual assessments',
                  style: _toolText(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              _assessment('Visceral fat estimate',
                  (data['visceral_fat_assessment'] ?? 'Estimated').toString()),
              _assessment('Posture',
                  (data['posture_assessment'] ?? 'Estimated').toString()),
              _assessment('Symmetry',
                  (data['symmetry_assessment'] ?? 'Estimated').toString()),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFF102619),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1C4B2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coach recommendation',
                  style: _toolText(
                      size: 13, color: _green, weight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(
                  (data['recommendation'] ??
                          'Keep training consistently and repeat the scan under the same conditions.')
                      .toString(),
                  style: _toolText(size: 12, color: const Color(0xFFD6D6D6))),
              const SizedBox(height: 8),
              Text(
                  (data['measurement_note'] ??
                          'AI estimate — not a medical measurement.')
                      .toString(),
                  style: _toolText(size: 10, color: _muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _image = null;
                  _result = null;
                }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('New scan',
                    style: _toolText(size: 13, weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    context.pushNamed(CoachTrainerWidget.routeName),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Ask the trainer',
                    style: _toolText(
                        size: 12, color: _bg, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _report() {
    final data = _result!;
    final fitnessScore = _number(data, 'fitness_score').round().clamp(0, 100);
    final bodyFat = _number(data, 'body_fat').toDouble();
    final weight = _number(data, 'weight_kg').toDouble();
    final muscleMass = _number(data, 'muscle_mass').toDouble();
    final musclePercent = weight > 0 ? muscleMass / weight * 100 : 0.0;
    final water = _number(data, 'water').toDouble();
    final proteinPercent = _number(data, 'protein_percent').toDouble();
    final visceral = _number(data, 'visceral_fat_level').round().clamp(1, 20);
    final segmental = (data['segmental_lean'] is List)
        ? (data['segmental_lean'] as List)
            .whereType<Map>()
            .map((item) =>
                item.map((key, value) => MapEntry(key.toString(), value)))
            .toList()
        : <Map<String, dynamic>>[];
    final hasPrevious = data['has_previous_scan'] == true;
    final scoreChange = _number(data, 'fitness_score_change').round();
    final fatChange = _number(data, 'body_fat_change').toDouble();
    final scoreColor = scoreChange >= 0 ? _green : const Color(0xFFFFB84A);
    final fatColor = fatChange <= 0 ? _green : const Color(0xFFFFB84A);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _ToolHeader(title: 'Body scan'),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('body-scan-report'),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x3D22E06B)),
                  gradient: const RadialGradient(
                    center: Alignment(0, -1),
                    radius: 1.2,
                    colors: [Color(0xFF16241B), Color(0xFF0D0D0D)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x2422E06B),
                        border: Border.all(color: const Color(0x4D22E06B)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text('FITNESS SCORE',
                          style: _toolText(
                              size: 11,
                              color: _green,
                              weight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),
                    _reportRing(
                      size: 150,
                      value: fitnessScore / 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$fitnessScore',
                              style:
                                  _toolText(size: 42, weight: FontWeight.w800)),
                          Text('of 100',
                              style: _toolText(size: 11, color: _muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data['fitness_rating'] ?? 'Fitness estimate'} · top ${_number(data, 'top_percent').round()}%',
                      style: _toolText(size: 14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasPrevious && scoreChange < 0
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 13,
                          color: scoreColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _valueDelta(data, 'fitness_score_change',
                              suffix: ' pts'),
                          style: _toolText(
                              size: 11,
                              color: hasPrevious ? scoreColor : _muted,
                              weight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: const Color(0xFF212121)),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    _reportRing(
                      size: 90,
                      value: bodyFat / 40,
                      strokeWidth: 11,
                      child: const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Body fat',
                              style: _toolText(size: 12, color: _muted)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: bodyFat.toStringAsFixed(1),
                                  style: _toolText(
                                      size: 34, weight: FontWeight.w800),
                                ),
                                TextSpan(
                                  text: '%',
                                  style: _toolText(
                                      size: 16,
                                      color: _green,
                                      weight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                hasPrevious && fatChange > 0
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 13,
                                color: fatColor,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _valueDelta(data, 'body_fat_change',
                                      suffix: '%'),
                                  style: _toolText(
                                      size: 11,
                                      color: hasPrevious ? fatColor : _muted,
                                      weight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _metricGrid([
                _metric('Weight', '${weight.toStringAsFixed(1)} kg'),
                _metric(
                    'Skeletal muscle', '${muscleMass.toStringAsFixed(1)} kg'),
                _metric('Body fat mass',
                    '${_number(data, 'fat_mass_kg').toStringAsFixed(1)} kg'),
                _metric('Lean body mass',
                    '${_number(data, 'lean_mass_kg').toStringAsFixed(1)} kg'),
                _metric('BMI', _number(data, 'bmi').toStringAsFixed(1)),
                _metric('BMR', '${_number(data, 'bmr_kcal').round()} kcal'),
                _metric('Body water', '${water.toStringAsFixed(1)}%'),
                _metric('Protein',
                    '${_number(data, 'protein_mass_kg').toStringAsFixed(1)} kg'),
                _metric('Bone mass',
                    '${_number(data, 'bone_mass_kg').toStringAsFixed(1)} kg'),
                _metric('Metabolic age',
                    '${_number(data, 'metabolic_age').round()} yrs'),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text('Composition analysis',
                    style: _toolText(size: 14, weight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: const Color(0xFF212121)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _analysisBar(
                      label: 'Body fat',
                      value: '${bodyFat.toStringAsFixed(1)}%',
                      zone: _bodyFatZone(bodyFat),
                      progress: bodyFat / 40,
                    ),
                    const SizedBox(height: 15),
                    _analysisBar(
                      label: 'Skeletal muscle',
                      value: '${musclePercent.toStringAsFixed(1)}%',
                      zone: musclePercent >= 45 ? 'High' : 'Optimal',
                      progress: musclePercent / 60,
                    ),
                    const SizedBox(height: 15),
                    _analysisBar(
                      label: 'Body water',
                      value: '${water.toStringAsFixed(1)}%',
                      zone: water >= 50 && water <= 65 ? 'Optimal' : 'Review',
                      progress: water / 80,
                      color: const Color(0xFF4A9EFF),
                    ),
                    const SizedBox(height: 15),
                    _analysisBar(
                      label: 'Protein',
                      value: '${proteinPercent.toStringAsFixed(1)}%',
                      zone: proteinPercent >= 14 && proteinPercent <= 20
                          ? 'Optimal'
                          : 'Review',
                      progress: proteinPercent / 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 132,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      border: Border.all(color: const Color(0xFF212121)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _reportRing(
                          size: 88,
                          value: visceral / 20,
                          strokeWidth: 12,
                          child: Text('$visceral',
                              style:
                                  _toolText(size: 26, weight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 10),
                        Text('Visceral fat',
                            style: _toolText(size: 11, color: _muted)),
                        const SizedBox(height: 5),
                        Text(
                            (data['visceral_fat_label'] ?? 'Estimated')
                                .toString(),
                            style: _toolText(
                                size: 11,
                                color: visceral < 10
                                    ? _green
                                    : const Color(0xFFFFB84A),
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        border: Border.all(color: const Color(0xFF212121)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visceral < 10
                                ? 'Visceral fat under 10 is considered the healthier zone. Your estimate is $visceral.'
                                : 'Your visceral-fat estimate is $visceral. Track the trend and discuss concerns with a clinician.',
                            style: _toolText(size: 12, color: _muted),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: visceral / 20,
                              minHeight: 6,
                              backgroundColor: const Color(0xFF1E1E1E),
                              valueColor: AlwaysStoppedAnimation(
                                visceral < 10
                                    ? _green
                                    : const Color(0xFFFFB84A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0',
                                  style: _toolText(size: 9, color: _muted)),
                              Text('Healthy 10',
                                  style: _toolText(size: 9, color: _muted)),
                              Text('20',
                                  style: _toolText(size: 9, color: _muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text('Segmental lean analysis',
                    style: _toolText(size: 14, weight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: const Color(0xFF212121)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < segmental.length; index++) ...[
                      _segmentBar(
                        label: (segmental[index]['segment'] ?? 'Segment')
                            .toString(),
                        value:
                            '${_number(segmental[index], 'kg').toStringAsFixed(1)} kg',
                        status: (segmental[index]['status'] ?? 'Estimated')
                            .toString(),
                        score: _number(segmental[index], 'score').round(),
                      ),
                      if (index != segmental.length - 1)
                        const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text('Muscle balance',
                    style: _toolText(size: 14, weight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: const Color(0xFF212121)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _analysisBar(
                      label: 'Chest & shoulders',
                      value: '',
                      zone: (data['chest'] ?? 'Estimated').toString(),
                      progress: _number(data, 'chest_score') / 100,
                    ),
                    const SizedBox(height: 13),
                    _analysisBar(
                      label: 'Arms',
                      value: '',
                      zone: (data['arms'] ?? 'Estimated').toString(),
                      progress: _number(data, 'arms_score') / 100,
                    ),
                    const SizedBox(height: 13),
                    _analysisBar(
                      label: 'Core',
                      value: '',
                      zone: (data['core'] ?? 'Estimated').toString(),
                      progress: _number(data, 'core_score') / 100,
                    ),
                    const SizedBox(height: 13),
                    _analysisBar(
                      label: 'Legs',
                      value: '',
                      zone: (data['legs'] ?? 'Estimated').toString(),
                      progress: _number(data, 'legs_score') / 100,
                      color: _number(data, 'legs_score') < 60
                          ? const Color(0xFFFFB84A)
                          : _green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text('Detailed metrics',
                    style: _toolText(size: 14, weight: FontWeight.w600)),
              ),
              _metricGrid([
                _metric('Essential fat',
                    '${_number(data, 'essential_fat_percent').toStringAsFixed(1)}%'),
                _metric('Beneficial fat',
                    '${_number(data, 'beneficial_fat_percent').toStringAsFixed(1)}%'),
                _metric('Unbeneficial fat',
                    '${_number(data, 'unbeneficial_fat_percent').toStringAsFixed(1)}%'),
                _metric('Lean mass %',
                    '${_number(data, 'lean_mass_percent').toStringAsFixed(1)}%'),
                _metric('Lean mass index',
                    _number(data, 'lean_mass_index').toStringAsFixed(1)),
                _metric('Fat mass index',
                    _number(data, 'fat_mass_index').toStringAsFixed(1)),
                _metric('Daily expenditure',
                    '${_number(data, 'tdee_kcal').round()} kcal'),
                _metric('Body surface area',
                    '${_number(data, 'body_surface_area_m2').toStringAsFixed(2)} m²'),
                _metric('Ideal weight estimate',
                    '${_number(data, 'ideal_body_weight_kg').toStringAsFixed(1)} kg'),
                _metric('Scan confidence',
                    '${(_number(data, 'confidence') * 100).round()}%'),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: const Color(0xFF212121)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _assessment('Posture',
                        (data['posture_assessment'] ?? 'Estimated').toString()),
                    _assessment(
                        'Symmetry',
                        (data['symmetry_assessment'] ?? 'Estimated')
                            .toString()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x1A22E06B), Color(0x0522E06B)],
                  ),
                  border: Border.all(color: const Color(0x4722E06B)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 16, color: _green),
                        const SizedBox(width: 8),
                        Text('Coach recommendation',
                            style: _toolText(
                                size: 13,
                                color: _green,
                                weight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (data['recommendation'] ??
                              'Keep training consistently and compare scans under the same conditions.')
                          .toString(),
                      style:
                          _toolText(size: 13, color: const Color(0xFFD4D4D4)),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      (data['measurement_note'] ??
                              'AI estimate — not a medical measurement.')
                          .toString(),
                      style: _toolText(size: 10, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _image = null;
                        _result = null;
                        _phase = _BodyScanPhase.intro;
                        _captureProgress = 0;
                        _analysisStage = 0;
                      }),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFF2C2C2C)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                      child: Text('New scan',
                          style: _toolText(size: 14, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () =>
                          context.pushNamed(CoachTrainerWidget.routeName),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                      child: Text('Ask the trainer',
                          style: _toolText(
                              size: 14, color: _bg, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
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
          child: switch (_phase) {
            _BodyScanPhase.intro => _intro(),
            _BodyScanPhase.capturing => _capturing(),
            _BodyScanPhase.analyzing => _analyzing(),
            _BodyScanPhase.report => _result == null ? _intro() : _report(),
          },
        ),
      ),
    );
  }
}
