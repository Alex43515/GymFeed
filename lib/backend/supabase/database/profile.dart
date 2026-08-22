import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed view of a GymFeed user, mirroring the old Firestore `UsersRecord` so the
/// widget layer can swap `currentUserDocument.x` for `currentUserProfile.x` with a
/// near-mechanical rename.
///
/// Public fields come from `profiles` (readable by anyone). Private fields come
/// from `profile_private` (owner-only via RLS) and are only populated when the
/// row is the current user's own — otherwise they fall back to sensible defaults.
class Profile {
  Profile(this.data, [Map<String, dynamic>? private])
      : _private = private ?? _extractPrivate(data);

  final Map<String, dynamic> data;
  final Map<String, dynamic> _private;

  static Map<String, dynamic> _extractPrivate(Map<String, dynamic> data) {
    // A joined `profiles?select=*,profile_private(*)` query nests the private row.
    final raw = data['profile_private'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    return const {};
  }

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(map);

  // ---- helpers ----
  String _s(Map<String, dynamic> m, String k) => (m[k] as String?) ?? '';
  int _i(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt() ?? 0;
  double _d(Map<String, dynamic> m, String k) =>
      (m[k] as num?)?.toDouble() ?? 0.0;
  bool _b(Map<String, dynamic> m, String k) => (m[k] as bool?) ?? false;
  DateTime? _dt(Map<String, dynamic> m, String k) =>
      m[k] == null ? null : DateTime.tryParse(m[k].toString());

  // ---- public (profiles) ----
  String get id => _s(data, 'id');
  String get uid =>
      id; // old code used `.uid`; identity is the Supabase user id
  String get username => _s(data, 'username');
  String get displayName => _s(data, 'display_name');
  String get photoUrl => _s(data, 'photo_url');
  String get bio => _s(data, 'bio');
  String get website => _s(data, 'website');
  String get customLink => _s(data, 'custom_link');
  DateTime? get createdTime => _dt(data, 'created_at');

  // ---- private (profile_private) ----
  String get email => _s(_private, 'email');
  String get phoneNumber => _s(_private, 'phone_number');
  DateTime? get birthday => _dt(_private, 'birthday');
  bool get enableEmail => _b(_private, 'enable_email');
  bool get gender => _b(_private, 'gender');
  int get age => _i(_private, 'age');
  int get height => _i(_private, 'height_cm');
  int get weight => _i(_private, 'weight_kg');
  String get workoutLevel => _s(_private, 'workout_level');
  String get goals => _s(_private, 'goals');
  String get workouts => _s(_private, 'workouts');
  String get workoutLenght => _s(_private, 'workout_length');
  String get workoutPeriod => _s(_private, 'workout_period');
  String get meals => _s(_private, 'meals');
  int get snacks => _i(_private, 'snacks');
  int get days => _i(_private, 'days');
  String get gptprompt => _s(_private, 'gpt_prompt');
  String get personalTrainerSuggestions =>
      _s(_private, 'personal_trainer_suggestions');
  String get visionURL => _s(_private, 'vision_url');
  String get progressImage => _s(_private, 'progress_image');
  String get progressImage2 => _s(_private, 'progress_image2');
  String get progressImage3 => _s(_private, 'progress_image3');
  String get progressImage4 => _s(_private, 'progress_image4');
  String get progressImage5 => _s(_private, 'progress_image5');
  String get progressImage6 => _s(_private, 'progress_image6');
  String get progressImage12 => _s(_private, 'progress_image12');
  int get progressButtonIndex => _i(_private, 'progress_button_index');
  int get leanMassIndex => _i(_private, 'lean_mass_index');
  int get fatMassIndex => _i(_private, 'fat_mass_index');
  double get ufat2 => _d(_private, 'ufat2');
  double get bfat2 => _d(_private, 'bfat2');
  double get efat2 => _d(_private, 'efat2');
  double get leanMass2 => _d(_private, 'lean_mass2');
  int get gptButton => _i(_private, 'gpt_button');
  int get visionButton => _i(_private, 'vision_button');
  int get buttonClick => _i(_private, 'button_click');
  int get caloriesScanner => _i(_private, 'calories_scanner');
  int get fatsScanner => _i(_private, 'fats_scanner');
  int get proteinScanner => _i(_private, 'protein_scanner');
  int get carbsScanner => _i(_private, 'carbs_scanner');
  DateTime? get age2 => _dt(_private, 'age2');
  String get geminiParse => _s(_private, 'gemini_parse');
  String get geminiParse2 => _s(_private, 'gemini_parse2');
  String get geminiParse3 => _s(_private, 'gemini_parse3');
  String get ufat => _s(_private, 'ufat');
  String get bfat => _s(_private, 'bfat');
  String get leanmass => _s(_private, 'leanmass');
  String get efat => _s(_private, 'efat');
  String get caloriesBurnt => _s(_private, 'calories_burnt');
  String get caloriesBurn => _s(_private, 'calories_burn');
  String get caloriesIntake => _s(_private, 'calories_intake');
  String get mealPlan => _s(_private, 'meal_plan');
  String get workoutPlan => _s(_private, 'workout_plan');
  String get proTips => _s(_private, 'pro_tips');
  String get quotes => _s(_private, 'quotes');
  String get carbsPerDay => _s(_private, 'carbs_per_day');
  String get proteinPerDay => _s(_private, 'protein_per_day');
  String get fatsPerDay => _s(_private, 'fats_per_day');
  String get caloricIntakePerDay => _s(_private, 'caloric_intake_per_day');
  String get gender2 => _s(_private, 'gender2');
  String get workoutWhere => _s(_private, 'workout_where');
  String get foodAlergies => _s(_private, 'food_alergies');
  String get descriptionScanner => _s(_private, 'description_scanner');
  String get compressVideo => _s(_private, 'compress_video');
  int get isLoadedHome => _i(_private, 'is_loaded_home');
  int get isLoadedTraining => _i(_private, 'is_loaded_training');
  int get isLoadedProfile => _i(_private, 'is_loaded_profile');
  int get isLoadedJoinTraining => _i(_private, 'is_loaded_join_training');
  bool get isLoadedTrainings => _b(_private, 'is_loaded_trainings');

  // ---- legacy Firestore list fields ----
  // The old UsersRecord embedded these as List<DocumentReference>. That data now
  // lives in dedicated Supabase tables (follows, notifications, chat_members,
  // training_participants, blocks). These getters return empty lists so widgets
  // that still read `currentUserDocument?.following.toList()` compile and render
  // an empty state; each screen swaps to the matching repository as it migrates.
  List<DocumentReference> get following {
    final ids = data['_following_ids'];
    if (ids is List) {
      return ids
          .map((id) => FirebaseFirestore.instance.doc('users/$id'))
          .toList();
    }
    return const <DocumentReference>[];
  }

  List<DocumentReference> get unreadNotifications =>
      const <DocumentReference>[];
  List<DocumentReference> get chats => const <DocumentReference>[];
  List<DocumentReference> get trainingsJoined => const <DocumentReference>[];
  List<DocumentReference> get userBlocked => const <DocumentReference>[];

  @override
  bool operator ==(Object other) => other is Profile && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Column groups so the repository knows which table each write targets.
/// Public columns live on `profiles`; everything else on `profile_private`.
const kProfilePublicColumns = <String>{
  'username',
  'display_name',
  'photo_url',
  'bio',
  'website',
  'custom_link',
};
