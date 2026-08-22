// GymFeed content seeder
// -----------------------------------------------------------------------------
// Creates N fake profiles and, per profile, uploads videos + images to Supabase
// Storage and inserts matching posts, so you can see the feed / reels / grids
// populated and gauge load speed.
//
// USAGE (from the scripts/ folder):
//   1) create scripts/.env  (see README.md) with:
//        SUPABASE_URL=https://bzinwojowkxavfzilvat.supabase.co
//        SUPABASE_SERVICE_ROLE_KEY=<your service_role key>
//        VIDEO_DIR=C:/Users/My SM PC/OneDrive/moji projekti/instagram_downloads
//        IMAGE_DIR=C:/Users/My SM PC/OneDrive/GymFeed all/gymfeed content/2024 GYM FEED/2024 GYM FEED/MOODBOARD
//   2) npm install
//   3) npm run seed
//
// Re-running is safe: users are reused if they already exist; posts are added.
// Uses the service_role key (bypasses RLS) — keep scripts/.env out of git.
// -----------------------------------------------------------------------------

import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://bzinwojowkxavfzilvat.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const VIDEO_DIR = process.env.VIDEO_DIR ||
  'C:/Users/My SM PC/OneDrive/moji projekti/instagram_downloads';
const IMAGE_DIR = process.env.IMAGE_DIR ||
  'C:/Users/My SM PC/OneDrive/GymFeed all/gymfeed content/2024 GYM FEED/2024 GYM FEED/MOODBOARD';

const VIDEOS_PER_USER = Number(process.env.VIDEOS_PER_USER || 10);
const IMAGES_PER_USER = Number(process.env.IMAGES_PER_USER || 5);
const PASSWORD = process.env.SEED_PASSWORD || 'GymFeed123!';

if (!SERVICE_KEY) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY is missing. Put it in scripts/.env');
  process.exit(1);
}

const supa = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const USERS = [
  { email: 'sophygreen@gymfeed.test', username: 'sophygreen', name: 'Sophia Green', bio: '50% off your first order. Join the program 💪 #sophygreen', website: 'www.sophygreen.com' },
  { email: 'tumbashmisha@gymfeed.test', username: 'tumbashmisha', name: 'Misha Tumbash', bio: 'Coach • strength & conditioning', website: 'www.mishatumbash.com' },
  { email: 'lazalaza@gymfeed.test', username: 'lazalaza', name: 'Lazar Lazarević', bio: 'Powerlifting. Big lifts, bigger plates.', website: 'www.lllalazalaza.org' },
  { email: 'alexs@gymfeed.test', username: 'alexs', name: 'Alex Sanchez', bio: 'Calisthenics & mobility', website: '' },
  { email: 'boris_92@gymfeed.test', username: 'boris92', name: 'Jusuf Boris', bio: 'Running the miles ☀️', website: '' },
];

const CAPTIONS = [
  'One video I posted a while ago — reposting because it helps. Watch the full thing 🔥',
  'Everything you need is in one place. #gymfeed',
  'Form check ✅ save this for your next session',
  'Progress over perfection. Day by day.',
  'Quick finisher you can do anywhere.',
  'Full body burner — 20 min, no excuses.',
  'This changed my training completely.',
  'Fuel right, train hard, rest well.',
  'Try this the next time you feel stuck.',
  'Consistency is the whole secret.',
];

const IMG_EXT = new Set(['.png', '.jpg', '.jpeg', '.webp']);
const contentTypeFor = (p) => {
  const e = path.extname(p).toLowerCase();
  if (e === '.mp4') return 'video/mp4';
  if (e === '.png') return 'image/png';
  if (e === '.webp') return 'image/webp';
  return 'image/jpeg';
};

async function walk(dir, matchExt) {
  const out = [];
  let entries;
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch (e) {
    return out;
  }
  for (const ent of entries) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      out.push(...(await walk(full, matchExt)));
    } else if (matchExt(path.extname(ent.name).toLowerCase())) {
      out.push(full);
    }
  }
  return out;
}

function shuffle(a) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

async function ensureBucket(id) {
  const { data } = await supa.storage.getBucket(id);
  if (data) return;
  // No custom fileSizeLimit — it can't exceed the project's global cap, so let
  // the bucket inherit it and we skip oversized files at upload time instead.
  const { error } = await supa.storage.createBucket(id, { public: true });
  if (error && !/already exists/i.test(error.message)) {
    throw new Error(`createBucket ${id}: ${error.message}`);
  }
  console.log(`• bucket "${id}" ready`);
}

