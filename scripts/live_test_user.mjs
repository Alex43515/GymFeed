import fs from 'node:fs';

function envFile(path) {
  const result = {};
  for (const line of fs.readFileSync(path, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (match) result[match[1]] = match[2];
  }
  return result;
}

const env = envFile(new URL('./.env', import.meta.url));
const url = env.SUPABASE_URL;
const secret = env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !secret) throw new Error('scripts/.env is missing Supabase admin credentials.');

const mode = process.argv[2];
if (mode === 'create') {
  const stamp = `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
  const email = `codex-premium-e2e-${stamp}@example.com`;
  const password = `GymFeed!${crypto.randomUUID().replaceAll('-', '')}`;
  const response = await fetch(`${url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: { apikey: secret, 'content-type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: 'Premium E2E Athlete' },
    }),
  });
  if (!response.ok) throw new Error(`Create user failed ${response.status}: ${await response.text()}`);
  const user = await response.json();
  process.stdout.write(JSON.stringify({ id: user.id, email, password }));
} else if (mode === 'delete') {
  const id = process.argv[3];
  if (!id) throw new Error('delete requires a user id');
  const response = await fetch(`${url}/auth/v1/admin/users/${encodeURIComponent(id)}`, {
    method: 'DELETE',
    headers: { apikey: secret },
  });
  if (!response.ok && response.status !== 404) {
    throw new Error(`Delete user failed ${response.status}: ${await response.text()}`);
  }
  process.stdout.write(JSON.stringify({ deleted: true, id }));
} else if (mode === 'first-post') {
  const response = await fetch(
    `${url}/rest/v1/posts?select=id,caption,food_title&deleted=eq.false&order=created_at.desc&limit=1`,
    { headers: { apikey: secret } },
  );
  if (!response.ok) {
    throw new Error(`Load post failed ${response.status}: ${await response.text()}`);
  }
  const rows = await response.json();
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error('No public post exists for the live share test.');
  }
  process.stdout.write(JSON.stringify(rows[0]));
} else if (mode === 'reset-premium') {
  const email = process.argv[3]?.trim().toLowerCase();
  const used = Number.parseInt(process.argv[4] ?? '0', 10);
  if (!email || !Number.isInteger(used)) {
    throw new Error('reset-premium requires an email and integer used counter');
  }
  const usersResponse = await fetch(
    `${url}/auth/v1/admin/users?page=1&per_page=1000`,
    { headers: { apikey: secret, authorization: `Bearer ${secret}` } },
  );
  if (!usersResponse.ok) {
    throw new Error(`Load users failed ${usersResponse.status}: ${await usersResponse.text()}`);
  }
  const usersPayload = await usersResponse.json();
  const matches = (usersPayload.users ?? []).filter(
    (user) => user.email?.trim().toLowerCase() === email,
  );
  if (matches.length !== 1) {
    throw new Error(`Expected one auth user for ${email}; found ${matches.length}`);
  }
  const userId = matches[0].id;
  const beforeResponse = await fetch(
    `${url}/rest/v1/profile_private?id=eq.${encodeURIComponent(userId)}&select=id,button_click`,
    { headers: { apikey: secret, authorization: `Bearer ${secret}` } },
  );
  if (!beforeResponse.ok) {
    throw new Error(`Load premium counter failed ${beforeResponse.status}: ${await beforeResponse.text()}`);
  }
  const beforeRows = await beforeResponse.json();
  if (beforeRows.length !== 1) {
    throw new Error(`No profile_private row exists for ${email}`);
  }
  const updateResponse = await fetch(
    `${url}/rest/v1/profile_private?id=eq.${encodeURIComponent(userId)}`,
    {
      method: 'PATCH',
      headers: {
        apikey: secret,
        authorization: `Bearer ${secret}`,
        'content-type': 'application/json',
        prefer: 'return=representation',
      },
      body: JSON.stringify({ button_click: used }),
    },
  );
  if (!updateResponse.ok) {
    throw new Error(`Reset premium counter failed ${updateResponse.status}: ${await updateResponse.text()}`);
  }
  const updatedRows = await updateResponse.json();
  if (updatedRows.length !== 1) {
    throw new Error(`Premium counter reset returned ${updatedRows.length} rows`);
  }
  process.stdout.write(JSON.stringify({
    email,
    userId,
    previousUsed: beforeRows[0].button_click ?? 0,
    currentUsed: updatedRows[0].button_click ?? 0,
    freeUsesRemaining: Math.max(0, 3 - used),
  }));
} else {
  throw new Error('Use create, delete, first-post, or reset-premium.');
}
