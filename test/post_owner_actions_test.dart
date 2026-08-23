import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('post owner actions', () {
    test('options sheet writes permissions and deletes through Supabase', () {
      final source = File(
        'lib/components/personal_post_options/personal_post_options_widget.dart',
      ).readAsStringSync();

      expect(source, contains('PostRepository().updateInteractionPermissions'));
      expect(source, contains('PostRepository().deletePost'));
      expect(source, isNot(contains('widget.post!.reference.update')));
      expect(source, contains('Could not update this post'));
      expect(source, contains('Could not delete this post'));
    });

    test('repository verifies that owner-scoped writes changed a row', () {
      final source = File(
        'lib/backend/supabase/repositories/post_repository.dart',
      ).readAsStringSync();

      expect(source, contains('updateInteractionPermissions'));
      expect(source, contains("'allow_comments': allowComments"));
      expect(source, contains("'allow_likes': allowLikes"));
      expect(source, contains(".select('id')"));
      expect(
        source,
        contains('Post was not found or is not owned by this user.'),
      );
    });

    test('edit action closes the sheet before opening the post editor', () {
      final options = File(
        'lib/components/personal_post_options/personal_post_options_widget.dart',
      ).readAsStringSync();
      final regular = File(
        'lib/pages/posts/post/post_widget.dart',
      ).readAsStringSync();
      final food = File(
        'lib/pages/posts/post_food/post_food_widget.dart',
      ).readAsStringSync();

      expect(options, contains('editRequested: true'));
      expect(
          options,
          isNot(contains(
              'context.pushNamed(\n                                EditPostWidget.routeName')));
      expect(regular, contains('if (result.editRequested)'));
      expect(food, contains('if (result.editRequested)'));
      expect(regular, contains('EditPostWidget.routeName'));
      expect(food, contains('EditPostWidget.routeName'));
    });

    test('food editor updates all meal details through the owner-scoped repo',
        () {
      final editor = File(
        'lib/pages/posts/edit_post/edit_post_widget.dart',
      ).readAsStringSync();
      final repository = File(
        'lib/backend/supabase/repositories/post_repository.dart',
      ).readAsStringSync();

      for (final label in [
        'Meal name',
        'Recipe and preparation',
        'Nutrition facts',
        'Cooking time',
        'Calories',
        'Protein (g)',
        'Fat',
        'Carbs',
      ]) {
        expect(editor, contains(label));
      }
      for (final column in [
        'food_title',
        'food_description',
        'recipe',
        'nutrition_facts',
        'cooking_time',
        'meal_type',
        'calories',
        'protein',
        'fats',
        'carbs',
      ]) {
        expect(repository, contains("'$column'"));
      }
      expect(repository, contains(".eq('user_id', uid)"));
      expect(repository, contains(".select('id')"));
    });

    test('editor replaces media, edits CTA and tags, and can delete', () {
      final editor = File(
        'lib/pages/posts/edit_post/edit_post_widget.dart',
      ).readAsStringSync();
      final repository = File(
        'lib/backend/supabase/repositories/post_repository.dart',
      ).readAsStringSync();

      expect(editor, contains('Replace image'));
      expect(editor, contains('Replace video'));
      expect(editor, contains("Key('remove-post-media')"));
      expect(editor, contains("Key('delete-post-from-editor')"));
      expect(editor, contains('showGymFeedLocationPicker'));
      expect(editor, contains('TagUsersWidget.routeName'));
      expect(repository, contains("'video_asset_id': videoAssetId"));
      expect(repository, contains("from('post_tags')"));
      expect(repository, contains('callToActionEnabled'));
    });

    test('food details expose comments and complete information tabs', () {
      final details = File(
        'lib/pages/posts/post_details/food_post_details_view.dart',
      ).readAsStringSync();
      final feedSql = File(
        'supabase/migrations/0028_feed_post_metadata.sql',
      ).readAsStringSync();

      expect(details, contains("_tabButton('Comments', 0)"));
      expect(details, contains("_tabButton('Info', 1)"));
      expect(details, isNot(contains('TabBarView(')));
      for (final label in [
        'Meal type',
        'Preparation time',
        'Nutrition facts',
        'Recipe & preparation',
      ]) {
        expect(details, contains(label));
      }
      expect(feedSql, contains('call_to_action_enabled'));
      expect(feedSql, contains('tagged_user_ids'));
      expect(feedSql, contains('nutrition_facts'));
    });

    test('home replaces or removes only the changed post in place', () {
      final source = File(
        'lib/pages/core_pages/feed/feed_widget.dart',
      ).readAsStringSync();

      expect(source, contains('_refreshPostInPlace'));
      expect(source, contains("row['deleted'] == true"));
      expect(source, contains('updatedItems.removeAt(index)'));
      expect(source, contains('controller.itemList = updatedItems'));
    });

    test('database rejects interactions when the owner disabled them', () {
      final sql = File(
        'supabase/migrations/0023_enforce_post_interaction_permissions.sql',
      ).readAsStringSync();

      expect(sql, contains('p.allow_likes'));
      expect(sql, contains('p.allow_comments'));
      expect(sql, contains('not p.deleted'));
      expect(sql, contains('auth.uid() = user_id'));
    });
  });
}
