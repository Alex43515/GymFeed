# Gymfeed seed i prvi kreatori

## Večeras, 5. novembar

| Kada | Šta radimo | Gotovo kada |
| --- | --- | --- |
| Prvih 30 min | Otvori prvih 15 kandidata sa [liste](../outputs/creator-seed-2026-11-05/gymfeed-instagram-100.csv). Pogledaj poslednja tri reelsa po profilu, pa pošalji DM kandidatima koji imaju svoj snimak treninga. | U postojećem `Influencer Outreach` tabu beležiš status i link ka konkretnom reelsu koji želiš. |
| Sledećih 45–60 min | Složi probnu turu za 5 demo profila na stagingu. Uzmi sopstvene ili licencirane fotografije i snimke. Proveri da feed prikaže sliku, video objavu i profil autora, a FitClips pusti vertikalni trening. | Broj zapisa se slaže sa manifestom. Video ima thumbnail, pusti se na telefonu i ima ispravnog autora. |
| Ostatak večeri | Proširi staging seed na 25 pa na 100 kad probna tura prođe. Ako stigne prvo odobrenje i materijal, pripremi jedan stvarni paket i pošalji kreatoru pregled. | Ponovljeno pokretanje daje nula duplikata. Možeš da povučeš jedan batch i vratiš staging na početno stanje. |

