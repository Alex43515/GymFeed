import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
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

  // "buttonClick" field.
  int? _buttonClick;
  int get buttonClick => _buttonClick ?? 0;
  bool hasButtonClick() => _buttonClick != null;

  // "visionButton" field.
  int? _visionButton;
  int get visionButton => _visionButton ?? 0;
  bool hasVisionButton() => _visionButton != null;

  // "progressImage" field.
  String? _progressImage;
  String get progressImage => _progressImage ?? '';
  bool hasProgressImage() => _progressImage != null;

  // "progressImage2" field.
  String? _progressImage2;
  String get progressImage2 => _progressImage2 ?? '';
  bool hasProgressImage2() => _progressImage2 != null;

  // "progressImage3" field.
  String? _progressImage3;
  String get progressImage3 => _progressImage3 ?? '';
  bool hasProgressImage3() => _progressImage3 != null;

  // "progressImage4" field.
  String? _progressImage4;
  String get progressImage4 => _progressImage4 ?? '';
  bool hasProgressImage4() => _progressImage4 != null;

  // "progressImage5" field.
  String? _progressImage5;
  String get progressImage5 => _progressImage5 ?? '';
  bool hasProgressImage5() => _progressImage5 != null;

  // "progressImage6" field.
  String? _progressImage6;
  String get progressImage6 => _progressImage6 ?? '';
  bool hasProgressImage6() => _progressImage6 != null;

  // "progressImage12" field.
  String? _progressImage12;
  String get progressImage12 => _progressImage12 ?? '';
  bool hasProgressImage12() => _progressImage12 != null;

  // "progressButtonIndex" field.
  int? _progressButtonIndex;
  int get progressButtonIndex => _progressButtonIndex ?? 0;
  bool hasProgressButtonIndex() => _progressButtonIndex != null;

  // "geminiParse" field.
  String? _geminiParse;
  String get geminiParse => _geminiParse ?? '';
  bool hasGeminiParse() => _geminiParse != null;

  // "ufat" field.
  String? _ufat;
  String get ufat => _ufat ?? '';
  bool hasUfat() => _ufat != null;

  // "bfat" field.
  String? _bfat;
  String get bfat => _bfat ?? '';
  bool hasBfat() => _bfat != null;

  // "leanmass" field.
  String? _leanmass;
  String get leanmass => _leanmass ?? '';
  bool hasLeanmass() => _leanmass != null;

  // "efat" field.
  String? _efat;
  String get efat => _efat ?? '';
  bool hasEfat() => _efat != null;

  // "caloriesBurnt" field.
  String? _caloriesBurnt;
  String get caloriesBurnt => _caloriesBurnt ?? '';
  bool hasCaloriesBurnt() => _caloriesBurnt != null;

  // "leanMassIndex" field.
  int? _leanMassIndex;
  int get leanMassIndex => _leanMassIndex ?? 0;
  bool hasLeanMassIndex() => _leanMassIndex != null;

  // "fatMassIndex" field.
  int? _fatMassIndex;
  int get fatMassIndex => _fatMassIndex ?? 0;
  bool hasFatMassIndex() => _fatMassIndex != null;

  // "geminiParse2" field.
  String? _geminiParse2;
  String get geminiParse2 => _geminiParse2 ?? '';
  bool hasGeminiParse2() => _geminiParse2 != null;

  // "caloriesBurn" field.
  String? _caloriesBurn;
  String get caloriesBurn => _caloriesBurn ?? '';
  bool hasCaloriesBurn() => _caloriesBurn != null;

  // "caloriesIntake" field.
  String? _caloriesIntake;
  String get caloriesIntake => _caloriesIntake ?? '';
  bool hasCaloriesIntake() => _caloriesIntake != null;

  // "mealPlan" field.
  String? _mealPlan;
  String get mealPlan => _mealPlan ?? '';
  bool hasMealPlan() => _mealPlan != null;

  // "workoutPlan" field.
  String? _workoutPlan;
  String get workoutPlan => _workoutPlan ?? '';
  bool hasWorkoutPlan() => _workoutPlan != null;

  // "proTips" field.
  String? _proTips;
  String get proTips => _proTips ?? '';
  bool hasProTips() => _proTips != null;

  // "quotes" field.
  String? _quotes;
  String get quotes => _quotes ?? '';
  bool hasQuotes() => _quotes != null;

  // "carbsPerDay" field.
  String? _carbsPerDay;
  String get carbsPerDay => _carbsPerDay ?? '';
  bool hasCarbsPerDay() => _carbsPerDay != null;

  // "proteinPerDay" field.
  String? _proteinPerDay;
  String get proteinPerDay => _proteinPerDay ?? '';
  bool hasProteinPerDay() => _proteinPerDay != null;

  // "fatsPerDay" field.
  String? _fatsPerDay;
  String get fatsPerDay => _fatsPerDay ?? '';
  bool hasFatsPerDay() => _fatsPerDay != null;

  // "caloricIntakePerDay" field.
  String? _caloricIntakePerDay;
  String get caloricIntakePerDay => _caloricIntakePerDay ?? '';
  bool hasCaloricIntakePerDay() => _caloricIntakePerDay != null;

  // "gender2" field.
  String? _gender2;
  String get gender2 => _gender2 ?? '';
  bool hasGender2() => _gender2 != null;

  // "workoutWhere" field.
  String? _workoutWhere;
  String get workoutWhere => _workoutWhere ?? '';
  bool hasWorkoutWhere() => _workoutWhere != null;

  // "foodAlergies" field.
  String? _foodAlergies;
  String get foodAlergies => _foodAlergies ?? '';
  bool hasFoodAlergies() => _foodAlergies != null;

  // "caloriesScanner" field.
  int? _caloriesScanner;
  int get caloriesScanner => _caloriesScanner ?? 0;
  bool hasCaloriesScanner() => _caloriesScanner != null;

  // "fatsScanner" field.
  int? _fatsScanner;
  int get fatsScanner => _fatsScanner ?? 0;
  bool hasFatsScanner() => _fatsScanner != null;

  // "proteinScanner" field.
  int? _proteinScanner;
  int get proteinScanner => _proteinScanner ?? 0;
  bool hasProteinScanner() => _proteinScanner != null;

  // "carbsScanner" field.
  int? _carbsScanner;
  int get carbsScanner => _carbsScanner ?? 0;
  bool hasCarbsScanner() => _carbsScanner != null;

  // "descriptionScanner" field.
  String? _descriptionScanner;
  String get descriptionScanner => _descriptionScanner ?? '';
  bool hasDescriptionScanner() => _descriptionScanner != null;

  // "compressVideo" field.
  String? _compressVideo;
  String get compressVideo => _compressVideo ?? '';
  bool hasCompressVideo() => _compressVideo != null;

  // "ufat2" field.
  double? _ufat2;
  double get ufat2 => _ufat2 ?? 0.0;
  bool hasUfat2() => _ufat2 != null;

  // "bfat2" field.
  double? _bfat2;
  double get bfat2 => _bfat2 ?? 0.0;
  bool hasBfat2() => _bfat2 != null;

  // "efat2" field.
  double? _efat2;
  double get efat2 => _efat2 ?? 0.0;
  bool hasEfat2() => _efat2 != null;

  // "leanMass2" field.
  double? _leanMass2;
  double get leanMass2 => _leanMass2 ?? 0.0;
  bool hasLeanMass2() => _leanMass2 != null;

  // "geminiParse3" field.
  String? _geminiParse3;
  String get geminiParse3 => _geminiParse3 ?? '';
  bool hasGeminiParse3() => _geminiParse3 != null;

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
    _buttonClick = castToType<int>(snapshotData['buttonClick']);
    _visionButton = castToType<int>(snapshotData['visionButton']);
    _progressImage = snapshotData['progressImage'] as String?;
    _progressImage2 = snapshotData['progressImage2'] as String?;
    _progressImage3 = snapshotData['progressImage3'] as String?;
    _progressImage4 = snapshotData['progressImage4'] as String?;
    _progressImage5 = snapshotData['progressImage5'] as String?;
    _progressImage6 = snapshotData['progressImage6'] as String?;
    _progressImage12 = snapshotData['progressImage12'] as String?;
    _progressButtonIndex = castToType<int>(snapshotData['progressButtonIndex']);
    _geminiParse = snapshotData['geminiParse'] as String?;
    _ufat = snapshotData['ufat'] as String?;
    _bfat = snapshotData['bfat'] as String?;
    _leanmass = snapshotData['leanmass'] as String?;
    _efat = snapshotData['efat'] as String?;
    _caloriesBurnt = snapshotData['caloriesBurnt'] as String?;
    _leanMassIndex = castToType<int>(snapshotData['leanMassIndex']);
    _fatMassIndex = castToType<int>(snapshotData['fatMassIndex']);
    _geminiParse2 = snapshotData['geminiParse2'] as String?;
    _caloriesBurn = snapshotData['caloriesBurn'] as String?;
    _caloriesIntake = snapshotData['caloriesIntake'] as String?;
    _mealPlan = snapshotData['mealPlan'] as String?;
    _workoutPlan = snapshotData['workoutPlan'] as String?;
    _proTips = snapshotData['proTips'] as String?;
    _quotes = snapshotData['quotes'] as String?;
    _carbsPerDay = snapshotData['carbsPerDay'] as String?;
    _proteinPerDay = snapshotData['proteinPerDay'] as String?;
    _fatsPerDay = snapshotData['fatsPerDay'] as String?;
    _caloricIntakePerDay = snapshotData['caloricIntakePerDay'] as String?;
    _gender2 = snapshotData['gender2'] as String?;
    _workoutWhere = snapshotData['workoutWhere'] as String?;
    _foodAlergies = snapshotData['foodAlergies'] as String?;
    _caloriesScanner = castToType<int>(snapshotData['caloriesScanner']);
    _fatsScanner = castToType<int>(snapshotData['fatsScanner']);
    _proteinScanner = castToType<int>(snapshotData['proteinScanner']);
    _carbsScanner = castToType<int>(snapshotData['carbsScanner']);
    _descriptionScanner = snapshotData['descriptionScanner'] as String?;
    _compressVideo = snapshotData['compressVideo'] as String?;
    _ufat2 = castToType<double>(snapshotData['ufat2']);
    _bfat2 = castToType<double>(snapshotData['bfat2']);
    _efat2 = castToType<double>(snapshotData['efat2']);
    _leanMass2 = castToType<double>(snapshotData['leanMass2']);
    _geminiParse3 = snapshotData['geminiParse3'] as String?;
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
  int? buttonClick,
  int? visionButton,
  String? progressImage,
  String? progressImage2,
  String? progressImage3,
  String? progressImage4,
  String? progressImage5,
  String? progressImage6,
  String? progressImage12,
  int? progressButtonIndex,
  String? geminiParse,
  String? ufat,
  String? bfat,
  String? leanmass,
  String? efat,
  String? caloriesBurnt,
  int? leanMassIndex,
  int? fatMassIndex,
  String? geminiParse2,
  String? caloriesBurn,
  String? caloriesIntake,
  String? mealPlan,
  String? workoutPlan,
  String? proTips,
  String? quotes,
  String? carbsPerDay,
  String? proteinPerDay,
  String? fatsPerDay,
  String? caloricIntakePerDay,
  String? gender2,
  String? workoutWhere,
  String? foodAlergies,
  int? caloriesScanner,
  int? fatsScanner,
  int? proteinScanner,
  int? carbsScanner,
  String? descriptionScanner,
  String? compressVideo,
  double? ufat2,
  double? bfat2,
  double? efat2,
  double? leanMass2,
  String? geminiParse3,
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
      'buttonClick': buttonClick,
      'visionButton': visionButton,
      'progressImage': progressImage,
      'progressImage2': progressImage2,
      'progressImage3': progressImage3,
      'progressImage4': progressImage4,
      'progressImage5': progressImage5,
      'progressImage6': progressImage6,
      'progressImage12': progressImage12,
      'progressButtonIndex': progressButtonIndex,
      'geminiParse': geminiParse,
      'ufat': ufat,
      'bfat': bfat,
      'leanmass': leanmass,
      'efat': efat,
      'caloriesBurnt': caloriesBurnt,
      'leanMassIndex': leanMassIndex,
      'fatMassIndex': fatMassIndex,
      'geminiParse2': geminiParse2,
      'caloriesBurn': caloriesBurn,
      'caloriesIntake': caloriesIntake,
      'mealPlan': mealPlan,
      'workoutPlan': workoutPlan,
      'proTips': proTips,
      'quotes': quotes,
      'carbsPerDay': carbsPerDay,
      'proteinPerDay': proteinPerDay,
      'fatsPerDay': fatsPerDay,
      'caloricIntakePerDay': caloricIntakePerDay,
      'gender2': gender2,
      'workoutWhere': workoutWhere,
      'foodAlergies': foodAlergies,
      'caloriesScanner': caloriesScanner,
      'fatsScanner': fatsScanner,
      'proteinScanner': proteinScanner,
      'carbsScanner': carbsScanner,
      'descriptionScanner': descriptionScanner,
      'compressVideo': compressVideo,
      'ufat2': ufat2,
      'bfat2': bfat2,
      'efat2': efat2,
      'leanMass2': leanMass2,
      'geminiParse3': geminiParse3,
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
        e1?.isLoadedJoinTraining == e2?.isLoadedJoinTraining &&
        e1?.buttonClick == e2?.buttonClick &&
        e1?.visionButton == e2?.visionButton &&
        e1?.progressImage == e2?.progressImage &&
        e1?.progressImage2 == e2?.progressImage2 &&
        e1?.progressImage3 == e2?.progressImage3 &&
        e1?.progressImage4 == e2?.progressImage4 &&
        e1?.progressImage5 == e2?.progressImage5 &&
        e1?.progressImage6 == e2?.progressImage6 &&
        e1?.progressImage12 == e2?.progressImage12 &&
        e1?.progressButtonIndex == e2?.progressButtonIndex &&
        e1?.geminiParse == e2?.geminiParse &&
        e1?.ufat == e2?.ufat &&
        e1?.bfat == e2?.bfat &&
        e1?.leanmass == e2?.leanmass &&
        e1?.efat == e2?.efat &&
        e1?.caloriesBurnt == e2?.caloriesBurnt &&
        e1?.leanMassIndex == e2?.leanMassIndex &&
        e1?.fatMassIndex == e2?.fatMassIndex &&
        e1?.geminiParse2 == e2?.geminiParse2 &&
        e1?.caloriesBurn == e2?.caloriesBurn &&
        e1?.caloriesIntake == e2?.caloriesIntake &&
        e1?.mealPlan == e2?.mealPlan &&
        e1?.workoutPlan == e2?.workoutPlan &&
        e1?.proTips == e2?.proTips &&
        e1?.quotes == e2?.quotes &&
        e1?.carbsPerDay == e2?.carbsPerDay &&
        e1?.proteinPerDay == e2?.proteinPerDay &&
        e1?.fatsPerDay == e2?.fatsPerDay &&
        e1?.caloricIntakePerDay == e2?.caloricIntakePerDay &&
        e1?.gender2 == e2?.gender2 &&
        e1?.workoutWhere == e2?.workoutWhere &&
        e1?.foodAlergies == e2?.foodAlergies &&
        e1?.caloriesScanner == e2?.caloriesScanner &&
        e1?.fatsScanner == e2?.fatsScanner &&
        e1?.proteinScanner == e2?.proteinScanner &&
        e1?.carbsScanner == e2?.carbsScanner &&
        e1?.descriptionScanner == e2?.descriptionScanner &&
        e1?.compressVideo == e2?.compressVideo &&
        e1?.ufat2 == e2?.ufat2 &&
        e1?.bfat2 == e2?.bfat2 &&
        e1?.efat2 == e2?.efat2 &&
        e1?.leanMass2 == e2?.leanMass2 &&
        e1?.geminiParse3 == e2?.geminiParse3;
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
        e?.isLoadedJoinTraining,
        e?.buttonClick,
        e?.visionButton,
        e?.progressImage,
        e?.progressImage2,
        e?.progressImage3,
        e?.progressImage4,
        e?.progressImage5,
        e?.progressImage6,
        e?.progressImage12,
        e?.progressButtonIndex,
        e?.geminiParse,
        e?.ufat,
        e?.bfat,
        e?.leanmass,
        e?.efat,
        e?.caloriesBurnt,
        e?.leanMassIndex,
        e?.fatMassIndex,
        e?.geminiParse2,
        e?.caloriesBurn,
        e?.caloriesIntake,
        e?.mealPlan,
        e?.workoutPlan,
        e?.proTips,
        e?.quotes,
        e?.carbsPerDay,
        e?.proteinPerDay,
        e?.fatsPerDay,
        e?.caloricIntakePerDay,
        e?.gender2,
        e?.workoutWhere,
        e?.foodAlergies,
        e?.caloriesScanner,
        e?.fatsScanner,
        e?.proteinScanner,
        e?.carbsScanner,
        e?.descriptionScanner,
        e?.compressVideo,
        e?.ufat2,
        e?.bfat2,
        e?.efat2,
        e?.leanMass2,
        e?.geminiParse3
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
