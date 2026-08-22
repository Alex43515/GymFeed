import '/auth/firebase_auth/auth_util.dart';
import '/ai_workout/coach_home/coach_section_switcher.dart';
import '/ai_workout/premium/ai_usage_gate.dart';
import '/backend/supabase/supabase.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

class CoachStats {
  const CoachStats({
    this.mealsScanned = 0,
    this.machinesLearned = 0,
    this.bodyScans = 0,
  });

  final int mealsScanned;
  final int machinesLearned;
  final int bodyScans;

  static Future<CoachStats> load() async {
    final userId = currentUserUid;
    if (userId.isEmpty) return const CoachStats();

    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1))
        .toUtc()
        .toIso8601String();

    var mealsScanned = 0;
    try {
      final meals = await supabase
          .from('meal_scans')
          .select('id')
          .eq('user_id', userId)
          .gte('scanned_on', startOfWeek);
      mealsScanned = meals.length;
    } catch (_) {}

    final private = await _privateCounters(userId);
    var machinesLearned = (private['vision_button'] as num?)?.toInt() ??
        currentUserDocument?.visionButton ??
        0;
    var bodyScans = (private['body_scan_count'] as num?)?.toInt() ?? 0;
    try {
      final activity = await supabase
          .from('coach_activity_log')
          .select('tool')
          .eq('user_id', userId)
          .gte('created_at', startOfWeek);
      machinesLearned =
          activity.where((row) => row['tool'] == 'equipment_scan').length;
      bodyScans = activity.where((row) => row['tool'] == 'body_scan').length;
    } catch (_) {
      // Migration 0014 may not be deployed yet; show compatibility totals.
    }
    return CoachStats(
      mealsScanned: mealsScanned,
      machinesLearned: machinesLearned,
      bodyScans: bodyScans,
    );
  }

  static Future<Map<String, dynamic>> _privateCounters(String userId) async {
    try {
      return await supabase
              .from('profile_private')
              .select('vision_button, body_scan_count')
              .eq('id', userId)
              .maybeSingle() ??
          const <String, dynamic>{};
    } catch (_) {
      return await supabase
              .from('profile_private')
              .select('vision_button')
              .eq('id', userId)
              .maybeSingle() ??
          const <String, dynamic>{};
    }
  }
}

enum _CoachTool { food, equipment, trainer, body }

