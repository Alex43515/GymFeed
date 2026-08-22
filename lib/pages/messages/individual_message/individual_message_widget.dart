import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/ai_workout/nutrition_diary/nutrition_diary_widget.dart';
import '/backend/supabase/repositories/chat_repository.dart';
import '/backend/supabase/repositories/meal_repository.dart';
import '/backend/supabase/repositories/post_repository.dart';
import '/backend/supabase/supabase.dart';
import '/backend/supabase/supabase_records.dart';
import '/custom_code/widgets/upload_progress_screen.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_video_player.dart';
import '/flutter_flow/upload_data.dart';
import '/workout/routines/workout_routine_flow.dart';
import '/workout/routines/workout_routine_models.dart';
import '/workout/routines/workout_routine_store.dart';
import '/pages/posts/post_details/post_details_widget.dart';
import '../message_media_pipeline.dart';
import '../messaging_shared.dart';

class IndividualMessageWidget extends StatefulWidget {
  const IndividualMessageWidget({
    super.key,
    this.chat,
  });

  final DocumentReference? chat;

  static String routeName = 'IndividualMessage';
  static String routePath = 'individualMessage';

  @override
  State<IndividualMessageWidget> createState() =>
      _IndividualMessageWidgetState();
}

class _IndividualMessageWidgetState extends State<IndividualMessageWidget> {
  final _repository = ChatRepository();
  final _messageController = TextEditingController();
  final _messageFocus = FocusNode();
  final _scrollController = ScrollController();
  Future<ChatMember?>? _otherFuture;
  Stream<List<ChatMessage>>? _messages;
  RealtimeChannel? _presenceChannel;
  Timer? _typingTimer;
  bool _otherOnline = false;
  bool _otherTyping = false;
  bool _showAttachments = false;
  bool _sending = false;
  bool _uploading = false;
  int _lastMessageCount = -1;

