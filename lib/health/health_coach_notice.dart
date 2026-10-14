import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'connected_health_controller.dart';
import 'connected_health_widget.dart';

/// Status only: opening Coach must never read health records or prompt access.
class HealthCoachNotice extends StatefulWidget {
  const HealthCoachNotice({super.key, required this.userId});
  final String userId;
  @override
  State<HealthCoachNotice> createState() => _HealthCoachNoticeState();
}

class _HealthCoachNoticeState extends State<HealthCoachNotice>
    with WidgetsBindingObserver {
  bool _sharing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void didUpdateWidget(HealthCoachNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _sharing = false;
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final uid = widget.userId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || uid != widget.userId) return;
      setState(() => _sharing =
          prefs.getBool(ConnectedHealthController.connectionKey(uid)) == true &&
              prefs.getBool(ConnectedHealthController.aiConsentKey(uid)) ==
                  true);
    } catch (_) {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF14231A),
      child: InkWell(
        onTap: () async {
          await context.pushNamed(ConnectedHealthWidget.routeName);
          if (mounted) await _refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.watch_outlined,
                color: Color(0xFF1FE276), size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    _sharing
                        ? 'Activity sharing on · Today’s readings checked per question'
                        : 'Activity sharing off · Connect health to personalize Coach',
                    style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 8),
            const Text('Manage',
                style: TextStyle(color: Color(0xFF1FE276), fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}
