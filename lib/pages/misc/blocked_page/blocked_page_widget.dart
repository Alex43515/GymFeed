import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';

/// Compatibility route for legacy links. New profile routes use the richer
/// BlockedAccountView after resolving which side of the block relationship the
/// current user is on.
class BlockedPageWidget extends StatelessWidget {
  const BlockedPageWidget({super.key});

  static String routeName = 'blockedPage';
  static String routePath = 'blockedPage';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          backgroundColor: const Color(0xFF080808),
          leading: IconButton(
            onPressed: () => context.safePop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                      color: Color(0xFF171717), shape: BoxShape.circle),
                  child: const Icon(Icons.person_off_outlined,
                      color: Color(0xFF16E57A), size: 44),
                ),
                const SizedBox(height: 24),
                const Text('Content unavailable',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text(
                  "You can't view or interact with this account's content.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9B9B9B), height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.safePop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16E57A),
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Go back',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
