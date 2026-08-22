import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

const sourceUsername = process.env.GYMFEED_TEST_SOURCE || 'alexZs';
const targetUsername = process.env.GYMFEED_TEST_TARGET || 'alexZf';
const cleanupAfter = process.env.GYMFEED_TEST_CLEANUP_AFTER;

const { data: profiles, error: profileError } = await supabase
  .from('profiles')
  .select('id,username')
  .in('username', [sourceUsername, targetUsername]);
if (profileError) throw profileError;
if (profiles.length !== 2) {
  throw new Error('Messaging test profiles were not found.');
}

const source = profiles.find((profile) => profile.username === sourceUsername);
const target = profiles.find((profile) => profile.username === targetUsername);
const { data: memberships, error: membershipError } = await supabase
  .from('chat_members')
  .select('chat_id,user_id,last_seen_at')
  .in('user_id', [source.id, target.id]);
if (membershipError) throw membershipError;

const sourceChatIds = new Set(
  memberships
    .filter((membership) => membership.user_id === source.id)
    .map((membership) => membership.chat_id),
);
const sharedChatIds = memberships
  .filter(
    (membership) =>
      membership.user_id === target.id && sourceChatIds.has(membership.chat_id),
  )
  .map((membership) => membership.chat_id);
let directChatIds = [];
if (sharedChatIds.length > 0) {
  const { data: allMembers, error: allMembersError } = await supabase
    .from('chat_members')
    .select('chat_id,user_id')
    .in('chat_id', sharedChatIds);
  if (allMembersError) throw allMembersError;
  const membersByChat = new Map();
  for (const membership of allMembers) {
    const users = membersByChat.get(membership.chat_id) || new Set();
    users.add(membership.user_id);
    membersByChat.set(membership.chat_id, users);
  }
  directChatIds = [...membersByChat.entries()]
    .filter(([, users]) => users.size === 2)
    .map(([chatId]) => chatId);
}

const { error: messageSchemaError } = await supabase
  .from('chat_messages')
  .select('id,chat_id,user_id,text,image_url,video_url,post_id,created_at')
  .limit(1);
if (messageSchemaError) throw messageSchemaError;

if (cleanupAfter) {
  const { data: markerMessages, error: markerError } = await supabase
    .from('chat_messages')
    .select('chat_id')
    .gte('created_at', cleanupAfter)
    .like('text', '%test_20260810%');
  if (markerError) throw markerError;
  const cleanupChatIds = [
    ...new Set([
      ...directChatIds,
      ...markerMessages.map((message) => message.chat_id),
    ]),
  ];
  let createdChats = [];
  if (cleanupChatIds.length > 0) {
    const { data: matchingChats, error: chatError } = await supabase
      .from('chats')
      .select('id,created_at')
      .in('id', cleanupChatIds)
      .gte('created_at', cleanupAfter);
    if (chatError) throw chatError;
    createdChats = matchingChats;
  }
  let cleaned = 0;
  for (const chat of createdChats) {
    const { data: messages, error: messageError } = await supabase
      .from('chat_messages')
      .select('text')
      .eq('chat_id', chat.id);
    if (messageError) throw messageError;
    const onlyAutomationMessages = messages.every((message) => {
      const text = message.text || '';
      return (
        text.startsWith('Messaging_test_') ||
        text.endsWith('_test_20260810') ||
        text.startsWith('__gymfeed_read__:') ||
        text.startsWith('__gymfeed_reaction__:')
      );
    });
    if (onlyAutomationMessages) {
      const { error: deleteError } = await supabase
        .from('chats')
        .delete()
        .eq('id', chat.id);
      if (deleteError) throw deleteError;
      cleaned += 1;
    }
  }
  console.log(`Messaging schema ready; cleaned ${cleaned} empty test chat(s).`);
} else {
  console.log(`Messaging schema ready; ${directChatIds.length} direct chat(s) already exist.`);
}
