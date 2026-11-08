# Influencer outreach — kako radi i kako se podešava

Kod je u `marketing/src/outreach/`, a ponuda i profil kreatora koje tražimo su u [`marketing/src/outreach/offer.mjs`](../marketing/src/outreach/offer.mjs). Taj fajl menjaš kad hoćeš da promeniš šta bot nudi.

## Tok

1. **Ponedeljak u 09:00** (n8n workflow `07-weekly-influencer-outreach.json`): worker preko OpenAI web search-a nađe nove fitness kreatore (IG + TikTok, internacionalne i balkanske). Ako je podešen Business Discovery, za Instagram profile proveri pratioce i engagement. Zatim AI oceni svakog kreatora, izabere nivo (starter / partner / face) i napiše personalizovanu prvu poruku. Novi redovi idu u tab **Influencer Outreach**, a duplikati se preskaču.
2. **Ti, oko 10 minuta dnevno:** otvoriš `Open DM`, nalepiš `First message` i pošalješ, najviše 10–15 novih poruka dnevno. Kad pošalješ sa Instagrama, sistem preko webhooka sam čekira **Reached**. Za TikTok čekiraš ručno.
3. **Kad kreator odgovori na Instagramu**, sistem čekira **Reacted** i **Messaged back**, a bot pročita ceo razgovor i:
   - odgovori (ako je `OUTREACH_AUTO_REPLY=true`) ili upiše predlog u `Suggested reply`;
   - ažurira `Conversation summary`, `Status`, `Email`;
   - kad kreator pristane, pita za novac/ugovor, traži čoveka ili bot nije siguran: čekira **Accepted** (ako je pristao), upiše tvoje ime u `Owner`, napiše `Next step for you` i pošalje obaveštenje na `OUTREACH_HANDOFF_WEBHOOK_URL` (ako je podešen).
4. Dok je u `Owner` nešto drugo od `Bot`, bot ćuti i samo beleži nove poruke. Ako upišeš `Bot`, preuzima ponovo.
5. Bot nikad ne odgovara ljudima kojih nema u sheetu.

Kolone sa checkboxom su `Reached / Reacted / Messaged back / Accepted`. Možeš ih menjati i ručno, na primer za TikTok.

## Šta treba podesiti (jednom)

### Google Sheet
Koristi isti service account kao Content Review. Bez `OUTREACH_SHEET_ID` tab ide u postojeću approval tabelu. Ako hoćeš posebnu tabelu, napravi je, podeli je sa service account email-om (Editor) i upiši njen ID. Tab i kolone se prave sami.

### Instagram (Meta) — za automatske odgovore
1. Na developers.facebook.com napravi app tipa **Business** i dodaj proizvod **Instagram → API setup with Instagram login**.
2. Poveži nalog `gymfeed.official` i generiši token sa dozvolama `instagram_business_basic` i `instagram_business_manage_messages`. Upiši ga u `INSTAGRAM_MESSAGING_ACCESS_TOKEN`.
   - Long-lived token traje **60 dana**. Obnavlja se pozivom `GET https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=...`. Za sada je to ručni korak.
3. **Webhooks:** callback URL je `https://<N8N_DOMAIN>/webhooks/instagram` (Caddy to šalje workeru), a verify token je vrednost iz `INSTAGRAM_WEBHOOK_VERIFY_TOKEN`. Pretplati se na `messages`, `message_reactions` i `messaging_seen`. U `INSTAGRAM_APP_SECRET` upiši App Secret.
4. U Instagram aplikaciji: Settings → Messages and story replies → Message controls → **Connected tools → Allow access to messages**.
5. **App Review:** da bi webhook stizao od bilo koga (a ne samo od test korisnika aplikacije), `instagram_business_manage_messages` mora dobiti **Advanced Access**. Za to treba Business Verification i kratak video koji pokazuje kako se koristi. Dok to ne prođe, testiraj sa nalogom dodatim kao tester.

### Business Discovery (opciono, za tačne brojeve pratilaca)
Traži Facebook stranicu povezanu sa IG nalogom i token preko Facebook Login-a (`instagram_basic`, `pages_read_engagement`, `pages_show_list`). U `INSTAGRAM_BUSINESS_ACCOUNT_ID` ide ID IG naloga, a u `INSTAGRAM_GRAPH_ACCESS_TOKEN` token. Bez ovoga se pratioci uzimaju iz web pretrage kao procena. Radi samo za creator/business profile, ne za lične.

### Env (u `marketing/.env`)
```
OUTREACH_ENABLED=true
OUTREACH_AUTO_REPLY=false          # prvo par dana gledaj predloge, pa prebaci na true
OUTREACH_OWNER_NAME=Aleksandar
OUTREACH_SHEET_ID=                 # prazno = ista tabela kao Content Review
OUTREACH_WEEKLY_TARGET=40
OUTREACH_MIN_FOLLOWERS=5000
OUTREACH_MAX_FOLLOWERS=250000
OUTREACH_MODEL=gpt-6-luna          # jeftin model, isti kao daily CMO
OUTREACH_HANDOFF_WEBHOOK_URL=      # npr. n8n webhook koji ti pošalje email/Telegram
INSTAGRAM_MESSAGING_ACCESS_TOKEN=
INSTAGRAM_APP_SECRET=
INSTAGRAM_WEBHOOK_VERIFY_TOKEN=    # bilo koji dugačak nasumičan string
INSTAGRAM_BUSINESS_ACCOUNT_ID=     # opciono
INSTAGRAM_GRAPH_ACCESS_TOKEN=      # opciono
```

### Deploy
- Rebuild `marketing-worker` i restartuj `caddy` (Caddyfile sada prosleđuje `/webhooks/instagram` workeru).
- U n8n importuj `07-weekly-influencer-outreach.json`. Stiže **neaktivan**, pa ga aktiviraš kad je sve podešeno.
- Ručno pokretanje: `POST /v1/outreach/weekly` sa `x-marketing-token` headerom, opciono sa body `{"target": 10}`.

## Pravila koja bot poštuje
Bot ne pominje iznose i ne pregovara. Creator Programs predstavlja kao „uskoro“, bez datuma. Ne izmišlja činjenice o kreatoru. Na pitanje da li je AI odgovara iskreno. Potpisuje se kao „— GymFeed team“. Sve je u `offer.mjs`.

## Trošak
Pretraga sa web search-om je jedan poziv nedeljno, a ocenjivanje ide po 10 kreatora u jednom pozivu. Svaki odgovor je jedan poziv jeftinog modela. Za 40 kreatora nedeljno i nekoliko desetina razgovora to je realno nekoliko dolara mesečno.
