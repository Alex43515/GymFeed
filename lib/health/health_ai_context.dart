import 'package:shared_preferences/shared_preferences.dart';
import 'connected_health_controller.dart';
import 'device_health_gateway.dart';

const healthAiConsentText =
    'When you send a question to AI Coach, GymFeed will read today’s steps, '
    'active calories and latest recorded heart rate, with their dates and times. '
    'This daily summary is sent securely through GymFeed’s Supabase service to '
    'OpenAI (or Google Gemini if needed) to personalize fitness and nutrition '
    'answers. These providers process requests under their data-retention '
    'policies; this is not on-device AI.\n\n'
    'The raw summary is not saved to your GymFeed profile or health database. '
    'Your questions, answers and plans may contain these numbers and are saved '
    'in your private Coach history or plans, not in rolling AI memory. '
    'There is no advertising use. You can turn sharing off here at any time; '
    'this stops future health sharing but does not delete existing history or '
    'plans. This is general coaching, not medical monitoring or advice.';

enum HealthAiStatus { disabled, unavailable, noData, ready }

/// Minimal per-request data. No source/device IDs, raw samples or persistent cache.
class HealthAiContext {
  const HealthAiContext.disabled()
      : status = HealthAiStatus.disabled,
        summary = null;
  const HealthAiContext(this.status, {this.summary});
  final HealthAiStatus status;
  final DailyHealthSummary? summary;
  bool get sharingEnabled => status != HealthAiStatus.disabled;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'scope': 'today_only',
        if (summary != null) ...{
          'local_date': _date(summary!.date),
          'read_at': summary!.syncedAt.toIso8601String(),
          'utc_offset_minutes': summary!.syncedAt.timeZoneOffset.inMinutes,
          'steps': summary!.steps,
          'active_calories_kcal': summary!.activeCalories,
          'latest_heart_rate_bpm': summary!.heartRate,
          'heart_rate_recorded_at': summary!.heartRateAt?.toIso8601String(),
          'heart_rate_is_live': false,
        },
      };

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class HealthAiContextReader {
  HealthAiContextReader({
    required this.userId,
    required this.currentUserId,
    required this.preferences,
    ConnectedHealthGateway? gateway,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 6),
  })  : gateway = gateway ?? DeviceHealthGateway(),
        clock = clock ?? DateTime.now;
  final String userId;
  final String Function() currentUserId;
  final SharedPreferences preferences;
  final ConnectedHealthGateway gateway;
  final DateTime Function() clock;
  final Duration timeout;

  bool get authorized =>
      userId.isNotEmpty &&
      userId == currentUserId() &&
      preferences.getBool(ConnectedHealthController.connectionKey(userId)) ==
          true &&
      preferences.getBool(ConnectedHealthController.aiConsentKey(userId)) ==
          true;

  Future<HealthAiContext> readForQuestion() async {
    if (!authorized) return const HealthAiContext.disabled();
    var active = true;
    try {
      // Never prompt for OS permissions from a chat send. Permission checks and
      // partial/revoked reads are handled by the existing read-only gateway.
      return await _read(() => active).timeout(timeout);
    } catch (_) {
      return authorized
          ? const HealthAiContext(HealthAiStatus.unavailable)
          : const HealthAiContext.disabled();
    } finally {
      active = false;
    }
  }

  Future<HealthAiContext> _read(bool Function() active) async {
    if (await gateway.availability() != HealthAvailability.available) {
      return authorized
          ? const HealthAiContext(HealthAiStatus.unavailable)
          : const HealthAiContext.disabled();
    }
    if (!active() || !authorized) return const HealthAiContext.disabled();
    final now = clock();
    final today = ConnectedHealthController.day(now);
    final raw = await gateway.readDay(today, now);
    if (!active() || !authorized) return const HealthAiContext.disabled();
    // Reject old-day snapshots, unknown timestamps and invalid numbers instead
    // of silently presenting stale data, missing readings as zero or live pulse.
    if (ConnectedHealthController.day(raw.date) != today) {
      return const HealthAiContext(HealthAiStatus.noData);
    }
    final heartAt = raw.heartRateAt?.toLocal();
    final validHeart = heartAt != null &&
        !heartAt.isBefore(today) &&
        !heartAt.isAfter(now) &&
        raw.heartRate != null &&
        raw.heartRate!.isFinite &&
        raw.heartRate! > 0;
    final data = DailyHealthSummary(
      date: today,
      syncedAt: now,
      steps: raw.steps != null && raw.steps! >= 0 ? raw.steps : null,
      activeCalories: raw.activeCalories != null &&
              raw.activeCalories!.isFinite &&
              raw.activeCalories! >= 0
          ? raw.activeCalories
          : null,
      heartRate: validHeart ? raw.heartRate : null,
      heartRateAt: validHeart ? heartAt : null,
    );
    return HealthAiContext(
        data.hasData ? HealthAiStatus.ready : HealthAiStatus.noData,
        summary: data);
  }
}
