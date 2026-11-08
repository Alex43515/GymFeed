import { randomBytes } from "node:crypto";
import sharp from "sharp";
import { createClient } from "@supabase/supabase-js";
import { loadConfig } from "../src/config.mjs";

const seed = "marketplace-demo-v1";
const config = loadConfig();
const db = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const username = "gymfeed_demo";

function checked(result, operation) {
  if (result.error) throw new Error(`${operation}: ${result.error.message}`);
  return result.data;
}

const exercise = (name, reps = 10, sets = 3) => ({
  name, setCount: sets, defaultWeightKg: 0, defaultReps: reps,
  setTargets: Array.from({ length: sets }, () => ({ weightKg: 0, reps })),
});

const plans = [
  {
    slug: "full-body-foundations", title: "DEMO - Full Body Foundations", goal: "beginner", level: "beginner", equipment: "gym", weeks: 2,
    summary: "Three full-body sessions per week with rest days between them.",
    sessions: [
      ["Full body A", ["Goblet Squat", "Dumbbell Bench Press", "Seated Cable Row", "Dead Bug"]],
      ["Full body B", ["Leg Press", "Lat Pulldown", "Dumbbell Shoulder Press", "Glute Bridge"]],
      ["Full body C", ["Step-Up", "Incline Push-Up", "Chest-Supported Row", "Standing Calf Raise"]],
    ],
    slots: [0, -1, 1, -1, 2, -1, -1], color: "#0BEA70",
  },
  {
    slug: "dumbbell-week", title: "DEMO - The Dumbbell Week", goal: "general", level: "beginner", equipment: "dumbbells", weeks: 1,
    summary: "A compact week with three sessions using dumbbells.",
    sessions: [
      ["Dumbbell full body A", ["Goblet Squat", "Dumbbell Floor Press", "One-Arm Dumbbell Row", "Dumbbell Romanian Deadlift"]],
      ["Dumbbell full body B", ["Reverse Lunge", "Seated Dumbbell Press", "Dumbbell Row", "Standing Calf Raise"]],
      ["Dumbbell full body C", ["Dumbbell Squat", "Dumbbell Floor Press", "Dumbbell Biceps Curl", "Glute Bridge"]],
    ],
    slots: [0, -1, 1, -1, 2, -1, -1], color: "#5FD6DB",
  },
  {
    slug: "upper-lower-split", title: "DEMO - Upper Lower Split", goal: "muscle", level: "intermediate", equipment: "gym", weeks: 4,
    summary: "Four weekly sessions alternating upper and lower body.",
    sessions: [
      ["Upper A", ["Dumbbell Bench Press", "Seated Cable Row", "Lat Pulldown", "Lateral Raise"]],
      ["Lower A", ["Goblet Squat", "Dumbbell Romanian Deadlift", "Leg Curl", "Standing Calf Raise"]],
      ["Upper B", ["Incline Dumbbell Press", "Chest-Supported Row", "Dumbbell Shoulder Press", "Cable Triceps Pushdown"]],
      ["Lower B", ["Leg Press", "Reverse Lunge", "Glute Bridge", "Seated Calf Raise"]],
    ],
    slots: [0, 1, -1, 2, 3, -1, -1], color: "#C8D96F",
  },
  {
    slug: "home-reset", title: "DEMO - Home Movement Reset", goal: "general", level: "beginner", equipment: "none", weeks: 2,
    summary: "Three short bodyweight sessions each week, with no gym equipment.",
    sessions: [
      ["Home session A", ["Bodyweight Squat", "Wall Push-Up", "Glute Bridge", "Dead Bug"]],
      ["Home session B", ["Reverse Lunge", "Wall Push-Up", "Bird Dog", "Standing Calf Raise"]],
      ["Home session C", ["Bodyweight Squat", "Knee Push-Up", "Glute Bridge", "Bird Dog"]],
    ],
    slots: [0, -1, 1, -1, 2, -1, -1], color: "#EF92BB",
  },
  {
    slug: "strength-basics", title: "DEMO - Strength Basics", goal: "strength", level: "intermediate", equipment: "gym", weeks: 3,
    summary: "Three weekly sample strength sessions built around basic movement patterns.",
    sessions: [
      ["Strength A", ["Goblet Squat", "Dumbbell Bench Press", "Seated Cable Row"]],
      ["Strength B", ["Dumbbell Romanian Deadlift", "Dumbbell Shoulder Press", "Lat Pulldown"]],
      ["Strength C", ["Leg Press", "Incline Dumbbell Press", "Chest-Supported Row"]],
    ],
    slots: [0, -1, 1, -1, 2, -1, -1], color: "#F4B56B",
  },
  {
    slug: "conditioning-starter", title: "DEMO - Conditioning Starter", goal: "conditioning", level: "beginner", equipment: "gym", weeks: 1,
    summary: "A sample week alternating simple full-body sessions with rest days.",
    sessions: [
      ["Conditioning A", ["Bodyweight Squat", "Incline Push-Up", "Seated Cable Row", "Standing Calf Raise"]],
      ["Conditioning B", ["Step-Up", "Dumbbell Floor Press", "Glute Bridge", "Dead Bug"]],
      ["Conditioning C", ["Reverse Lunge", "Wall Push-Up", "One-Arm Dumbbell Row", "Bird Dog"]],
    ],
    slots: [0, -1, 1, -1, 2, -1, -1], color: "#A6B9F8",
  },
];

