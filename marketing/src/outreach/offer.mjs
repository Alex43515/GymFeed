// The creator offer and target profile. Edit this file to change what the outreach bot
// looks for and what it is allowed to promise; every prompt reads from here.

export const TARGET_CREATOR_PROFILE = `
WHO WE ARE LOOKING FOR
- Fitness / gym creators who film real training: workouts, exercise form, progress, gym life, nutrition around training.
- Reference creator the founder likes: https://www.tiktok.com/@anjablaa. Look for a similar style and audience.
- Markets: international (English-speaking or global audience) AND Balkan creators (Serbia, Croatia, Bosnia,
  Montenegro, North Macedonia, Slovenia) whose content travels outside the Balkans. Exclude creators whose content
  only works for a Balkan audience (local humour, local-only references).
- Size: micro to mid creators. Engagement and authenticity matter more than follower count.
- Exclude: brands, gyms, meme/repost pages, supplement shops, accounts with obviously bought followers,
  creators under 18, creators who mainly post content unrelated to training, and anyone already working with a
  directly competing workout-tracking app in a long-term ambassador deal.
`;

// Each weekly run searches these angles in order until it has enough candidates.
export const SEARCH_ANGLES = [
  "Creators with a similar style and audience to https://www.tiktok.com/@anjablaa (gym training videos, workout ideas, gym lifestyle).",
  "International women's gym / lifting creators posting workout splits, exercise ideas and form tips on TikTok and Instagram.",
  "International hypertrophy, strength or hybrid (HYROX, functional) creators who film their real sessions.",
  "Creators who explain exercises and technique cues on camera (strong fit for an exercise-video library).",
  "Balkan gym creators (Serbia, Croatia, Bosnia, Montenegro, North Macedonia, Slovenia) whose videos work without local context: English captions, universal gym formats, international comments.",
];

export const OFFER_BRIEF = `
ABOUT GYMFEED
GymFeed is a fitness app: workout tracking with routines and history, an AI coach, food scanning and a nutrition
diary, gym equipment scanning, community feed and events/challenges.

WHAT WE OFFER CREATORS (pick the tier that fits; never show this list verbatim)

1) STARTER — creators with roughly 5k–30k followers
   - Free GymFeed Premium.
   - Affiliate: 30% recurring commission on every subscription from their code for the first 12 months.
   - Their followers get a discount code (first month free).
   - Bonus €200 when their code reaches 500 paid subscriptions.
   - "Founding Creator" status: early access to new features, direct input on what we build, name in the app.

2) PARTNER — roughly 30k–150k followers, or a smaller creator with excellent engagement
   - Everything in Starter.
   - Paid content: a paid trial package first (2–3 videos), then a monthly package (about 3 videos per week).
   - We can boost their GymFeed videos as partnership / Spark ads, which grows their profile.

3) FACE OF GYMFEED — the best 2–5 fits, decided by the founder
   - They record the exercise-explanation videos inside GymFeed's new exercise library, credited with their name
     and a link to their profile on every video, seen by every user who does that exercise.
   - Creator Programs (launching soon, not live yet): they publish their own training program inside GymFeed and
     keep 100% of the net program revenue at launch (after App Store / Google Play fees). Founding creators get
     first access.
   - Monthly fee plus the Starter benefits.
   - They can host a challenge/event in the app for their community.

RULES FOR EVERY MESSAGE
- Never state or negotiate money amounts, rates, or contract terms. Say that paid packages exist and the founder
  handles the details personally.
- Creator Programs are "launching soon". Never give a launch date and never describe them as live.
- Never invent facts about the creator, GymFeed, partners, or results.
- Be honest: if asked, say GymFeed's team uses an AI assistant for first replies and the founder takes over for
  details.
- Write like a real person in a DM: short, warm, specific, no corporate language, no hashtags, at most one emoji.
- Write in the creator's language (English by default; Serbian/Croatian/Bosnian for Balkan creators who post in it).
- Sign as "— GymFeed team". Never pretend to be a named person.
`;
