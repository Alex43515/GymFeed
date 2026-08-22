import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/supabase/repositories/profile_repository.dart';

class BlockedAccountView extends StatefulWidget {
  const BlockedAccountView({
    super.key,
    required this.relationship,
    required this.onBack,
    this.account,
    this.onUnblocked,
  });

  final AccountBlockRelationship relationship;
  final UsersRecord? account;
  final VoidCallback onBack;
  final VoidCallback? onUnblocked;

  @override
  State<BlockedAccountView> createState() => _BlockedAccountViewState();
}

class _BlockedAccountViewState extends State<BlockedAccountView> {
  bool _busy = false;

  Future<void> _unblock() async {
    final id = widget.account?.reference.id ?? '';
    if (_busy || id.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ProfileRepository().unblock(id);
      if (mounted) widget.onUnblocked?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not unblock this account: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedByMe =
        widget.relationship == AccountBlockRelationship.blockedByMe;
    final username = widget.account?.username.trim() ?? '';
    final photo = widget.account?.photoUrl.trim() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(blockedByMe && username.isNotEmpty ? '@$username' : ''),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (blockedByMe && photo.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photo,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _blockedIcon(),
                  ),
                )
              else
                _blockedIcon(),
              const SizedBox(height: 24),
              Text(
                blockedByMe
                    ? 'You blocked this account'
                    : 'Profile unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                blockedByMe
                    ? "Their profile and activity are hidden. Unblock them to view their content or interact again. Following and old direct-chat membership are not restored automatically."
                    : "You can't view this profile or interact with this account.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9B9B9B), height: 1.5),
              ),
              const SizedBox(height: 32),
              if (blockedByMe)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _unblock,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16E57A),
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(_busy ? 'Unblocking…' : 'Unblock account',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF343434)),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Go back',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockedIcon() => Container(
        width: 92,
        height: 92,
        decoration: const BoxDecoration(
            color: Color(0xFF171717), shape: BoxShape.circle),
        child: const Icon(Icons.person_off_outlined,
            color: Color(0xFF16E57A), size: 44),
      );
}