class _CoachToolData {
  const _CoachToolData({
    required this.tool,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final _CoachTool tool;
  final String title;
  final String subtitle;
  final IconData icon;
}

class CoachHomeWidget extends StatefulWidget {
  const CoachHomeWidget({
    super.key,
    this.statsLoader,
    this.entitlementLoader,
    this.usageStatusLoader,
    this.upgradeOpener,
  });

  static String routeName = 'coachHome';
  static String routePath = 'coachHome';

  final Future<CoachStats> Function()? statsLoader;
  final Future<bool> Function()? entitlementLoader;
  final Future<AiUsageStatus> Function()? usageStatusLoader;
  final Future<void> Function()? upgradeOpener;

  static Future<CoachStats>? _cachedStats;
  static String? _cachedStatsUserId;

  static Future<void> warmUp() async {
    await _loadStats();
  }

  static Future<CoachStats> _loadStats({bool refresh = false}) {
    final userId = currentUserUid;
    if (refresh || _cachedStats == null || _cachedStatsUserId != userId) {
      _cachedStatsUserId = userId;
      _cachedStats = CoachStats.load();
    }
    return _cachedStats!;
  }

  @override
  State<CoachHomeWidget> createState() => _CoachHomeWidgetState();
}

class _CoachHomeWidgetState extends State<CoachHomeWidget> {
  static const _background = Color(0xFF0B0B0B);
  static const _surface = Color(0xFF141414);
  static const _surfaceBorder = Color(0xFF252525);
  static const _muted = Color(0xFF8A8A8A);
  static const _iconSurface = Color(0xFF103820);

  static const _tools = [
    _CoachToolData(
      tool: _CoachTool.food,
      title: 'Scan food',
      subtitle: 'Calories & macros from a photo',
      icon: Icons.restaurant_rounded,
    ),
    _CoachToolData(
      tool: _CoachTool.equipment,
      title: 'Scan equipment',
      subtitle: 'Identify any machine instantly',
      icon: Icons.fitness_center_rounded,
    ),
    _CoachToolData(
      tool: _CoachTool.trainer,
      title: 'AI Trainer',
      subtitle: 'Chat with your 24/7 coach',
      icon: Icons.auto_awesome_rounded,
    ),
    _CoachToolData(
      tool: _CoachTool.body,
      title: 'Body scan',
      subtitle: 'Full composition report',
      icon: Icons.accessibility_new_rounded,
    ),
  ];

  late Future<CoachStats> _statsFuture;
  late Future<AiUsageStatus> _usageFuture;
  bool _openingTool = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = widget.statsLoader?.call() ?? CoachHomeWidget._loadStats();
    _usageFuture = _loadUsageStatus();
  }

  Future<AiUsageStatus> _loadUsageStatus() async {
    if (widget.usageStatusLoader != null) {
      return widget.usageStatusLoader!();
    }
    if (widget.entitlementLoader != null) {
      final premium = await widget.entitlementLoader!();
      return AiUsageStatus(isPremium: premium, used: 0);
    }
    return AiUsageGate().loadStatus();
  }

  Future<void> _refresh() async {
    _statsFuture =
        widget.statsLoader?.call() ?? CoachHomeWidget._loadStats(refresh: true);
    _usageFuture = _loadUsageStatus();
    safeSetState(() {});
    await Future.wait<dynamic>([_statsFuture, _usageFuture]);
  }

  Future<void> _openTool(_CoachTool tool) async {
    if (_openingTool) return;
    safeSetState(() => _openingTool = true);
    final routeName = switch (tool) {
      _CoachTool.food => CoachFoodScannerWidget.routeName,
      _CoachTool.equipment => CoachEquipmentScannerWidget.routeName,
      _CoachTool.trainer => CoachTrainerWidget.routeName,
      _CoachTool.body => CoachBodyScanWidget.routeName,
    };

    await context.pushNamed(routeName);
    if (!mounted) return;
    _statsFuture =
        widget.statsLoader?.call() ?? CoachHomeWidget._loadStats(refresh: true);
    _usageFuture = _loadUsageStatus();
    safeSetState(() => _openingTool = false);
  }

  Future<void> _openUpgrade() async {
    if (widget.upgradeOpener != null) {
      await widget.upgradeOpener!();
    } else {
      await openPremiumUpgrade(context);
    }
    if (!mounted) return;
    _usageFuture = _loadUsageStatus();
    safeSetState(() {});
  }

  void _selectSection(CoachSection section) {
    switch (section) {
      case CoachSection.coach:
        return;
      case CoachSection.train:
        context.goNamed(TrainingHomeWidget.routeName);
        return;
      case CoachSection.events:
        context.goNamed(CoachEventsWidget.routeName);
        return;
    }
  }

  String _dateLabel() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  TextStyle _style(
    BuildContext context, {
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
  }) =>
      FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Poppins',
            color: color ?? FlutterFlowTheme.of(context).tertiary,
            fontSize: size,
            letterSpacing: 0,
            fontWeight: weight,
            lineHeight: height,
          );

