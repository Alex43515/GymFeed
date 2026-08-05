import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';

import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';
export '/backend/firebase_dynamic_links/firebase_dynamic_links.dart'
    show generateCurrentPageLink;

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => _RouteErrorBuilder(
        state: state,
        child: appStateNotifier.loggedIn ? FeedWidget() : WelcomePageWidget(),
      ),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? FeedWidget() : WelcomePageWidget(),
          routes: [
            FFRoute(
              name: FeedWidget.routeName,
              path: FeedWidget.routePath,
              requireAuth: true,
              builder: (context, params) => FeedWidget(
                indexNumberHimePage: params.getParam(
                  'indexNumberHimePage',
                  ParamType.bool,
                ),
              ),
            ),
            FFRoute(
              name: NotificationsWidget.routeName,
              path: NotificationsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => NotificationsWidget(),
            ),
            FFRoute(
              name: SearchWidget.routeName,
              path: SearchWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SearchWidget(),
            ),
            FFRoute(
              name: ProfileWidget.routeName,
              path: ProfileWidget.routePath,
              builder: (context, params) => ProfileWidget(
                tabSelector: params.getParam(
                  'tabSelector',
                  ParamType.int,
                ),
              ),
            ),
            FFRoute(
              name: CommentsWidget.routeName,
              path: CommentsWidget.routePath,
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
              name: PostDetailsWidget.routeName,
              path: PostDetailsWidget.routePath,
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
              name: NewPostWidget.routeName,
              path: NewPostWidget.routePath,
              requireAuth: true,
              builder: (context, params) => NewPostWidget(),
            ),
            FFRoute(
              name: CallToActionWidget.routeName,
              path: CallToActionWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CallToActionWidget(),
            ),
            FFRoute(
              name: LocationWidget.routeName,
              path: LocationWidget.routePath,
              requireAuth: true,
              builder: (context, params) => LocationWidget(),
            ),
            FFRoute(
              name: SignUpWidget.routeName,
              path: SignUpWidget.routePath,
              builder: (context, params) => SignUpWidget(),
            ),
            FFRoute(
              name: SignInWidget.routeName,
              path: SignInWidget.routePath,
              builder: (context, params) => SignInWidget(),
            ),
            FFRoute(
              name: SignUpNameWidget.routeName,
              path: SignUpNameWidget.routePath,
              builder: (context, params) => SignUpNameWidget(),
            ),
            FFRoute(
              name: SignUpPasswordWidget.routeName,
              path: SignUpPasswordWidget.routePath,
              builder: (context, params) => SignUpPasswordWidget(),
            ),
            FFRoute(
              name: SignUpBirthdayWidget.routeName,
              path: SignUpBirthdayWidget.routePath,
              builder: (context, params) => SignUpBirthdayWidget(),
            ),
            FFRoute(
              name: SignUpUsernameWidget.routeName,
              path: SignUpUsernameWidget.routePath,
              builder: (context, params) => SignUpUsernameWidget(),
            ),
            FFRoute(
              name: SignUpUsernameConfirmationWidget.routeName,
              path: SignUpUsernameConfirmationWidget.routePath,
              builder: (context, params) => SignUpUsernameConfirmationWidget(),
            ),
            FFRoute(
              name: TagUsersWidget.routeName,
              path: TagUsersWidget.routePath,
              requireAuth: true,
              builder: (context, params) => TagUsersWidget(),
            ),
            FFRoute(
              name: SelectTaggedUsersWidget.routeName,
              path: SelectTaggedUsersWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SelectTaggedUsersWidget(),
            ),
            FFRoute(
              name: ProfileOtherWidget.routeName,
              path: ProfileOtherWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProfileOtherWidget(
                username: params.getParam(
                  'username',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: EditProfileWidget.routeName,
              path: EditProfileWidget.routePath,
              requireAuth: true,
              builder: (context, params) => EditProfileWidget(),
            ),
            FFRoute(
              name: FollowersFollowingWidget.routeName,
              path: FollowersFollowingWidget.routePath,
              requireAuth: true,
              builder: (context, params) => FollowersFollowingWidget(
                followersTabIndex: params.getParam(
                  'followersTabIndex',
                  ParamType.int,
                ),
              ),
            ),
            FFRoute(
              name: FollowersFollowingOtherWidget.routeName,
              path: FollowersFollowingOtherWidget.routePath,
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
              name: EditPostWidget.routeName,
              path: EditPostWidget.routePath,
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
              name: MessagesWidget.routeName,
              path: MessagesWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MessagesWidget(),
            ),
            FFRoute(
              name: NewMessageWidget.routeName,
              path: NewMessageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => NewMessageWidget(),
            ),
            FFRoute(
              name: IndividualMessageWidget.routeName,
              path: IndividualMessageWidget.routePath,
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
              name: GetStartedWidget.routeName,
              path: GetStartedWidget.routePath,
              requireAuth: true,
              builder: (context, params) => GetStartedWidget(),
            ),
            FFRoute(
              name: AssistantGPTWidget.routeName,
              path: AssistantGPTWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AssistantGPTWidget(),
            ),
            FFRoute(
              name: AssistantGPTProWidget.routeName,
              path: AssistantGPTProWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AssistantGPTProWidget(),
            ),
            FFRoute(
              name: GptVisionWidget.routeName,
              path: GptVisionWidget.routePath,
              requireAuth: true,
              builder: (context, params) => GptVisionWidget(),
            ),
            FFRoute(
              name: GptVisionProWidget.routeName,
              path: GptVisionProWidget.routePath,
              requireAuth: true,
              builder: (context, params) => GptVisionProWidget(),
            ),
            FFRoute(
              name: ScheduleTrainingWidget.routeName,
              path: ScheduleTrainingWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ScheduleTrainingWidget(),
            ),
            FFRoute(
              name: EditTrainingWidget.routeName,
              path: EditTrainingWidget.routePath,
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
              name: TrainingpostDetailsWidget.routeName,
              path: TrainingpostDetailsWidget.routePath,
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
              name: TrainingHomeWidget.routeName,
              path: TrainingHomeWidget.routePath,
              requireAuth: true,
              builder: (context, params) => TrainingHomeWidget(),
            ),
            FFRoute(
              name: JoinTrainingWidget.routeName,
              path: JoinTrainingWidget.routePath,
              requireAuth: true,
              builder: (context, params) => JoinTrainingWidget(),
            ),
            FFRoute(
              name: ProgressDetailsWidget.routeName,
              path: ProgressDetailsWidget.routePath,
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
              name: ExplorePageWidget.routeName,
              path: ExplorePageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ExplorePageWidget(),
            ),
            FFRoute(
              name: BlockedPageWidget.routeName,
              path: BlockedPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => BlockedPageWidget(),
            ),
            FFRoute(
              name: CreateFoodPostWidget.routeName,
              path: CreateFoodPostWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CreateFoodPostWidget(),
            ),
            FFRoute(
              name: WelcomePageWidget.routeName,
              path: WelcomePageWidget.routePath,
              builder: (context, params) => WelcomePageWidget(),
            ),
            FFRoute(
              name: LoginWidget.routeName,
              path: LoginWidget.routePath,
              builder: (context, params) => LoginWidget(),
            ),
            FFRoute(
              name: CreateAccountWidget.routeName,
              path: CreateAccountWidget.routePath,
              builder: (context, params) => CreateAccountWidget(),
            ),
            FFRoute(
              name: ForgotPasswordWidget.routeName,
              path: ForgotPasswordWidget.routePath,
              builder: (context, params) => ForgotPasswordWidget(),
            ),
            FFRoute(
              name: EmailVerificationWidget.routeName,
              path: EmailVerificationWidget.routePath,
              builder: (context, params) => EmailVerificationWidget(),
            ),
            FFRoute(
              name: AllMostDoneWidget.routeName,
              path: AllMostDoneWidget.routePath,
              builder: (context, params) => AllMostDoneWidget(),
            ),
            FFRoute(
              name: ProfilePictureWidget.routeName,
              path: ProfilePictureWidget.routePath,
              builder: (context, params) => ProfilePictureWidget(),
            ),
            FFRoute(
              name: Gender2Widget.routeName,
              path: Gender2Widget.routePath,
              builder: (context, params) => Gender2Widget(),
            ),
            FFRoute(
              name: HowOldAreYouWidget.routeName,
              path: HowOldAreYouWidget.routePath,
              builder: (context, params) => HowOldAreYouWidget(),
            ),
            FFRoute(
              name: WeightWidget.routeName,
              path: WeightWidget.routePath,
              builder: (context, params) => WeightWidget(),
            ),
            FFRoute(
              name: HeightWidget.routeName,
              path: HeightWidget.routePath,
              builder: (context, params) => HeightWidget(),
            ),
            FFRoute(
              name: WorkOutLevelWidget.routeName,
              path: WorkOutLevelWidget.routePath,
              builder: (context, params) => WorkOutLevelWidget(),
            ),
            FFRoute(
              name: FiveQuestionsWidget.routeName,
              path: FiveQuestionsWidget.routePath,
              builder: (context, params) => FiveQuestionsWidget(),
            ),
            FFRoute(
              name: GoalsWidget.routeName,
              path: GoalsWidget.routePath,
              builder: (context, params) => GoalsWidget(),
            ),
            FFRoute(
              name: MealsWidget.routeName,
              path: MealsWidget.routePath,
              builder: (context, params) => MealsWidget(),
            ),
            FFRoute(
              name: WorkoutDaysWidget.routeName,
              path: WorkoutDaysWidget.routePath,
              builder: (context, params) => WorkoutDaysWidget(),
            ),
            FFRoute(
              name: WorkoutWhenWidget.routeName,
              path: WorkoutWhenWidget.routePath,
              builder: (context, params) => WorkoutWhenWidget(),
            ),
            FFRoute(
              name: WorkoutLenghtWidget.routeName,
              path: WorkoutLenghtWidget.routePath,
              builder: (context, params) => WorkoutLenghtWidget(),
            ),
            FFRoute(
              name: AllDone2Widget.routeName,
              path: AllDone2Widget.routePath,
              builder: (context, params) => AllDone2Widget(),
            ),
            FFRoute(
              name: UsernameWidget.routeName,
              path: UsernameWidget.routePath,
              builder: (context, params) => UsernameWidget(),
            ),
            FFRoute(
              name: ChangePasswordWidget.routeName,
              path: ChangePasswordWidget.routePath,
              builder: (context, params) => ChangePasswordWidget(),
            ),
            FFRoute(
              name: UnblockListWidget.routeName,
              path: UnblockListWidget.routePath,
              requireAuth: true,
              builder: (context, params) => UnblockListWidget(),
            ),
            FFRoute(
              name: SavedPostsWidget.routeName,
              path: SavedPostsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SavedPostsWidget(),
            ),
            FFRoute(
              name: MyInfoWidget.routeName,
              path: MyInfoWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MyInfoWidget(),
            ),
            FFRoute(
              name: MyInfoEditWidget.routeName,
              path: MyInfoEditWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MyInfoEditWidget(),
            ),
            FFRoute(
              name: VideoReelsWidget.routeName,
              path: VideoReelsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VideoReelsWidget(
                initialStoryIndex: params.getParam(
                  'initialStoryIndex',
                  ParamType.int,
                ),
              ),
            ),
            FFRoute(
              name: LanguageWidget.routeName,
              path: LanguageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => LanguageWidget(),
            ),
            FFRoute(
              name: DetailsExercisePageWidget.routeName,
              path: DetailsExercisePageWidget.routePath,
              requireAuth: true,
              asyncParams: {
                'userRecord': getDoc(['users'], UsersRecord.fromSnapshot),
              },
              builder: (context, params) => DetailsExercisePageWidget(
                userRecord: params.getParam(
                  'userRecord',
                  ParamType.Document,
                ),
                trainingReference: params.getParam(
                  'trainingReference',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['exercise'],
                ),
              ),
            ),
            FFRoute(
              name: MealScannerWidget.routeName,
              path: MealScannerWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MealScannerWidget(
                mealRef: params.getParam(
                  'mealRef',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['mealScanner'],
                ),
              ),
            ),
            FFRoute(
              name: MealScannerProWidget.routeName,
              path: MealScannerProWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MealScannerProWidget(),
            ),
            FFRoute(
              name: BodyScannerWidget.routeName,
              path: BodyScannerWidget.routePath,
              requireAuth: true,
              builder: (context, params) => BodyScannerWidget(),
            ),
            FFRoute(
              name: BodyScannerProWidget.routeName,
              path: BodyScannerProWidget.routePath,
              requireAuth: true,
              builder: (context, params) => BodyScannerProWidget(),
            ),
            FFRoute(
              name: ReportWidget.routeName,
              path: ReportWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReportWidget(),
            ),
            FFRoute(
              name: WorkoutWhereWidget.routeName,
              path: WorkoutWhereWidget.routePath,
              builder: (context, params) => WorkoutWhereWidget(),
            ),
            FFRoute(
              name: FoodAlergiesWidget.routeName,
              path: FoodAlergiesWidget.routePath,
              builder: (context, params) => FoodAlergiesWidget(),
            ),
            FFRoute(
              name: TestWidget.routeName,
              path: TestWidget.routePath,
              requireAuth: true,
              builder: (context, params) => TestWidget(),
            ),
            FFRoute(
              name: AddingMealsWidget.routeName,
              path: AddingMealsWidget.routePath,
              requireAuth: true,
              asyncParams: {
                'mealRef':
                    getDoc(['mealScanner'], MealScannerRecord.fromSnapshot),
              },
              builder: (context, params) => AddingMealsWidget(
                mealRef: params.getParam(
                  'mealRef',
                  ParamType.Document,
                ),
              ),
            ),
            FFRoute(
              name: MealScannerCopyWidget.routeName,
              path: MealScannerCopyWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MealScannerCopyWidget(),
            ),
            FFRoute(
              name: DetailsExercisePage2Widget.routeName,
              path: DetailsExercisePage2Widget.routePath,
              requireAuth: true,
              asyncParams: {
                'userRecord': getDoc(['users'], UsersRecord.fromSnapshot),
              },
              builder: (context, params) => DetailsExercisePage2Widget(
                userRecord: params.getParam(
                  'userRecord',
                  ParamType.Document,
                ),
                trainingReference: params.getParam(
                  'trainingReference',
                  ParamType.DocumentReference,
                  isList: false,
                  collectionNamePath: ['workout'],
                ),
              ),
            ),
            FFRoute(
              name: VideoCompressWidget.routeName,
              path: VideoCompressWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VideoCompressWidget(),
            ),
            FFRoute(
              name: VideoCompressCopyWidget.routeName,
              path: VideoCompressCopyWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VideoCompressCopyWidget(),
            ),
            FFRoute(
              name: AddingMealsCopyWidget.routeName,
              path: AddingMealsCopyWidget.routePath,
              requireAuth: true,
              asyncParams: {
                'mealRef':
                    getDoc(['mealScanner'], MealScannerRecord.fromSnapshot),
              },
              builder: (context, params) => AddingMealsCopyWidget(
                mealRef: params.getParam(
                  'mealRef',
                  ParamType.Document,
                ),
              ),
            ),
            FFRoute(
              name: MealCollectionWidget.routeName,
              path: MealCollectionWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MealCollectionWidget(),
            ),
            FFRoute(
              name: VideoCompressCopyCopyWidget.routeName,
              path: VideoCompressCopyCopyWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VideoCompressCopyCopyWidget(),
            ),
            FFRoute(
              name: VideoCompressCopyCopyCopyWidget.routeName,
              path: VideoCompressCopyCopyCopyWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VideoCompressCopyCopyCopyWidget(),
            ),
            FFRoute(
              name: ReportCopyWidget.routeName,
              path: ReportCopyWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReportCopyWidget(),
            ),
            FFRoute(
              name: Bodyscanner2Widget.routeName,
              path: Bodyscanner2Widget.routePath,
              requireAuth: true,
              builder: (context, params) => Bodyscanner2Widget(),
            ),
            FFRoute(
              name: Bodyscanner3Widget.routeName,
              path: Bodyscanner3Widget.routePath,
              requireAuth: true,
              builder: (context, params) => Bodyscanner3Widget(),
            ),
            FFRoute(
              name: Bodyscanner4Widget.routeName,
              path: Bodyscanner4Widget.routePath,
              requireAuth: true,
              builder: (context, params) => Bodyscanner4Widget(),
            ),
            FFRoute(
              name: WorkoutPlanWidget.routeName,
              path: WorkoutPlanWidget.routePath,
              requireAuth: true,
              builder: (context, params) => WorkoutPlanWidget(),
            ),
            FFRoute(
              name: MealPlanWidget.routeName,
              path: MealPlanWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MealPlanWidget(),
            ),
            FFRoute(
              name: JebemtimaterWidget.routeName,
              path: JebemtimaterWidget.routePath,
              requireAuth: true,
              builder: (context, params) => JebemtimaterWidget(),
            ),
            FFRoute(
              name: VideoReelsCopyWidget.routeName,
              path: VideoReelsCopyWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VideoReelsCopyWidget(
                initialStoryIndex: params.getParam(
                  'initialStoryIndex',
                  ParamType.int,
                ),
              ),
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

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class _RouteErrorBuilder extends StatefulWidget {
  const _RouteErrorBuilder({
    Key? key,
    required this.state,
    required this.child,
  }) : super(key: key);

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
