# GymFeed Plans: marketplace planova treninga

**Ideja:** svaki korisnik može da napravi plan treninga (od 1 do 31 dana) sa video objašnjenjima i da ga prodaje po fiksnoj ceni od **9,99 $**. Kupac doda plan u svoj Train, izabere datum početka, i treninzi mu se automatski rasporede po danima. Prodavac zarađuje od svake prodaje, a GymFeed mu isplaćuje novac jednom mesečno.

Influenceri nisu poseban sistem. Oni su prodavci kojima pomažemo da krenu, plus dobijaju affiliate kodove (§11).

---

## 1. Gde to živi u aplikaciji

**U Train-u, ne u Events.** Plan je trening koji radiš ti, po svom rasporedu, a Train već ima rutine, raspored i praćenje setova. Events su vremenski vezane grupne aktivnosti. Kasnije se može dodati „radimo ovaj plan zajedno od 1. januara“ kao event, ali to je nadogradnja.

| Mesto | Šta se vidi |
|---|---|
| **Train → „Plans“** (nova kartica/tab na Train početnoj) | Prodavnica: istaknuti, najprodavaniji, novi, filteri (cilj, nivo, trajanje, oprema, besplatni/plaćeni), pretraga |
| **Train → „My plans“** | Kupljeni planovi (aktivni / završeni) i planovi koje sam napravio (sa zaradom) |
| **Profil korisnika → tab „Plans“** | Svi planovi tog korisnika. Ljudi kupuju od onih koje prate, pa je ovo glavni kanal prodaje |
| **Feed** | „Podeli plan“ pravi post-karticu sa coverom, cenom i dugmetom „Pogledaj plan“ |

## 2. Kako neko napravi plan

Train → Plans → **„Create plan“**. Koristi se postojeći editor rutina i biblioteka vežbi, pa se ništa ne pravi od nule.

1. **Osnovno:** naziv, kratak opis, cilj (snaga / mišićna masa / mršavljenje / kondicija / početnici), nivo, oprema (teretana / bučice / kod kuće), **trajanje 1–31 dan**, cover slika.
2. **Dani:** lista dana 1…N. Svaki dan je **trening** ili **odmor**.
   - Trening se pravi u postojećem editoru rutina (vežbe, setovi, ponavljanja, kilaža, odmor, napomene).
   - Može da se ubaci i neka od sopstvenih postojećih rutina.
   - Prečica „Ponovi nedelju“ kopira dane 1–7 u 8–14 itd.
3. **Video:**
   - **intro video plana je obavezan**: 9:16, do 60 s, prodavac objašnjava kome je plan namenjen;
   - **video po vežbi je opciono**, do 45 s.
   - Upload ide kroz postojeći Bunny pipeline (`create-upload` → `media_assets`).
4. **Cena:** **9,99 $** ili **besplatno**. Besplatni planovi su važni za rast, jer prodavac prvo skupi publiku.
5. **Prvi put pre prodaje** (samo za plaćene planove):
   - prihvatanje uslova za prodavce;
   - potvrda da ima 18+ godina;
   - podešavanje isplate i poreski podaci (§5.5).
6. **Slanje na pregled:** prvi plan svakog prodavca pregleda čovek, a kasnije samo automatska provera sadržaja i prijave korisnika (§6). Posle odobrenja plan je javan.
7. **Izmene posle objave** prave novu verziju. Kupci dobijaju ažuriranje, ali njihov već zakazani raspored se ne menja dok ga sami ne obnove.

## 3. Kupovina i paywall

### Proizvod u store-u
- **Jedan proizvod za sve planove:** `gf_plan_unlock`, tip **Consumable**, 9,99 $ (Apple automatski preračunava lokalne cene). Pravi se jednom u App Store Connect-u, Google Play Console-u i RevenueCat-u.
- **Zašto consumable, a ne poseban proizvod po planu:**
  - planove prave korisnici, pa ne možemo za svaki plan otvarati proizvod u store-u i čekati Apple-ov review;
  - Apple ovo dozvoljava kao „token“ model: kupljeni token se odmah zameni za izabrani plan;
  - sadržaj koji prave korisnici mora poštovati 1.2 (moderacija) i 3.1.1 (plaćanje ide kroz IAP).
