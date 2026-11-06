import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const policy = await readFile(new URL('../public_html/privacy/index.html', import.meta.url), 'utf8');

test('privacy policy is a public standalone English HTML document', () => {
  assert.match(policy, /<html lang="en">/);
  assert.match(policy, /<h1>Privacy Policy<\/h1>/);
  assert.match(policy, /rel="canonical" href="https:\/\/gymfeed\.io\/privacy\/"/);
  assert.doesNotMatch(policy, /<script|<iframe|contenteditable|docs\.google\.com/i);
});

test('retention explains account, content, history, health, exceptions, and backups', () => {
  assert.match(policy, /id="data-retention"/);
  assert.equal((policy.match(/<dt>/g) ?? []).length, 6);
  for (const phrase of ['while your GymFeed account exists', 'verified account-deletion request', 'only on your device', 'previously saved history', 'legal obligation', 'backup cycle expires']) {
    assert.ok(policy.includes(phrase), `Missing retention disclosure: ${phrase}`);
  }
  assert.doesNotMatch(policy, /we do not (?:store|retain) user data/i);
});

test('deletion can be requested outside the app without supplying a password', () => {
  assert.match(policy, /id="account-deletion"/);
  assert.match(policy, /without installing or signing in/);
  assert.match(policy, /mailto:official@gymfeed\.io\?subject=GymFeed%20account%20deletion%20request/);
  assert.match(policy, /Do not send your password/);
  assert.match(policy, /does not automatically cancel an app-store subscription/);
});

test('connected-health disclosures from the existing production page are preserved', () => {
  for (const phrase of ['Apple Health', 'Health Connect', 'read-only access', 'separately enable AI sharing', 'excluded from rolling AI memory', 'does not delete existing history or plans']) {
    assert.ok(policy.includes(phrase), `Missing existing health disclosure: ${phrase}`);
  }
});