  String get _chatId => widget.chat?.id ?? '';
  String get _uid => supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    if (_chatId.isNotEmpty) {
      _otherFuture = _repository.otherMember(_chatId);
      _messages = _repository.watchMessages(_chatId);
      unawaited(_repository.markSeen(_chatId));
      WidgetsBinding.instance.addPostFrameCallback((_) => _connectRealtime());
    }
    _messageController.addListener(_onTyping);
  }

  void _connectRealtime() {
    if (_uid.isEmpty || _chatId.isEmpty || _presenceChannel != null) return;
    final channel = supabase.channel(
      'gymfeed-messaging',
      opts: RealtimeChannelConfig(key: _uid, enabled: true),
    );
    _presenceChannel = channel;
    channel
        .onPresenceSync((_) async {
          final other = await _otherFuture;
          if (!mounted || other == null) return;
          setState(() {
            _otherOnline = channel
                .presenceState()
                .any((state) => state.key == other.userId);
          });
        })
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (payload['chat_id']?.toString() != _chatId ||
                payload['user_id']?.toString() == _uid) {
              return;
            }
            if (!mounted) return;
            setState(() => _otherTyping = payload['is_typing'] == true);
          },
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(channel.track({
              'user_id': _uid,
              'online_at': DateTime.now().toUtc().toIso8601String(),
            }));
          }
        });
  }

  void _onTyping() {
    final channel = _presenceChannel;
    if (channel == null) return;
    unawaited(channel.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'chat_id': _chatId,
        'user_id': _uid,
        'is_typing': _messageController.text.trim().isNotEmpty,
      },
    ));
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1400), () {
      unawaited(channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'chat_id': _chatId,
          'user_id': _uid,
          'is_typing': false,
        },
      ));
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _messageController.clear();
    try {
      await _repository.sendMessage(_chatId, text);
      await _repository.markSeen(_chatId);
      _broadcastStoppedTyping();
    } catch (error) {
      if (mounted) {
        _messageController.text = text;
        _showError('Message was not sent', error);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _broadcastStoppedTyping() {
    final channel = _presenceChannel;
    if (channel == null) return;
    unawaited(channel.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'chat_id': _chatId,
        'user_id': _uid,
        'is_typing': false,
      },
    ));
  }

  Future<void> _pickAndSendMedia({required bool video}) async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _showAttachments = false;
    });
    try {
      final selection = await selectMedia(
        storageFolderPath: 'messages/$_chatId',
        mediaSource:
            video ? MediaSource.videoGallery : MediaSource.photoGallery,
        isVideo: video,
        imageQuality: video ? null : 88,
      );
      if (selection == null || selection.isEmpty) return;
      final file = selection.first;
      String? imageUrl;
      String? videoUrl;
      if (video) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compressing video…'),
            duration: Duration(minutes: 2),
          ),
        );
        final compressed = await compressSelectedMessageVideo(file);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final upload = await showUploadProgress(
          context,
          videoBytes: compressed.bytes!,
          videoTitle: 'GymFeed message video',
          videoFileName: compressed.name ?? 'gymfeed-message.mp4',
        );
        videoUrl = upload?.videoPlaylistUrl;
        if (videoUrl == null || videoUrl.isEmpty) {
          throw StateError('The video upload did not return a playback URL.');
        }
      } else {
        final upload = await showUploadProgress(
          context,
          imageBytes: file.bytes,
          imageFileName: file.storagePath.split('/').last,
        );
        imageUrl = upload?.imageUrl;
        if (imageUrl == null || imageUrl.isEmpty) {
          throw StateError('The photo upload did not return an image URL.');
        }
      }
      await _repository.sendMessage(
        _chatId,
        '',
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );
    } catch (error) {
      if (mounted) _showError('Media was not sent', error);
    } finally {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _shareWorkout() async {
    setState(() => _showAttachments = false);
    final routines = await WorkoutRoutineStore.loadRoutines();
    if (!mounted) return;
    final routine = await showModalBottomSheet<WorkoutRoutine>(
      context: context,
      backgroundColor: messageSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _WorkoutPicker(routines: routines),
    );
    if (routine == null) return;
    try {
      await _repository.shareWorkout(_chatId, routine.toJson());
    } catch (error) {
      if (mounted) _showError('Workout was not shared', error);
    }
  }

  Future<void> _shareMeal() async {
    setState(() => _showAttachments = false);
    List<MealScan> meals;
    try {
      meals = await MealRepository().myScans(limit: 25);
    } catch (error) {
      if (mounted) _showError('Meals could not be loaded', error);
      return;
    }
    if (!mounted) return;
    if (meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan and log a meal before sharing it.')),
      );
      return;
    }
    final meal = await showModalBottomSheet<MealScan>(
      context: context,
      backgroundColor: messageSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _MealPicker(meals: meals),
    );
    if (meal == null) return;
    try {
      await _repository.shareMeal(_chatId, {
        'id': meal.id,
        'name': meal.foodName,
        'description': meal.description,
        'calories': meal.calories,
        'protein': meal.proteinG,
        'carbs': meal.carbsG,
        'fat': meal.fatG,
        'photo_url': meal.photoUrl,
        'meal_type': meal.mealType,
      });
    } catch (error) {
      if (mounted) _showError('Meal was not shared', error);
    }
  }

  void _showError(String message, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message: $error')),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('Messages');
    }
  }

  void _scrollToBottom(int count) {
    if (count == _lastMessageCount) return;
    _lastMessageCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _broadcastStoppedTyping();
    _typingTimer?.cancel();
    _messageController
      ..removeListener(_onTyping)
      ..dispose();
    _messageFocus.dispose();
    _scrollController.dispose();
    final channel = _presenceChannel;
    if (channel != null) unawaited(supabase.removeChannel(channel));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId.isEmpty) {
      return Scaffold(
        backgroundColor: messageBackground,
        body: SafeArea(
          child: Center(
            child: TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back, color: messageGreen),
              label: Text('This conversation is unavailable',
                  style: messageText(color: messageMuted)),
            ),
          ),
        ),
      );
    }
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: messageBackground,
        body: SafeArea(
          child: FutureBuilder<ChatMember?>(
            future: _otherFuture,
            builder: (context, otherSnapshot) {
              final other = otherSnapshot.data;
              return Column(
                children: [
                  _ChatHeader(
                    other: other,
                    online: _otherOnline,
                    typing: _otherTyping,
                    onBack: _goBack,
                  ),
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _messages,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const MessageLoading();
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Messages could not be loaded',
                                style: messageText(color: messageMuted)),
                          );
                        }
                        final all = snapshot.data ?? const <ChatMessage>[];
                        final reactions = <String, Set<String>>{};
                        DateTime? remoteSeenAt = other?.lastSeenAt;
                        for (final message
                            in all.where((item) => item.isReaction)) {
                          final target = message.reactionPayload['message_id']
                                  ?.toString() ??
                              '';
                          if (target.isNotEmpty) {
                            reactions.putIfAbsent(target, () => <String>{})
                              ..add(message.senderId);
                          }
                        }
                        for (final receipt in all.where((item) =>
                            item.isReadReceipt && item.senderId != _uid)) {
                          final time = receipt.createdAt;
                          if (time != null &&
                              (remoteSeenAt == null ||
                                  time.isAfter(remoteSeenAt))) {
                            remoteSeenAt = time;
                          }
                        }
                        final visible = all
                            .where((item) =>
                                !item.isReaction && !item.isReadReceipt)
                            .toList();
                        _scrollToBottom(visible.length);
                        if (visible.isNotEmpty) {
                          unawaited(_repository.markSeen(_chatId));
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 26),
                          itemCount: visible.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121212),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text('Today',
                                        style: messageText(
                                            size: 10, color: messageMuted)),
                                  ),
                                ),
                              );
                            }
                            final message = visible[index - 1];
                            final mine = message.senderId == _uid;
                            final isLastMine = mine &&
                                !visible
                                    .skip(index)
                                    .any((item) => item.senderId == _uid);
                            return _MessageBubble(
                              message: message,
                              mine: mine,
                              hearted:
                                  reactions[message.id]?.isNotEmpty == true,
                              heartedByMe:
                                  reactions[message.id]?.contains(_uid) == true,
                              showDelivery: isLastMine,
                              otherLastSeenAt: remoteSeenAt,
                              onReact: () async {
                                try {
                                  await _repository.toggleHeartReaction(
                                      _chatId, message.id);
                                } catch (error) {
                                  if (mounted) {
                                    _showError('Reaction was not saved', error);
                                  }
                                }
                              },
                              onOpenWorkout: _openWorkout,
                              onOpenMeal: _openMeal,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_showAttachments)
                    _AttachmentMenu(
                      onPhoto: () => _pickAndSendMedia(video: false),
                      onVideo: () => _pickAndSendMedia(video: true),
                      onWorkout: _shareWorkout,
                      onMeal: _shareMeal,
                    ),
                  _Composer(
                    controller: _messageController,
                    focusNode: _messageFocus,
                    sending: _sending || _uploading,
                    attachmentsOpen: _showAttachments,
                    onToggleAttachments: () =>
                        setState(() => _showAttachments = !_showAttachments),
                    onSend: _send,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openWorkout(Map<String, dynamic> payload) {
    final raw = payload['routine'];
    if (raw is! Map) return;
    final routine = WorkoutRoutine.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'shared-routine'),
        builder: (_) => RoutineDetailWidget(routine: routine),
      ),
    );
  }

  void _openMeal(Map<String, dynamic> _) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'nutrition-diary'),
        builder: (_) => const NutritionDiaryWidget(),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.other,
    required this.online,
    required this.typing,
    required this.onBack,
  });

  final ChatMember? other;
  final bool online;
  final bool typing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1B1B1B))),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
            MessageAvatar(
              displayName: other?.displayName ?? '',
              username: other?.username ?? '',
              photoUrl: other?.photoUrl ?? '',
              online: online,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other == null
                        ? 'Loading...'
                        : messageDisplayName(
                            other!.displayName, other!.username),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: messageText(size: 14, weight: FontWeight.w700),
                  ),
                  Text(
                    typing
                        ? 'typing...'
                        : online
                            ? 'Active now'
                            : other?.username.isNotEmpty == true
                                ? '@${other!.username}'
                                : 'Offline',
                    style: messageText(
                      size: 10,
                      color: typing || online ? messageGreen : messageMuted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.hearted,
    required this.heartedByMe,
    required this.showDelivery,
    required this.otherLastSeenAt,
    required this.onReact,
    required this.onOpenWorkout,
    required this.onOpenMeal,
  });

  final ChatMessage message;
  final bool mine;
  final bool hearted;
  final bool heartedByMe;
  final bool showDelivery;
  final DateTime? otherLastSeenAt;
  final VoidCallback onReact;
  final ValueChanged<Map<String, dynamic>> onOpenWorkout;
  final ValueChanged<Map<String, dynamic>> onOpenMeal;

  @override
  Widget build(BuildContext context) {
    final seen = otherLastSeenAt != null &&
        message.createdAt != null &&
        !otherLastSeenAt!.isBefore(message.createdAt!);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: onReact,
              onDoubleTap: onReact,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .78),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: mine ? messageGreen : messageSurface,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomLeft: Radius.circular(mine ? 18 : 5),
                        bottomRight: Radius.circular(mine ? 5 : 18),
                      ),
                      border: mine
                          ? null
                          : Border.all(color: messageBorder, width: .8),
                    ),
                    child: _BubbleContent(
                      message: message,
                      mine: mine,
                      onOpenWorkout: onOpenWorkout,
                      onOpenMeal: onOpenMeal,
                    ),
                  ),
                  if (hearted)
                    Positioned(
                      left: mine ? null : 7,
                      right: mine ? 7 : null,
                      bottom: -10,
                      child: Container(
                        width: 28,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: messageBorder),
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: heartedByMe
                              ? const Color(0xFFFF3D75)
                              : const Color(0xFFFF7199),
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showDelivery) ...[
              const SizedBox(height: 4),
              Text(
                  '${seen ? 'Seen' : 'Delivered'} · ${chatClock(message.createdAt)}',
                  style: messageText(size: 9, color: messageMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.mine,
    required this.onOpenWorkout,
    required this.onOpenMeal,
  });

  final ChatMessage message;
  final bool mine;
  final ValueChanged<Map<String, dynamic>> onOpenWorkout;
  final ValueChanged<Map<String, dynamic>> onOpenMeal;

  @override
  Widget build(BuildContext context) {
    if (message.isShare) {
      final payload = message.sharePayload;
      final workout = payload['type']?.toString() == 'workout';
      return _ShareCard(
        payload: payload,
        workout: workout,
        onOpen: () => workout ? onOpenWorkout(payload) : onOpenMeal(payload),
      );
    }
    if (message.postId.isNotEmpty) {
      return _PostShareCard(postId: message.postId);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl.isNotEmpty)
          CachedNetworkImage(
            key: ValueKey('message-image-${message.id}'),
            imageUrl: message.imageUrl,
            width: 270,
            height: 230,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              width: 270,
              height: 230,
              child: MessageLoading(),
            ),
            errorWidget: (_, __, ___) => const SizedBox(
              width: 270,
              height: 120,
              child: Icon(Icons.broken_image_outlined, color: messageMuted),
            ),
          ),
        if (message.videoUrl.isNotEmpty)
          SizedBox(
            key: ValueKey('message-video-${message.id}'),
            width: 280,
            child: FlutterFlowVideoPlayer(
              path: message.videoUrl,
              width: 280,
              aspectRatio: 16 / 9,
              autoPlay: false,
              looping: false,
              showControls: true,
              allowFullScreen: true,
              allowPlaybackSpeedMenu: false,
            ),
          ),
        if (message.body.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            child: Text(
              message.body,
              style: messageText(
                size: 13.5,
                color: mine ? const Color(0xFF032313) : Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _PostShareCard extends StatelessWidget {
  const _PostShareCard({required this.postId});

  final String postId;

  void _open(BuildContext context) {
    context.pushNamed(
      PostDetailsWidget.routeName,
      queryParameters: {
        'post': serializeParam(
          supaRef('posts', postId),
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
        future: PostRepository().getById(postId),
        builder: (context, snapshot) {
          final post = snapshot.data ?? const <String, dynamic>{};
          final food = post['food_post'] == true;
          final title = (food ? post['food_title'] : post['caption'])
                  ?.toString()
                  .trim() ??
              '';
          final thumbnail = [
            (post['video_thumbnail'] ?? '').toString(),
            (post['legacy_photo_url'] ?? '').toString(),
          ].firstWhere((value) => value.isNotEmpty, orElse: () => '');
          return SizedBox(
            width: 248,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (thumbnail.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: thumbnail,
                    width: 248,
                    height: 132,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      width: 248,
                      height: 132,
                      child: MessageLoading(),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: food
                              ? const Color(0xFF123047)
                              : const Color(0xFF0D3D25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          food ? Icons.restaurant_rounded : Icons.image_rounded,
                          color: food ? const Color(0xFF55A9FF) : messageGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food ? 'SHARED FOOD POST' : 'SHARED POST',
                              style: messageText(
                                size: 9,
                                color: messageGreen,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              title.isEmpty ? 'GymFeed post' : title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: messageText(
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: messageBorder),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _open(context),
                    child: Text(
                      'View post',
                      style: messageText(
                        size: 12,
                        color: messageGreen,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.payload,
    required this.workout,
    required this.onOpen,
  });

  final Map<String, dynamic> payload;
  final bool workout;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final data = payload[workout ? 'routine' : 'meal'];
    final details = data is Map
        ? data.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    final title = (payload['title'] ??
            details['name'] ??
            (workout ? 'Shared workout' : 'Shared meal'))
        .toString();
    final exerciseCount = details['exercises'] is List
        ? (details['exercises'] as List).length
        : 0;
    final calories = (details['calories'] as num?)?.round() ?? 0;
    return SizedBox(
      width: 248,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: workout
                        ? const Color(0xFF0D3D25)
                        : const Color(0xFF11324A),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    workout ? Icons.fitness_center : Icons.restaurant,
                    color: workout ? messageGreen : const Color(0xFF57A6FF),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout ? 'SHARED WORKOUT' : 'SHARED MEAL',
                          style: messageText(
                              size: 9,
                              color: messageGreen,
                              weight: FontWeight.w600)),
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              messageText(size: 13, weight: FontWeight.w700)),
                      Text(
                        workout
                            ? '$exerciseCount exercises · workout routine'
                            : '$calories kcal · ${details['meal_type'] ?? 'Meal'}',
                        style: messageText(size: 10, color: messageMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: messageBorder),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onOpen,
              child: Text(workout ? 'View routine' : 'View diary',
                  style: messageText(
                      size: 12, color: messageGreen, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentMenu extends StatelessWidget {
  const _AttachmentMenu({
    required this.onPhoto,
    required this.onVideo,
    required this.onWorkout,
    required this.onMeal,
  });

  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onWorkout;
  final VoidCallback onMeal;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 244,
          margin: const EdgeInsets.fromLTRB(16, 0, 0, 9),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: messageSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: messageBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AttachmentTile(
                  key: const ValueKey('message-share-photo'),
                  icon: Icons.photo_camera_outlined,
                  color: const Color(0xFF4B9DFF),
                  label: 'Share a photo',
                  onTap: onPhoto),
              _AttachmentTile(
                  key: const ValueKey('message-share-video'),
                  icon: Icons.videocam_outlined,
                  color: const Color(0xFF8D7CFF),
                  label: 'Share a video',
                  onTap: onVideo),
              _AttachmentTile(
                  icon: Icons.fitness_center,
                  color: messageGreen,
                  label: 'Share a workout',
                  onTap: onWorkout),
              _AttachmentTile(
                  icon: Icons.restaurant_outlined,
                  color: const Color(0xFF4B9DFF),
                  label: 'Share a meal',
                  onTap: onMeal),
            ],
          ),
        ),
      );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        title:
            Text(label, style: messageText(size: 12, weight: FontWeight.w700)),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.attachmentsOpen,
    required this.onToggleAttachments,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool attachmentsOpen;
  final VoidCallback onToggleAttachments;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Material(
              color: messageSurface,
              shape: const CircleBorder(side: BorderSide(color: messageBorder)),
              child: IconButton(
                tooltip: 'Attachments',
                onPressed: sending ? null : onToggleAttachments,
                icon: Icon(
                  attachmentsOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: messageGreen,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                cursorColor: messageGreen,
                style: messageText(size: 13),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: messageText(color: const Color(0xFF5E6269)),
                  isDense: true,
                  filled: true,
                  fillColor: messageSurface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
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
            const SizedBox(width: 9),
            Material(
              color: messageGreen,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Send',
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF042313),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Color(0xFF042313), size: 19),
              ),
            ),
          ],
        ),
      );
}

class _WorkoutPicker extends StatelessWidget {
  const _WorkoutPicker({required this.routines});
  final List<WorkoutRoutine> routines;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Text('Share a workout',
                    style: messageText(size: 18, weight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  itemCount: routines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final routine = routines[index];
                    return ListTile(
                      onTap: () => Navigator.pop(context, routine),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: messageBorder),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      leading:
                          const Icon(Icons.fitness_center, color: messageGreen),
                      title: Text(routine.name,
                          style: messageText(weight: FontWeight.w700)),
                      subtitle: Text(
                          '${routine.exercises.length} exercises · ~${routine.estimatedMinutes} min',
                          style: messageText(size: 10, color: messageMuted)),
                      trailing:
                          const Icon(Icons.send_rounded, color: messageGreen),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _MealPicker extends StatelessWidget {
  const _MealPicker({required this.meals});
  final List<MealScan> meals;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Text('Share a meal',
                    style: messageText(size: 18, weight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  itemCount: meals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final meal = meals[index];
                    return ListTile(
                      onTap: () => Navigator.pop(context, meal),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: messageBorder),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      leading: meal.photoUrl == null
                          ? const Icon(Icons.restaurant, color: messageGreen)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: CachedNetworkImage(
                                imageUrl: meal.photoUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                      title: Text(
                          meal.foodName.isEmpty ? 'Logged meal' : meal.foodName,
                          style: messageText(weight: FontWeight.w700)),
                      subtitle: Text(
                          '${meal.calories.round()} kcal · ${meal.mealType}',
                          style: messageText(size: 10, color: messageMuted)),
                      trailing:
                          const Icon(Icons.send_rounded, color: messageGreen),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 42,
          height: 4,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4A4A4A),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
}
