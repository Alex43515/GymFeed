import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "username" field.
  String? _username;
  String get username => _username ?? '';
  bool hasUsername() => _username != null;

  // "bio" field.
  String? _bio;
  String get bio => _bio ?? '';
  bool hasBio() => _bio != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "following" field.
  List<DocumentReference>? _following;
  List<DocumentReference> get following => _following ?? const [];
  bool hasFollowing() => _following != null;

  // "enable_email" field.
  bool? _enableEmail;
  bool get enableEmail => _enableEmail ?? false;
  bool hasEnableEmail() => _enableEmail != null;

  // "birthday" field.
  DateTime? _birthday;
  DateTime? get birthday => _birthday;
  bool hasBirthday() => _birthday != null;

  // "unreadNotifications" field.
  List<DocumentReference>? _unreadNotifications;
  List<DocumentReference> get unreadNotifications =>
      _unreadNotifications ?? const [];
  bool hasUnreadNotifications() => _unreadNotifications != null;

  // "chats" field.
  List<DocumentReference>? _chats;
  List<DocumentReference> get chats => _chats ?? const [];
  bool hasChats() => _chats != null;

  // "personalTrainerSuggestions" field.
  String? _personalTrainerSuggestions;
  String get personalTrainerSuggestions => _personalTrainerSuggestions ?? '';
  bool hasPersonalTrainerSuggestions() => _personalTrainerSuggestions != null;

  // "gptButton" field.
  int? _gptButton;
  int get gptButton => _gptButton ?? 0;
  bool hasGptButton() => _gptButton != null;

  // "visionURL" field.
  String? _visionURL;
  String get visionURL => _visionURL ?? '';
  bool hasVisionURL() => _visionURL != null;

  // "trainingsJoined" field.
  List<DocumentReference>? _trainingsJoined;
  List<DocumentReference> get trainingsJoined => _trainingsJoined ?? const [];
  bool hasTrainingsJoined() => _trainingsJoined != null;

  // "isLoadedTrainings" field.
  bool? _isLoadedTrainings;
  bool get isLoadedTrainings => _isLoadedTrainings ?? false;
  bool hasIsLoadedTrainings() => _isLoadedTrainings != null;

  // "user_blocked" field.
  List<DocumentReference>? _userBlocked;
  List<DocumentReference> get userBlocked => _userBlocked ?? const [];
  bool hasUserBlocked() => _userBlocked != null;

  // "reelsSaved" field.
  List<DocumentReference>? _reelsSaved;
  List<DocumentReference> get reelsSaved => _reelsSaved ?? const [];
  bool hasReelsSaved() => _reelsSaved != null;

  // "workoutLevel" field.
  String? _workoutLevel;
  String get workoutLevel => _workoutLevel ?? '';
  bool hasWorkoutLevel() => _workoutLevel != null;

  // "days" field.
  int? _days;
  int get days => _days ?? 0;
  bool hasDays() => _days != null;

  // "snacks" field.
  int? _snacks;
  int get snacks => _snacks ?? 0;
  bool hasSnacks() => _snacks != null;

  // "gender" field.
  bool? _gender;
  bool get gender => _gender ?? false;
  bool hasGender() => _gender != null;

  // "goals" field.
  String? _goals;
  String get goals => _goals ?? '';
  bool hasGoals() => _goals != null;

  // "workouts" field.
  String? _workouts;
  String get workouts => _workouts ?? '';
  bool hasWorkouts() => _workouts != null;

  // "workoutLenght" field.
  String? _workoutLenght;
  String get workoutLenght => _workoutLenght ?? '';
  bool hasWorkoutLenght() => _workoutLenght != null;

  // "workoutPeriod" field.
  String? _workoutPeriod;
  String get workoutPeriod => _workoutPeriod ?? '';
  bool hasWorkoutPeriod() => _workoutPeriod != null;

  // "age" field.
  int? _age;
  int get age => _age ?? 0;
  bool hasAge() => _age != null;

  // "height" field.
  int? _height;
  int get height => _height ?? 0;
  bool hasHeight() => _height != null;

  // "weight" field.
  int? _weight;
  int get weight => _weight ?? 0;
  bool hasWeight() => _weight != null;

  // "age2" field.
  DateTime? _age2;
  DateTime? get age2 => _age2;
  bool hasAge2() => _age2 != null;

  // "meals" field.
  String? _meals;
  String get meals => _meals ?? '';
  bool hasMeals() => _meals != null;

  // "gptprompt" field.
  String? _gptprompt;
  String get gptprompt => _gptprompt ?? '';
  bool hasGptprompt() => _gptprompt != null;

  // "customLink" field.
  String? _customLink;
  String get customLink => _customLink ?? '';
  bool hasCustomLink() => _customLink != null;

  // "isLoadedHome" field.
  int? _isLoadedHome;
  int get isLoadedHome => _isLoadedHome ?? 0;
  bool hasIsLoadedHome() => _isLoadedHome != null;

  // "isLoadedTraining" field.
  int? _isLoadedTraining;
  int get isLoadedTraining => _isLoadedTraining ?? 0;
  bool hasIsLoadedTraining() => _isLoadedTraining != null;

  // "isLoadedProfile" field.
  int? _isLoadedProfile;
  int get isLoadedProfile => _isLoadedProfile ?? 0;
  bool hasIsLoadedProfile() => _isLoadedProfile != null;

  // "isLoadedJoinTraining" field.
  int? _isLoadedJoinTraining;
  int get isLoadedJoinTraining => _isLoadedJoinTraining ?? 0;
  bool hasIsLoadedJoinTraining() => _isLoadedJoinTraining != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _username = snapshotData['username'] as String?;
    _bio = snapshotData['bio'] as String?;
    _website = snapshotData['website'] as String?;
    _following = getDataList(snapshotData['following']);
    _enableEmail = snapshotData['enable_email'] as bool?;
    _birthday = snapshotData['birthday'] as DateTime?;
    _unreadNotifications = getDataList(snapshotData['unreadNotifications']);
    _chats = getDataList(snapshotData['chats']);
    _personalTrainerSuggestions =
        snapshotData['personalTrainerSuggestions'] as String?;
    _gptButton = castToType<int>(snapshotData['gptButton']);
    _visionURL = snapshotData['visionURL'] as String?;
    _trainingsJoined = getDataList(snapshotData['trainingsJoined']);
    _isLoadedTrainings = snapshotData['isLoadedTrainings'] as bool?;
    _userBlocked = getDataList(snapshotData['user_blocked']);
    _reelsSaved = getDataList(snapshotData['reelsSaved']);
    _workoutLevel = snapshotData['workoutLevel'] as String?;
    _days = castToType<int>(snapshotData['days']);
    _snacks = castToType<int>(snapshotData['snacks']);
    _gender = snapshotData['gender'] as bool?;
    _goals = snapshotData['goals'] as String?;
    _workouts = snapshotData['workouts'] as String?;
    _workoutLenght = snapshotData['workoutLenght'] as String?;
    _workoutPeriod = snapshotData['workoutPeriod'] as String?;
    _age = castToType<int>(snapshotData['age']);
    _height = castToType<int>(snapshotData['height']);
    _weight = castToType<int>(snapshotData['weight']);
    _age2 = snapshotData['age2'] as DateTime?;
    _meals = snapshotData['meals'] as String?;
    _gptprompt = snapshotData['gptprompt'] as String?;
    _customLink = snapshotData['customLink'] as String?;
    _isLoadedHome = castToType<int>(snapshotData['isLoadedHome']);
    _isLoadedTraining = castToType<int>(snapshotData['isLoadedTraining']);
    _isLoadedProfile = castToType<int>(snapshotData['isLoadedProfile']);
    _isLoadedJoinTraining =
        castToType<int>(snapshotData['isLoadedJoinTraining']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  String? username,
  String? bio,
  String? website,
  bool? enableEmail,
  DateTime? birthday,
  String? personalTrainerSuggestions,
  int? gptButton,
  String? visionURL,
  bool? isLoadedTrainings,
  String? workoutLevel,
  int? days,
  int? snacks,
  bool? gender,
  String? goals,
  String? workouts,
  String? workoutLenght,
  String? workoutPeriod,
  int? age,
  int? height,
  int? weight,
  DateTime? age2,
  String? meals,
  String? gptprompt,
  String? customLink,
  int? isLoadedHome,
  int? isLoadedTraining,
  int? isLoadedProfile,
  int? isLoadedJoinTraining,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'username': username,
      'bio': bio,
      'website': website,
      'enable_email': enableEmail,
      'birthday': birthday,
      'personalTrainerSuggestions': personalTrainerSuggestions,
      'gptButton': gptButton,
      'visionURL': visionURL,
      'isLoadedTrainings': isLoadedTrainings,
      'workoutLevel': workoutLevel,
      'days': days,
      'snacks': snacks,
      'gender': gender,
      'goals': goals,
      'workouts': workouts,
      'workoutLenght': workoutLenght,
      'workoutPeriod': workoutPeriod,
      'age': age,
      'height': height,
      'weight': weight,
      'age2': age2,
      'meals': meals,
      'gptprompt': gptprompt,
      'customLink': customLink,
      'isLoadedHome': isLoadedHome,
      'isLoadedTraining': isLoadedTraining,
      'isLoadedProfile': isLoadedProfile,
      'isLoadedJoinTraining': isLoadedJoinTraining,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    const listEquality = ListEquality();
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.username == e2?.username &&
        e1?.bio == e2?.bio &&
        e1?.website == e2?.website &&
        listEquality.equals(e1?.following, e2?.following) &&
        e1?.enableEmail == e2?.enableEmail &&
        e1?.birthday == e2?.birthday &&
        listEquality.equals(e1?.unreadNotifications, e2?.unreadNotifications) &&
        listEquality.equals(e1?.chats, e2?.chats) &&
        e1?.personalTrainerSuggestions == e2?.personalTrainerSuggestions &&
        e1?.gptButton == e2?.gptButton &&
        e1?.visionURL == e2?.visionURL &&
        listEquality.equals(e1?.trainingsJoined, e2?.trainingsJoined) &&
        e1?.isLoadedTrainings == e2?.isLoadedTrainings &&
        listEquality.equals(e1?.userBlocked, e2?.userBlocked) &&
        listEquality.equals(e1?.reelsSaved, e2?.reelsSaved) &&
        e1?.workoutLevel == e2?.workoutLevel &&
        e1?.days == e2?.days &&
        e1?.snacks == e2?.snacks &&
        e1?.gender == e2?.gender &&
        e1?.goals == e2?.goals &&
        e1?.workouts == e2?.workouts &&
        e1?.workoutLenght == e2?.workoutLenght &&
        e1?.workoutPeriod == e2?.workoutPeriod &&
        e1?.age == e2?.age &&
        e1?.height == e2?.height &&
        e1?.weight == e2?.weight &&
        e1?.age2 == e2?.age2 &&
        e1?.meals == e2?.meals &&
        e1?.gptprompt == e2?.gptprompt &&
        e1?.customLink == e2?.customLink &&
        e1?.isLoadedHome == e2?.isLoadedHome &&
        e1?.isLoadedTraining == e2?.isLoadedTraining &&
        e1?.isLoadedProfile == e2?.isLoadedProfile &&
        e1?.isLoadedJoinTraining == e2?.isLoadedJoinTraining;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber,
        e?.username,
        e?.bio,
        e?.website,
        e?.following,
        e?.enableEmail,
        e?.birthday,
        e?.unreadNotifications,
        e?.chats,
        e?.personalTrainerSuggestions,
        e?.gptButton,
        e?.visionURL,
        e?.trainingsJoined,
        e?.isLoadedTrainings,
        e?.userBlocked,
        e?.reelsSaved,
        e?.workoutLevel,
        e?.days,
        e?.snacks,
        e?.gender,
        e?.goals,
        e?.workouts,
        e?.workoutLenght,
        e?.workoutPeriod,
        e?.age,
        e?.height,
        e?.weight,
        e?.age2,
        e?.meals,
        e?.gptprompt,
        e?.customLink,
        e?.isLoadedHome,
        e?.isLoadedTraining,
        e?.isLoadedProfile,
        e?.isLoadedJoinTraining
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
