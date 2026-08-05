import 'dart:async';

import 'serialization_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';


final _handledMessageIds = <String?>{};

class PushNotificationsHandler extends StatefulWidget {
  const PushNotificationsHandler({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  _PushNotificationsHandlerState createState() =>
      _PushNotificationsHandlerState();
}

class _PushNotificationsHandlerState extends State<PushNotificationsHandler> {
  bool _loading = false;

  Future handleOpenedPushNotification() async {
    if (isWeb) {
      return;
    }

    final notification = await FirebaseMessaging.instance.getInitialMessage();
    if (notification != null) {
      await _handlePushNotification(notification);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handlePushNotification);
  }

  Future _handlePushNotification(RemoteMessage message) async {
    if (_handledMessageIds.contains(message.messageId)) {
      return;
    }
    _handledMessageIds.add(message.messageId);

    safeSetState(() => _loading = true);
    try {
      final initialPageName = message.data['initialPageName'] as String;
      final initialParameterData = getInitialParameterData(message.data);
      final parametersBuilder = parametersBuilderMap[initialPageName];
      if (parametersBuilder != null) {
        final parameterData = await parametersBuilder(initialParameterData);
        if (mounted) {
          context.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        } else {
          appNavigatorKey.currentContext?.pushNamed(
            initialPageName,
            pathParameters: parameterData.pathParameters,
            extra: parameterData.extra,
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      safeSetState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      handleOpenedPushNotification();
    });
  }

  @override
  Widget build(BuildContext context) => _loading
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
      : widget.child;
}

class ParameterData {
  const ParameterData(
      {this.requiredParams = const {}, this.allParams = const {}});
  final Map<String, String?> requiredParams;
  final Map<String, dynamic> allParams;

  Map<String, String> get pathParameters => Map.fromEntries(
        requiredParams.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
  Map<String, dynamic> get extra => Map.fromEntries(
        allParams.entries.where((e) => e.value != null),
      );

  static Future<ParameterData> Function(Map<String, dynamic>) none() =>
      (data) async => ParameterData();
}

final parametersBuilderMap =
    <String, Future<ParameterData> Function(Map<String, dynamic>)>{
  'Feed': (data) async => ParameterData(
        allParams: {
          'indexNumberHimePage':
              getParameter<bool>(data, 'indexNumberHimePage'),
        },
      ),
  'Notifications': ParameterData.none(),
  'Search': ParameterData.none(),
  'Profile': (data) async => ParameterData(
        allParams: {
          'tabSelector': getParameter<int>(data, 'tabSelector'),
        },
      ),
  'Comments': (data) async => ParameterData(
        allParams: {
          'post': getParameter<DocumentReference>(data, 'post'),
        },
      ),
  'PostDetails': (data) async => ParameterData(
        allParams: {
          'post': getParameter<DocumentReference>(data, 'post'),
        },
      ),
  'NewPost': ParameterData.none(),
  'CallToAction': ParameterData.none(),
  'Location': ParameterData.none(),
  'SignUp': ParameterData.none(),
  'SignIn': ParameterData.none(),
  'SignUp_Name': ParameterData.none(),
  'SignUp_Password': ParameterData.none(),
  'SignUp_Birthday': ParameterData.none(),
  'SignUp_Username': ParameterData.none(),
  'SignUp_UsernameConfirmation': ParameterData.none(),
  'TagUsers': ParameterData.none(),
  'SelectTaggedUsers': ParameterData.none(),
  'ProfileOther': (data) async => ParameterData(
        allParams: {
          'username': getParameter<String>(data, 'username'),
        },
      ),
  'EditProfile': ParameterData.none(),
  'FollowersFollowing': (data) async => ParameterData(
        allParams: {
          'followersTabIndex': getParameter<int>(data, 'followersTabIndex'),
        },
      ),
  'FollowersFollowingOther': (data) async => ParameterData(
        allParams: {
          'userRef': getParameter<DocumentReference>(data, 'userRef'),
        },
      ),
  'EditPost': (data) async => ParameterData(
        allParams: {
          'post': await getDocumentParameter<PostsRecord>(
              data, 'post', PostsRecord.fromSnapshot),
        },
      ),
  'Messages': ParameterData.none(),
  'NewMessage': ParameterData.none(),
  'IndividualMessage': (data) async => ParameterData(
        allParams: {
          'chat': getParameter<DocumentReference>(data, 'chat'),
        },
      ),
  'Get_Started': ParameterData.none(),
  'assistantGPT': ParameterData.none(),
  'assistantGPTPro': ParameterData.none(),
  'gptVision': ParameterData.none(),
  'gptVisionPro': ParameterData.none(),
  'ScheduleTraining': ParameterData.none(),
  'editTraining': (data) async => ParameterData(
        allParams: {
          'trainingReference':
              getParameter<DocumentReference>(data, 'trainingReference'),
          'userRecord': await getDocumentParameter<UsersRecord>(
              data, 'userRecord', UsersRecord.fromSnapshot),
        },
      ),
  'trainingpostDetails': (data) async => ParameterData(
        allParams: {
          'userRecord': await getDocumentParameter<UsersRecord>(
              data, 'userRecord', UsersRecord.fromSnapshot),
          'trainingReference':
              getParameter<DocumentReference>(data, 'trainingReference'),
        },
      ),
  'trainingHome': ParameterData.none(),
  'JoinTraining': ParameterData.none(),
  'progressDetails': (data) async => ParameterData(
        allParams: {
          'userRecord': await getDocumentParameter<UsersRecord>(
              data, 'userRecord', UsersRecord.fromSnapshot),
          'trainingReference': await getDocumentParameter<WorkoutRecord>(
              data, 'trainingReference', WorkoutRecord.fromSnapshot),
        },
      ),
  'ExplorePage': ParameterData.none(),
  'blockedPage': ParameterData.none(),
  'createFoodPost': ParameterData.none(),
  'WelcomePage': ParameterData.none(),
  'login': ParameterData.none(),
  'CreateAccount': ParameterData.none(),
  'forgotPassword': ParameterData.none(),
  'EmailVerification': ParameterData.none(),
  'AllMostDone': ParameterData.none(),
  'ProfilePicture': ParameterData.none(),
  'Gender2': ParameterData.none(),
  'HowOldAreYou': ParameterData.none(),
  'Weight': ParameterData.none(),
  'Height': ParameterData.none(),
  'WorkOutLevel': ParameterData.none(),
  'FiveQuestions': ParameterData.none(),
  'Goals': ParameterData.none(),
  'Meals': ParameterData.none(),
  'workoutDays': ParameterData.none(),
  'workoutWhen': ParameterData.none(),
  'workoutLenght': ParameterData.none(),
  'allDone2': ParameterData.none(),
  'Username': ParameterData.none(),
  'changePassword': ParameterData.none(),
  'unblockList': ParameterData.none(),
  'savedPosts': ParameterData.none(),
  'myInfo': ParameterData.none(),
  'myInfoEdit': ParameterData.none(),
  'videoReels': (data) async => ParameterData(
        allParams: {
          'initialStoryIndex': getParameter<int>(data, 'initialStoryIndex'),
        },
      ),
  'Language': ParameterData.none(),
  'detailsExercisePage': (data) async => ParameterData(
        allParams: {
          'userRecord': await getDocumentParameter<UsersRecord>(
              data, 'userRecord', UsersRecord.fromSnapshot),
          'trainingReference':
              getParameter<DocumentReference>(data, 'trainingReference'),
        },
      ),
  'mealScanner': (data) async => ParameterData(
        allParams: {
          'mealRef': getParameter<DocumentReference>(data, 'mealRef'),
        },
      ),
  'mealScannerPro': ParameterData.none(),
  'bodyScanner': ParameterData.none(),
  'bodyScannerPro': ParameterData.none(),
  'report': ParameterData.none(),
  'workoutWhere': ParameterData.none(),
  'foodAlergies': ParameterData.none(),
  'test': ParameterData.none(),
  'addingMeals': (data) async => ParameterData(
        allParams: {
          'mealRef': await getDocumentParameter<MealScannerRecord>(
              data, 'mealRef', MealScannerRecord.fromSnapshot),
        },
      ),
  'mealScannerCopy': ParameterData.none(),
  'detailsExercisePage2': (data) async => ParameterData(
        allParams: {
          'userRecord': await getDocumentParameter<UsersRecord>(
              data, 'userRecord', UsersRecord.fromSnapshot),
          'trainingReference':
              getParameter<DocumentReference>(data, 'trainingReference'),
        },
      ),
  'videoCompress': ParameterData.none(),
  'videoCompressCopy': ParameterData.none(),
  'addingMealsCopy': (data) async => ParameterData(
        allParams: {
          'mealRef': await getDocumentParameter<MealScannerRecord>(
              data, 'mealRef', MealScannerRecord.fromSnapshot),
        },
      ),
  'mealCollection': ParameterData.none(),
  'videoCompressCopyCopy': ParameterData.none(),
  'videoCompressCopyCopyCopy': ParameterData.none(),
  'reportCopy': ParameterData.none(),
  'bodyscanner2': ParameterData.none(),
  'bodyscanner3': ParameterData.none(),
  'bodyscanner4': ParameterData.none(),
  'workoutPlan': ParameterData.none(),
  'mealPlan': ParameterData.none(),
  'jebemtimater': ParameterData.none(),
  'videoReelsCopy': (data) async => ParameterData(
        allParams: {
          'initialStoryIndex': getParameter<int>(data, 'initialStoryIndex'),
        },
      ),
};

Map<String, dynamic> getInitialParameterData(Map<String, dynamic> data) {
  try {
    final parameterDataStr = data['parameterData'];
    if (parameterDataStr == null ||
        parameterDataStr is! String ||
        parameterDataStr.isEmpty) {
      return {};
    }
    return jsonDecode(parameterDataStr) as Map<String, dynamic>;
  } catch (e) {
    print('Error parsing parameter data: $e');
    return {};
  }
}
