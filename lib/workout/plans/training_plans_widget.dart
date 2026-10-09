import 'package:flutter/material.dart';

import '/backend/supabase/repositories/training_plan_repository.dart';
import '/workout/routines/workout_routine_store.dart';

import 'training_plan_builder_widget.dart';
import 'training_plan_detail_widget.dart';
import 'training_plan_models.dart';
import 'training_plan_schedule.dart';
import 'training_plan_service.dart';
import 'training_plan_ui.dart';

/// Train → Plans: browse community plans, and see plans you follow or made.
/// Pops `true` when the Train calendar may have changed.
class TrainingPlansWidget extends StatefulWidget {
  const TrainingPlansWidget({super.key, this.service});

  final TrainingPlanService? service;

  @override
  State<TrainingPlansWidget> createState() => _TrainingPlansWidgetState();
}

class _TrainingPlansWidgetState extends State<TrainingPlansWidget> {
  late final TrainingPlanService _service =
      widget.service ?? TrainingPlanService();
  TrainingPlanRepository get _repository => _service.repository;

  int _tab = 0;
  String? _goal;
  final _search = TextEditingController();
  late Future<List<TrainingPlan>> _storeFuture;
  late Future<_MyPlans> _mineFuture;
  bool _calendarChanged = false;
  int? _reviewCount;

  @override
  void initState() {
    super.initState();
    _loadStore();
    _loadMine();
    _loadReviewCount();
  }

