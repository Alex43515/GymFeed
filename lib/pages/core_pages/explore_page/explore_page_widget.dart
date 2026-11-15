import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/components/nav_bar/nav_bar_widget.dart';
import '/components/post_type_badge/post_type_badge.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/core_pages/profile_other/profile_other_widget.dart';
import '/pages/posts/post_details/post_details_widget.dart';

class ExplorePageWidget extends StatefulWidget {
  const ExplorePageWidget({super.key, this.initialTab = 0});

  /// 0 = posts, 1 = people (suggested accounts).
  final int initialTab;
  static const String routeName = 'ExplorePage';
  static const String routePath = 'explorePage';
  @override
  State<ExplorePageWidget> createState() => _ExplorePageWidgetState();
}

class _ExplorePageWidgetState extends State<ExplorePageWidget>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF0EEA78);
  late final TabController _tabs;
  final _search = TextEditingController();
  String _query = '';
  late Future<List<PostsRecord>> _posts;
  final _peopleScroll = ScrollController();
  final _peopleRepository = ProfileRepository();
  final Map<String, Profile> _people = {};
  Timer? _searchDebounce;
  late int _selectedTab;
  int _peopleRequest = 0;
  int? _nextPeopleOffset = 0;
  bool _loadingPeople = false;
  bool _peopleError = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _selectedTab = _tabs.index;
    _tabs.addListener(_tabChanged);
    _peopleScroll.addListener(_maybeLoadMorePeople);
    _posts = queryPostsRecordOnce(limit: 150);
    if (_tabs.index == 1) unawaited(_loadPeople());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabs.dispose();
    _peopleScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _tabChanged() {
    if (_tabs.index == _selectedTab) return;
    _selectedTab = _tabs.index;
    _search.clear();
    _resetPeople('');
  }

  void _changed(String value) {
    if (_tabs.index != 1) {
      setState(() => _query = value.trim().toLowerCase());
      return;
    }
    _resetPeople(value.trim().toLowerCase(), debounce: true);
  }

  void _resetPeople(String query, {bool debounce = false}) {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    setState(() {
      _query = query;
      _peopleRequest++;
      _people.clear();
      _nextPeopleOffset = 0;
      _loadingPeople = false;
      _peopleError = false;
    });
    if (_tabs.index != 1) return;
    if (debounce) {
      _searchDebounce = Timer(const Duration(milliseconds: 250), () {
        _searchDebounce = null;
        unawaited(_loadPeople());
      });
    }
    if (_peopleScroll.hasClients) _peopleScroll.jumpTo(0);
    if (!debounce) unawaited(_loadPeople());
  }

  void _maybeLoadMorePeople() {
    if (_tabs.index == 1 &&
        !_peopleError &&
        _searchDebounce == null &&
        _peopleScroll.hasClients &&
        _peopleScroll.position.hasContentDimensions &&
        _peopleScroll.position.extentAfter < 400) {
      unawaited(_loadPeople());
    }
  }

  Future<void> _loadPeople() async {
    final offset = _nextPeopleOffset;
    if (_loadingPeople || offset == null) return;
    final request = _peopleRequest;
    final query = _query;
    setState(() {
      _loadingPeople = true;
      _peopleError = false;
    });
    try {
      final page = await _peopleRepository.explorePeople(query, offset: offset);
      if (!mounted || request != _peopleRequest) return;
      setState(() {
        for (final profile in page.profiles) {
          _people[profile.id] = profile;
        }
        _nextPeopleOffset = page.nextOffset;
        _loadingPeople = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && request == _peopleRequest) _maybeLoadMorePeople();
      });
    } catch (_) {
      if (!mounted || request != _peopleRequest) return;
      setState(() {
        _loadingPeople = false;
        _peopleError = true;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _posts = queryPostsRecordOnce(limit: 150));
    await _posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const NavBarWidget(selectPageIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Explore',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 25,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('explore-search'),
                controller: _search,
                onChanged: _changed,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _tabs.index == 0 ? 'Search posts' : 'Search people',
                  hintStyle: const TextStyle(color: Color(0xFF777777)),
                  prefixIcon: const Icon(Icons.search_rounded, color: _green),
                  filled: true,
                  fillColor: const Color(0xFF151515),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF292929)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF292929)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _green),
                  ),
                ),
              ),
            ),
            TabBar(
              key: const Key('explore-tabs'),
              controller: _tabs,
              indicatorColor: _green,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF777777),
              tabs: const [Tab(text: 'Explore'), Tab(text: 'People')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [_postGrid(), _peopleList()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postGrid() {
    return FutureBuilder<List<PostsRecord>>(
      future: _posts,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final posts = snapshot.data!.where((post) {
          if (_query.isEmpty) return true;
          return post.postCaption.toLowerCase().contains(_query) ||
              post.postTitleFood.toLowerCase().contains(_query) ||
              post.postDescriptionFood.toLowerCase().contains(_query);
        }).toList();
        return RefreshIndicator(
          onRefresh: _refresh,
          color: _green,
          backgroundColor: const Color(0xFF151515),
          child: GridView.builder(
            key: const Key('explore-mixed-post-grid'),
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 110),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 5 : 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final rawPhoto = post.postPhoto.isNotEmpty
                  ? post.postPhoto
                  : post.postPhotoFood;
              final thumbnail = post.videoThumbnail.isNotEmpty
                  ? post.videoThumbnail
                  : rawPhoto;
              final image = functions.bunnyCDNImagePath(thumbnail);
              final hasVideo =
                  post.postVideo.isNotEmpty || post.postVideoFood.isNotEmpty;
              return InkWell(
                onTap: () => context.pushNamed(
                  PostDetailsWidget.routeName,
                  queryParameters: {
                    'post': serializeParam(
                        post.reference, ParamType.DocumentReference),
                  }.withoutNulls,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: const Color(0xFF161616),
                      child: image.isEmpty
                          ? const Icon(Icons.image_outlined,
                              color: Color(0xFF666666))
                          : CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF666666)),
                            ),
                    ),
                    if (hasVideo)
                      const Positioned(
                        top: 7,
                        left: 7,
                        child: Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white, size: 24),
                      ),
                    if (post.foodPost)
                      const Positioned(
                          top: 6, right: 6, child: FoodPostBadge(size: 27)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _peopleList() {
    final people = _people.values.toList(growable: false);
    final showFooter =
        _peopleError || _nextPeopleOffset != null || people.isEmpty;
    return ListView.separated(
      key: const Key('explore-people-list'),
      controller: _peopleScroll,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
      itemCount: people.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF222222)),
      itemBuilder: (context, index) {
        if (index == people.length) {
          if (_peopleError) {
            return Center(
              child: TextButton(
                onPressed: _loadPeople,
                child: const Text('Could not load people. Retry'),
              ),
            );
          }
          if (_nextPeopleOffset != null) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator(color: _green)),
            );
          }
          return const Center(
            child: Text('No people found',
                style: TextStyle(color: Colors.white70)),
          );
        }
        final profile = people[index];
        return ListTile(
          onTap: () => context.pushNamed(
            ProfileOtherWidget.routeName,
            queryParameters: {
              'username': serializeParam(profile.username, ParamType.String),
            }.withoutNulls,
          ),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF173A25),
            backgroundImage: profile.photoUrl.isEmpty
                ? null
                : NetworkImage(profile.photoUrl),
            child: profile.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: _green)
                : null,
          ),
          title: Text(
              profile.displayName.isEmpty
                  ? profile.username
                  : profile.displayName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('@${profile.username}',
              style: const TextStyle(color: Color(0xFF888888))),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF777777)),
        );
      },
    );
  }
}