const MAX_BYTES = Number(process.env.MAX_UPLOAD_MB || 49) * 1024 * 1024;
async function sizeOf(p) {
  try {
    return (await fs.stat(p)).size;
  } catch {
    return Infinity;
  }
}

async function getOrCreateUser(u) {
  // Look for an existing user with this email (paginated list).
  for (let page = 1; page <= 20; page++) {
    const { data, error } = await supa.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw new Error(`listUsers: ${error.message}`);
    const found = data.users.find((x) => x.email === u.email);
    if (found) return found.id;
    if (data.users.length < 200) break;
  }
  const { data, error } = await supa.auth.admin.createUser({
    email: u.email,
    password: PASSWORD,
    email_confirm: true,
    user_metadata: { display_name: u.name, username: u.username },
  });
  if (error) throw new Error(`createUser ${u.email}: ${error.message}`);
  console.log(`• created user ${u.email}`);
  return data.user.id;
}

async function uploadTo(bucket, uid, filePath) {
  const buf = await fs.readFile(filePath);
  const key = `${uid}/${crypto.randomUUID()}${path.extname(filePath).toLowerCase()}`;
  const { error } = await supa.storage.from(bucket).upload(key, buf, {
    contentType: contentTypeFor(filePath),
    upsert: true,
  });
  if (error) throw new Error(`upload ${bucket}/${key}: ${error.message}`);
  return supa.storage.from(bucket).getPublicUrl(key).data.publicUrl;
}

const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

async function main() {
  console.log('GymFeed seeder →', SUPABASE_URL);
  await ensureBucket('images');
  await ensureBucket('videos');

  const videos = shuffle(await walk(VIDEO_DIR, (e) => e === '.mp4'));
  const images = shuffle(await walk(IMAGE_DIR, (e) => IMG_EXT.has(e)));
  console.log(`• found ${videos.length} videos, ${images.length} images`);
  if (videos.length === 0) console.warn('⚠ no videos found in VIDEO_DIR');
  if (images.length === 0) { console.error('❌ no images found in IMAGE_DIR'); process.exit(1); }

  let vi = 0, ii = 0;
  const nextVideo = () => videos[(vi++) % videos.length];
  const nextImage = () => images[(ii++) % images.length];

  let createdPosts = 0;
  let when = Date.now();

  for (const u of USERS) {
    const uid = await getOrCreateUser(u);

    // Avatar + public profile fields.
    const avatarUrl = await uploadTo('images', uid, nextImage());
    const { error: pErr } = await supa.from('profiles').upsert({
      id: uid,
      username: u.username,
      display_name: u.name,
      photo_url: avatarUrl,
      bio: u.bio,
      website: u.website,
      updated_at: new Date().toISOString(),
    });
    if (pErr) throw new Error(`profile ${u.username}: ${pErr.message}`);
    console.log(`\n@${u.username} (${uid})`);

    const posts = [];

    // Video posts.
    for (let k = 0; k < VIDEOS_PER_USER && videos.length; k++) {
      const videoUrl = await uploadTo('videos', uid, nextVideo());
      const thumbUrl = await uploadTo('images', uid, nextImage());
      when -= rand(7, 90) * 60 * 1000; // stagger back in time
      posts.push({
        user_id: uid,
        caption: CAPTIONS[rand(0, CAPTIONS.length - 1)],
        legacy_photo_url: '',
        legacy_video_url: videoUrl,
        video_thumbnail: thumbUrl,
        food_post: false,
        created_at: new Date(when).toISOString(),
      });
      process.stdout.write('  🎬');
    }

    // Image posts.
    for (let k = 0; k < IMAGES_PER_USER && images.length; k++) {
      const photoUrl = await uploadTo('images', uid, nextImage());
      when -= rand(7, 90) * 60 * 1000;
      posts.push({
        user_id: uid,
        caption: CAPTIONS[rand(0, CAPTIONS.length - 1)],
        legacy_photo_url: photoUrl,
        legacy_video_url: '',
        video_thumbnail: '',
        food_post: false,
        created_at: new Date(when).toISOString(),
      });
      process.stdout.write('  🖼');
    }

    const { error: postErr } = await supa.from('posts').insert(posts);
    if (postErr) throw new Error(`posts ${u.username}: ${postErr.message}`);
    createdPosts += posts.length;
    process.stdout.write(`  → ${posts.length} posts\n`);
  }

  console.log(`\n✅ Done. ${USERS.length} profiles, ${createdPosts} posts.`);
  console.log('Login for any profile:  <username>@gymfeed.test  /  ' + PASSWORD);
}

main().catch((e) => {
  console.error('\n❌', e.message || e);
  process.exit(1);
});
