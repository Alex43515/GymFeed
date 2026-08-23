import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TagUsersWidget extends StatelessWidget {
  const TagUsersWidget({super.key});

  static String routeName = 'TagUsers';
  static String routePath = 'tagUsers';
  static const _green = Color(0xFF0EEA78);

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final references = FFAppState().taggedUsers.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: Colors.white,
        title: const Text('Tag people',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Done',
                style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            const Text('People in this post',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Tagged people are linked to the post and receive a notification.',
              style: TextStyle(color: Color(0xFF8A8A8A), height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const Key('add-tagged-people'),
              onPressed: () =>
                  context.pushNamed(SelectTaggedUsersWidget.routeName),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                  references.isEmpty ? 'Add people' : 'Add or remove people'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: Color(0xFF315D43)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17)),
              ),
            ),
            const SizedBox(height: 16),
            if (references.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 42),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF252525)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        color: Color(0xFF6F6F6F), size: 34),
                    SizedBox(height: 8),
                    Text('No one tagged yet',
                        style: TextStyle(color: Color(0xFF8A8A8A))),
                  ],
                ),
              ),
            for (final reference in references)
              StreamBuilder<UsersRecord>(
                stream: UsersRecord.getDocument(reference),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: const Color(0xFF292929)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF173A25),
                          backgroundImage: user.photoUrl.isEmpty
                              ? null
                              : NetworkImage(user.photoUrl),
                          child: user.photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded, color: _green)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName.isEmpty
                                    ? '@${user.username}'
                                    : user.displayName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text('@${user.username}',
                                  style: const TextStyle(
                                      color: Color(0xFF898989), fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove tag',
                          onPressed: () => FFAppState().update(() {
                            FFAppState()
                                .taggedUsers
                                .removeWhere((item) => item.id == reference.id);
                          }),
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
