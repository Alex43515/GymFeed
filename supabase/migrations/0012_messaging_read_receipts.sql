-- Messaging reliability: allow members to advance only their own read marker.
drop policy if exists "update own chat read marker" on public.chat_members;
create policy "update own chat read marker"
  on public.chat_members for update
  using (user_id = auth.uid() and public.is_chat_member(chat_id))
  with check (user_id = auth.uid() and public.is_chat_member(chat_id));

-- Reactions and compatibility read receipts are stored as system messages.
-- They must not replace the human-readable conversation preview.
create or replace function public.update_chat_last_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.text like '__gymfeed_reaction__:%'
     or new.text like '__gymfeed_read__:%' then
    return null;
  end if;

  update public.chats
     set last_message = coalesce(
           nullif(new.text, ''),
           case when coalesce(new.video_url, '') <> '' then 'Video'
                when coalesce(new.image_url, '') <> '' then 'Photo'
                else '' end
         ),
         last_message_at = new.created_at,
         last_message_sent_by = new.user_id
   where id = new.chat_id;
  return null;
end;
$$;

