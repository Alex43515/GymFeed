import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL ||
  'https://bzinwojowkxavfzilvat.supabase.co';
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!serviceKey) {
  throw new Error('SUPABASE_SERVICE_ROLE_KEY is missing from scripts/.env');
}

const supabase = createClient(url, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const countBy = (rows, field) => {
  const counts = new Map();
  for (const row of rows) {
    const id = row[field];
    if (id) counts.set(id, (counts.get(id) || 0) + 1);
  }
  return counts;
};

const requiredRows = async (table, columns) => {
  const { data, error } = await supabase.from(table).select(columns);
  if (error) throw new Error(`${table}: ${error.message}`);
  return data || [];
};

const posts = await requiredRows('posts', 'id,like_count,comment_count');
const likes = await requiredRows('post_likes', 'post_id');
const comments = await requiredRows('comments', 'post_id');
const likesByPost = countBy(likes, 'post_id');
const commentsByPost = countBy(comments, 'post_id');

let changedPosts = 0;
for (const post of posts) {
  const likeCount = likesByPost.get(post.id) || 0;
  const commentCount = commentsByPost.get(post.id) || 0;
  if (post.like_count === likeCount && post.comment_count === commentCount) {
    continue;
  }
  const { error } = await supabase
    .from('posts')
    .update({ like_count: likeCount, comment_count: commentCount })
    .eq('id', post.id);
  if (error) throw new Error(`posts/${post.id}: ${error.message}`);
  changedPosts += 1;
}

const trainings = await requiredRows('user_trainings', 'id,like_count');
const trainingLikes = await requiredRows('training_likes', 'training_id');
const likesByTraining = countBy(trainingLikes, 'training_id');

let changedTrainings = 0;
for (const training of trainings) {
  const likeCount = likesByTraining.get(training.id) || 0;
  if (training.like_count === likeCount) continue;
  const { error } = await supabase
    .from('user_trainings')
    .update({ like_count: likeCount })
    .eq('id', training.id);
  if (error) throw new Error(`user_trainings/${training.id}: ${error.message}`);
  changedTrainings += 1;
}

console.log(
  `Reconciled ${changedPosts} posts and ${changedTrainings} training items.`,
);
