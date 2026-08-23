import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/workout/schedule_training/workout_location_picker.dart';

class LocationWidget extends StatefulWidget {
  const LocationWidget({super.key});
  static const String routeName = 'Location';
  static const String routePath = 'location';
  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  static const _green = Color(0xFF0EEA78);
  bool _opening = false;

  Future<void> _pick() async {
    if (_opening) return;
    setState(() => _opening = true);
    final place = await showGymFeedLocationPicker(
      context,
      title: 'Post location',
      subtitle: 'Search for a restaurant, gym, city, or address.',
    );
    if (!mounted) return;
    setState(() => _opening = false);
    if (place == null) return;
    FFAppState().location = place.address;
    FFAppState().update(() {});
  }

  @override
  Widget build(BuildContext context) {
    final location = FFAppState().location.trim();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Location',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Done',
                style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add a location',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Help people find the place connected to this post.',
                  style: TextStyle(color: Color(0xFF929292), fontSize: 13)),
              const SizedBox(height: 22),
              InkWell(
                key: const Key('post-location-search-button'),
                onTap: _pick,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: _green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          location.isEmpty ? 'Search location' : location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: location.isEmpty
                                  ? const Color(0xFF888888)
                                  : Colors.white,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                      if (_opening)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _green),
                        )
                      else
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    FFAppState().location = '';
                    FFAppState().update(() {});
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Remove location'),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
