import '/ai_workout/coach_home/coach_section_switcher.dart';
import '/backend/supabase/repositories/training_repository.dart';
import '/backend/supabase/supabase.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

class CoachEventsWidget extends StatefulWidget {
  const CoachEventsWidget({super.key, this.trainingsLoader});

  static String routeName = 'coachEvents';
  static String routePath = 'coachEvents';

  final Future<List<Training>> Function()? trainingsLoader;

  @override
  State<CoachEventsWidget> createState() => _CoachEventsWidgetState();
}

class _CoachEventsWidgetState extends State<CoachEventsWidget> {
  static const _background = Color(0xFF0B0B0B);
  static const _surface = Color(0xFF151515);
  static const _border = Color(0xFF262626);
  static const _muted = Color(0xFF8B8B8B);
  static const _filters = ['All', 'Full body', 'Cardio', 'Cross-Fit', 'Legs'];

  late Future<List<Training>> _future;
  final Map<String, bool> _joined = {};
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';
  String _scope = 'Discover';
  String _query = '';
  bool _searching = false;

  String? get _currentUserId {
    try {
      return supabase.auth.currentUser?.id;
    } catch (_) {
      // Widget tests can inject data without booting the Supabase singleton.
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Training>> _load() async {
    if (widget.trainingsLoader != null) return widget.trainingsLoader!();
    final repository = TrainingRepository();
    final uid = _currentUserId;
    final groups = await Future.wait<List<Training>>([
      repository.feed(limit: 100),
      if (uid != null) repository.joinedByCurrentUser(limit: 100),
      if (uid != null) repository.byUser(uid, limit: 100),
    ]);
    final unique = <String, Training>{};
    for (final group in groups) {
      for (final training in group) {
        unique[training.id] = training;
      }
    }
    final result = unique.values.toList(growable: false);
    result.sort((a, b) => (b.startsAt ?? b.createdAt ?? DateTime(1970))
        .compareTo(a.startsAt ?? a.createdAt ?? DateTime(1970)));
    return result;
  }

  Future<void> _refresh() async {
    _future = _load();
    setState(() {});
    await _future;
  }

  void _selectSection(CoachSection section) {
    switch (section) {
      case CoachSection.coach:
        context.goNamed(CoachHomeWidget.routeName);
        return;
      case CoachSection.train:
        context.goNamed(TrainingHomeWidget.routeName);
        return;
      case CoachSection.events:
        return;
    }
  }

  bool _matches(Training training) {
    final haystack =
        '${training.title} ${training.description ?? ''} ${training.authorUsername} ${training.authorDisplayName}'
            .toLowerCase();
    final normalizedCategory =
        training.category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final normalizedFilter =
        _filter.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final filterMatches = switch (_filter) {
      'All' => true,
      _ => normalizedCategory == normalizedFilter,
    };
    final uid = _currentUserId;
    final joined = _joined[training.id] ?? training.joinedByMe;
    final scopeMatches = switch (_scope) {
      'Joined' => joined,
      'Created' => uid != null && training.userId == uid,
      _ => true,
    };
    final words = _query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return scopeMatches && filterMatches && words.every(haystack.contains);
  }

  String _scheduleLabel(Training training) {
    final start = training.startsAt;
    if (start != null) {
      final local = start.toLocal();
      return '${dateTimeFormat('EEE, MMM d', local)} · ${dateTimeFormat('jm', local)}';
    }
    final parts = [training.trainingDateRaw, training.trainingTimeRaw]
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    return parts.isEmpty ? 'Schedule to be confirmed' : parts;
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  Future<void> _toggleJoined(Training training) async {
    final wasJoined = _joined[training.id] ?? training.joinedByMe;
    setState(() => _joined[training.id] = !wasJoined);
    try {
      if (wasJoined) {
        await TrainingRepository().leave(training.id);
      } else {
        await TrainingRepository().join(training.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _joined[training.id] = wasJoined);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not update this event. Try again.')),
      );
    }
  }

  TextStyle _text({
    double size = 14,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  Widget _upcomingCard(Training training, int index) {
    final image = training.coverUrl;
    final joined = _joined[training.id] ?? training.joinedByMe;
    return GestureDetector(
      key: ValueKey('upcoming-event-${training.id}'),
      onTap: () => _openEventDetails(training),
      child: Container(
        width: 238,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          image: image.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(image),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(
                      Color(0x99101010), BlendMode.darken),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _scheduleLabel(training),
                    style: _text(size: 11, color: const Color(0xFFC9C9C9)),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: joined
                        ? const Color(0xFF1FE276)
                        : const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    joined ? 'JOINED' : 'OPEN',
                    style: _text(
                      size: 9,
                      color: joined ? const Color(0xFF070707) : Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              training.title.isEmpty ? 'Training event' : training.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _text(size: 18, weight: FontWeight.w700, height: 1.15),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, size: 14, color: _muted),
                  const SizedBox(width: 5),
                  Text(
                      training.difficultyLevel.isEmpty
                          ? 'All levels'
                          : training.difficultyLevel,
                      style: _text(size: 11, color: _muted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule_rounded, size: 14, color: _muted),
                  const SizedBox(width: 5),
                  Text(
                      training.duration > 0
                          ? '${training.duration} min'
                          : 'Flexible',
                      style: _text(size: 11, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(Training training, int index) {
    final theme = FlutterFlowTheme.of(context);
    final image = training.coverUrl;
    final joined = _joined[training.id] ?? training.joinedByMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        key: ValueKey('event-card-${training.id}'),
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openEventDetails(training),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 142,
                width: double.infinity,
                child: image.isEmpty
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF163A27), Color(0xFF101010)],
                          ),
                        ),
                        child: Icon(
                          index.isEven
                              ? Icons.fitness_center_rounded
                              : Icons.directions_run_rounded,
                          color: theme.primary.withValues(alpha: 0.72),
                          size: 42,
                        ),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF17281E),
                          child: Icon(Icons.fitness_center_rounded,
                              color: Color(0xFF1FE276), size: 40),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        training.category.isEmpty
                            ? 'Workout'
                            : training.category,
                        style: _text(
                            size: 11,
                            color: theme.primary,
                            weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      training.title.isEmpty
                          ? 'GymFeed workout'
                          : training.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(size: 17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      training.description?.isNotEmpty == true
                          ? training.description!
                          : '${training.difficultyLevel.isEmpty ? 'All levels' : training.difficultyLevel} · ${training.duration > 0 ? '${training.duration} min' : 'Flexible'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(size: 12, color: _muted),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton(
                        onPressed: () => _toggleJoined(training),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              joined ? const Color(0xFF242424) : theme.primary,
                          foregroundColor:
                              joined ? Colors.white : const Color(0xFF080808),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(joined ? 'Joined' : 'Join',
                            style: _text(
                              size: 13,
                              color: joined
                                  ? Colors.white
                                  : const Color(0xFF080808),
                              weight: FontWeight.w700,
                            )),
                      ),
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

  Future<void> _openEventDetails(Training training) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final joined = _joined[training.id] ?? training.joinedByMe;
          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .9),
            decoration: const BoxDecoration(
              color: Color(0xFF101010),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                Align(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF555555),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (training.coverUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      training.coverUrl,
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        training.category.isEmpty
                            ? 'Workout event'
                            : training.category,
                        style: _text(
                            size: 12,
                            color: FlutterFlowTheme.of(context).primary,
                            weight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                    training.title.isEmpty ? 'GymFeed workout' : training.title,
                    style: _text(size: 24, weight: FontWeight.w700)),
                const SizedBox(height: 12),
                _detailLine(
                    Icons.calendar_month_rounded, _scheduleLabel(training)),
                _detailLine(
                    Icons.speed_rounded,
                    training.difficultyLevel.isEmpty
                        ? 'All levels'
                        : training.difficultyLevel),
                _detailLine(
                    Icons.timer_outlined,
                    training.duration > 0
                        ? '${training.duration} minutes'
                        : 'Flexible duration'),
                if (training.locationLat != null &&
                    training.locationLng != null)
                  _detailLine(Icons.location_on_outlined,
                      '${training.locationLat!.toStringAsFixed(5)}, ${training.locationLng!.toStringAsFixed(5)}'),
                if (training.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Text(training.description!,
                      style: _text(size: 13, color: const Color(0xFFC4C4C4))),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: ValueKey('event-details-join-${training.id}'),
                    onPressed: () async {
                      await _toggleJoined(training);
                      setSheetState(() {});
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: joined
                          ? const Color(0xFF292929)
                          : FlutterFlowTheme.of(context).primary,
                      foregroundColor:
                          joined ? Colors.white : const Color(0xFF080808),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27)),
                    ),
                    child: Text(joined ? 'Leave event' : 'Join event',
                        style: _text(
                            size: 14,
                            color:
                                joined ? Colors.white : const Color(0xFF080808),
                            weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _detailLine(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(icon, color: _muted, size: 19),
            const SizedBox(width: 10),
            Expanded(child: Text(value, style: _text(size: 13))),
          ],
        ),
      );

  Widget _loadingCard({double height = 210}) => Container(
        height: height,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.2, color: Color(0xFF1FE276)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final horizontal =
        media.size.width > 640 ? (media.size.width - 600) / 2 : 20.0;

    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.35)),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const NavBarWidget(selectPageIndex: 3),
        body: SafeArea(
          child: FutureBuilder<List<Training>>(
            future: _future,
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <Training>[];
              final visible = all.where(_matches).toList();
              return RefreshIndicator(
                onRefresh: _refresh,
                color: FlutterFlowTheme.of(context).primary,
                backgroundColor: _surface,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 110),
                  children: [
                    CoachSectionSwitcher(
                      selected: CoachSection.events,
                      onSelected: _selectSection,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Upcoming activities',
                              style: _text(size: 21, weight: FontWeight.w700)),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('View more',
                              style: _text(size: 12, color: _muted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      _loadingCard(height: 180)
                    else if (all.isNotEmpty)
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: all.take(2).length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, index) =>
                              _upcomingCard(all[index], index),
                        ),
                      ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _searching
                                ? TextField(
                                    key: const ValueKey('event-search-input'),
                                    controller: _searchController,
                                    autofocus: true,
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                    textInputAction: TextInputAction.search,
                                    style: _text(size: 14),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search events, hosts, workouts…',
                                      hintStyle: _text(size: 12, color: _muted),
                                      isDense: true,
                                      filled: true,
                                      fillColor: _surface,
                                      prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: _muted,
                                          size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide:
                                            const BorderSide(color: _border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide:
                                            const BorderSide(color: _border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primary),
                                      ),
                                    ),
                                  )
                                : Align(
                                    key: const ValueKey('event-list-title'),
                                    alignment: Alignment.centerLeft,
                                    child: Text('Events',
                                        style: _text(
                                            size: 22, weight: FontWeight.w700)),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: const ValueKey('event-search-toggle'),
                          tooltip: 'Search events',
                          onPressed: _toggleSearch,
                          icon: Icon(
                            _searching
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      key: const ValueKey('event-scope-tabs'),
                      children:
                          const ['Discover', 'Joined', 'Created'].map((scope) {
                        final selected = scope == _scope;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: scope == 'Created' ? 0 : 8),
                            child: ChoiceChip(
                              key: ValueKey('event-scope-$scope'),
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(scope, textAlign: TextAlign.center),
                              ),
                              selected: selected,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _scope = scope),
                              selectedColor:
                                  FlutterFlowTheme.of(context).primary,
                              backgroundColor: _surface,
                              side: BorderSide(
                                  color: selected
                                      ? FlutterFlowTheme.of(context).primary
                                      : _border),
                              labelStyle: _text(
                                size: 11,
                                color:
                                    selected ? const Color(0xFF080808) : _muted,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final value = _filters[index];
                          final selected = value == _filter;
                          return ChoiceChip(
                            key: ValueKey('event-filter-$value'),
                            label: Text(value),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = value),
                            showCheckmark: false,
                            selectedColor: FlutterFlowTheme.of(context).primary,
                            backgroundColor: _surface,
                            side: BorderSide(
                                color: selected
                                    ? FlutterFlowTheme.of(context).primary
                                    : _border),
                            labelStyle: _text(
                              size: 12,
                              color:
                                  selected ? const Color(0xFF080808) : _muted,
                              weight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      _loadingCard(height: 300)
                    else if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Text(
                          'Events could not load. Pull down to retry.',
                          textAlign: TextAlign.center,
                          style: _text(color: _muted),
                        ),
                      )
                    else if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Text(
                          all.isEmpty
                              ? 'No events have been posted yet.'
                              : _query.trim().isNotEmpty
                                  ? 'No events match “${_query.trim()}”.'
                                  : 'No events match this filter.',
                          textAlign: TextAlign.center,
                          style: _text(color: _muted),
                        ),
                      )
                    else
                      ...visible.asMap().entries.map(
                            (entry) => _eventCard(entry.value, entry.key),
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
