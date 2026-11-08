import 'package:flutter/widgets.dart';

/// Marks a widget the guided tour can point at.
///
/// Registered by id instead of a GlobalKey because some pages are mounted
/// twice at once (the Feed sits under nested routes). The newest one wins.
class TourAnchor extends StatefulWidget {
  const TourAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  static final Map<String, List<_TourAnchorState>> _mounted = {};

  /// The most recently built anchor with this id, if any is on screen.
  static BuildContext? find(String id) {
    final anchors = _mounted[id];
    if (anchors == null || anchors.isEmpty) return null;
    return anchors.last.context;
  }

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  void _register(String id) =>
      TourAnchor._mounted.putIfAbsent(id, () => []).add(this);

  void _unregister(String id) => TourAnchor._mounted[id]?.remove(this);

  @override
  void initState() {
    super.initState();
    _register(widget.id);
  }

  @override
  void didUpdateWidget(TourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _unregister(oldWidget.id);
      _register(widget.id);
    }
  }

  @override
  void dispose() {
    _unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
