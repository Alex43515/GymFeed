import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/supabase/supabase.dart';

/// Bridge helpers that let FlutterFlow's generated `Record` layer read from
/// Supabase while keeping the `DocumentReference`-shaped API the widgets expect.
///
/// A synthesized reference is just a path object (`collection/id`) — no Firestore
/// network call is made. `ref.id` carries the Supabase row id, which the Record
/// data-access methods use as the Supabase primary key.

DocumentReference supaRef(String collection, String id) =>
    FirebaseFirestore.instance.collection(collection).doc(id);

/// Single row by id from a Supabase [table] (null on blank id / not found).
Future<Map<String, dynamic>?> supaById(String table, String id) async {
  if (id.isEmpty) return null;
  try {
    return await supabase.from(table).select().eq('id', id).maybeSingle();
  } catch (_) {
    return null;
  }
}

/// Parse a Supabase timestamp/date string to DateTime (null-safe).
DateTime? supaDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

/// Build a `users/<id>` reference from a Supabase user id (for author refs).
DocumentReference? supaUserRef(dynamic userId) {
  final id = (userId ?? '').toString();
  return id.isEmpty ? null : supaRef('users', id);
}

/// The current signed-in Supabase user id ('' if none).
String supaCurrentUid() => supabase.auth.currentUser?.id ?? '';

/// Synthesize a `List<DocumentReference>` of length [count] so widgets that read
/// `record.likes.length` show the right count. If [likedByUid] is set, the real
/// user ref is included first so `.contains(currentUserReference)` reflects the
/// liked state. The write path (like/unlike) goes through PostRepository.
List<DocumentReference> likePlaceholders(int count, {String? likedByUid}) {
  final refs = <DocumentReference>[];
  if (likedByUid != null && likedByUid.isNotEmpty) {
    refs.add(supaRef('users', likedByUid));
  }
  var i = 0;
  while (refs.length < count) {
    refs.add(supaRef('users', '_like_${i++}'));
  }
  return refs;
}
