import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/chat_repository.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/backend/supabase/supabase_records.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/messages/individual_message/individual_message_widget.dart';
import '../messaging_shared.dart';

class NewMessageWidget extends StatefulWidget {
  const NewMessageWidget({super.key});

  static String routeName = 'NewMessage';
  static String routePath = 'newMessage';

  @override
  State<NewMessageWidget> createState() => _NewMessageWidgetState();
}

class _NewMessageWidgetState extends State<NewMessageWidget> {
  final _profiles = ProfileRepository();
  final _chats = ChatRepository();
  final _searchController = TextEditingController();
  late Future<List<Profile>> _people;
  Timer? _debounce;
  String? _openingUserId;

  @override
  void initState() {
    super.initState();
    _people = _profiles.suggested();
    _searchController.addListener(_scheduleSearch);
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchController.text.trim();
      if (!mounted) return;
      setState(() {
        _people =
            query.isEmpty ? _profiles.suggested() : _profiles.search(query);
      });
    });
  }

  Future<void> _open(Profile profile) async {
    if (_openingUserId != null) return;
    setState(() => _openingUserId = profile.id);
    try {
      final chatId = await _chats.getOrCreateDirectChat(profile.id);
      if (!mounted) return;
      context.goNamed(
        IndividualMessageWidget.routeName,
        queryParameters: {
          'chat': serializeParam(
            supaRef('chats', chatId),
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _openingUserId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start this chat: $error')),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_scheduleSearch)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final searching = _searchController.text.trim().isNotEmpty;
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: messageBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: () => context.safePop(),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 27),
                      ),
                    ),
                    Text('New message',
                        style: messageText(size: 16, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF1B1B1B)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  cursorColor: messageGreen,
                  style: messageText(),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 15, right: 8),
                      child: Center(
                        widthFactor: 1,
                        child: Text('To:',
                            style: messageText(size: 12, color: messageMuted)),
                      ),
                    ),
                    hintText: 'Search people',
                    hintStyle: messageText(color: const Color(0xFF5E6269)),
                    filled: true,
                    fillColor: messageSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: messageBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: messageGreen),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(searching ? 'Results' : 'Suggested',
                    style: messageText(size: 12, color: messageMuted)),
              ),
              Expanded(
                child: FutureBuilder<List<Profile>>(
                  future: _people,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const MessageLoading();
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _people = _searchController.text.trim().isEmpty
                                ? _profiles.suggested()
                                : _profiles.search(_searchController.text);
                          }),
                          icon: const Icon(Icons.refresh, color: messageGreen),
                          label: Text('Try again',
                              style: messageText(color: messageMuted)),
                        ),
                      );
                    }
                    final people = snapshot.data ?? const <Profile>[];
                    if (people.isEmpty) {
                      return Center(
                        child: Text(
                          searching
                              ? 'No people found'
                              : 'No suggested people yet',
                          style: messageText(color: messageMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                      itemCount: people.length,
                      itemBuilder: (_, index) {
                        final person = people[index];
                        final opening = _openingUserId == person.id;
                        return InkWell(
                          onTap: opening ? null : () => _open(person),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 11),
                            child: Row(
                              children: [
                                MessageAvatar(
                                  displayName: person.displayName,
                                  username: person.username,
                                  photoUrl: person.photoUrl,
                                  size: 46,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        messageDisplayName(person.displayName,
                                            person.username),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: messageText(
                                            size: 14, weight: FontWeight.w700),
                                      ),
                                      if (person.username.isNotEmpty)
                                        Text('@${person.username}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: messageText(
                                                size: 11, color: messageMuted)),
                                    ],
                                  ),
                                ),
                                if (opening)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: messageGreen,
                                    ),
                                  ),
                              ],
                            ),
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
      ),
    );
  }
}