- **Pravila za token:** kupovina ne sme da „istekne“ i mora da postoji vraćanje kupljenog. Pošto se kupovina odmah vezuje za nalog u našoj bazi, vraćanje radi prijavom na isti nalog. To treba napisati u napomeni za App Review.
- **Zabranjeno u aplikaciji:** link „kupi jeftinije na sajtu“, zbog pravila 3.1.1.

### Tok kupovine
1. Korisnik otvori plan i vidi **paywall**: cover, intro video, besplatan pregled **prvog dana**, cena iz store-a i dugme „Kupi plan“.
2. Aplikacija zove RPC `create_plan_purchase_intent(plan_id)`. On vraća `intent_id` i odbija kupovinu ako je to plan samog prodavca ili ako je već kupljen.
3. RevenueCat kupi `gf_plan_unlock`. Treba nova funkcija `purchaseStoreProduct` u `lib/flutter_flow/revenue_cat_util.dart`, jer postojeća `purchasePackage` gleda samo glavnu ponudu.
4. **Edge funkcija `confirm-plan-purchase`** dobije `intent_id` + `store_transaction_id`, proveri transakciju preko RevenueCat REST API-ja za tog korisnika, upiše `plan_purchases` i otključa plan. Korisnik plan dobija odmah, bez čekanja.
5. **RevenueCat webhook (rezervni put):** postojeći `supabase/functions/revenuecat-webhook` za `NON_RENEWING_PURCHASE` sa `product_id = gf_plan_unlock` vezuje transakciju za otvoreni intent, ako aplikacija nije stigla (npr. pukla mreža). Za refund (`CANCELLATION`) kupovina dobija status `refunded`, a prodavcu se odbija od zarade.
6. **Neto iznos** se računa iz webhooka: RevenueCat šalje `price`, `tax_percentage`, `commission_percentage` i `takehome_percentage`, a to se čuva uz svaku kupovinu (§5).

**Premium i planovi su odvojeni.** Premium (`premium_features`) ne otključava plaćene planove. U suprotnom ne bi bilo jasno koliko prihoda pripada prodavcu.

## 4. Dodavanje u Train i automatski raspored

Posle kupovine (ili odmah, za besplatan plan), dugme **„Dodaj u moj Train“** otvara:

1. **Datum početka**, npr. 1. januar.
2. **Kako da rasporedi:**
   - **„Uzastopno“** (podrazumevano, kako si opisao): dan 1 plana = 1. januar, dan 2 = 2. januar… Dani odmora ostaju prazni.
   - **„Samo moji dani treninga“**: korisnik izabere npr. pon/sre/pet, a treninzi iz plana (bez dana odmora) se ređaju na te dane. Za 7-dnevni plan sa 4 treninga to bude 1, 3, 5. i 8. januar.
3. **Pregled kalendara** pre potvrde, sa upozorenjem ako tog dana već ima zakazan trening.

**Tehnički:**
- Svaki dan sa treningom postaje lokalna rutina `plan-<planId>-v<verzija>-d<dan>`, kategorije „Plan · Ime prodavca“. Raspored se upisuje u postojeći raspored (`WorkoutRoutineStore.scheduleRoutine`).
- Treba nova metoda `WorkoutRoutineStore.importPlan(planKey, routines, schedule)`. Postojeći `importStarterPlan` pamti samo jedan plan, a korisnik može imati više planova.
- Upis se čuva i u bazi (`plan_enrollments`: plan, verzija, datum početka, režim, dani). Na novom telefonu se raspored ponovo izgradi iz baze, jer su rutine danas samo lokalne.
- Opcije: **„Pomeri plan“** (novi datum početka, preračuna buduće dane) i **„Ukloni plan“** (briše buduće zakazane dane, istorija ostaje).
- Kad se plan završi, korisnik dobija poziv da ga **oceni** (1–5 i kratak komentar). Ocene se prikazuju u prodavnici.

## 5. Kako novac stiže do prodavca

### 5.1 Tok novca

```
Kupac plati 9,99 $
  → Apple / Google uzmu proviziju (15% u Small Business programu) i PDV gde važi
  → isplate GymFeed firmi (Apple ~33 dana posle kraja meseca, Google ~15. u narednom mesecu)
  → GymFeed vodi stanje svakog prodavca u bazi
  → jednom mesečno GymFeed isplati prodavcima preko servisa za isplate
```

