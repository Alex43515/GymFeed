import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/signup_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'how_old_are_you_model.dart';
export 'how_old_are_you_model.dart';

class HowOldAreYouWidget extends StatefulWidget {
  const HowOldAreYouWidget({super.key});

  static String routeName = 'HowOldAreYou';
  static String routePath = 'howOldAreYou';

  @override
  State<HowOldAreYouWidget> createState() => _HowOldAreYouWidgetState();
}

class _HowOldAreYouWidgetState extends State<HowOldAreYouWidget> {
  late HowOldAreYouModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Selectable birth years (oldest .. this year).
  final List<int> _years =
      List<int>.generate(DateTime.now().year - 1930 + 1, (i) => 1930 + i);

  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;

  int _dayIndex = 0; // -> day 1
  int _monthIndex = 0; // -> January
  late int _yearIndex; // default 2000
  bool _picking =
      false; // false = calendar-icon view (014), true = wheels (015)
  bool _picked = false; // whether the user has opened the picker

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' //
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HowOldAreYouModel());

    _yearIndex = _years.indexOf(2000);
    if (_yearIndex < 0) _yearIndex = _years.length ~/ 2;
    _dayCtrl = FixedExtentScrollController(initialItem: _dayIndex);
    _monthCtrl = FixedExtentScrollController(initialItem: _monthIndex);
    _yearCtrl = FixedExtentScrollController(initialItem: _yearIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _model.dispose();
    super.dispose();
  }

  int get _selectedDay => _dayIndex + 1;
  int get _selectedMonth => _monthIndex + 1;
  int get _selectedYear => _years[_yearIndex];

  DateTime get _selectedDate {
    final maxDay = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final d = _selectedDay > maxDay ? maxDay : _selectedDay;
    return DateTime(_selectedYear, _selectedMonth, d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondary,
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(28.0, 24.0, 28.0, 28.0),
          child: Column(
            children: [
              const SizedBox(height: 40.0),
              Text(
                'How old are you?',
                textAlign: TextAlign.center,
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: theme.tertiary,
                  fontSize: 30.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Complete your details to continue',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.override(
                  fontFamily: 'Poppins',
                  color: theme.secondaryText,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                ),
              ),
              Expanded(
                child: _picking ? _buildWheels(theme) : _buildCalendar(theme),
              ),
              signupPageDots(context: context, active: 2),
              const SizedBox(height: 24.0),
              signupPrimaryButton(
                context: context,
                text: 'Next',
                enabled: _picked,
                onPressed: () async {
                  if (!_picked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please choose your date of birth.',
                          style: TextStyle(color: theme.secondary),
                        ),
                        backgroundColor: theme.primary,
                        duration: const Duration(milliseconds: 3000),
                      ),
                    );
                    return;
                  }
                  _model.datePicked = _selectedDate;
                  FFAppState().age2 = _selectedDate;
                  FFAppState().update(() {});
                  context.pushNamed(WeightWidget.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 014: green calendar badge + DD / MM / YYYY field ──────────────────────
  Widget _buildCalendar(FlutterFlowTheme theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150.0,
          height: 150.0,
          decoration:
              BoxDecoration(color: theme.primary, shape: BoxShape.circle),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: theme.secondary, size: 78.0),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                  child: Text(
                    _picked ? '$_selectedDay' : '26',
                    style: theme.titleLarge.override(
                      fontFamily: 'Poppins',
                      color: theme.secondary,
                      fontSize: 24.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40.0),
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => safeSetState(() {
            _picking = true;
            _picked = true;
          }),
          child: Container(
            width: double.infinity,
            height: 62.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Text(
              _picked
                  ? '${_two(_selectedDay)} / ${_two(_selectedMonth)} / $_selectedYear'
                  : 'DD / MM / YYYY',
              style: theme.bodyMedium.override(
                fontFamily: 'Poppins',
                color: _picked ? theme.secondary : theme.secondaryText,
                fontSize: 17.0,
                letterSpacing: 1.0,
                fontWeight: _picked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 015: three scroll wheels (day / month / year) ─────────────────────────
  Widget _buildWheels(FlutterFlowTheme theme) {
    return Center(
      child: SizedBox(
        height: 290.0,
        child: Row(
          children: [
            _wheel(
              controller: _dayCtrl,
              count: 31,
              selectedIndex: _dayIndex,
              label: (i) => '${i + 1}',
              onChanged: (i) => safeSetState(() => _dayIndex = i),
            ),
            _wheel(
              controller: _monthCtrl,
              count: 12,
              selectedIndex: _monthIndex,
              label: (i) => _months[i],
              onChanged: (i) => safeSetState(() => _monthIndex = i),
            ),
            _wheel(
              controller: _yearCtrl,
              count: _years.length,
              selectedIndex: _yearIndex,
              label: (i) => '${_years[i]}',
              onChanged: (i) => safeSetState(() => _yearIndex = i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selectedIndex,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 58.0,
        diameterRatio: 1.6,
        perspective: 0.004,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, i) {
            final selected = i == selectedIndex;
            return Center(
              child: Text(
                label(i),
                style: theme.displaySmall.override(
                  fontFamily: 'Poppins',
                  color: selected ? theme.tertiary : theme.accent1,
                  fontSize: selected ? 30.0 : 24.0,
                  letterSpacing: 0.0,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _two(int v) => v < 10 ? '0$v' : '$v';
}
