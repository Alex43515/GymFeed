/// Returns only rows that are owned by [userId].
///
/// Profile queries are already scoped in Supabase. This second, client-side
/// guard prevents a future query regression from ever rendering another
/// account's posts on a profile page.
List<Map<String, dynamic>> retainRowsOwnedBy(
  Iterable<Map<String, dynamic>> rows,
  String userId,
) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return const <Map<String, dynamic>>[];

  return rows
      .where((row) => (row['user_id'] ?? '').toString() == normalizedUserId)
      .toList(growable: false);
}

List<Map<String, dynamic>> retainProfilePostRows(
  Iterable<Map<String, dynamic>> rows,
  String userId,
) =>
    retainRowsOwnedBy(rows, userId);