  Widget _header(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Coach',
                style: _style(
                  context,
                  size: 28,
                  weight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<AiUsageStatus>(
          future: _usageFuture,
          builder: (context, snapshot) {
            final status =
                snapshot.data ?? const AiUsageStatus(isPremium: false, used: 0);
            final active = status.isPremium;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? theme.primary.withValues(alpha: 0.10)
                    : const Color(0xFFFF8A2A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? theme.primary.withValues(alpha: 0.28)
                      : const Color(0xFFFF8A2A).withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? theme.primary : const Color(0xFFFF8A2A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    active
                        ? 'Pro active'
                        : '${status.remaining} free ${status.remaining == 1 ? 'use' : 'uses'} left',
                    style: _style(
                      context,
                      size: 13,
                      color: active ? theme.primary : const Color(0xFFFF8A2A),
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _premiumBanner(BuildContext context) {
    return FutureBuilder<AiUsageStatus>(
      future: _usageFuture,
      builder: (context, snapshot) {
        final status =
            snapshot.data ?? const AiUsageStatus(isPremium: false, used: 0);
        if (status.isPremium) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _iconSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF176137)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFF1FE276)),
                const SizedBox(width: 11),
                Expanded(
                  child: Text('GymFeed Pro active · Unlimited AI tools',
                      style:
                          _style(context, size: 13, weight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }
        return Container(
          key: const ValueKey('coach-premium-banner'),
          padding: const EdgeInsets.fromLTRB(17, 15, 15, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF20E576), Color(0xFF35CD70)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x22000000),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF062313), size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unlock GymFeed Pro',
                        style: _style(context,
                            size: 15,
                            color: const Color(0xFF07180E),
                            weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      status.exhausted
                          ? '0 uses left · Upgrade for unlimited access'
                          : '${status.remaining} free uses left · Then upgrade',
                      style: _style(context,
                          size: 11, color: const Color(0xFF174C2B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('coach-upgrade'),
                onPressed: _openUpgrade,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF06351C),
                  foregroundColor: const Color(0xFF1FE276),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text('Upgrade',
                    style: _style(context,
                        size: 12,
                        color: const Color(0xFF1FE276),
                        weight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _nutritionDiaryCard(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      key: const ValueKey('coach-nutrition-diary'),
      onTap: () => context.pushNamed(NutritionDiaryWidget.routeName),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  Icon(Icons.menu_book_rounded, color: theme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrition diary',
                      style:
                          _style(context, size: 15, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Your logged meals, day by day',
                      style: _style(context, size: 11, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 23),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      key: const ValueKey('coach-progress'),
      onTap: () => context.pushNamed(MyInfoWidget.routeName),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  Icon(Icons.bar_chart_rounded, color: theme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Progress & plans',
                      style:
                          _style(context, size: 15, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Your custom plans, stats & monthly photos',
                      style: _style(context, size: 11, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 23),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10482B), Color(0xFF111B15), Color(0xFF0E0E0E)],
          stops: [0, 0.48, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your body, decoded.',
            style: _style(context, size: 21, weight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            'Scan meals, decode machines, chat with your trainer, and track '
            'composition — all with AI.',
            style: _style(context, size: 14, color: const Color(0xFFE2E2E2)),
          ),
        ],
      ),
    );
  }

  Widget _toolCard(BuildContext context, _CoachToolData data) {
    final theme = FlutterFlowTheme.of(context);
    return Semantics(
      button: true,
      label: '${data.title}. ${data.subtitle}',
      child: InkWell(
        onTap: _openingTool ? null : () => _openTool(data.tool),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, color: theme.primary, size: 22),
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _style(context, size: 15, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _style(context, size: 12, color: _muted, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, int value, String label,
      {bool accent = false}) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: _style(
              context,
              size: 21,
              color: accent ? theme.primary : theme.tertiary,
              weight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _style(context, size: 11, color: _muted, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(BuildContext context) {
    return FutureBuilder<CoachStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const CoachStats();
        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'This week',
                      style: _style(
                        context,
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(_dateLabel(),
                      style: _style(context, size: 11, color: _muted)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stat(context, stats.mealsScanned, 'Meals scanned',
                      accent: true),
                  _stat(context, stats.machinesLearned, 'Machines learned'),
                  _stat(context, stats.bodyScans, 'Body scans'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final effectiveTextScale =
        mediaQuery.textScaler.scale(1).clamp(1.0, 1.4).toDouble();
    final toolCardHeight = 172 + ((effectiveTextScale - 1) * 40);
    final horizontalPadding =
        mediaQuery.size.width > 640 ? (mediaQuery.size.width - 600) / 2 : 20.0;

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.4),
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const NavBarWidget(selectPageIndex: 3),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: FlutterFlowTheme.of(context).primary,
            backgroundColor: _surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      horizontalPadding, 20, horizontalPadding, 0),
                  sliver: SliverList.list(
                    children: [
                      CoachSectionSwitcher(
                        selected: CoachSection.coach,
                        onSelected: _selectSection,
                      ),
                      const SizedBox(height: 18),
                      _header(context),
                      const SizedBox(height: 12),
                      _premiumBanner(context),
                      const SizedBox(height: 20),
                      _hero(context),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your AI tools',
                              style: _style(
                                context,
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text('4 unlocked',
                              style: _style(context, size: 12, color: _muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: toolCardHeight,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _toolCard(context, _tools[index]),
                      childCount: _tools.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      horizontalPadding, 22, horizontalPadding, 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _nutritionDiaryCard(context),
                        const SizedBox(height: 14),
                        _progressCard(context),
                        const SizedBox(height: 14),
                        _statsCard(context),
                      ],
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