**Kupac nikad ne plaća direktno prodavcu.** Novac uvek prvo legne na račun GymFeed-a (Apple i Google plaćaju samo tebe), a GymFeed onda isplaćuje prodavce. Tako rade i Patreon, Gumroad i slične platforme.

### 5.2 Koliko je to po prodaji (okvirno, za 9,99 $)

| Kupac iz | PDV | Apple/Google 15% | Neto za GymFeed |
|---|---|---|---|
| SAD (bez PDV-a) | 0 | ~1,50 $ | **~8,49 $** |
| EU (~20% PDV uračunat u cenu) | ~1,67 $ | ~1,25 $ | **~7,07 $** |

Tačni procenti stižu u webhooku po svakoj kupovini, pa se računa precizno, a ne po proceni. Bez Small Business programa provizija je 30%. RevenueCat uzima 1% prihoda iznad 2.500 $ mesečno.

### 5.3 Podela: tvoja odluka

| Opcija | Prodavac dobija | GymFeed | Komentar |
|---|---|---|---|
| A | **100% neto** | 0 | Najjača poruka, ali GymFeed plaća troškove isplata, moderacije i prevara iz svog džepa |
| **B (preporuka)** | **80% neto** (~5,60–6,80 $) | 20% neto | Pokriva troškove isplata i moderacije, a i dalje je bolje od većine platformi |
| C | Fiksno **6 $ po prodaji** | ostatak | Najlakše za objasniti, ali u nekim zemljama GymFeed gubi novac |

Može i kombinacija: **100% za prvih 6–12 meseci**, posle toga B.

**Odluka (9. 10. 2026):** GymFeed zadržava **30% neto** (posle Apple/Google provizije i PDV-a), a prodavac dobija **70% neto**. Za influencere se procenat ugovara pojedinačno i čuva u `seller_profiles.share_pct`.

### 5.4 Stanje prodavca

- Svaka kupovina upisuje u `seller_ledger` stavku **„pending“**: udeo prodavca u neto iznosu.
- Posle **30 dana** (rok za refundacije) stavka postaje **„available“**.
- Refund pravi negativnu stavku.
- **Isplata jednom mesečno**, kad je „available“ iznad praga (npr. **25 $**). Isplata se upisuje kao stavka „paid“.
- Prodavac u „My plans → Zarada“ vidi: na čekanju / dostupno / isplaćeno, prodaje po planu i istoriju isplata.

### 5.5 Kako fizički isplatiti ljude

