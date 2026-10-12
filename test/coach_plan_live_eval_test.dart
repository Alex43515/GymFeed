// Opt-in provider evaluation using synthetic context only. No diary/calendar
// writes occur. Set GYMFEED_EVAL_OPENAI_KEY in the environment and run:
// flutter test test/coach_plan_live_eval_test.dart --dart-define=RUN_LIVE_COACH_EVAL=true
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:gym_feed/backend/supabase/repositories/ai_coach_repository.dart';
import 'package:gym_feed/backend/supabase/repositories/coach_plan_actions.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_LIVE_COACH_EVAL');
  final key = Platform.environment['GYMFEED_EVAL_OPENAI_KEY'];
  final today = DateTime(2026, 10, 12);
  const context = AiCoachContext(
    profile: {
      'name': 'Evaluation athlete',
      'workout_level': 'beginner',
      'workouts_per_week': '3',
      'weight_kg': 75,
      'height_cm': 180,
      'workout_location': 'home',
      'primary_goal': 'general fitness',
      'daily_calorie_goal': 2200,
      'food_allergies_and_exclusions': 'Peanuts',
      'meals_per_day': '3'
    },
    starterPlan: {},
    currentRoutines: [],
    workoutSchedule: {},
    recentWorkouts: [],
    recentMeals: [],
    latestProgress: {},
  );

  Future<String?> call(List<Map<String, dynamic>> messages) async {
    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'model': 'gpt-5-mini',
            'messages': messages,
            'reasoning_effort': 'low',
            'max_completion_tokens': 16000,
            'response_format': {
              'type': 'json_schema',
              'json_schema': {
                'name': 'gymfeed_coach_plan',
                'strict': true,
                'schema': coachPlanResponseSchema
              }
            },
          }),
        )
        .timeout(const Duration(seconds: 120));
    if (response.statusCode != 200) {
      throw StateError(
          'Provider evaluation failed with HTTP ${response.statusCode}');
    }
    final root = jsonDecode(utf8.decode(response.bodyBytes));
    return root['choices'][0]['message']['content'] as String?;
  }

  final cases = <String, (String, String)>{
    'English': (
      'Add a two-set push-up workout tomorrow to Train and a rice-and-bean lunch the day after tomorrow to Meal Diary.',
      'Yes, I confirm, add them.'
    ),
    'Serbian Latin': (
      'Dodaj sutra trening sa dve serije sklekova u Train i prekosutra ručak od pirinča i pasulja u meal diary.',
      'Da, potvrđujem, odradi to.'
    ),
    'Serbian Cyrillic': (
      'Додај сутра тренинг са две серије склекова и прекосутра ручак од пиринча и пасуља у дневник исхране.',
      'Да, потврђујем, додај то.'
    ),
    'Spanish': (
      'Añade mañana un entrenamiento de flexiones de dos series y pasado mañana un almuerzo de arroz y frijoles al diario de comidas.',
      'Sí, confirmo, hazlo.'
    ),
    'French': (
      'Ajoute demain un entraînement de pompes de deux séries et après-demain un déjeuner de riz et haricots au journal alimentaire.',
      'Oui, je confirme, fais-le.'
    ),
    'German': (
      'Füge morgen ein Training mit zwei Sätzen Liegestützen und übermorgen ein Mittagessen mit Reis und Bohnen ins Ernährungstagebuch ein.',
      'Ja, ich bestätige, mach das.'
    ),
    'Portuguese': (
      'Adicione amanhã um treino de flexões com duas séries e depois de amanhã um almoço de arroz e feijão no diário alimentar.',
      'Sim, confirmo, pode fazer.'
    ),
    'Russian': (
      'Добавь на завтра тренировку из двух подходов отжиманий и на послезавтра обед из риса и фасоли в дневник питания.',
      'Да, подтверждаю, добавь.'
    ),
    'Arabic': (
      'أضف تمرين ضغط من مجموعتين غداً، وغداء من الأرز والفاصوليا بعد غد إلى يوميات الوجبات.',
      'نعم، أؤكد، نفذ ذلك.'
    ),
    'Hindi': (
      'कल के लिए दो सेट पुश-अप की कसरत जोड़ें और परसों के लिए चावल और बीन्स का दोपहर का भोजन मील डायरी में जोड़ें।',
      'हाँ, मैं पुष्टि करता हूँ, इसे जोड़ दें।'
    ),
    'Chinese': ('请添加明天的两组俯卧撑训练，并把后天的米饭和豆类午餐加入饮食日记。', '是的，我确认，请执行。'),
    'Japanese': (
      '明日に腕立て伏せ2セットのトレーニングを追加し、明後日にご飯と豆の昼食を食事日記に追加してください。',
      'はい、確認しました。実行してください。'
    ),
  };

  test(
      'live multilingual requests compile dated plans and confirmations execute intent',
      () async {
    expect(key, isNotNull,
        reason: 'An evaluation API key is required when explicitly enabled.');
    final onlyLanguage = Platform.environment['GYMFEED_EVAL_LANGUAGE'];
    final names = cases.keys
        .where((name) => onlyLanguage == null || name == onlyLanguage)
        .toList();
    final failures = <String>[];
    for (var offset = 0; offset < names.length; offset += 3) {
      await Future.wait(names.skip(offset).take(3).map((language) async {
        try {
          final engine = CoachPlanAssistant(aiCall: call);
          final request = cases[language]!.$1;
          final proposed = await engine.respond(
            systemPrompt: buildAiCoachSystemPrompt(context: context),
            history: [],
            question: request,
            now: today,
            foodAllergies: 'Peanuts',
          );
          expect(proposed.intent, 'propose',
              reason: '$language: ${proposed.text}');
          expect(
              proposed.proposal!.workouts.single.date, DateTime(2026, 10, 13),
              reason: language);
          expect(proposed.proposal!.meals.single.date, DateTime(2026, 10, 14),
              reason: language);
          final confirmation = await engine.respond(
            systemPrompt: buildAiCoachSystemPrompt(context: context),
            history: [
              {'role': 'user', 'content': request},
              {'role': 'assistant', 'content': proposed.text}
            ],
            question: cases[language]!.$2,
            now: today,
            latestAction: proposed.proposal,
          );
          expect(confirmation.intent, 'confirm', reason: language);
          expect(confirmation.proposal, isNull, reason: language);
          print('PASS $language: request dates + written confirmation');
        } catch (error) {
          failures.add('$language: $error');
          print('FAIL $language: $error');
        }
      }));
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  }, skip: !enabled, timeout: const Timeout(Duration(minutes: 15)));

  test('live negations, changes, repeat confirmation and seven-day batch',
      () async {
    final engine = CoachPlanAssistant(aiCall: call);
    final proposed = await engine.respond(
      systemPrompt: buildAiCoachSystemPrompt(context: context),
      history: [],
      question: cases['English']!.$1,
      now: today,
    );
    for (final request in [
      'Ne, nemoj da dodaš to.',
      'لا، لا تضف الخطة.',
      '不，我不确认，请不要添加。'
    ]) {
      final decision = await engine.respond(
        systemPrompt: buildAiCoachSystemPrompt(context: context),
        history: [],
        question: request,
        now: today,
        latestAction: proposed.proposal,
      );
      expect(decision.intent, 'cancel', reason: request);
    }
    final changed = await engine.respond(
      systemPrompt: buildAiCoachSystemPrompt(context: context),
      history: [],
      question: 'Move the workout to 2026-10-15, keeping the meal as it is.',
      now: today,
      latestAction: proposed.proposal,
    );
    expect(changed.intent, 'propose');
    expect(changed.proposal!.workouts.single.date, DateTime(2026, 10, 15));
    expect(changed.proposal!.meals.single.date, DateTime(2026, 10, 14));
    final repeated = await engine.respond(
      systemPrompt: buildAiCoachSystemPrompt(context: context),
      history: [],
      question: 'Potvrđujem ponovo, uradi to.',
      now: today,
      latestAction: proposed.proposal!.withStatus('implemented'),
    );
    expect(repeated.intent, isIn(['chat', 'confirm']));
    expect(repeated.proposal, isNull);
    final weekly = await engine.respond(
      systemPrompt: buildAiCoachSystemPrompt(context: context),
      history: [],
      question:
          'Dodaj plan za sedam dana od danas: ručak od pirinča i pasulja svakog dana, a trening od dve serije sklekova samo u utorak i petak.',
      now: today,
    );
    expect(weekly.intent, 'propose');
    expect(weekly.proposal!.meals, hasLength(7));
    expect(weekly.proposal!.workouts.map((item) => item.date),
        [DateTime(2026, 10, 13), DateTime(2026, 10, 16)]);
    print(
        'PASS negatives, date change, repeat confirmation and seven-day batch');
  }, skip: !enabled, timeout: const Timeout(Duration(minutes: 8)));

  test('live approval of a text-only plan applies without another confirmation',
      () async {
    final engine = CoachPlanAssistant(aiCall: call);
    final approved = await engine.respond(
      systemPrompt: buildAiCoachSystemPrompt(context: context),
      history: [
        {'role': 'user', 'content': 'Predloži mi trening i ručak.'},
        {
          'role': 'assistant',
          'content': 'Predlog: 2026-10-13, trening Push-up, '
              'dve serije po 8 ponavljanja sa sopstvenom težinom. Za 2026-10-14, '
              'Lunch: Rice bowl — skuvaj 80g pirinča i dodaj 150g pasulja i povrće; '
              '600 kcal, protein 25g, carbs 90g, fat 15g. Da li da dodam oba u plan?'
        },
      ],
      question: 'Da, potvrđujem. Dodaj oba.',
      now: today,
    );
    expect(approved.intent, 'apply', reason: approved.text);
    expect(approved.proposal!.workouts.single.date, DateTime(2026, 10, 13));
    expect(
        approved.proposal!.workouts.single.routine.exercises.single.setTargets
            .map((item) => item.reps),
        [8, 8]);
    expect(approved.proposal!.meals.single.date, DateTime(2026, 10, 14));
    print(
        'PASS approval of a text-only plan: exact payload compiled for immediate application');
  }, skip: !enabled, timeout: const Timeout(Duration(minutes: 3)));
}
