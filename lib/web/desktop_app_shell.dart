import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/index.dart';

/// Desktop-only frame for the Flutter web build.
///
/// The routed page remains the exact same application page used on mobile.
/// This frame supplies desktop navigation, a wider working canvas and useful
/// secondary content without changing Android or iOS behavior.
class DesktopAppShell extends StatelessWidget {
  const DesktopAppShell({
    super.key,
    required this.child,
    required this.currentPath,
    required this.authenticated,
    required this.loading,
    required this.router,
  });

  final Widget child;
  final String currentPath;
  final bool authenticated;
  final bool loading;
  final GoRouter router;

  static const _background = Color(0xFF080808);
  static const _surface = Color(0xFF111111);
  static const _surfaceRaised = Color(0xFF171717);
  static const _border = Color(0xFF292929);
  static const _green = Color(0xFF16E77D);
  static const _muted = Color(0xFF8A8F96);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      ),
      child: Material(
        color: _background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 860 || loading) {
              return child;
            }

            final workspace = authenticated && _isWorkspacePath(currentPath);
            if (!workspace) {
              return _DesktopAuthFrame(child: child);
            }

            final compactNav = constraints.maxWidth < 1180;
            final showFeedRail = constraints.maxWidth >= 1320 &&
                _isSocialColumnPath(currentPath);
            final contentMaxWidth = showFeedRail ? 760.0 : 1120.0;
            final availableContentWidth = constraints.maxWidth -
                (compactNav ? 88.0 : 248.0) -
                (showFeedRail ? 320.0 : 0.0);
            final viewportWidth = availableContentWidth < contentMaxWidth
                ? availableContentWidth
                : contentMaxWidth;

            return Row(
              children: [
                SizedBox(
                  width: compactNav ? 88 : 248,
                  child: _DesktopNavigation(
                    currentPath: currentPath,
                    compact: compactNav,
                    router: router,
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ColoredBox(
                          color: const Color(0xFF0B0B0B),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentMaxWidth,
                                maxHeight: constraints.maxHeight,
                              ),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: _background,
                                  border: Border.symmetric(
                                    vertical: BorderSide(color: _border),
                                  ),
                                ),
                                child: MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    size: Size(
                                      viewportWidth,
                                      constraints.maxHeight,
                                    ),
                                  ),
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showFeedRail)
                        SizedBox(
                          width: 320,
                          child: _DesktopFeedRail(router: router),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _isSocialColumnPath(String path) {
    return path == '/' ||
        path.startsWith('/feed') ||
        path.startsWith('/postDetails') ||
        path.startsWith('/comments');
  }

  static bool _isWorkspacePath(String path) {
    if (path == '/') return true;
    const prefixes = <String>[
      '/feed',
      '/notifications',
      '/search',
      '/profilePage',
      '/profileOther',
      '/editProfile',
      '/followersFollowing',
      '/savedPosts',
      '/comments',
      '/postDetails',
      '/newPost',
      '/editPost',
      '/createFoodPost',
      '/tagUsers',
      '/selectTaggedUsers',
      '/messages',
      '/newMessage',
      '/individualMessage',
      '/explorePage',
      '/videoReels',
      '/coachHome',
      '/coachEvents',
      '/nutritionDiary',
      '/coachFoodScanner',
      '/coachEquipmentScanner',
      '/coachTrainer',
      '/coachBodyScan',
      '/trainingHome',
      '/scheduleTraining',
      '/editTraining',
      '/trainingpostDetails',
      '/joinTraining',
      '/progressDetails',
      '/newRoutine',
      '/routine',
      '/workoutSession',
      '/payment',
    ];
    return prefixes.any(path.startsWith);
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.currentPath,
    required this.compact,
    required this.router,
  });

  final String currentPath;
  final bool compact;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final name = currentUserDisplayName.trim();
    final email = currentUserEmail.trim();
    final display = name.isNotEmpty ? name : (email.isNotEmpty ? email : 'You');

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesktopAppShell._surface,
        border: Border(right: BorderSide(color: DesktopAppShell._border)),
      ),
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(compact ? 12 : 18, 18, compact ? 12 : 18, 14),
          child: Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              _Brand(compact: compact),
              const SizedBox(height: 32),
              _NavItem(
                compact: compact,
                icon: Icons.home_rounded,
                label: 'Home',
                active: _active(
                    <String>['/', '/feed', '/postDetails', '/comments']),
                onTap: () => router.goNamed(FeedWidget.routeName),
              ),
              _NavItem(
                compact: compact,
                icon: Icons.grid_view_rounded,
                label: 'Explore',
                active: _active(<String>['/explorePage', '/search']),
                onTap: () => router.goNamed(ExplorePageWidget.routeName),
              ),
              _NavItem(
                compact: compact,
                icon: Icons.auto_awesome_rounded,
                label: 'Coach',
                active: _active(<String>[
                  '/coach',
                  '/nutritionDiary',
                  '/progressDetails',
                ]),
                onTap: () => router.goNamed(CoachHomeWidget.routeName),
              ),
              _NavItem(
                compact: compact,
                icon: Icons.fitness_center_rounded,
                label: 'Train',
                active: _active(<String>[
                  '/trainingHome',
                  '/scheduleTraining',
                  '/editTraining',
                  '/trainingpostDetails',
                  '/joinTraining',
                  '/newRoutine',
                  '/routine',
                  '/workoutSession',
                ]),
                onTap: () => router.goNamed(TrainingHomeWidget.routeName),
              ),
              _NavItem(
                compact: compact,
                icon: Icons.play_circle_fill_rounded,
                label: 'FitClips',
                active: _active(<String>['/videoReels']),
                onTap: () => router.goNamed(VideoReelsWidget.routeName),
              ),
              _NavItem(
                compact: compact,
                icon: Icons.chat_bubble_rounded,
                label: 'Messages',
                active: _active(<String>[
                  '/messages',
                  '/newMessage',
                  '/individualMessage',
                ]),
                onTap: () => router.goNamed(MessagesWidget.routeName),
              ),
              const Spacer(),
              _NavItem(
                compact: compact,
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                active: _active(<String>['/notifications']),
                onTap: () => router.goNamed(NotificationsWidget.routeName),
              ),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => router.goNamed(ProfileWidget.routeName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: _active(<String>['/profilePage', '/editProfile'])
                        ? DesktopAppShell._green.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      _UserAvatar(name: display),
                      if (!compact) ...[
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Text(
                                'View profile',
                                style: TextStyle(
                                  color: DesktopAppShell._muted,
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'official@gymfeed.io',
                    style: TextStyle(
                      color: Color(0xFF666B70),
                      fontFamily: 'Poppins',
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _active(List<String> paths) {
    return paths.any((path) =>
        path == '/' ? currentPath == '/' : currentPath.startsWith(path));
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          compact ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/app_launcher_icon.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 11),
          const Text(
            'GymFeed',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.compact,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? DesktopAppShell._green : const Color(0xFFA4A8AD);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Tooltip(
        message: compact ? label : '',
        child: Material(
          color: active
              ? DesktopAppShell._green.withValues(alpha: 0.11)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            hoverColor: Colors.white.withValues(alpha: 0.045),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (!compact) const SizedBox(width: 14),
                  Icon(icon, color: color, size: 23),
                  if (!compact) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final photo = currentUserPhoto.trim();
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF0F5133),
        shape: BoxShape.circle,
      ),
      child: photo.isNotEmpty
          ? Image.network(
              photo,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(),
            )
          : _initial(),
    );
  }

  Widget _initial() => Text(
        name.isEmpty ? 'G' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: DesktopAppShell._green,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      );
}

class _DesktopFeedRail extends StatelessWidget {
  const _DesktopFeedRail({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesktopAppShell._surface,
        border: Border(left: BorderSide(color: DesktopAppShell._border)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick actions',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _QuickAction(
                icon: Icons.add_photo_alternate_rounded,
                label: 'Create a post',
                description: 'Share a workout, meal or update',
                onTap: () => router.pushNamed(NewPostWidget.routeName),
              ),
              _QuickAction(
                icon: Icons.restaurant_rounded,
                label: 'Log a meal',
                description: 'Open your nutrition diary',
                onTap: () => router.pushNamed(NutritionDiaryWidget.routeName),
              ),
              _QuickAction(
                icon: Icons.fitness_center_rounded,
                label: 'Plan a workout',
                description: 'Add a session to Train',
                onTap: () => router.pushNamed(ScheduleTrainingWidget.routeName),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF07341F), Color(0xFF0E5D37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: DesktopAppShell._green.withValues(alpha: 0.38),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: DesktopAppShell._green,
                      size: 26,
                    ),
                    const SizedBox(height: 38),
                    const Text(
                      'Your plan. Your history. Your AI Coach.',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Review today’s training, meals and personalized guidance.',
                      style: TextStyle(
                        color: Color(0xFFC6D8CE),
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () =>
                            router.goNamed(CoachHomeWidget.routeName),
                        style: FilledButton.styleFrom(
                          backgroundColor: DesktopAppShell._green,
                          foregroundColor: const Color(0xFF07160E),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Open Coach',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'GYMFEED DESKTOP',
                style: TextStyle(
                  color: Color(0xFF686D72),
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account stays synchronized with the GymFeed mobile app.',
                style: TextStyle(
                  color: DesktopAppShell._muted,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: DesktopAppShell._surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: DesktopAppShell._border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E3A25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: DesktopAppShell._green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          color: DesktopAppShell._muted,
                          fontFamily: 'Poppins',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF74797E),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopAuthFrame extends StatelessWidget {
  const _DesktopAuthFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(64),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF071B11), Color(0xFF090909)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(right: BorderSide(color: DesktopAppShell._border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(compact: false),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: DesktopAppShell._green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DesktopAppShell._green.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Text(
                    'TRAIN / EAT / CONNECT',
                    style: TextStyle(
                      color: DesktopAppShell._green,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: const Text(
                    'Your fitness world, now on every screen.',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 48,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: const Text(
                    'Build workouts, track nutrition, share progress and work with your AI Coach from the same GymFeed account.',
                    style: TextStyle(
                      color: Color(0xFFAAB1AD),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  '(c) 2026 GymFeed / official@gymfeed.io',
                  style: TextStyle(
                    color: Color(0xFF6D7470),
                    fontFamily: 'Poppins',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 540,
          child: ColoredBox(
            color: DesktopAppShell._background,
            child: Center(
              child: SizedBox(
                width: 520,
                height: media.size.height,
                child: MediaQuery(
                  data: media.copyWith(size: Size(520, media.size.height)),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