Lista sadrži 100 jedinstvenih Instagram handle-ova iz javnih direktorijuma. Instagram je ograničio direktnu proveru profila, pa su javna dostupnost, poslednja aktivnost, autorstvo konkretnih klipova i jezik za DM za ručnu proveru. Redosled prvih 15 daje prednost manjim autorima i pokriva teretanu, kućni trening, snagu, kalisteniku i Pilates. [Virev](https://virev.ai/blog/micro-fitness-influencers) · [Klint Micro](https://tryklint.ai/influencers/fitness/micro/) · [Klint Instagram](https://tryklint.ai/influencers/instagram/fitness/) · [IQFluence](https://iqfluence.io/public/top-influencers/spanish-fitness-influencers) · [Influencers Worship](https://influencersworship.com/calisthenics_instagram_influencers/)

## Šta ide u seed

Za staging koristi 100 izmišljenih profila, obeleženih kao demo. Svaki ima avatar, bio i jezik, a raspodela aktivnosti varira kroz 30 dana. Predlog je 70 profila na engleskom, 20 na španskom i 10 na drugim jezicima.

| Tip profila | Profila | Foto objava po profilu | Video objava po profilu | Treninga sa videom po profilu |
| --- | ---: | ---: | ---: | ---: |
| Povremeni | 45 | 2 | 1 | 1 |
| Redovni | 35 | 3 | 1 | 2 |
| Kreatori i treneri | 20 | 5 | 2 | 4 |
| Ukupno | 100 | 295 | 120 | 195 |

Za javni launch kreiraj uvoz na Gymfeed nalog koji kreator otvori ili potvrdi, uz potpis i link ka originalu prema dogovoru. Prvi cilj je 5–10 kreatora sa paketom od **1 avatara, 3 fotografije i 3 reelsa**, od kojih bar jedan prikazuje ceo trening ili daje jasna uputstva za vežbe. Za svež feed rasporedi dogovorene objave kroz nekoliko dana. Broj javnih naloga zavisi od broja potvrđenih saradnji.

## Kako Gymfeed treba da upiše sadržaj

- **Profil i feed.** Profil ide u `profiles`, fotografije u postojeći `images` bucket, a foto i obične video objave u `posts`. Za video koristi postojeći tok `create-upload` i Bunny TUS. Sačekaj da `media_assets` pređe u `ready` i poveži asset i thumbnail.
- **Treninzi i FitClips.** Trening sa snimkom ide u `user_trainings` sa naslovom, opisom i `video_asset_id`. FitClips čita tu tabelu. Instagram reel može da ide ovde kada zaista prikazuje trening. Struktuirane rutine sa serijama, ponavljanjima i odmorom pripremi iz kreatorovih potvrđenih instrukcija ako želi da ih korisnici mogu pokrenuti iz aplikacije.
- **Seeder za staging.** Postojeći [seed_content.mjs](../scripts/seed_content.mjs) pravi pet profila i dodaje nove `posts` pri svakom pokretanju. Za batch od 100 treba verzionisan manifest sa stabilnim ID-jevima, eksplicitan staging URL i `--dry-run`. Vodi evidenciju ID-jeva profila, objava, treninga i Storage/Bunny objekata po batchu radi ponovnog pokretanja i čišćenja.
- **Provera.** Testiraj feed, profil i FitClips kao običan ulogovani korisnik. Proveri ispravnog autora, titlove, thumbnail i reprodukciju na telefonu. Prekini jedan video upload, nastavi isti batch i proveri da ostane jedan asset i jedan zapis. Proveri i povlačenje probne ture zajedno sa medijima.

## Kako stiže materijal od kreatora

1. Kreator potvrdi konkretne linkove i da li možemo da koristimo avatar, ime, opis, klipove i titlove na Gymfeedu. Sačuvaj referencu na potvrdu i dogovoreni kredit. Za reel sa muzikom ili gostima traži verziju koju kreator može da odobri za objavu na Gymfeedu, po potrebi čist video sa originalnim govorom.
2. Za prvu turu kreator šalje originalne fajlove ili izvoz iz **Accounts Center** koji sadrži dogovorene objave. Direktno preuzimanje sa Instagram profila je zasebna integracija. Meta traži dozvolu za automatizovano prikupljanje čak i kad je sadržaj vidljiv javno. Za veći obim predvidi **Instagram Login** za profesionalne naloge, autorizaciju svakog kreatora i izbor konkretnih media ID-jeva. [Meta Accounts Center](https://about.fb.com/news/2023/10/manage-your-information-across-apps/) · [Meta Instagram API](https://www.postman.com/meta/instagram/collection/6yqw8pt/instagram-api) · [Meta o automatizovanom prikupljanju](https://about.fb.com/news/2021/04/how-we-combat-scraping/)
3. Pokreni [skriptu za pripremu medija](../scripts/stage_creator_media.py) sa lokalnim ZIP-om ili folderom. Kopira tačno fajlove iz manifesta u novi batch, sa SHA-256 i referencom na dozvolu. U ovoj fazi materijal ostaje lokalno. Provera kodeka, transkodiranje i upload u Gymfeed su naredni koraci.

Primer `approval.json`. Stavi tačne relativne putanje iz foldera ili ZIP-a, a za svaki odobreni fajl dodaj jedan red u `assets`.

```json
{
  "handle": "example_coach",
  "consent_ref": "outreach-2026-11-05-example-coach",
  "assets": [
    {"file": "avatar.jpg", "kind": "avatar"},
    {"file": "photos/gym.jpg", "kind": "photo"},
    {"file": "clips/upper-body.mp4", "kind": "reel", "caption": "Upper body day"}
  ]
}
```

```powershell
python scripts/stage_creator_media.py approval.json creator.zip outputs/seed/example-coach
python scripts/stage_creator_media.py approval.json creator.zip outputs/seed/example-coach --apply
```

Prva komanda je dry run. Posle pripreme proveri dimenzije, trajanje, orijentaciju i audio. Za FitClips ciljaj vertikalni 9:16 i generiši thumbnail iz istog klipa.

## Poruke za prvi kontakt

**EN**

> Hey [name], I’m Aleksandar from Gymfeed. I saw your [specific workout/reel] and I’d love to feature a few of your training posts on Gymfeed. Would you be open to trying it with 3 reels and 3 photos? You pick the posts, we credit you and link to the originals, and you see the preview before anything goes live.

**ES**

> Hola [nombre], soy Aleksandar de Gymfeed. Vi tu [rutina o reel concreto] y me gustaría compartir algunas de tus publicaciones de entrenamiento en Gymfeed. ¿Te animas a probar con 3 reels y 3 fotos? Tú eliges las publicaciones, te damos crédito con enlace a los originales y puedes revisar todo antes de publicarlo.
