import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/supabase/database/profile.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UnblockListWidget extends StatefulWidget {
  const UnblockListWidget({super.key});

  static String routeName = 'unblockList';
  static String routePath = 'unblockList';

  @override
  State<UnblockListWidget> createState() => _UnblockListWidgetState();
}

class _UnblockListWidgetState extends State<UnblockListWidget> {
  late Future<List<Profile>> _future;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _future = ProfileRepository().blockedAccounts();
  }

  Future<void> _unblock(Profile profile) async {
    if (_busy.contains(profile.id)) return;
    setState(() => _busy.add(profile.id));
    try {
      await ProfileRepository().unblock(profile.id);
      if (!mounted) return;
      setState(() {
        _busy.remove(profile.id);
        _future = ProfileRepository().blockedAccounts();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy.remove(profile.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not unblock account: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080808),
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.safePop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          title: const Text('Blocked accounts',
              style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
        ),
        body: FutureBuilder<List<Profile>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF16E57A)),
              );
            }
            if (snapshot.hasError) {
              return _EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load blocked accounts',
                message: 'Check your connection and try again.',
                action: () => setState(
                    () => _future = ProfileRepository().blockedAccounts()),
              );
            }
            final accounts = snapshot.data ?? const <Profile>[];
            if (accounts.isEmpty) {
              return const _EmptyState(
                icon: Icons.shield_outlined,
                title: 'No blocked accounts',
                message: 'Accounts you block will appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final profile = accounts[index];
                final busy = _busy.contains(profile.id);
                return Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    border: Border.all(color: const Color(0xFF292929)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: profile.photoUrl.isEmpty
                            ? _avatarFallback()
                            : CachedNetworkImage(
                                imageUrl: profile.photoUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _avatarFallback(),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName
                                  : profile.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                            if (profile.username.isNotEmpty)
                              Text('@${profile.username}',
                                  style: const TextStyle(
                                      color: Color(0xFF8B8B8B), fontSize: 12)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => _unblock(profile),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF3B3B3B)),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(busy ? 'Wait…' : 'Unblock'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );

  Widget _avatarFallback() => Container(
        width: 50,
        height: 50,
        color: const Color(0xFF103824),
        child: const Icon(Icons.person, color: Color(0xFF16E57A)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF16E57A), size: 58),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8B8B8B))),
              if (action != null) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: action,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16E57A),
                      foregroundColor: Colors.black),
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      );
}