async function demoSeller() {
  const existing = checked(await db.from("profiles").select("id").eq("username", username).maybeSingle(), "Find demo seller");
  if (existing) {
    const account = checked(await db.auth.admin.getUserById(existing.id), "Verify demo account");
    if (account.user.app_metadata?.seed !== seed) throw new Error("Demo username belongs to another account; refusing to change it");
    return existing.id;
  }
  const account = checked(await db.auth.admin.createUser({
    email: "gymfeed-marketplace-demo@example.com",
    password: randomBytes(48).toString("base64url"),
    email_confirm: true,
    ban_duration: "876000h",
    app_metadata: { seed },
    user_metadata: { username, display_name: "GymFeed Demo" },
  }), "Create disabled demo seller");
  checked(await db.from("profiles").update({
    bio: "Demo plans for exploring GymFeed Marketplace. Sample content, not a real trainer account. No video instruction is included.",
  }).eq("id", account.user.id), "Label demo seller");
  return account.user.id;
}

async function cover(plan, sellerId) {
  const title = plan.title.slice("DEMO - ".length);
  const words = title.split(" ");
  const midpoint = Math.ceil(words.length / 2);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900">
    <rect width="1600" height="900" fill="#0B100E"/>
    <rect x="0" y="0" width="26" height="900" fill="${plan.color}"/>
    <text x="110" y="135" font-family="Arial,sans-serif" font-weight="700" font-size="48" fill="white">GymFeed Demo</text>
    <text x="110" y="365" font-family="Arial,sans-serif" font-weight="700" font-size="104" fill="white">${words.slice(0, midpoint).join(" ")}</text>
    <text x="110" y="495" font-family="Arial,sans-serif" font-weight="700" font-size="104" fill="${plan.color}">${words.slice(midpoint).join(" ")}</text>
    <text x="110" y="660" font-family="Arial,sans-serif" font-size="40" fill="#C4CEC9">${plan.weeks * 7} DAYS / ${plan.level.toUpperCase()} / ${plan.equipment.toUpperCase()}</text>
    <text x="110" y="800" font-family="Arial,sans-serif" font-size="34" fill="#93A79B">SAMPLE PLAN / FREE</text>
  </svg>`;
  const bytes = await sharp(Buffer.from(svg)).png().toBuffer();
  const path = `${sellerId}/marketplace-demo/${plan.slug}.png`;
  checked(await db.storage.from("images").upload(path, bytes, { contentType: "image/png", upsert: true }), "Upload demo cover");
  return db.storage.from("images").getPublicUrl(path).data.publicUrl;
}

const sellerId = await demoSeller();
const seeded = [];
for (const [index, plan] of plans.entries()) {
  const old = checked(await db.from("training_plans").select("id,status").eq("seller_id", sellerId).eq("title", plan.title).maybeSingle(), "Find demo plan");
  if (old?.status === "published") {
    seeded.push({ id: old.id, title: plan.title, reused: true });
    continue;
  }
  const coverUrl = await cover(plan, sellerId);
  const fields = {
    seller_id: sellerId, title: plan.title,
    description: `${plan.summary}\n\nDEMO: Sample content for testing Marketplace browsing and adding a plan to Train. Not a personalized training prescription. Loads start at 0 kg so they can be edited before training. No exercise or intro videos are included.`,
    goal: plan.goal, level: plan.level, equipment: plan.equipment,
    day_count: plan.weeks * 7, price_cents: 0, status: "draft",
    cover_image_url: coverUrl, is_featured: index < 3,
  };
  const saved = checked(await (old
    ? db.from("training_plans").update(fields).eq("id", old.id)
    : db.from("training_plans").insert(fields)).select("id").single(), "Save demo plan");
  const days = Array.from({ length: plan.weeks * 7 }, (_, position) => {
    const slot = plan.slots[position % 7];
    const session = slot >= 0 ? plan.sessions[slot] : null;
    return {
      plan_id: saved.id, day: position + 1,
      kind: session ? "workout" : "rest",
      title: session ? `Week ${Math.floor(position / 7) + 1} - ${session[0]}` : "Rest day",
      notes: "Demo schedule. Edit exercise settings and choose appropriate loads before training.",
      exercises: session ? session[1].map((name) => exercise(name, plan.goal === "strength" ? 6 : 10)) : [],
    };
  });
  checked(await db.from("training_plan_days").upsert(days, { onConflict: "plan_id,day" }), "Save demo days");
  const count = checked(await db.from("training_plan_days").select("day,kind,exercises").eq("plan_id", saved.id), "Verify demo days");
  if (count.length !== fields.day_count || count.some((day) => day.kind === "workout" && !day.exercises.length)) {
    throw new Error(`Incomplete demo plan: ${plan.title}`);
  }
  checked(await db.from("training_plans").update({ status: "published", published_at: new Date().toISOString() }).eq("id", saved.id), "Publish demo plan");
  seeded.push({ id: saved.id, title: plan.title, days: fields.day_count, workouts: count.filter((day) => day.kind === "workout").length });
}

const visible = checked(await db.from("training_plans")
  .select("id,title,status,cover_image_url,seller:profiles!training_plans_seller_id_fkey(id,username,display_name),days:training_plan_days(day,kind)")
  .eq("seller_id", sellerId).eq("status", "published")
  .order("enrollment_count", { ascending: false }).order("published_at", { ascending: false }), "Verify Marketplace query");
if (visible.length !== plans.length || visible.some((plan) => !plan.seller || !plan.cover_image_url || !plan.days.length)) {
  throw new Error("Marketplace verification failed");
}
for (const plan of visible) {
  const response = await fetch(plan.cover_image_url, { method: "HEAD" });
  if (!response.ok) throw new Error(`Cover unavailable for ${plan.title}: ${response.status}`);
}
console.log(JSON.stringify({ seller: "GymFeed Demo", sellerId, plans: seeded, verified: visible.length }, null, 2));
