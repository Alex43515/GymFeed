import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/profile_repository.dart';

class BlockedWidget extends StatefulWidget {
  const BlockedWidget({super.key, this.userDetails});

  final UsersRecord? userDetails;

  @override
  State<BlockedWidget> createState() => _BlockedWidgetState();
}

class _BlockedWidgetState extends State<BlockedWidget> {
  bool _blocking = false;

  Future<void> _block() async {
    if (_blocking) return;
    final targetId = widget.userDetails?.reference.id ?? '';
    if (targetId.isEmpty) return;
    setState(() => _blocking = true);
    try {
      await ProfileRepository().block(targetId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _blocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block this account: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userDetails;
    final username = user?.username.trim() ?? '';
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF292929))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: const Color(0xFF454545),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                  color: Color(0xFF33171B), shape: BoxShape.circle),
              child:
                  const Icon(Icons.block, color: Color(0xFFFF5A62), size: 35),
            ),
            const SizedBox(height: 18),
            Text(
              'Block ${username.isEmpty ? 'this account' : '@$username'}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              "You won't see each other's profiles, posts, food posts, stories, workouts or activity. Following is removed in both directions and your direct conversation is hidden.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9B9B9B), height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              "They won't be notified that you blocked them.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF707070), fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _blocking ? null : _block,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B49),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: _blocking
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Block account',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: _blocking ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
