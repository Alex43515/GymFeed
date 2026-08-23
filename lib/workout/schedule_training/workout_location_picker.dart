import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';

class WorkoutLocationSearchService {
  const WorkoutLocationSearchService();

  Future<List<FFPlace>> search(String query) async {
    final value = query.trim();
    if (value.length < 2) return const [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '7',
      'q': value,
    });
    final response = await http.get(uri, headers: const {
      'User-Agent': 'GymFeed/1.0 (official@gymfeed.io)',
      'Accept-Language': 'en',
    }).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Location search is temporarily unavailable.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((raw) {
          final row = Map<String, dynamic>.from(raw);
          final address = Map<String, dynamic>.from(
              (row['address'] as Map?) ?? const <String, dynamic>{});
          String first(List<String> keys) {
            for (final key in keys) {
              final value = address[key]?.toString().trim() ?? '';
              if (value.isNotEmpty) return value;
            }
            return '';
          }

          final display = (row['display_name'] ?? '').toString();
          final name = (row['name'] ?? '').toString().trim();
          return FFPlace(
            latLng: LatLng(
              double.tryParse(row['lat']?.toString() ?? '') ?? 0,
              double.tryParse(row['lon']?.toString() ?? '') ?? 0,
            ),
            name: name.isNotEmpty ? name : display.split(',').first.trim(),
            address: display,
            city: first(['city', 'town', 'village', 'municipality']),
            state: first(['state', 'region']),
            country: first(['country']),
            zipCode: first(['postcode']),
          );
        })
        .where((place) => place.address.isNotEmpty)
        .toList(growable: false);
  }
}

Future<FFPlace?> showWorkoutLocationPicker(BuildContext context) {
  return showGymFeedLocationPicker(
    context,
    title: 'Workout location',
    subtitle: 'Search for a gym, park, city, or address.',
  );
}

Future<FFPlace?> showGymFeedLocationPicker(
  BuildContext context, {
  String title = 'Add location',
  String subtitle = 'Search for a place, city, or address.',
}) {
  return showModalBottomSheet<FFPlace>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WorkoutLocationSheet(title: title, subtitle: subtitle),
  );
}

class _WorkoutLocationSheet extends StatefulWidget {
  const _WorkoutLocationSheet({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_WorkoutLocationSheet> createState() => _WorkoutLocationSheetState();
}

class _WorkoutLocationSheetState extends State<_WorkoutLocationSheet> {
  final _controller = TextEditingController();
  final _service = const WorkoutLocationSearchService();
  Timer? _debounce;
  List<FFPlace> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final results = await _service.search(value);
        if (!mounted || value != _controller.text) return;
        setState(() {
          _results = results;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Could not search locations. Check your connection.';
        });
      }
    });
  }

  TextStyle _style(double size,
          {Color color = Colors.white, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .82),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF555555),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(widget.title, style: _style(21, weight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(widget.subtitle,
              style: _style(12, color: const Color(0xFF929292))),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('workout-location-search'),
            controller: _controller,
            autofocus: true,
            onChanged: _changed,
            style: _style(14),
            decoration: InputDecoration(
              hintText: 'Search location',
              hintStyle: _style(13, color: const Color(0xFF777777)),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF1FE276)),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1FE276),
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF191919),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2B2B2B)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2B2B2B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1FE276)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _error != null
                ? Center(
                    child: Text(_error!,
                        style: _style(13, color: const Color(0xFFFF6B6B))))
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 34),
                          child: Text(
                            _controller.text.trim().length < 2
                                ? 'Type at least 2 characters.'
                                : _loading
                                    ? 'Searching…'
                                    : 'No matching location found.',
                            style: _style(13, color: const Color(0xFF858585)),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFF242424)),
                        itemBuilder: (context, index) {
                          final place = _results[index];
                          return ListTile(
                            key: ValueKey('workout-location-result-$index'),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 5),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF103620),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: Color(0xFF1FE276)),
                            ),
                            title: Text(place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _style(14, weight: FontWeight.w600)),
                            subtitle: Text(place.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    _style(11, color: const Color(0xFF8E8E8E))),
                            onTap: () => Navigator.pop(context, place),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
