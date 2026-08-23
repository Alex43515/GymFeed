import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/backend/supabase/repositories/training_repository.dart';

Future<void> showGymFeedEventDetails(
  BuildContext context,
  Training training, {
  bool? initiallyJoined,
  ValueChanged<bool>? onJoinedChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EventDetailsSheet(
      training: training,
      initiallyJoined: initiallyJoined ?? training.joinedByMe,
      onJoinedChanged: onJoinedChanged,
    ),
  );
}

class _EventDetailsSheet extends StatefulWidget {
  const _EventDetailsSheet({
    required this.training,
    required this.initiallyJoined,
    this.onJoinedChanged,
  });
  final Training training;
  final bool initiallyJoined;
  final ValueChanged<bool>? onJoinedChanged;

  @override
  State<_EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<_EventDetailsSheet> {
  static const _green = Color(0xFF0EEA78);
  late bool _joined;
  bool _working = false;
  late Future<List<Map<String, dynamic>>> _participants;

  @override
  void initState() {
    super.initState();
    _joined = widget.initiallyJoined;
    _participants = TrainingRepository().participants(widget.training.id);
  }

  Future<void> _toggle() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      if (_joined) {
        await TrainingRepository().leave(widget.training.id);
      } else {
        await TrainingRepository().join(widget.training.id);
      }
      if (!mounted) return;
      setState(() {
        _joined = !_joined;
        _participants = TrainingRepository().participants(widget.training.id);
      });
      widget.onJoinedChanged?.call(_joined);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _maps() async {
    final lat = widget.training.locationLat;
    final lng = widget.training.locationLng;
    if (lat == null || lng == null) return;
    await launchUrl(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$lat,$lng',
      }),
      mode: LaunchMode.externalApplication,
    );
  }

  String _schedule() {
    final date = widget.training.startsAt?.toLocal();
    if (date != null) {
      String two(int value) => value.toString().padLeft(2, '0');
      return '${two(date.day)}/${two(date.month)}/${date.year} · ${two(date.hour)}:${two(date.minute)}';
    }
    return '${widget.training.trainingDateRaw} ${widget.training.trainingTimeRaw}'
        .trim();
  }

  TextStyle _style(double size,
          {Color color = Colors.white, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
          fontFamily: 'Poppins',
          fontSize: size,
          color: color,
          fontWeight: weight);

  @override
  Widget build(BuildContext context) {
    final training = widget.training;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .93),
      decoration: const BoxDecoration(
        color: Color(0xFF101010),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Align(
            child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF555555),
                    borderRadius: BorderRadius.circular(99))),
          ),
          const SizedBox(height: 18),
          if (training.coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(training.coverUrl,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: Text(
                    training.category.isEmpty
                        ? 'Workout event'
                        : training.category,
                    style: _style(12, color: _green, weight: FontWeight.w700))),
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
          Text(training.title.isEmpty ? 'GymFeed workout' : training.title,
              style: _style(26, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          _line(Icons.calendar_month_rounded,
              _schedule().isEmpty ? 'Schedule not set' : _schedule()),
          _line(
              Icons.speed_rounded,
              training.difficultyLevel.isEmpty
                  ? 'All levels'
                  : training.difficultyLevel),
          _line(
              Icons.timer_outlined,
              training.duration > 0
                  ? '${training.duration} minutes'
                  : 'Flexible duration'),
          if (training.locationLat != null && training.locationLng != null)
            InkWell(
              key: const Key('event-google-maps-link'),
              onTap: _maps,
              child: _line(
                  Icons.location_on_outlined, 'Open location in Google Maps',
                  color: _green, trailing: Icons.open_in_new_rounded),
            ),
          const SizedBox(height: 18),
          Text('Created by', style: _style(12, color: const Color(0xFF858585))),
          const SizedBox(height: 8),
          Row(children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFF173A25),
              backgroundImage: training.authorPhotoUrl.isEmpty
                  ? null
                  : NetworkImage(training.authorPhotoUrl),
              child: training.authorPhotoUrl.isEmpty
                  ? const Icon(Icons.person_rounded, color: _green)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      training.authorDisplayName.isEmpty
                          ? 'GymFeed member'
                          : training.authorDisplayName,
                      style: _style(14, weight: FontWeight.w700)),
                  if (training.authorUsername.isNotEmpty)
                    Text('@${training.authorUsername}',
                        style: _style(11, color: _green)),
                ])),
          ]),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _participants,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <Map<String, dynamic>>[];
              return Container(
                key: const Key('event-participants-section'),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF292929))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${rows.length} ${rows.length == 1 ? 'person' : 'people'} joined',
                          style: _style(14, weight: FontWeight.w700)),
                      if (rows.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final row in rows) _participant(row),
                        ]),
                      ],
                    ]),
              );
            },
          ),
          if (training.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 18),
            Text('About', style: _style(15, weight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(training.description!,
                style: _style(13, color: const Color(0xFFC4C4C4))),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('event-details-join-button'),
            onPressed: _working ? null : _toggle,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(55),
              backgroundColor: _joined ? const Color(0xFF292929) : _green,
              foregroundColor: _joined ? Colors.white : const Color(0xFF07150D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27)),
            ),
            child: _working
                ? const CircularProgressIndicator(strokeWidth: 2, color: _green)
                : Text(_joined ? 'Leave event' : 'Join event',
                    style: _style(14,
                        color: _joined ? Colors.white : const Color(0xFF07150D),
                        weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _participant(Map<String, dynamic> row) {
    final profile = row['profile'] is Map
        ? Map<String, dynamic>.from(row['profile'] as Map)
        : const <String, dynamic>{};
    final username = (profile['username'] ?? 'Member').toString();
    final photo = (profile['photo_url'] ?? '').toString();
    return Chip(
      avatar: CircleAvatar(
          backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
          backgroundColor: const Color(0xFF173A25),
          child: photo.isEmpty
              ? const Icon(Icons.person, size: 14, color: _green)
              : null),
      label: Text('@$username', style: _style(11)),
      backgroundColor: const Color(0xFF222222),
      side: BorderSide.none,
    );
  }

  Widget _line(IconData icon, String value,
      {Color color = Colors.white, IconData? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF8B8B8B), size: 19),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: _style(13, color: color))),
        if (trailing != null) Icon(trailing, color: color, size: 17),
      ]),
    );
  }
}
