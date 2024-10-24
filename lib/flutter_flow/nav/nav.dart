import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';
export '/backend/firebase_dynamic_links/firebase_dynamic_links.dart'
    show generateCurrentPageLink;

const kTransitionInfoKey = '__transition_info__';

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      errorBuilder: (context, state) => _RouteErrorBuilder(
        state: state,
        child: appStateNotifier.loggedIn ? const FeedWidget() : const WelcomePageWidget(),
      ),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? const FeedWidget() : const WelcomePageWidget(),
          routes: [
            FFRoute(
              name: 'Feed',
              path: 'feed',
              requireAuth: true,
              builder: (context, params) => FeedWidget(
                indexNumberHimePage: params.getParam(
                  'indexNumberHimePage',
                  ParamType.bool,
                ),
              ),
            ),
            FFRoute(
              name: 'Notifications',
              path: 'notifications',
              requireAuth: true,
              builder: (context, params) => const NotificationsWidget(),
            ),
            FFRoute(
              name: 'Search',
              path: 'search',
              requireAuth: true,
              builder: (context, params) => const SearchWidget(),
            ),
            FFRoute(
              name: 'Profile',
              path: 'profilePage',
              requireAuth: true,
              builder: (context, params) => ProfileWidget(
                tabSelector: params.getParam(
                  'tabSelector',
                  ParamType.int,
                ),
              ),
            ),
            FFRoute(
              name: 'Comments',
              path: 'comments',
              requireAuth: true,
              builder: (context, params) => CommentsWidget(
                post: params.getParam(
                  'post',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['posts'],
                ),
              ),
            ),
            FFRoute(
              name: 'PostDetails',
              path: 'postDetails',
              requireAuth: true,
              builder: (context, params) => PostDetailsWidget(
                post: params.getParam(
                  'post',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['posts'],
                ),
              ),
            ),
            FFRoute(
              name: 'NewPost',
              path: 'newPost',
              requireAuth: true,
              builder: (context, params) => const NewPostWidget(),
            ),
            FFRoute(
              name: 'CallToAction',
              path: 'callToAction',
              requireAuth: true,
              builder: (context, params) => const CallToActionWidget(),
            ),
            FFRoute(
              name: 'Location',
              path: 'location',
              requireAuth: true,
              builder: (context, params) => const LocationWidget(),
            ),
            FFRoute(
              name: 'SignUp',
              path: 'signUp',
              builder: (context, params) => const SignUpWidget(),
            ),
            FFRoute(
              name: 'SignIn',
              path: 'signIn',
              builder: (context, params) => const SignInWidget(),
            ),
            FFRoute(
              name: 'SignUp_Name',
              path: 'signUpName',
              builder: (context, params) => const SignUpNameWidget(),
            ),
            FFRoute(
              name: 'SignUp_Password',
              path: 'signUpPassword',
              builder: (context, params) => const SignUpPasswordWidget(),
            ),
            FFRoute(
              name: 'SignUp_Birthday',
              path: 'signUpBirthday',
              builder: (context, params) => const SignUpBirthdayWidget(),
            ),
            FFRoute(
              name: 'SignUp_Username',
              path: 'signUpUsername',
              builder: (context, params) => const SignUpUsernameWidget(),
            ),
            FFRoute(
              name: 'SignUp_UsernameConfirmation',
              path: 'signUpUsernameConfirmation',
              builder: (context, params) => const SignUpUsernameConfirmationWidget(),
            ),
            FFRoute(
              name: 'TagUsers',
              path: 'tagUsers',
              requireAuth: true,
              builder: (context, params) => const TagUsersWidget(),
            ),
            FFRoute(
              name: 'SelectTaggedUsers',
              path: 'selectTaggedUsers',
              requireAuth: true,
              builder: (context, params) => const SelectTaggedUsersWidget(),
            ),
            FFRoute(
              name: 'ProfileOther',
              path: 'profileOther',
              requireAuth: true,
              builder: (context, params) => ProfileOtherWidget(
                username: params.getParam(
                  'username',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: 'EditProfile',
              path: 'editProfile',
              requireAuth: true,
              builder: (context, params) => const EditProfileWidget(),
            ),
            FFRoute(
              name: 'FollowersFollowing',
              path: 'followersFollowing',
              requireAuth: true,
              builder: (context, params) => FollowersFollowingWidget(
                followersTabIndex: params.getParam(
                  'followersTabIndex',
                  ParamType.int,
                ),
              ),
            ),
            FFRoute(
              name: 'FollowersFollowingOther',
              path: 'followersFollowingOther',
              requireAuth: true,
              builder: (context, params) => FollowersFollowingOtherWidget(
                userRef: params.getParam(
                  'userRef',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['users'],
                ),
              ),
            ),
            FFRoute(
              name: 'EditPost',
              path: 'editPost',
              requireAuth: true,
              asyncParams: {
                'post': getDoc(['posts'], PostsRecord.fromSnapshot),
              },
              builder: (context, params) => EditPostWidget(
                post: params.getParam(
                  'post',
                  ParamType.Document,
                ),
              ),
            ),
            FFRoute(
              name: 'Messages',
              path: 'messages',
              requireAuth: true,
              builder: (context, params) => const MessagesWidget(),
            ),
            FFRoute(
              name: 'NewMessage',
              path: 'newMessage',
              requireAuth: true,
              builder: (context, params) => const NewMessageWidget(),
            ),
            FFRoute(
              name: 'IndividualMessage',
              path: 'individualMessage',
              requireAuth: true,
              builder: (context, params) => IndividualMessageWidget(
                chat: params.getParam(
                  'chat',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['chats'],
                ),
              ),
            ),
            FFRoute(
              name: 'Get_Started',
              path: 'getStarted',
              requireAuth: true,
              builder: (context, params) => const GetStartedWidget(),
            ),
            FFRoute(
              name: 'assistantGPT',
              path: 'assistantGPT',
              requireAuth: true,
              builder: (context, params) => const AssistantGPTWidget(),
            ),
            FFRoute(
              name: 'assistantGPTPro',
              path: 'assistantGPTPro',
              requireAuth: true,
              builder: (context, params) => const AssistantGPTProWidget(),
            ),
            FFRoute(
              name: 'gptVision',
              path: 'gptVision',
              requireAuth: true,
              builder: (context, params) => const GptVisionWidget(),
            ),
            FFRoute(
              name: 'gptVisionPro',
              path: 'gptVisionPro',
              requireAuth: true,
              builder: (context, params) => const GptVisionProWidget(),
            ),
            FFRoute(
              name: 'ScheduleTraining',
              path: 'scheduleTraining',
              requireAuth: true,
              builder: (context, params) => const ScheduleTrainingWidget(),
            ),
            FFRoute(
              name: 'editTraining',
              path: 'editTraining',
              requireAuth: true,
              asyncParams: {
                'userRecord': getDoc(['users'], UsersRecord.fromSnapshot),
              },
              builder: (context, params) => EditTrainingWidget(
                trainingReference: params.getParam(
                  'trainingReference',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['userTrainings'],
                ),
                userRecord: params.getParam(
                  'userRecord',
                  ParamType.Document,
                ),
              ),
            ),
            FFRoute(
              name: 'trainingpostDetails',
              path: 'trainingpostDetails',
              requireAuth: true,
              asyncParams: {
                'userRecord': getDoc(['users'], UsersRecord.fromSnapshot),
              },
              builder: (context, params) => TrainingpostDetailsWidget(
                userRecord: params.getParam(
                  'userRecord',
                  ParamType.Document,
                ),
                trainingReference: params.getParam(
                  'trainingReference',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['userTrainings'],
                ),
              ),
            ),
            FFRoute(
              name: 'trainingHome',
              path: 'trainingHome',
              requireAuth: true,
              builder: (context, params) => const TrainingHomeWidget(),
            ),
            FFRoute(
              name: 'JoinTraining',
              path: 'joinTraining',
              requireAuth: true,
              builder: (context, params) => const JoinTrainingWidget(),
            ),
            FFRoute(
              name: 'progressDetails',
              path: 'progressDetails',
              requireAuth: true,
              asyncParams: {
                'userRecord': getDoc(['users'], UsersRecord.fromSnapshot),
                'trainingReference':
                    getDoc(['workout'], WorkoutRecord.fromSnapshot),
              },
              builder: (context, params) => ProgressDetailsWidget(
                userRecord: params.getParam(
                  'userRecord',
                  ParamType.Document,
                ),
                trainingReference: params.getParam(
                  'trainingReference',
                  ParamType.Document,
                ),
              ),
            ),
            FFRoute(
              name: 'ExplorePage',
              path: 'explorePage',
              requireAuth: true,
              builder: (context, params) => const ExplorePageWidget(),
            ),
            FFRoute(
              name: 'blockedPage',
              path: 'blockedPage',
              requireAuth: true,
              builder: (context, params) => const BlockedPageWidget(),
            ),
            FFRoute(
              name: 'createFoodPost',
              path: 'createFoodPost',
              requireAuth: true,
              builder: (context, params) => const CreateFoodPostWidget(),
            ),
            FFRoute(
              name: 'WelcomePage',
              path: 'welcomePage',
              builder: (context, params) => const WelcomePageWidget(),
            ),
            FFRoute(
              name: 'login',
              path: 'login',
              builder: (context, params) => const LoginWidget(),
            ),
            FFRoute(
              name: 'CreateAccount',
              path: 'createAccount',
              builder: (context, params) => const CreateAccountWidget(),
            ),
            FFRoute(
              name: 'forgotPassword',
              path: 'forgotPassword',
              builder: (context, params) => const ForgotPasswordWidget(),
            ),
            FFRoute(
              name: 'EmailVerification',
              path: 'emailVerification',
              builder: (context, params) => const EmailVerificationWidget(),
            ),
            FFRoute(
              name: 'AllMostDone',
              path: 'allMostDone',
              builder: (context, params) => const AllMostDoneWidget(),
            ),
            FFRoute(
              name: 'ProfilePicture',
              path: 'profilePicture',
              builder: (context, params) => const ProfilePictureWidget(),
            ),
            FFRoute(
              name: 'Gender2',
              path: 'gender2',
              builder: (context, params) => const Gender2Widget(),
            ),
            FFRoute(
              name: 'HowOldAreYou',
              path: 'howOldAreYou',
              builder: (context, params) => const HowOldAreYouWidget(),
            ),
            FFRoute(
              name: 'Weight',
              path: 'weight',
              builder: (context, params) => const WeightWidget(),
            ),
            FFRoute(
              name: 'Height',
              path: 'height',
              builder: (context, params) => const HeightWidget(),
            ),
            FFRoute(
              name: 'WorkOutLevel',
              path: 'workOutLevel',
              builder: (context, params) => const WorkOutLevelWidget(),
            ),
            FFRoute(
              name: 'FiveQuestions',
              path: 'fiveQuestions',
              builder: (context, params) => const FiveQuestionsWidget(),
            ),
            FFRoute(
              name: 'Goals',
              path: 'goals',
              builder: (context, params) => const GoalsWidget(),
            ),
            FFRoute(
              name: 'Meals',
              path: 'meals',
              builder: (context, params) => const MealsWidget(),
            ),
            FFRoute(
              name: 'workoutDays',
              path: 'workoutDays',
              builder: (context, params) => const WorkoutDaysWidget(),
            ),
            FFRoute(
              name: 'workoutWhen',
              path: 'workoutWhen',
              builder: (context, params) => const WorkoutWhenWidget(),
            ),
            FFRoute(
              name: 'workoutLenght',
              path: 'workoutLenght',
              builder: (context, params) => const WorkoutLenghtWidget(),
            ),
            FFRoute(
              name: 'allDone2',
              path: 'allDone2',
              builder: (context, params) => const AllDone2Widget(),
            ),
            FFRoute(
              name: 'Username',
              path: 'username',
              builder: (context, params) => const UsernameWidget(),
            ),
            FFRoute(
              name: 'changePassword',
              path: 'changePassword',
              builder: (context, params) => const ChangePasswordWidget(),
            ),
            FFRoute(
              name: 'unblockList',
              path: 'unblockList',
              requireAuth: true,
              builder: (context, params) => const UnblockListWidget(),
            ),
            FFRoute(
              name: 'savedPosts',
              path: 'savedPosts',
              requireAuth: true,
              builder: (context, params) => const SavedPostsWidget(),
            ),
            FFRoute(
              name: 'myInfo',
              path: 'myInfo',
              requireAuth: true,
              builder: (context, params) => const MyInfoWidget(),
            ),
            FFRoute(
              name: 'myInfoEdit',
              path: 'myInfoEdit',
              requireAuth: true,
              builder: (context, params) => const MyInfoEditWidget(),
            ),
            FFRoute(
              name: 'videoReels',
              path: 'videoReels',
              requireAuth: true,
              builder: (context, params) => VideoReelsWidget(
                initialStoryIndex: params.getParam(
                  'initialStoryIndex',
                  ParamType.int,
                ),
              ),
            ),
            FFRoute(
              name: 'Language',
              path: 'language',
              requireAuth: true,
              builder: (context, params) => const LanguageWidget(),
            )
          ].map((r) => r.toRoute(appStateNotifier)).toList(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
      observers: [routeObserver],
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/welcomePage';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Container(
                  color: FlutterFlowTheme.of(context).secondary,
                  child: Center(
                    child: Image.asset(
                      'assets/images/07.png',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : PushNotificationsHandler(child: page);

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => const TransitionInfo(hasTransition: false);
}

class _RouteErrorBuilder extends StatefulWidget {
  const _RouteErrorBuilder({
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

  @override
  State<_RouteErrorBuilder> createState() => _RouteErrorBuilderState();
}

class _RouteErrorBuilderState extends State<_RouteErrorBuilder> {
  @override
  void initState() {
    super.initState();

    // Handle erroneous links from Firebase Dynamic Links.

    String? location;

    /*
    Handle `links` routes that have dynamic-link entangled with deep-link 
    */
    if (widget.state.uri.toString().startsWith('/link') &&
        widget.state.uri.queryParameters.containsKey('deep_link_id')) {
      final deepLinkId = widget.state.uri.queryParameters['deep_link_id'];
      if (deepLinkId != null) {
        final deepLinkUri = Uri.parse(deepLinkId);
        final link = deepLinkUri.toString();
        final host = deepLinkUri.host;
        location = link.split(host).last;
      }
    }

    if (widget.state.uri.toString().startsWith('/link') &&
        widget.state.uri.toString().contains('request_ip_version')) {
      location = '/';
    }

    if (location != null) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => context.go(location!));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
