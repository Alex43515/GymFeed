import '/ai_workout/payment/payment_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;
import '/index.dart';
import 'package:flutter/material.dart';
import 'training_home_model.dart';
export 'training_home_model.dart';

class TrainingHomeWidget extends StatefulWidget {
  const TrainingHomeWidget({super.key});

  static String routeName = 'trainingHome';
  static String routePath = 'trainingHome';

  @override
  State<TrainingHomeWidget> createState() => _TrainingHomeWidgetState();
}

class _TrainingHomeWidgetState extends State<TrainingHomeWidget> {
  late TrainingHomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Plans / Joined / History
  int _tab = 0;

  // Design tokens (GymFeed AI Coach design).
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF141414);
  static const Color _cardBorder = Color(0xFF232323);
  static const Color _muted = Color(0xFF8A8A8A);
  static const Color _flame = Color(0xFFFF8A3D);

  static const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdayLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrainingHomeModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _openTraining(UsersRecord? user, DocumentReference trainingRef) {
    context.pushNamed(
      TrainingpostDetailsWidget.routeName,
      queryParameters: {
        'userRecord': serializeParam(user, ParamType.Document),
        'trainingReference':
            serializeParam(trainingRef, ParamType.DocumentReference),
      }.withoutNulls,
      extra: <String, dynamic>{'userRecord': user},
    );
  }

  // ── AI feature chooser (labeled AI Coach pill + center Coach tab) ───────────
  // Each option keeps the freemium gate: a shared free-usage counter (gptButton)
  // up to 5 uses, then the paywall unless the user is entitled (→ Pro screen).
  Future<void> _showAiChooser() async {
    final theme = FlutterFlowTheme.of(context);
    Widget optionRow(String label, VoidCallback onTap) => InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(24.0, 20.0, 20.0, 20.0),
            child: Row(
              children: [
                Container(
                  width: 18.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF0A0A0A), width: 2.0),
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    label,
                    style: theme.headlineMedium.override(
                      fontFamily: 'Poppins',
                      color: const Color(0xFF0A0A0A),
                      fontSize: 18.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF0A0A0A), size: 24.0),
              ],
            ),
          ),
        );
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (sheetContext) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10.0),
              optionRow('Personal AI fitness expert', () {
                Navigator.pop(sheetContext);
                _openAiFeature(isScanner: false);
              }),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                child: Container(height: 1.0, color: const Color(0x1A0A0A0A)),
              ),
              optionRow('Machine scanner', () {
                Navigator.pop(sheetContext);
                _openAiFeature(isScanner: true);
              }),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
    if (mounted) safeSetState(() {});
  }

  Future<void> _openAiFeature({required bool isScanner}) async {
    final isEntitled =
        await revenue_cat.isEntitled('premium_features') ?? false;
    if (!isEntitled) {
      await revenue_cat.loadOfferings();
    }
    if (!mounted) return;
    if (isEntitled) {
      context.pushNamed(isScanner
          ? GptVisionProWidget.routeName
          : AssistantGPTProWidget.routeName);
      return;
    }
    final used = valueOrDefault(currentUserDocument?.gptButton, 0);
    if (used <= 5) {
      await currentUserReference!.update({
        ...mapToFirestore({'gptButton': FieldValue.increment(1)}),
      });
      if (!mounted) return;
      context.pushNamed(
          isScanner ? GptVisionWidget.routeName : AssistantGPTWidget.routeName);
    } else {
      _showPaywall();
    }
  }

  void _showPaywall() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: PaymentWidget(),
      ),
    ).then((value) => safeSetState(() {}));
  }

  // ── Sections ───────────────────────────────────────────────────────────────
  Widget _header(int streak) {
    final theme = FlutterFlowTheme.of(context);
    final now = getCurrentTimestamp;
    final dateStr =
        '${_weekdayLong[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';
    final name = currentUserDisplayName.trim().isEmpty
        ? 'athlete'
        : currentUserDisplayName.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20.0, 14.0, 20.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: theme.bodySmall.override(
                    fontFamily: 'Poppins',
                    color: _muted,
                    fontSize: 13.0,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  "Let's train, $name",
                  style: theme.headlineMedium.override(
                    fontFamily: 'Poppins',
                    color: theme.tertiary,
                    fontSize: 26.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            padding:
                const EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 14.0, 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(22.0),
              border: Border.all(color: _cardBorder, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: _flame, size: 18.0),
                const SizedBox(width: 6.0),
                Text(
                  '$streak',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: theme.tertiary,
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStrip() {
    final theme = FlutterFlowTheme.of(context);
    final now = getCurrentTimestamp;
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 18.0, 12.0, 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final d = monday.add(Duration(days: i));
          final isToday = d.day == now.day && d.month == now.month;
          // green dot for today and earlier days this week (workout streak feel)
          final dotOn = i <= (now.weekday - 1);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekdayShort[i],
                style: theme.bodySmall.override(
                  fontFamily: 'Poppins',
                  color: _muted,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: 34.0,
                height: 34.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday ? theme.primary : Colors.transparent,
                ),
                child: Text(
                  '${d.day}',
                  style: theme.bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: isToday ? const Color(0xFF0A0A0A) : theme.tertiary,
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6.0),
              Container(
                width: 5.0,
                height: 5.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotOn ? theme.primary : Colors.transparent,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2.0, 0.0, 0.0, 10.0),
      child: Text(
        text,
        style: theme.bodyMedium.override(
          fontFamily: 'Poppins',
          color: _muted,
          fontSize: 14.0,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _todayCard(UserTrainingsRecord t) {
    final theme = FlutterFlowTheme.of(context);
    final meta = t.duration > 0
        ? '${t.trainingCategory} · ~${t.duration} min'
        : [t.trainingCategory, t.trainingTime]
            .where((s) => s.isNotEmpty)
            .join(' · ');
    return StreamBuilder<UsersRecord>(
      stream: t.userTraining != null
          ? UsersRecord.getDocument(t.userTraining!)
          : const Stream.empty(),
      builder: (context, snap) {
        final user = snap.data;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: _cardBorder, width: 1.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.trainingTitle.isEmpty
                              ? 'Your next session'
                              : t.trainingTitle,
                          style: theme.headlineMedium.override(
                            fontFamily: 'Poppins',
                            color: theme.tertiary,
                            fontSize: 20.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (meta.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 4.0, 0.0, 0.0),
                            child: Text(
                              meta,
                              style: theme.bodySmall.override(
                                fontFamily: 'Poppins',
                                color: _muted,
                                fontSize: 13.0,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Container(
                    width: 44.0,
                    height: 44.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded,
                        color: Color(0xFF0A0A0A), size: 22.0),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _openTraining(user, t.reference),
                      borderRadius: BorderRadius.circular(24.0),
                      child: Container(
                        height: 48.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24.0),
                          border:
                              Border.all(color: const Color(0x33FFFFFF), width: 1.5),
                        ),
                        child: Text(
                          'Preview',
                          style: theme.bodyMedium.override(
                            fontFamily: 'Poppins',
                            color: theme.tertiary,
                            fontSize: 15.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: InkWell(
                      onTap: () => _openTraining(user, t.reference),
                      borderRadius: BorderRadius.circular(24.0),
                      child: Container(
                        height: 48.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Color(0xFF0A0A0A), size: 20.0),
                            const SizedBox(width: 4.0),
                            Text(
                              'Start workout',
                              style: theme.bodyMedium.override(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF0A0A0A),
                                fontSize: 15.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _aiCoachPill() {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: () async => _showAiChooser(),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(14.0, 14.0, 16.0, 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF08240F),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.primary.withOpacity(0.5), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF0A0A0A), size: 20.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Coach',
                    style: theme.bodyMedium.override(
                      fontFamily: 'Poppins',
                      color: theme.tertiary,
                      fontSize: 15.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Ask the expert or scan a machine',
                    style: theme.bodySmall.override(
                      fontFamily: 'Poppins',
                      color: _muted,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.primary, size: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _tabsRow() {
    final theme = FlutterFlowTheme.of(context);
    Widget tab(String label, int i) {
      final active = _tab == i;
      return Expanded(
        child: InkWell(
          onTap: () => safeSetState(() => _tab = i),
          borderRadius: BorderRadius.circular(22.0),
          child: Container(
            height: 40.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? theme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(22.0),
            ),
            child: Text(
              label,
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: active ? const Color(0xFF0A0A0A) : _muted,
                fontSize: 14.0,
                letterSpacing: 0.0,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(26.0),
        border: Border.all(color: _cardBorder, width: 1.0),
      ),
      child: Row(
        children: [tab('Plans', 0), tab('Joined', 1), tab('History', 2)],
      ),
    );
  }

  Widget _planCard(UserTrainingsRecord t) {
    final theme = FlutterFlowTheme.of(context);
    final metaBits = [t.difficultyLevel, t.trainingTime]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return StreamBuilder<UsersRecord>(
      stream: t.userTraining != null
          ? UsersRecord.getDocument(t.userTraining!)
          : const Stream.empty(),
      builder: (context, snap) {
        final user = snap.data;
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 14.0),
          child: Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: _cardBorder, width: 1.0),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.0),
                  child: Container(
                    width: 64.0,
                    height: 64.0,
                    color: const Color(0xFF1C1C1C),
                    alignment: Alignment.center,
                    child: t.trainingBackgroundImage.isNotEmpty
                        ? Image.network(
                            t.trainingBackgroundImage,
                            width: 64.0,
                            height: 64.0,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: _muted,
                                size: 24.0),
                          )
                        : const Icon(Icons.fitness_center_rounded,
                            color: _muted, size: 24.0),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.trainingTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          fontFamily: 'Poppins',
                          color: theme.tertiary,
                          fontSize: 15.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (t.trainingCategory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 3.0, 0.0, 0.0),
                          child: Text(
                            t.trainingCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.override(
                              fontFamily: 'Poppins',
                              color: theme.primary,
                              fontSize: 12.5,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (metaBits.isNotEmpty)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 2.0, 0.0, 0.0),
                          child: Text(
                            metaBits,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.override(
                              fontFamily: 'Poppins',
                              color: _muted,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openTraining(user, t.reference),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 38.0,
                        height: 38.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Color(0xFF0A0A0A), size: 22.0),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    InkWell(
                      onTap: () => _openTraining(user, t.reference),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: _muted, size: 20.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.fitness_center_rounded, color: _muted, size: 40.0),
            const SizedBox(height: 12.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: _muted,
                fontSize: 14.0,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _bg,
        floatingActionButton: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
          child: FloatingActionButton(
            onPressed: () async {
              context.pushNamed(JoinTrainingWidget.routeName);
            },
            backgroundColor: theme.primary,
            elevation: 8.0,
            child: Icon(Icons.add, color: theme.secondary, size: 32.0),
          ),
        ),
        bottomNavigationBar: wrapWithModel(
          model: _model.navBarModel,
          updateCallback: () => safeSetState(() {}),
          child: NavBarWidget(selectPageIndex: 3),
        ),
        body: SafeArea(
          child: StreamBuilder<List<UserTrainingsRecord>>(
            stream: queryUserTrainingsRecord(
              queryBuilder: (userTrainingsRecord) => userTrainingsRecord
                  .orderBy('TrainingDate')
                  .orderBy('TrainingTime'),
            ),
            builder: (context, snapshot) {
              final loading = !snapshot.hasData;
              final all = snapshot.data ?? <UserTrainingsRecord>[];
              final today = all.isNotEmpty ? all.first : null;

              List<UserTrainingsRecord> visible;
              String emptyText;
              if (_tab == 1) {
                visible = all
                    .where((t) =>
                        t.trainingAttendees.contains(currentUserReference))
                    .toList();
                emptyText = 'You haven\'t joined any trainings yet.';
              } else if (_tab == 2) {
                visible = all
                    .where((t) => t.userTraining == currentUserReference)
                    .toList();
                emptyText = 'Trainings you create will show up here.';
              } else {
                visible = all;
                emptyText = 'No plans yet — tap + to schedule one.';
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(all.length),
                    _weekStrip(),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          20.0, 22.0, 20.0, 120.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (today != null) ...[
                            _sectionLabel("Today's plan"),
                            _todayCard(today),
                            const SizedBox(height: 18.0),
                          ],
                          _aiCoachPill(),
                          const SizedBox(height: 22.0),
                          _tabsRow(),
                          const SizedBox(height: 16.0),
                          if (loading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Center(
                                child: SizedBox(
                                  width: 22.0,
                                  height: 22.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.primary),
                                  ),
                                ),
                              ),
                            )
                          else if (visible.isEmpty)
                            _emptyState(emptyText)
                          else
                            ...visible.map(_planCard),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
