import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectTaggedUsersWidget extends StatefulWidget {
  const SelectTaggedUsersWidget({super.key});

  static String routeName = 'SelectTaggedUsers';
  static String routePath = 'selectTaggedUsers';

  @override
  State<SelectTaggedUsersWidget> createState() =>
      _SelectTaggedUsersWidgetState();
}

class _SelectTaggedUsersWidgetState extends State<SelectTaggedUsersWidget> {
  static const _green = Color(0xFF0EEA78);
  late final Future<List<UsersRecord>> _usersFuture;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = queryUsersRecordOnce(limit: 500);
    _search.addListener(() {
      final value = _search.text.trim().toLowerCase();
      if (value != _query && mounted) setState(() => _query = value);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _selected(UsersRecord user) => FFAppState()
      .taggedUsers
      .any((reference) => reference.id == user.reference.id);

  void _toggle(UsersRecord user) {
    final state = FFAppState();
    state.update(() {
      if (_selected(user)) {
        state.taggedUsers.removeWhere(
          (reference) => reference.id == user.reference.id,
        );
      } else {
        state.addToTaggedUsers(user.reference);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        title: const Text('Tag people',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          TextButton(
            key: const Key('tag-users-done'),
            onPressed: () => context.pop(),
            child: Text(
              FFAppState().taggedUsers.isEmpty
                  ? 'Done'
                  : 'Done (${FFAppState().taggedUsers.length})',
              style:
                  const TextStyle(color: _green, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                key: const Key('tag-users-search'),
                controller: _search,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or username',
                  hintStyle: const TextStyle(color: Color(0xFF777777)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF8A8A8A)),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF8A8A8A)),
                        ),
                  filled: true,
                  fillColor: const Color(0xFF151515),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFF292929)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _green),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UsersRecord>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _green));
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('People could not be loaded.',
                          style: TextStyle(color: Color(0xFF999999))),
                    );
                  }
                  final users = (snapshot.data ?? const <UsersRecord>[])
                      .where((user) => user.uid != currentUserUid)
                      .where((user) {
                    if (_query.isEmpty) return true;
                    return user.displayName.toLowerCase().contains(_query) ||
                        user.username.toLowerCase().contains(_query);
                  }).toList()
                    ..sort((a, b) {
                      final selectedOrder =
                          (_selected(b) ? 1 : 0) - (_selected(a) ? 1 : 0);
                      if (selectedOrder != 0) return selectedOrder;
                      return a.displayName.compareTo(b.displayName);
                    });
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('No people found.',
                          style: TextStyle(color: Color(0xFF888888))),
                    );
                  }
                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 30),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFF202020)),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = _selected(user);
                      return ListTile(
                        key: Key('tag-user-${user.uid}'),
                        onTap: () => _toggle(user),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 5),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFF173A25),
                          backgroundImage: user.photoUrl.isEmpty
                              ? null
                              : NetworkImage(user.photoUrl),
                          child: user.photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded, color: _green)
                              : null,
                        ),
                        title: Text(
                          user.displayName.isEmpty
                              ? '@${user.username}'
                              : user.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('@${user.username}',
                            style: const TextStyle(
                                color: Color(0xFF8A8A8A), fontSize: 13)),
                        trailing: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? _green : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected ? _green : const Color(0xFF555555),
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Color(0xFF07150D), size: 18)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
