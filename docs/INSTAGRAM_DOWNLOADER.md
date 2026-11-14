# Preuzimanje Instagram profila

`scripts/download_instagram.py` koristi Apify Instagram Scraper. Potreban je Python 3.11+;
Python biblioteke se ne instaliraju. Instagram prijava i pristup Chrome-u nisu potrebni.
Apify nalog, API ključ i raspoloživ kredit jesu potrebni.

## Jednokratno podešavanje

1. Napravi nalog na https://console.apify.com/ i proveri raspoloživ kredit.
2. U **Settings > API & Integrations** pronađi svoj API token.
3. Iz korena ovog projekta pokreni `powershell -File scripts/setup_instagram.ps1`.
   Unesi ključ u lokalni skriveni prompt. Nemoj ga slati u chat niti unositi u Git.
   Čuva se kao Windows korisnička promenljiva okruženja `APIFY_TOKEN`, dostupna procesima
   tog korisnika; nije šifrovani trezor. Skripta je čita i bez ponovnog pokretanja terminala.

## Pokretanje

```powershell
python scripts/download_instagram.py "https://www.instagram.com/fiit/"
```

Podrazumevani folder je Windows Desktop/fiit (podržan i preusmeren/OneDrive Desktop).
Za drugi profil menjaš samo URL. `--output` može da promeni folder.

- Uzimaju se prve 20 medijske stavke iz do 20 objava, sortiranih po datumu od najnovijih.
  Pinovane objave ne dobijaju prednost. Servis može vratiti objave pomešanim redosledom;
  sortiranje se zato radi lokalno, pre brojanja i preuzimanja 20 medijskih fajlova.
- Svaka stavka karusela računa se pojedinačno. Video thumbnail se ne broji kao fotografija.
  Reels koji nisu u feedu profila nisu zasebno pretraživani.
- `manifest.json` čuva originalni caption, datum, izvor, rezultat, veličinu i SHA-256 svakog fajla.
- Skripta proverava potpis fajla. Ako postoji FFmpeg (na PATH ili u ovom projektu),
  dekodira video radi provere i spaja zasebnu audio traku kada je servis dostavi.
  `has_audio` u manifestu beleži rezultat; skripta ne dodaje zvuk izvornom tihom videu.
- Ponovno pokretanje koristi sačuvani Apify run i preskače fajlove sa ispravnim checksumom.
  Ne kreira automatski novi naplativi run. Ako su CDN linkovi istekli, pregledaj run u
  Apify Console; uklanjanje `.apify-run.json` namerno pokreće novi naplativi run.
- Podrazumevani limit troška po run-u je **0,10 USD**. Ako servis stane zbog limita,
  proveri naplatu pre novog run-a. Opcija `--max-cost-usd` važi samo pri kreiranju run-a.
- Izlazni kod: `0` = svih 20 sačuvano, `2` = delimično, `1` = greška/podešavanje nedostaje.
  Manje dostupnog sadržaja se jasno prijavljuje kao delimičan rezultat.

## Stanje provere

Direktan anonimni pokušaj za `fiit` 7. novembra 2026. završio se sa 0 fajlova.
Apify pristup profilu `fiit` je potvrđen 7. novembra 2026: servis je vratio 20 objava
sa captionima i medijskim linkovima. API ključ se čuva lokalno u korisničkom okruženju.
Stvarno preuzimanje je završeno: Desktop/fiit sadrži 17 fotografija i 3 MP4 videa,
ukupno 20 fajlova (9.312.353 bajta), sortiranih od najnovijih objava. Sve fotografije
i videi su uspešno dekodirani, sva 3 videa imaju audio traku, a captioni i SHA-256
provere sačuvani su u manifestu. Jedan Apify run naplaćen je 0,054 USD; ponovno
čitanje istog run-a nije pokrenulo novi scraper.
Lokalni testovi proveravaju preuzimanje, brojanje karusela, cap od 20, captione,
nastavak rada i odbijanje HTML stranice umesto medija. Oni ne dokazuju dostupnost Instagrama.

Dokumentacija servisa:
- https://apify.com/apify/instagram-scraper
- https://apify.com/apify/instagram-scraper/api
- https://docs.apify.com/api/v2/actors-runs-post
- https://docs.apify.com/api/v2/dataset-items-get
