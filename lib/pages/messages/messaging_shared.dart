import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const messageBackground = Color(0xFF080808);
const messageSurface = Color(0xFF151515);
const messageBorder = Color(0xFF292929);
const messageGreen = Color(0xFF1FE276);
const messageMuted = Color(0xFF858585);

TextStyle messageText({
  double size = 14,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w400,
  double height = 1.25,
}) =>
    TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );

String messageDisplayName(String displayName, String username) {
  final name = displayName.trim();
  if (name.isNotEmpty) return name;
  final handle = username.trim();
  return handle.isNotEmpty ? handle : 'GymFeed member';
}

String conversationTime(DateTime? value, {DateTime? now}) {
  if (value == null) return '';
  final current = now ?? DateTime.now();
  final local = value.toLocal();
  final difference = current.difference(local);
  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inHours < 24 && current.day == local.day) {
    return '${difference.inHours}h';
  }
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (difference.inDays < 7) return weekdays[local.weekday - 1];
  return '${local.day}/${local.month}';
}

String chatClock(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class MessageAvatar extends StatelessWidget {
  const MessageAvatar({
    super.key,
    required this.displayName,
    required this.username,
    required this.photoUrl,
    this.size = 54,
    this.online = false,
  });

  final String displayName;
  final String username;
  final String photoUrl;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final label = messageDisplayName(displayName, username);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFF12C76A),
              shape: BoxShape.circle,
            ),
            child: photoUrl.trim().isEmpty
                ? Center(
                    child: Text(
                      label.substring(0, 1).toUpperCase(),
                      style: messageText(
                        size: size * .31,
                        color: const Color(0xFF042313),
                        weight: FontWeight.w700,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        label.substring(0, 1).toUpperCase(),
                        style: messageText(
                          size: size * .31,
                          color: const Color(0xFF042313),
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: 0,
              child: Container(
                width: size * .31,
                height: size * .31,
                decoration: BoxDecoration(
                  color: messageGreen,
                  borderRadius: BorderRadius.circular(size * .09),
                  border: Border.all(color: messageBackground, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MessageLoading extends StatelessWidget {
  const MessageLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: messageGreen,
          ),
        ),
      );
}
