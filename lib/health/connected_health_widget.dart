import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connected_health_controller.dart';
import 'device_health_gateway.dart';

const _green = Color(0xFF1FE276);
const _surface = Color(0xFF151515);
const _muted = Color(0xFFAAAAAA);

class ConnectedHealthWidget extends StatefulWidget {
  const ConnectedHealthWidget(
      {super.key, required this.userId, this.controller});
  static const routeName = 'connectedHealth';
  static const routePath = '/connectedHealth';
  final String userId;
  final ConnectedHealthController? controller;
  @override
  State<ConnectedHealthWidget> createState() => _ConnectedHealthWidgetState();
}

class _ConnectedHealthWidgetState extends State<ConnectedHealthWidget>
    with WidgetsBindingObserver {
  ConnectedHealthController? _controller;
  bool _loadFailed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = widget.controller ??
          ConnectedHealthController(
              gateway: DeviceHealthGateway(),
              userId: widget.userId,
              preferences: await SharedPreferences.getInstance());
      if (!mounted) {
        if (widget.controller == null) controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loadFailed = false;
      });
      await controller.initialize();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller?.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) _controller?.dispose();
    super.dispose();
  }

  Future<void> _manage() async {
    try {
      final opened = await _controller!.gateway.openSettings();
      if (!opened && mounted) _showSettingsHelp();
    } catch (_) {
      if (mounted) _showSettingsHelp();
    }
  }

  void _showSettingsHelp() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_controller!.gateway.isIOS
            ? 'Open Apple Health → your profile → Apps → GymFeed to manage access.'
            : 'Open Health Connect → App permissions → GymFeed to manage access.')));
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: _surface,
              title: const Text('Disconnect health?',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                  'This stops sync and clears this screen. To revoke access completely, also turn off GymFeed permissions in your health app.',
                  style: TextStyle(color: _muted)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Disconnect',
                        style: TextStyle(color: _green)))
              ],
            ));
    if (confirmed == true) await _controller!.disconnect();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
            backgroundColor: const Color(0xFF080808),
            foregroundColor: Colors.white,
            title: const Text('Connected health',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20))),
        body: _loadFailed
            ? Center(
                child: TextButton(
                    onPressed: _load,
                    child: const Text('Could not open health. Try again')))
            : _controller == null
                ? const Center(child: CircularProgressIndicator(color: _green))
                : AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, _) => _body(_controller!)),
      );

  Widget _body(ConnectedHealthController c) {
    final supported = c.available == HealthAvailability.available;
    final connected = c.optedIn && supported;
    final summary = c.summary;
    final today = ConnectedHealthController.day(c.clock());
    final firstDay = DateTime(today.year, today.month, today.day - 6);
    return RefreshIndicator(
        onRefresh: c.refresh,
        color: _green,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _panel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    const Icon(Icons.watch_outlined,
                                        color: _green, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                            supported ||
                                                    c.available ==
                                                        HealthAvailability
                                                            .installRequired
                                                ? c.gateway.providerName
                                                : 'Your daily activity',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 23,
                                                fontWeight: FontWeight.w700)))
                                  ]),
                                  const SizedBox(height: 14),
                                  Text(
                                      connected
                                          ? (summary?.hasData == true
                                              ? 'Synced from your health app'
                                              : 'Access requested · waiting for data')
                                          : 'Bring your watch activity into GymFeed',
                                      style: const TextStyle(
                                          color: _green,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Text(
                                      connected
                                          ? 'Steps, active calories and your latest recorded heart rate. Refresh after your watch syncs with your phone.'
                                          : 'Your watch syncs with Apple Health on iPhone or Health Connect on Android. GymFeed reads your daily activity from there.',
                                      style: const TextStyle(
                                          color: _muted, height: 1.6)),
                                  if (c.busy) ...[
                                    const SizedBox(height: 16),
                                    const LinearProgressIndicator(
                                        color: _green,
                                        backgroundColor: Color(0xFF303030))
                                  ],
                                  const SizedBox(height: 18),
                                  if (!c.initialized && c.busy)
                                    const Text('Checking availability…',
                                        style: TextStyle(color: _muted))
                                  else if (c.available ==
                                      HealthAvailability.unsupported)
                                    const Text(
                                        'Available in the GymFeed iPhone and Android app. Android Health Connect requires Android 9 or newer and a supported phone.',
                                        style: TextStyle(
                                            color: _muted, height: 1.5))
                                  else if (c.available ==
                                      HealthAvailability.installRequired)
                                    _button(
                                        'Install or update Health Connect',
                                        Icons.download_rounded,
                                        c.busy
                                            ? null
                                            : () async {
                                                try {
                                                  await c.gateway.install();
                                                } catch (_) {
                                                  if (mounted)
                                                    _showSettingsHelp();
                                                }
                                              })
                                  else if (!connected ||
                                      c.state ==
                                          HealthConnectionState
                                              .permissionRequired)
                                    _button('Connect ${c.gateway.providerName}',
                                        Icons.link, c.busy ? null : c.connect)
                                  else
                                    _button('Sync now', Icons.sync_rounded,
                                        c.busy ? null : c.refresh),
                                  if (supported)
                                    TextButton(
                                        onPressed: c.busy ? null : _manage,
                                        child: const Text(
                                            'Manage health permissions',
                                            style: TextStyle(color: _green))),
                                  if (c.message != null)
                                    Text(c.message!,
                                        style: const TextStyle(
                                            color: _muted, height: 1.5)),
                                ])),
                            if (connected) ...[
                              const SizedBox(height: 22),
                              Row(children: [
                                IconButton(
                                    tooltip: 'Previous day',
                                    onPressed: c.busy ||
                                            !c.selectedDate.isAfter(firstDay)
                                        ? null
                                        : () => c.selectDate(DateTime(
                                            c.selectedDate.year,
                                            c.selectedDate.month,
                                            c.selectedDate.day - 1)),
                                    icon: const Icon(Icons.chevron_left),
                                    color: Colors.white,
                                    disabledColor: Colors.grey),
                                Expanded(
                                    child: Text(
                                        c.selectedDate == today
                                            ? 'Today'
                                            : DateFormat('EEE, d MMM')
                                                .format(c.selectedDate),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700))),
                                IconButton(
                                    tooltip: 'Next day',
                                    onPressed: c.busy ||
                                            !c.selectedDate.isBefore(today)
                                        ? null
                                        : () => c.selectDate(
                                            ConnectedHealthController.nextDay(
                                                c.selectedDate)),
                                    icon: const Icon(Icons.chevron_right),
                                    color: Colors.white,
                                    disabledColor: Colors.grey),
                              ]),
                              const SizedBox(height: 10),
                              _metric(
                                  Icons.directions_walk_rounded,
                                  'Steps',
                                  summary?.steps == null
                                      ? '—'
                                      : NumberFormat.decimalPattern()
                                          .format(summary!.steps),
                                  'steps'),
                              const SizedBox(height: 12),
                              _metric(
                                  Icons.local_fire_department_outlined,
                                  'Active calories',
                                  summary?.activeCalories?.round().toString() ??
                                      '—',
                                  'kcal'),
                              const SizedBox(height: 12),
                              _metric(
                                  Icons.favorite_border_rounded,
                                  'Latest heart rate',
                                  summary?.heartRate?.round().toString() ?? '—',
                                  'bpm',
                                  caption: summary?.heartRateAt == null
                                      ? 'No reading available'
                                      : 'Recorded ${DateFormat('HH:mm').format(summary!.heartRateAt!.toLocal())} · not live'),
                              const SizedBox(height: 14),
                              if (summary != null)
                                Text(
                                    'Last sync: ${DateFormat('d MMM, HH:mm').format(summary.syncedAt.toLocal())}',
                                    style: const TextStyle(
                                        color: _muted, fontSize: 12)),
                              if (summary?.hasData != true && !c.busy)
                                Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Text(
                                        'No readable records for this day. Check that your watch has synced, and allow the data types you want in ${c.gateway.providerName}.${c.gateway.isIOS ? ' Apple Health does not reveal whether reading was denied.' : ''}',
                                        style: const TextStyle(
                                            color: _muted, height: 1.5))),
                              if (summary?.sources.isNotEmpty == true)
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                        'Sources: ${summary!.sources.join(', ')}',
                                        style: const TextStyle(
                                            color: _muted, fontSize: 12))),
                            ],
                            const SizedBox(height: 22),
                            _panel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('How to connect your watch',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  const SizedBox(height: 10),
                                  Text(
                                      c.gateway.isIOS
                                          ? '1. Pair your Apple Watch with your iPhone.\n2. Let the watch sync its activity to Apple Health.\n3. Connect Apple Health above and choose which data GymFeed can read.'
                                          : '1. Pair your watch using its companion app.\n2. Enable that app’s sharing to Health Connect (for example, in Samsung Health).\n3. Connect Health Connect above and choose which data GymFeed can read.',
                                      style: const TextStyle(
                                          color: _muted, height: 1.8)),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Compatibility depends on your watch app sharing data to Apple Health or Health Connect. Pairing happens in your watch app.',
                                      style: TextStyle(
                                          color: _muted, height: 1.5)),
                                ])),
                            const SizedBox(height: 18),
                            const Row(children: [
                              Icon(Icons.lock_outline, color: _green, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text('Private · read-only · optional',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)))
                            ]),
                            const SizedBox(height: 8),
                            const Text(
                                'Health data stays on this phone. It is never uploaded to GymFeed, sent to AI, used for ads or shared on your profile. Only your connection preference is saved. Sync runs while this screen is open; you can disconnect anytime.',
                                style: TextStyle(
                                    color: _muted, height: 1.5, fontSize: 12)),
                            if (c.optedIn)
                              TextButton(
                                  onPressed: c.busy ? null : _disconnect,
                                  child: const Text('Disconnect health',
                                      style: TextStyle(color: Colors.white))),
                          ]))),
            ]));
  }

  Widget _button(String label, IconData icon, VoidCallback? action) => SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
          onPressed: action,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))));
  Widget _panel({required Widget child}) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF292929))),
      child: child);
  Widget _metric(IconData icon, String title, String value, String unit,
          {String? caption}) =>
      _panel(
          child: Row(children: [
        Icon(icon, color: _green, size: 30),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _muted)),
          const SizedBox(height: 7),
          Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
                Text(unit, style: const TextStyle(color: _muted))
              ]),
          if (caption != null)
            Text(caption, style: const TextStyle(color: _muted, fontSize: 12)),
        ]))
      ]));
}

class ConnectedHealthEntryCard extends StatelessWidget {
  const ConnectedHealthEntryCard({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const Icon(Icons.watch_outlined, color: _green, size: 30),
                const SizedBox(width: 16),
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Connected health',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Your watch · Steps · Daily activity',
                          style: TextStyle(color: _muted, fontSize: 12)),
                    ])),
                const Icon(Icons.chevron_right, color: _green)
              ]))));
}