  /// Only GymFeed admins get a review queue; for everyone else this is null.
  Future<void> _loadReviewCount() async {
    try {
      if (!await _repository.isAdmin()) return;
      final queue = await _repository.reviewQueue();
      if (mounted) setState(() => _reviewCount = queue.length);
    } catch (_) {
      // The store works without the admin queue.
    }
  }

  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      settings: const RouteSettings(name: 'training-plan-review'),
      builder: (_) => TrainingPlanReviewQueueWidget(service: _service),
    ));
    if (mounted) {
      _refresh();
      _loadReviewCount();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _loadStore() =>
      _storeFuture = _repository.browse(goal: _goal, search: _search.text);

  void _loadMine() => _mineFuture = () async {
        final results = await Future.wait<dynamic>([
          _repository.mine(),
          _repository.activeEnrollments(),
          WorkoutRoutineStore.loadPlanSyncKeys(),
        ]);
        final local = results[2] as Map<String, String>;
        return _MyPlans(
          created: results[0] as List<TrainingPlan>,
          following: (results[1] as List<TrainingPlanEnrollment>)
              .where((item) =>
                  item.plan != null &&
                  local.containsKey(trainingPlanKey(item.planId)))
              .toList(),
        );
      }();

  void _refresh() => setState(() {
        _loadStore();
        _loadMine();
      });

  Future<void> _open(String planId) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'training-plan-detail'),
      builder: (_) =>
          TrainingPlanDetailWidget(planId: planId, service: _service),
    ));
    if (changed == true) _calendarChanged = true;
    if (mounted) _refresh();
  }

  Future<void> _create() async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'new-training-plan'),
      builder: (_) => TrainingPlanBuilderWidget(repository: _repository),
    ));
    if (saved == true && mounted) {
      setState(() => _tab = 1);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Draft saved. Open it and tap Submit to publish.')));
    }
  }

  Widget _tabs() {
    const labels = ['Discover', 'My plans'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: planBorder),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == _tab;
          return Expanded(
            child: InkWell(
              key: ValueKey('plans-tab-$index'),
              onTap: () => setState(() => _tab = index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? planGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(labels[index],
                    style: planText(
                        size: 12,
                        color: selected ? planBg : planMuted,
                        weight: FontWeight.w600)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
        child: Text(text,
            textAlign: TextAlign.center,
            style: planText(size: 13, color: planMuted)),
      );

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: CircularProgressIndicator(color: planGreen, strokeWidth: 2.4)),
      );

  List<Widget> _discover() => [
        TextField(
          key: const ValueKey('plans-search'),
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => setState(_loadStore),
          style: planText(size: 14),
          decoration: planInput('Search plans').copyWith(
            prefixIcon: const Icon(Icons.search_rounded, color: planMuted),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry in [
                const MapEntry<String?, String>(null, 'All'),
                ...trainingPlanGoals.entries
                    .map((e) => MapEntry<String?, String>(e.key, e.value)),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    key: ValueKey('plans-goal-${entry.key ?? 'all'}'),
                    label: Text(entry.value),
                    selected: _goal == entry.key,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _goal = entry.key;
                      _loadStore();
                    }),
                    labelStyle: planText(
                        size: 12,
                        color: _goal == entry.key ? planBg : Colors.white,
                        weight: FontWeight.w600),
                    backgroundColor: planCard,
                    selectedColor: planGreen,
                    side: BorderSide(
                        color: _goal == entry.key ? planGreen : planBorder),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<TrainingPlan>>(
          future: _storeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loading();
            }
            if (snapshot.hasError) {
              return _message('Plans could not load. Pull down to try again.');
            }
            final plans = snapshot.data ?? const [];
            if (plans.isEmpty) {
              return _message(
                  'No plans here yet. Be the first — create a plan and share it with the community.');
            }
            return Column(
              children: plans
                  .map((plan) => TrainingPlanCard(
                      plan: plan, onTap: () => _open(plan.id)))
                  .toList(),
            );
          },
        ),
      ];

  List<Widget> _mine() => [
        FutureBuilder<_MyPlans>(
          future: _mineFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loading();
            }
            if (snapshot.hasError) {
              return _message('Your plans could not load. Pull down to try again.');
            }
            final mine = snapshot.data ?? const _MyPlans();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('On my Train',
                    style: planText(
                        size: 13, color: planMuted, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (mine.following.isEmpty)
                  _message('Plans you add to your Train appear here.')
                else
                  ...mine.following.map((item) => TrainingPlanCard(
                      plan: item.plan!, onTap: () => _open(item.planId))),
                const SizedBox(height: 14),
                Text('Created by me',
                    style: planText(
                        size: 13, color: planMuted, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (mine.created.isEmpty)
                  _message('Plans you create appear here.')
                else
                  ...mine.created.map((plan) => TrainingPlanCard(
                      plan: plan, showStatus: true, onTap: () => _open(plan.id))),
              ],
            );
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _calendarChanged);
      },
      child: planScaled(
        context,
        Scaffold(
          backgroundColor: planBg,
          floatingActionButton: FloatingActionButton.extended(
            key: const ValueKey('create-training-plan'),
            onPressed: _create,
            backgroundColor: planGreen,
            foregroundColor: planBg,
            icon: const Icon(Icons.add_rounded),
            label: Text('Create plan',
                style: planText(size: 13, color: planBg, weight: FontWeight.w700)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                planTopBar(
                  context,
                  title: 'Training plans',
                  subtitle: 'From the GymFeed community',
                  action: _reviewCount == null
                      ? null
                      : TextButton(
                          key: const ValueKey('open-plan-review-queue'),
                          onPressed: _openReviewQueue,
                          child: Text('Review ($_reviewCount)',
                              style: planText(
                                  size: 12,
                                  color: _reviewCount! > 0
                                      ? planAmber
                                      : planMuted,
                                  weight: FontWeight.w700)),
                        ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: planGreen,
                    backgroundColor: planCard,
                    onRefresh: () async => _refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 96),
                      children: [
                        _tabs(),
                        const SizedBox(height: 16),
                        ...(_tab == 0 ? _discover() : _mine()),
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

class _MyPlans {
  const _MyPlans({this.created = const [], this.following = const []});

  final List<TrainingPlan> created;
  final List<TrainingPlanEnrollment> following;
}

/// Admin-only list of creators' plans waiting for review.
class TrainingPlanReviewQueueWidget extends StatefulWidget {
  const TrainingPlanReviewQueueWidget({super.key, this.service});

  final TrainingPlanService? service;

  @override
  State<TrainingPlanReviewQueueWidget> createState() =>
      _TrainingPlanReviewQueueWidgetState();
}

class _TrainingPlanReviewQueueWidgetState
    extends State<TrainingPlanReviewQueueWidget> {
  late final TrainingPlanService _service =
      widget.service ?? TrainingPlanService();
  late Future<List<TrainingPlan>> _queue = _service.repository.reviewQueue();

  Future<void> _open(String planId) async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      settings: const RouteSettings(name: 'training-plan-review-detail'),
      builder: (_) =>
          TrainingPlanDetailWidget(planId: planId, service: _service),
    ));
    if (mounted) setState(() => _queue = _service.repository.reviewQueue());
  }

  @override
  Widget build(BuildContext context) {
    return planScaled(
      context,
      Scaffold(
        backgroundColor: planBg,
        body: SafeArea(
          child: Column(
            children: [
              planTopBar(context,
                  title: 'Plans to review', subtitle: 'First plans of new creators'),
              Expanded(
                child: FutureBuilder<List<TrainingPlan>>(
                  future: _queue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: planGreen));
                    }
                    final plans = snapshot.data ?? const [];
                    if (snapshot.hasError || plans.isEmpty) {
                      return Center(
                        child: Text(
                            snapshot.hasError
                                ? 'The review queue could not load.'
                                : 'Nothing to review right now.',
                            style: planText(size: 13, color: planMuted)),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      children: plans
                          .map((plan) => TrainingPlanCard(
                              plan: plan, onTap: () => _open(plan.id)))
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
