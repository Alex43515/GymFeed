-- Replace seeded/demo counter placeholders with values derived from the
-- canonical interaction tables. Existing triggers keep the counters accurate
-- after this one-time repair.

update public.posts as post
set like_count = (
      select count(*)::integer
      from public.post_likes as post_like
      where post_like.post_id = post.id
    ),
    comment_count = (
      select count(*)::integer
      from public.comments as comment
      where comment.post_id = post.id
    )
where post.like_count is distinct from (
        select count(*)::integer
        from public.post_likes as post_like
        where post_like.post_id = post.id
      )
   or post.comment_count is distinct from (
        select count(*)::integer
        from public.comments as comment
        where comment.post_id = post.id
      );

update public.user_trainings as training
set like_count = (
      select count(*)::integer
      from public.training_likes as training_like
      where training_like.training_id = training.id
    )
where training.like_count is distinct from (
        select count(*)::integer
        from public.training_likes as training_like
        where training_like.training_id = training.id
      );
