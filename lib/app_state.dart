import 'package:flutter/material.dart';
import '/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _assistantId = prefs.getString('ff_assistantId') ?? _assistantId;
    });
    _safeInit(() {
      _list = prefs.getBool('ff_list') ?? _list;
    });
    _safeInit(() {
      _list2 = prefs.getBool('ff_list2') ?? _list2;
    });
    _safeInit(() {
      _selectedLanguage =
          prefs.getBool('ff_selectedLanguage') ?? _selectedLanguage;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  bool _showCommentField = false;
  bool get showCommentField => _showCommentField;
  set showCommentField(bool value) {
    _showCommentField = value;
  }

  List<DocumentReference> _emptyList = [];
  List<DocumentReference> get emptyList => _emptyList;
  set emptyList(List<DocumentReference> value) {
    _emptyList = value;
  }

  void addToEmptyList(DocumentReference value) {
    emptyList.add(value);
  }

  void removeFromEmptyList(DocumentReference value) {
    emptyList.remove(value);
  }

  void removeAtIndexFromEmptyList(int index) {
    emptyList.removeAt(index);
  }

  void updateEmptyListAtIndex(
    int index,
    DocumentReference Function(DocumentReference) updateFn,
  ) {
    emptyList[index] = updateFn(_emptyList[index]);
  }

  void insertAtIndexInEmptyList(int index, DocumentReference value) {
    emptyList.insert(index, value);
  }

  String _uploadPhoto = '';
  String get uploadPhoto => _uploadPhoto;
  set uploadPhoto(String value) {
    _uploadPhoto = value;
  }

  String _calltoactiontext = '';
  String get calltoactiontext => _calltoactiontext;
  set calltoactiontext(String value) {
    _calltoactiontext = value;
  }

  String _calltoactionurl = '';
  String get calltoactionurl => _calltoactionurl;
  set calltoactionurl(String value) {
    _calltoactionurl = value;
  }

  bool _calltoactionenabled = false;
  bool get calltoactionenabled => _calltoactionenabled;
  set calltoactionenabled(bool value) {
    _calltoactionenabled = value;
  }

  String _location = '';
  String get location => _location;
  set location(String value) {
    _location = value;
  }

  String _signupEmail = '';
  String get signupEmail => _signupEmail;
  set signupEmail(String value) {
    _signupEmail = value;
  }

  String _signupName = '';
  String get signupName => _signupName;
  set signupName(String value) {
    _signupName = value;
  }

  String _signupPassword = '';
  String get signupPassword => _signupPassword;
  set signupPassword(String value) {
    _signupPassword = value;
  }

  DateTime? _signupBirthday = DateTime.fromMillisecondsSinceEpoch(946746000000);
  DateTime? get signupBirthday => _signupBirthday;
  set signupBirthday(DateTime? value) {
    _signupBirthday = value;
  }

  String _signupUsername = '';
  String get signupUsername => _signupUsername;
  set signupUsername(String value) {
    _signupUsername = value;
  }

  List<DocumentReference> _taggedUsers = [];
  List<DocumentReference> get taggedUsers => _taggedUsers;
  set taggedUsers(List<DocumentReference> value) {
    _taggedUsers = value;
  }

  void addToTaggedUsers(DocumentReference value) {
    taggedUsers.add(value);
  }

  void removeFromTaggedUsers(DocumentReference value) {
    taggedUsers.remove(value);
  }

  void removeAtIndexFromTaggedUsers(int index) {
    taggedUsers.removeAt(index);
  }

  void updateTaggedUsersAtIndex(
    int index,
    DocumentReference Function(DocumentReference) updateFn,
  ) {
    taggedUsers[index] = updateFn(_taggedUsers[index]);
  }

  void insertAtIndexInTaggedUsers(int index, DocumentReference value) {
    taggedUsers.insert(index, value);
  }

  bool _showRecentSearch = true;
  bool get showRecentSearch => _showRecentSearch;
  set showRecentSearch(bool value) {
    _showRecentSearch = value;
  }

  String _imageLabels = '';
  String get imageLabels => _imageLabels;
  set imageLabels(String value) {
    _imageLabels = value;
  }

  String _currentSearch = '';
  String get currentSearch => _currentSearch;
  set currentSearch(String value) {
    _currentSearch = value;
  }

  bool _imageSearchDummyToggle = false;
  bool get imageSearchDummyToggle => _imageSearchDummyToggle;
  set imageSearchDummyToggle(bool value) {
    _imageSearchDummyToggle = value;
  }

  String _tempProfilePic = '';
  String get tempProfilePic => _tempProfilePic;
  set tempProfilePic(String value) {
    _tempProfilePic = value;
  }

  List<DocumentReference> _tempUserList = [];
  List<DocumentReference> get tempUserList => _tempUserList;
  set tempUserList(List<DocumentReference> value) {
    _tempUserList = value;
  }

  void addToTempUserList(DocumentReference value) {
    tempUserList.add(value);
  }

  void removeFromTempUserList(DocumentReference value) {
    tempUserList.remove(value);
  }

  void removeAtIndexFromTempUserList(int index) {
    tempUserList.removeAt(index);
  }

  void updateTempUserListAtIndex(
    int index,
    DocumentReference Function(DocumentReference) updateFn,
  ) {
    tempUserList[index] = updateFn(_tempUserList[index]);
  }

  void insertAtIndexInTempUserList(int index, DocumentReference value) {
    tempUserList.insert(index, value);
  }

  DocumentReference? _tempUserRecord;
  DocumentReference? get tempUserRecord => _tempUserRecord;
  set tempUserRecord(DocumentReference? value) {
    _tempUserRecord = value;
  }

  String _assistantId = 'asst_5Bary23tk80wnVzfinJNCfT4';
  String get assistantId => _assistantId;
  set assistantId(String value) {
    _assistantId = value;
    prefs.setString('ff_assistantId', value);
  }

  String _apiKey =
      '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';
  String get apiKey => _apiKey;
  set apiKey(String value) {
    _apiKey = value;
  }

  String _query = '';
  String get query => _query;
  set query(String value) {
    _query = value;
  }

  String _imageURL = '';
  String get imageURL => _imageURL;
  set imageURL(String value) {
    _imageURL = value;
  }

  String _chatHistoryAPP = '';
  String get chatHistoryAPP => _chatHistoryAPP;
  set chatHistoryAPP(String value) {
    _chatHistoryAPP = value;
  }

  String _assistantVisionID = 'asst_5Bary23tk80wnVzfinJNCfT4';
  String get assistantVisionID => _assistantVisionID;
  set assistantVisionID(String value) {
    _assistantVisionID = value;
  }

  bool _list = true;
  bool get list => _list;
  set list(bool value) {
    _list = value;
    prefs.setBool('ff_list', value);
  }

  bool _list2 = true;
  bool get list2 => _list2;
  set list2(bool value) {
    _list2 = value;
    prefs.setBool('ff_list2', value);
  }

  String _theusernames = '';
  String get theusernames => _theusernames;
  set theusernames(String value) {
    _theusernames = value;
  }

  String _uploadVideo = '';
  String get uploadVideo => _uploadVideo;
  set uploadVideo(String value) {
    _uploadVideo = value;
  }

  String _bio = '';
  String get bio => _bio;
  set bio(String value) {
    _bio = value;
  }

  String _workoutLevel = '';
  String get workoutLevel => _workoutLevel;
  set workoutLevel(String value) {
    _workoutLevel = value;
  }

  int _days = 0;
  int get days => _days;
  set days(int value) {
    _days = value;
  }

  int _snacks = 0;
  int get snacks => _snacks;
  set snacks(int value) {
    _snacks = value;
  }

  bool _gender = false;
  bool get gender => _gender;
  set gender(bool value) {
    _gender = value;
  }

  String _goals = '';
  String get goals => _goals;
  set goals(String value) {
    _goals = value;
  }

  String _workouts = '';
  String get workouts => _workouts;
  set workouts(String value) {
    _workouts = value;
  }

  String _workoutLenght = '';
  String get workoutLenght => _workoutLenght;
  set workoutLenght(String value) {
    _workoutLenght = value;
  }

  String _workoutPeriod = '';
  String get workoutPeriod => _workoutPeriod;
  set workoutPeriod(String value) {
    _workoutPeriod = value;
  }

  DateTime? _age2;
  DateTime? get age2 => _age2;
  set age2(DateTime? value) {
    _age2 = value;
  }

  int _height = 0;
  int get height => _height;
  set height(int value) {
    _height = value;
  }

  int _weight = 0;
  int get weight => _weight;
  set weight(int value) {
    _weight = value;
  }

  String _meals = '';
  String get meals => _meals;
  set meals(String value) {
    _meals = value;
  }

  String _profileImage = '';
  String get profileImage => _profileImage;
  set profileImage(String value) {
    _profileImage = value;
  }

  LatLng? _locationPost;
  LatLng? get locationPost => _locationPost;
  set locationPost(LatLng? value) {
    _locationPost = value;
  }

  bool _selectedLanguage = false;
  bool get selectedLanguage => _selectedLanguage;
  set selectedLanguage(bool value) {
    _selectedLanguage = value;
    prefs.setBool('ff_selectedLanguage', value);
  }

  String _geminiOutput = '';
  String get geminiOutput => _geminiOutput;
  set geminiOutput(String value) {
    _geminiOutput = value;
  }

  String _workoutWhere = '';
  String get workoutWhere => _workoutWhere;
  set workoutWhere(String value) {
    _workoutWhere = value;
  }

  String _foodAlergies = '';
  String get foodAlergies => _foodAlergies;
  set foodAlergies(String value) {
    _foodAlergies = value;
  }

  String _gender2 = '';
  String get gender2 => _gender2;
  set gender2(String value) {
    _gender2 = value;
  }

  String _selectedVideoPath = '';
  String get selectedVideoPath => _selectedVideoPath;
  set selectedVideoPath(String value) {
    _selectedVideoPath = value;
  }

  List<String> _Category = [
    'Cardio',
    'Muscle Mass',
    'Calisthenics',
    'CrossFit',
    'Zumba',
    'Yoga'
  ];
  List<String> get Category => _Category;
  set Category(List<String> value) {
    _Category = value;
  }

  void addToCategory(String value) {
    Category.add(value);
  }

  void removeFromCategory(String value) {
    Category.remove(value);
  }

  void removeAtIndexFromCategory(int index) {
    Category.removeAt(index);
  }

  void updateCategoryAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    Category[index] = updateFn(_Category[index]);
  }

  void insertAtIndexInCategory(int index, String value) {
    Category.insert(index, value);
  }

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;
  set uploadProgress(double value) {
    _uploadProgress = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