| Način | Prednosti | Mane | Kada |
|---|---|---|---|
| **Ručno** (PayPal / Wise / banka, mesečna lista iz baze) | Bez integracije, kreće odmah | Ručni rad, ti skupljaš poreske podatke | Prvih ~20–30 prodavaca |
| **[Trolley](https://trolley.com/l/creator-influencer-payout-platform)** | Napravljen za isplate kreatorima: 210+ zemalja, sam prikuplja W-8/W-9 formulare, radi DAC7 i provere identiteta | Cena samo na upit, mesečni trošak | **Preporuka** kad prodavaca bude više |
| **Stripe Connect Express** | Odlična integracija i proveravanje identiteta | Zavisi od zemlje firme. Stripe-ova [zvanična stranica](https://docs.stripe.com/connect/cross-border-payouts) dozvoljava self-serve prekogranične isplate samo za platforme i primaoce u SAD, UK, EEA, Kanadi i Švajcarskoj, a **Srbija nije na toj listi** | Ako GymFeed ima firmu u SAD/EU i prodavci su uglavnom odatle |
| Payoneer | Široko dostupan | Slabija integracija | Alternativa za Trolley |

**Preporuka:** kreni **ručno** (Wise/PayPal) sa pragom od 25 $. Model u bazi napravi odmah tako da kasnije samo uključiš Trolley ili Stripe, bez menjanja logike. Izbor zavisi od toga **u kojoj zemlji je GymFeed firma** (§9).

### 5.6 Obaveze koje dolaze sa isplatama

- **Ko prodaje:** prodavci moraju biti punoletni, sa potvrđenim identitetom pre prve isplate (servis za isplate to radi, a ručno ide uz kopiju dokumenta).
- **Porez:**
  - prikupljanje poreskih podataka (W-8BEN/W-9 ako firma posluje u SAD);
  - DAC7 izveštavanje ako firma ili prodavci potpadaju pod EU pravila za digitalne platforme;
  - provera sankcija.
  - Trolley ili Stripe ovo pokrivaju, ručno to radiš sa knjigovođom.
- **Uslovi za prodavce:** podela prihoda, rok isplate, odbijanje refundacija, pravo GymFeed-a da ukloni plan, licenca za sadržaj, zabrana medicinskih tvrdnji. **Ovo piše pravnik.**
- **Knjigovodstvo:** ceo iznos od Apple-a/Google-a je prihod GymFeed-a, a isplate prodavcima su trošak. Pitaj knjigovođu kako se to vodi u tvojoj zemlji.

## 6. Kvalitet i moderacija

- Postoji `content_safety` workflow (migracija `0027_content_safety_workflow.sql`), pa ga planovi i videi koriste isto kao postovi.
- Prvi plan svakog prodavca pregleda čovek. Posle toga ide AI provera teksta i videa plus prijave korisnika.
- **Pravila sadržaja:**
  - bez medicinskih obećanja („-10 kg za 7 dana“);
  - bez opasnih vežbi bez upozorenja;
  - bez tuđih videa i muzike sa autorskim pravima.
- U svakom planu stoji disclaimer: „Konsultuj lekara pre početka programa“.
- Refundacije rade Apple i Google, ne GymFeed. Korisnik ih traži kod store-a, a mi samo odbijemo iznos od prodavca.
- Prodavac sa puno refundacija ili prijava gubi pravo prodaje.

## 7. Baza (Supabase)

```
seller_profiles     user_id (pk), status (none|pending|approved|suspended), terms_accepted_at,
                    is_adult_confirmed, payout_provider (manual|trolley|stripe), payout_account_ref,
                    payout_email, tax_status (missing|submitted|verified), country, share_pct, share_until
plans               id, seller_id, slug, title, description, goal, level, equipment, days (1-31),
                    price_cents (0 | 999), cover_url, intro_video_asset_id, status
                    (draft|in_review|published|rejected|removed), version, rating_avg, rating_count,
                    sales_count, published_at, created_at
plan_days           plan_id, version, day (1..N), kind (workout|rest), title, notes,
                    exercises jsonb  -- [{name, exercise_id?, sets:[{reps, weight_kg?}], rest_s, notes, video_asset_id?}]
plan_purchase_intents id, user_id, plan_id, status (open|completed|expired), created_at
plan_purchases      id, user_id, plan_id, seller_id, intent_id, store, store_transaction_id (unique),
                    rc_event_id, price_usd, tax_pct, commission_pct, net_usd, seller_share_usd,
                    status (paid|refunded), purchased_at
plan_enrollments    id, user_id, plan_id, version, start_date, mode (consecutive|weekdays),
                    weekdays int[], status (active|completed|removed), created_at
plan_reviews        user_id, plan_id, rating 1-5, comment, created_at
seller_ledger       id, seller_id, kind (sale|refund|payout|adjustment), amount_usd, purchase_id,
                    payout_id, status (pending|available|paid), available_at, created_at
seller_payouts      id, seller_id, amount_usd, currency, provider, reference, status, paid_at
```

**RLS (ko šta vidi):**
- `plans` i `plan_days` za dan 1 vidi svako.
- Ostale dane vidi samo kupac (`plan_purchases.status = 'paid'`), prodavac ili korisnik besplatnog plana. To ide preko RPC-a `plan_content(plan_id)`.
- Ledger i isplate vidi samo sam prodavac (za čitanje), a sve izmene radi service role.

## 8. Redosled izrade

| Faza | Šta | Glavni fajlovi | Okvirno |
|---|---|---|---|
| **1** | Pravljenje i objava **besplatnih** planova + dodavanje u Train sa automatskim rasporedom | migracija (`plans`, `plan_days`, `plan_enrollments`), `lib/backend/supabase/repositories/plan_repository.dart`, `lib/workout/plans/*` (prodavnica, detalj, builder, „Dodaj u Train“), `workout_routine_store.dart` (`importPlan`), Train početna, tab na profilu | 2–3 nedelje |
| **2** | Video u planovima (intro + po vežbi) i moderacija | `create-upload`, `media_repository.dart`, content safety | 1 nedelja |
| **3** | **Plaćeni planovi:** `gf_plan_unlock`, paywall, intent, `confirm-plan-purchase`, webhook, refundacije, Premium ostaje odvojen | `revenue_cat_util.dart`, `supabase/functions/confirm-plan-purchase`, `revenuecat-webhook/index.ts`, migracija (`plan_purchases`, intents) | 1–1,5 nedelja |
| **4** | Prodavci: onboarding, ledger, ekran zarade, mesečni izveštaj za ručne isplate | migracija (`seller_*`), ekran zarade, SQL/CSV izveštaj | 1 nedelja |
| **5** | Ocene, deljenje na feed, istaknuti planovi, pretraga | — | 1 nedelja |
| **6** | Automatske isplate (Trolley ili Stripe) | edge funkcija + onboarding link | 1 nedelja, kad bude potrebno |

### Status faze 1 (urađeno, nije pušteno)

- **Baza:** `supabase/migrations/20261009180000_training_plans.sql`, sa tabelama `training_plans`, `training_plan_days` i `training_plan_enrollments`, RLS pravilima i RPC funkcijama `save_training_plan`, `submit_training_plan` i `review_training_plan`.
- **Aplikacija** (`lib/workout/plans/`):
  - prodavnica i „My plans“;
  - detalj plana;
  - builder (koristi postojeći editor rutina);
  - „Add to my Train“ sa dva režima rasporeda i pregledom kalendara;
  - kartica „Training plans“ na Train ekranu.
- **Rutine plana:** u Train listi rutina se ne prikazuju (ostaju u kalendaru i na stranici plana), a na novom telefonu se vraćaju iz baze.
- **Testovi:** `test/training_plans_test.dart`.

### Status faze 2 (video po vežbi + pregled u aplikaciji)

- **Video za svaku vežbu je obavezan.** Ista vežba ima jedan video po planu (npr. Squat na danu 1 i danu 8). Builder ima sekciju „Exercise videos“ (upload preko postojećeg Bunny pipeline-a, do 60 s).
- **Proveru radi i baza:** `submit_training_plan` odbija plan ako neka vežba nema video ili je upload pao. Migracija je `20261010090000_training_plan_videos.sql`, tabela `training_plan_exercise_videos`.
- **Gledanje:** kupac na stranici plana tapne vežbu i gleda video. U aktivnom treningu pored vežbe iz plana stoji dugme „How to“.
- **Admin pregled u aplikaciji:**
  - admini su upisani u `app_admins`;
  - Train → Training plans → **Review (N)** u gornjem desnom uglu (vidi ga samo admin);
  - admin otvara plan, gleda videe i bira **Approve** ili **Request changes** sa napomenom, koju kreator vidi na svom planu.
- **Prvi admin:** nalog `alexZ`. Novi admin se dodaje sa:
  `insert into app_admins (user_id) select id from profiles where username = '<username>';`

### Status faze 2b (sve besplatno je urađeno, plaćeni planovi nisu)

- **Upload videa direktno na svakoj vežbi:** u builder-u svaki dan prikazuje svoje vežbe, a uz svaku stoji Upload/Replace. Ista vežba na više dana deli jedan video.
- **Cover slika** (obavezna, `images` bucket kao slike postova) i **intro video** (obavezan, Bunny). Stranica plana prikazuje cover sa dugmetom „Watch intro“, a karte u prodavnici prikazuju cover.
- **Ocene 1–5 + komentar:** samo ljudi koji su dodali plan u Train i nisu njegov autor. Prosek se računa sam.
- **Istaknuti planovi:** admin na stranici objavljenog plana bira „Admin: feature in store“, a ti planovi su na vrhu Discover-a.
- **Tab „Plans“ na profilu** (mobilni profil) prikazuje objavljene planove tog korisnika.
- **Deljenje:** link `https://gymfeed.io/trainingPlan?id=<id>` otvara plan u aplikaciji na Androidu (App Links), odnosno u web aplikaciji. Na iOS-u za sada otvara web, jer iOS associated domains nisu podešeni za gymfeed.io.
- **Prijava plana:** isti „Report“ tok kao za postove (`content_type = training_plan`).
- **Zaštita:** objavljen plan ne može da se menja direktno, samo kroz uređivanje i ponovno slanje.
- Migracija je `20261010120000_training_plan_media_and_ratings.sql` (puštena u produkciju).

**Odobravanje bez aplikacije** (i dalje radi) — u Supabase SQL editoru:
```sql
select id, title, seller_id, created_at from training_plans where status = 'in_review';
select review_training_plan('<id>', true, '');                          -- odobri
select review_training_plan('<id>', false, 'Dodaj bar 3 vežbe po danu');  -- vrati na doradu
```
Kada je prodavcu odobren prvi plan, sledeći planovi se objavljuju odmah.

**Zašto prvo besplatni planovi:** ceo tok (pravljenje → objava → dodavanje u Train → raspored) se testira i pušta bez App Store review-a za plaćanje, bez pravnih papira i bez isplata. Ljudi počnu da prave planove dok se priprema plaćeni deo.

## 9. Šta mi treba od tebe

**Odluke**
1. **Podela prihoda:** A, B, C ili kombinacija (§5.3).
2. Da li važi cena **9,99 $** za sve i da li su dozvoljeni **besplatni planovi** (preporuka: da).
3. **Ko sme da prodaje:** svako, ili samo verifikovani nalozi (postoji verification-first signup)? Preporuka: prave svi, prodaju samo verifikovani sa 18+.
4. **Prag i učestalost isplate** (preporuka: 25 $, mesečno, 30 dana čekanja).

**Firma, novac, pravno**
5. **U kojoj zemlji je registrovana firma** koja prima novac od Apple-a/Google-a? Od toga zavisi da li je moguć Stripe ili ide Trolley/ručno, i koji poreski papiri trebaju.
6. Da li si u Apple **Small Business Program-u** (15%)? Ako nisi, prijavi se.
7. **Uslovi za prodavce** i dopuna Terms of Service: radi pravnik. Ja mogu da napišem nacrt kao polaznu tačku.
8. Razgovor sa **knjigovođom** o tome kako se vode isplate prodavcima.

**Store i alati (moraš ti, ja nemam pristup)**
9. App Store Connect i Google Play: napraviti consumable proizvod `gf_plan_unlock` (9,99 $). U RevenueCat-u ga dodati i napraviti mi **secret API key (v2)** za proveru kupovina u edge funkciji.
10. Sandbox testeri: Apple sandbox nalog + Google license tester.
11. Supabase: smem li migracije direktno na production ili prvo na branch/staging?

**Dizajn i sadržaj**
12. Da li imaš dizajn za Plans, ili da ga uradim u stilu Train ekrana?
13. 2–3 tvoja plana za start, da prodavnica ne bude prazna prvog dana.

## 10. Rizici

- **Apple review:** consumable token model je dozvoljen, ali review zavisi od toga kako ga objasnimo. Zato u napomeni za review piše: „Users buy a plan unlock that is immediately redeemed for the selected creator plan and permanently tied to their account.“
- **Prevare:** prodavac kupuje sopstvene planove ukradenim karticama. Zaštite su 30 dana čekanja, zabrana kupovine sopstvenog plana i praćenje refundacija.
- **Kvalitet:** loši planovi kvare prodavnicu. Zaštite su pregled prvog plana, ocene i istaknuti planovi koje biraš ti.

## 11. Influenceri i affiliate kodovi

Influenceri koriste isti marketplace, samo uz podršku:
- istaknuto mesto u prodavnici;
- pomoć pri pravljenju prvog plana;
- **affiliate kod** za Premium pretplatu: 30% neto u prvih 12 meseci, „1 mesec besplatno“ za pratioce, bonus na 500 pretplata.

Kod se unosi na paywall-u ili preko linka `gymfeed.io/c/<kod>`, RPC `claim_creator_code` ga upisuje, a webhook pri `INITIAL_PURCHASE`/`RENEWAL` upisuje proviziju u isti `seller_ledger`, pa isplata ide istim putem. Detalji tabela: `creator_codes`, `creator_attributions` (jedan kod po korisniku, prvi važi).

Outreach bot u `marketing/src/outreach/offer.mjs` trenutno opisuje „Creator Programs“ sa 100% neto prihoda. Kad odlučiš o podeli (§5.3), ponudu treba uskladiti sa marketplace-om.
