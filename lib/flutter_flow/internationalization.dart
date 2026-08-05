import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'sr'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? srText = '',
  }) =>
      [enText, srText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // Feed
  {
    '8hvfxm0f': {
      'en': 'GymFeed',
      'sr': 'GymFeed',
    },
    'rcya004l': {
      'en': '',
      'sr': '1',
    },
    'nbpjjjx7': {
      'en': '',
      'sr': '1',
    },
    'ri7h4z57': {
      'en': 'Your gym day',
      'sr': 'Tvoja priča',
    },
    'eramvpcj': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Notifications
  {
    'r2feecfs': {
      'en': 'Notifications',
      'sr': 'Obaveštenja',
    },
    'ep50da7k': {
      'en': 'New',
      'sr': 'Novo',
    },
    'l3sek4ds': {
      'en': 'Today',
      'sr': 'Danas',
    },
    'lu0b9e7b': {
      'en': 'This Week',
      'sr': 'Ove Nedelje',
    },
    '0dt1z197': {
      'en': 'This Month',
      'sr': 'Ovog meseca',
    },
    'l6qk1j9r': {
      'en': 'Earlier',
      'sr': 'Ranije',
    },
    '5ikgk6bb': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Search
  {
    'sj4au3sp': {
      'en': 'Search',
      'sr': 'Traži',
    },
    'adv46abx': {
      'en': 'Cancel',
      'sr': 'Otkaži',
    },
    'nzez13l1': {
      'en': 'Profiles',
      'sr': 'Profili',
    },
    '19tk1teb': {
      'en': 'Images',
      'sr': 'Slike',
    },
    'hjq4tvo4': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Profile
  {
    '66b42tj6': {
      'en': 'Edit profile',
      'sr': 'Uredi profil',
    },
    'n4zw6om7': {
      'en': 'Share Profile',
      'sr': 'Podeli profil',
    },
    'zpuo4hdx': {
      'en': 'Level',
      'sr': 'Nivo',
    },
    'rnzbd532': {
      'en': 'Followers',
      'sr': 'Pratilaca',
    },
    'pfuriiwh': {
      'en': 'Following',
      'sr': 'Prati',
    },
    'sxoptvz5': {
      'en': 'Posts',
      'sr': 'Postovi',
    },
    '49ij6m19': {
      'en': 'Tagged',
      'sr': 'Tagovani',
    },
    'udvxuaaw': {
      'en': 'Workout',
      'sr': 'Trening',
    },
    '4yyxcsyv': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    'fu2oct6y': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    'f4l7x8g4': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'tb1xnw4m': {
      'en': '@username',
      'sr': '@korisničkoime',
    },
    'ki2frwuu': {
      'en': '4',
      'sr': '4',
    },
    '220zvw85': {
      'en':
          'I\'m back with a super quick Instagram redesign just for the fan. Rounded corners and cute icons, what else do we need, haha.⁣ ',
      'sr':
          'Вратио сам се са супер брзим редизајн Инстаграма само за обожаваоце. Заобљени углови и слатке иконе, шта нам још треба, хаха.⁣',
    },
    'vt8ba8ez': {
      'en': 'Profile',
      'sr': 'Profil',
    },
  },
  // Comments
  {
    'e00yfq1z': {
      'en': 'Comments',
      'sr': 'Komentari',
    },
    'qxuqupi8': {
      'en': ' ',
      'sr': '',
    },
    'x23iq6vu': {
      'en': ' ',
      'sr': '',
    },
    'c8prcmaq': {
      'en': 'Send',
      'sr': 'Pošalji',
    },
    'df1l3y2d': {
      'en': 'Delete',
      'sr': 'Izbrši',
    },
    '8hg5yg0f': {
      'en': 'Post',
      'sr': 'Postavi',
    },
    '5qksggbd': {
      'en': 'Sorry, this post isn\'t\navailable.',
      'sr': 'Žao mi je, ovaj post nije dostupan.',
    },
    'dx5wp7r6': {
      'en':
          'The link you followed may be broken, or the post may have been removed.',
      'sr':
          'Link koji ste pratili je možda neispravan ili je objava uklonjena.',
    },
    '866612rm': {
      'en': 'Go back.',
      'sr': 'Idi nazad.',
    },
    'qbnhdw4u': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // PostDetails
  {
    'jih60or0': {
      'en': '@',
      'sr': '',
    },
    'f30go95t': {
      'en': 'Sorry, this post isn\'t\navailable.',
      'sr': 'Žao mi je, ovaj post nije dostupan.',
    },
    'hw3tmkr1': {
      'en':
          'The link you followed may be broken, or the post may have been removed.',
      'sr':
          'Link koji ste pratili je možda neispravan ili je objava uklonjena.',
    },
    'ax91shfz': {
      'en': 'Go back.',
      'sr': 'Idi nazad.',
    },
    'maz0xtrj': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // NewPost
  {
    'gfmx68cs': {
      'en': 'Write a caption...',
      'sr': 'Napiši naslov...',
    },
    'gxi7alpn': {
      'en': 'Tag people',
      'sr': 'Taguj prijatelje',
    },
    'ptiby4zd': {
      'en': 'Add call to action',
      'sr': 'Dodaj poziv na akciju',
    },
    'e4am1fw6': {
      'en': 'Select Location',
      'sr': '',
    },
    'f0mknr3m': {
      'en': 'Hide like and view counts on post',
      'sr': 'Sakrij broj lajkova i pregleda na objavama.',
    },
    'ps023jux': {
      'en': 'Hide comments on post',
      'sr': 'Sakrij komentare na postu',
    },
    'fdoyg1po': {
      'en':
          'Please note that all videos over 60 seconds\nwill be rejected upon upload',
      'sr': 'Dodaj sliku ili video',
    },
    'nd2x9kdy': {
      'en': 'Add image or video',
      'sr': '',
    },
    'y1m6bx5t': {
      'en': 'Image',
      'sr': 'Slika',
    },
    'o3o8qzcf': {
      'en': 'Delete image',
      'sr': 'Obriši sliku',
    },
    'cswrimin': {
      'en': 'Video',
      'sr': 'Video',
    },
    'biusty2j': {
      'en': 'Delete video',
      'sr': 'Obriši video',
    },
    '0g3q6m84': {
      'en': 'New post',
      'sr': 'Nova objava',
    },
    'h38vk44z': {
      'en': 'Share',
      'sr': 'Podeli',
    },
    '7qj33ncu': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // CallToAction
  {
    'vdu7d5s5': {
      'en': 'Call to action button',
      'sr': 'Dugme za poziv za akciju',
    },
    '5vedkjk5': {
      'en':
          'Create a call to action button that will appear at the bottom of your uploaded image.',
      'sr':
          'Napravite dugme za poziv na akciju koje će se pojaviti na dnu otpremljene slike.',
    },
    '4kfct2pl': {
      'en': 'Button text',
      'sr': 'Tekst dugmenta',
    },
    'mqnobewa': {
      'en': 'Button text',
      'sr': 'Tekst dugmenta',
    },
    '3i3f1gyn': {
      'en': 'Button link',
      'sr': 'Link dugme',
    },
    'mmpl5cbc': {
      'en': 'Button link',
      'sr': 'Link dugme',
    },
    'a2y8rby4': {
      'en': 'Button text is required.',
      'sr': 'Tekst dugmeta je obavezan',
    },
    'b4zcr80v': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opcije iz padajućeg menija',
    },
    '1qk8qp3g': {
      'en': 'Button link is required.',
      'sr': 'Link na dugmetu je obavezan.',
    },
    't6k6tpc1': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opcije iz padajućeg menija',
    },
    'd48gz29f': {
      'en': 'Call to action',
      'sr': 'Poziv na akciju',
    },
    '3c20dj3q': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
    '8wmty495': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Location
  {
    'ev8aef5r': {
      'en': 'Add a location',
      'sr': 'Dodajte lokaciju',
    },
    'irx732pm': {
      'en':
          'Add a location so users know where your photo was taken or what it might be a picture of.',
      'sr':
          'Dodajte lokaciju kako bi korisnici znali gde je vaša fotografija snimljena ili šta bi mogla biti slika.',
    },
    '5l9eudq6': {
      'en': 'Location',
      'sr': 'Lokacija',
    },
    'olyw413i': {
      'en': 'Location',
      'sr': 'Lokacija',
    },
    '3pfcihv9': {
      'en': 'Location is required.',
      'sr': 'Lokacija je oabavezna.',
    },
    'okzhxam5': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    'fbncfi46': {
      'en': 'Location',
      'sr': 'Lokacija',
    },
    'bluqhn9l': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
    'sk6gm0oc': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SignUp
  {
    '5dnx8uma': {
      'en': 'GymFeed',
      'sr': 'GymFeed',
    },
    'zy4lw4ue': {
      'en':
          'Sign up to get your custom meal and workout plan and enjoy the community',
      'sr':
          'Prijavite se da biste dobili prilagođeni plan obroka i vežbanja i uživajte u zajednici.',
    },
    '9b5yofhd': {
      'en': 'Email Address',
      'sr': 'Email adresa',
    },
    'hspqdm99': {
      'en': 'Email address is required.',
      'sr': 'Adresa email je obavezna.',
    },
    'hmw244u5': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    'eh5bs813': {
      'en': 'Next',
      'sr': 'Sledeca',
    },
    'n93hna0c': {
      'en': 'Already have an account?',
      'sr': 'Već imate nalog?',
    },
    'ip07md2h': {
      'en': 'Sign In.',
      'sr': 'Prijavi se.',
    },
    '60lnokwh': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SignIn
  {
    'l27my6dz': {
      'en': 'Welcome Back,',
      'sr': 'Dobrodošli nazad,',
    },
    '0gehgc8q': {
      'en': 'Sign in your email and pasword to continue',
      'sr':
          'Prijavite se svojom adresom e-pošte i lozinkom da biste nastavili.',
    },
    'mqgf0hf0': {
      'en': 'Email Address',
      'sr': 'E-adresa',
    },
    '3ee6nru5': {
      'en': 'Password',
      'sr': 'Lozinka',
    },
    'b47mdvcl': {
      'en': 'Forgot password?',
      'sr': 'Zaboravili ste lozinku?',
    },
    'e748v53d': {
      'en': 'Email address is required.',
      'sr': 'E-adresa je obavezna.',
    },
    '19k38q71': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    '8jbkfhre': {
      'en': 'Pasword is required.',
      'sr': 'Lozinka je obavezna.',
    },
    'gmixmb6m': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    '2es19ing': {
      'en': 'Log in',
      'sr': 'Prijavi se',
    },
    'ex6iu87r': {
      'en': 'Don\'t have an account?',
      'sr': '',
    },
    'pe2ksmga': {
      'en': 'Sign Up.',
      'sr': '',
    },
    'yep8ih4h': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SignUp_Name
  {
    'nw9wbj91': {
      'en': 'Add Your Name',
      'sr': 'Dodaj svoje ime',
    },
    'ea99utla': {
      'en': 'Add your name so friends can find you.ody',
      'sr': 'Dodajte svoje ime kako bi vas prijatelji mogli pronaći.',
    },
    'qoz8t5op': {
      'en': 'Full Name',
      'sr': 'Puno ime',
    },
    '5hu0udtk': {
      'en': '',
      'sr': 'Biografija (recite nam nešto o sebi)',
    },
    'v2kabbcl': {
      'en': 'Bio (tell people about you)',
      'sr': 'Biografija (recite nam nešto o sebi)',
    },
    'o6wzktwf': {
      'en': 'Full name is required.',
      'sr': 'Puno ime je obavezno.',
    },
    '1ywee5el': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    'fnah2ho0': {
      'en': 'Next',
      'sr': 'Sledeća',
    },
    'arozyh0i': {
      'en': 'Already have an account?',
      'sr': 'Već imate nalog?',
    },
    '0l4ltmjr': {
      'en': 'Sign In.',
      'sr': 'Prijavi se.',
    },
    '91w8r9s9': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SignUp_Password
  {
    'akcdmbl2': {
      'en': 'Create a Password',
      'sr': 'Napravite lozinku',
    },
    'sd0k5jap': {
      'en':
          'Create a password that is secure and private so you can login to your account in the future.',
      'sr':
          'Napravite lozinku koja je sigurna i privatna kako biste se ubuduće mogli prijaviti na svoj nalog.',
    },
    's79x8n26': {
      'en': 'Password',
      'sr': 'Lozinka',
    },
    'srvzmhfv': {
      'en': 'Password is required.',
      'sr': 'Lozinka je obavezna.',
    },
    '6dtzogga': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    'd43ulysq': {
      'en': 'Next',
      'sr': 'Sledeca',
    },
    'qv5e35xi': {
      'en': 'Already have an account?',
      'sr': 'Već imate nalog?',
    },
    '3r27m7tr': {
      'en': 'Sign In.',
      'sr': 'Prijavi se.',
    },
    'nk1evq8x': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SignUp_Birthday
  {
    'ckth8jjb': {
      'en': 'Add Your Birthday',
      'sr': 'Dodajte svoj rodjendan',
    },
    'xowllirn': {
      'en': 'This wont be part of your public profile.',
      'sr': 'Ovo neće biti deo vašeg javnog profila.',
    },
    'x410ynvc': {
      'en': 'Next',
      'sr': 'Sledeće',
    },
    '1o822f0x': {
      'en':
          'Use your own birthday, even if this account is for a business, a pet or something else.',
      'sr':
          'Koristite svoj rodjendan, čak iako je ovo nalog za posao, kućnog ljubimca ili bilo šta drugo.',
    },
    'rton32ef': {
      'en': 'Already have an account?',
      'sr': 'Već imate nalog?',
    },
    'd8oi78eg': {
      'en': 'Sign In.',
      'sr': 'Prijavite se.',
    },
    'yx4grlmp': {
      'en': 'Home',
      'sr': 'Početak',
    },
  },
  // SignUp_Username
  {
    '5fe4t445': {
      'en': 'Create Username',
      'sr': 'Kreirajte korisničko ime',
    },
    'vsbgxz5t': {
      'en':
          'Pick a username for your new account. You can always change it later.',
      'sr':
          'Izaberite korisničko ime za svoj novi nalog. Uvek ga možete promeniti kasnije.',
    },
    '2rkdove2': {
      'en': 'Username',
      'sr': 'Korisničko ime',
    },
    'fmaro2c1': {
      'en': 'Next',
      'sr': 'Sledeca',
    },
    'hb4n4bxl': {
      'en': 'Already have an account?',
      'sr': 'Već imate nalog?',
    },
    'icocz29l': {
      'en': 'Sign In.',
      'sr': 'Prijavi se.',
    },
    'ygh3r1wx': {
      'en': 'Username is required.',
      'sr': 'Korisničko ime je obavezno.',
    },
    '0h9rulr2': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    '3ny2wuux': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SignUp_UsernameConfirmation
  {
    'h8w37a6n': {
      'en': 'Sign up as',
      'sr': 'Prijavi se kao',
    },
    'azv8u5az': {
      'en': 'You can always change your username later.',
      'sr': 'Uvek možete promeniti svoje korisničko ime kasnije.',
    },
    '3hfsjhvf': {
      'en':
          'Before tapping Sign up, you need to agree to our Terms, Privacy Policy and Cookies Policy.',
      'sr':
          'Pre nego što tapnete na Registruj se, morate da prihvatite naše uslove, politiku privatnosti i politiku kolačića.',
    },
    'gi29icf3': {
      'en': 'User Policy',
      'sr': 'Politika privatnosti',
    },
    'wh7pmi3c': {
      'en': 'Continue',
      'sr': 'Prijavi se.',
    },
    'slzrhsj6': {
      'en': 'Already have an account?',
      'sr': 'Već imate nalog?',
    },
    'af0p2pxv': {
      'en': 'Sign In.',
      'sr': 'Prijavi se.',
    },
    '74hubav1': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // TagUsers
  {
    'l45r3ba7': {
      'en': 'Tag users',
      'sr': 'Taguj korisnika',
    },
    'ewight4d': {
      'en': 'Tag users so others know who is shown in the photo.',
      'sr':
          'Označite korisnike kako bi drugi znali ko je prikazan na fotografiji.',
    },
    '7kxma8xx': {
      'en': 'Location is required.',
      'sr': 'Lokacija je obavezna.',
    },
    'h93504eg': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    'uuvj5mvl': {
      'en': 'Tag users',
      'sr': 'Taguj korisnika',
    },
    '1u6kanvb': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
    '5z2x47hw': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // SelectTaggedUsers
  {
    'sbjxj84y': {
      'en': 'Select users',
      'sr': 'Izaberite korisnika',
    },
    '4pt3didt': {
      'en': 'Search for a person',
      'sr': 'Potražite osobu',
    },
    'b8an91bf': {
      'en': 'Cancel',
      'sr': 'Otkaži',
    },
    '3m2bmf8d': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // ProfileOther
  {
    'zm41tzrh': {
      'en': 'Message',
      'sr': 'Poruka',
    },
    'l6zbnbid': {
      'en': 'Message',
      'sr': 'Poruka',
    },
    'rmn8ix5j': {
      'en': 'Message',
      'sr': 'Pošalji poruku',
    },
    '4fy6g1gm': {
      'en': 'Level',
      'sr': 'Nivo',
    },
    'l4yq21yh': {
      'en': 'Followers',
      'sr': 'Pratilaca',
    },
    'taf8pvzf': {
      'en': 'Following',
      'sr': 'Prati',
    },
    '1ns1kqpw': {
      'en': 'Posts',
      'sr': 'Objave',
    },
    'suueoyxj': {
      'en': 'Tagged',
      'sr': 'Označeni',
    },
    'rbxccos2': {
      'en': 'Workout',
      'sr': 'Treninzi',
    },
    'tkv1vzm1': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    'iak9oa9k': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    'uv3hr95i': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'q5gngh7o': {
      'en': '@username',
      'sr': '@korisnicko ime',
    },
    'auybfyy8': {
      'en': '4',
      'sr': '4',
    },
    '0n21kp8k': {
      'en': '',
      'sr': '',
    },
    'y5y8ii21': {
      'en': 'Profile',
      'sr': 'Profil',
    },
  },
  // EditProfile
  {
    'y2tvfsol': {
      'en': 'Edit profile',
      'sr': 'Uredi profil',
    },
    'nqa7zerc': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
    'k0f359nx': {
      'en': 'Cancel',
      'sr': 'Otkaži',
    },
    '383js2jj': {
      'en': 'Edit picture',
      'sr': 'Uredi sliku',
    },
    'wvvkjmwr': {
      'en': 'Full Name',
      'sr': 'Puno ime',
    },
    '0i5unt2h': {
      'en': 'Full Name',
      'sr': 'Puno ime',
    },
    'qwyeepq5': {
      'en': 'Email',
      'sr': 'Email',
    },
    'djyleecl': {
      'en': 'Username',
      'sr': 'Koriscniko ime',
    },
    '1jrejrrz': {
      'en': 'Email address is required.',
      'sr': 'Email adresa je obavezna.',
    },
    'juy3kies': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg menija',
    },
    'y01gmh0n': {
      'en': 'Bio',
      'sr': 'Bio',
    },
    'g09rtndf': {
      'en': 'Bio',
      'sr': 'Bio',
    },
    'cgz3bqhz': {
      'en': 'Website',
      'sr': 'Web sajt',
    },
    'ofr5n4he': {
      'en': 'Website',
      'sr': 'Web sajt',
    },
    'qf8ati0c': {
      'en': 'Profile information',
      'sr': 'Informacije o profilu',
    },
    'aglyk735': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // FollowersFollowing
  {
    'zefbbdnz': {
      'en': '  •  ',
      'sr': '•',
    },
    '9d0w5a7m': {
      'en': 'Follow',
      'sr': 'Pratite',
    },
    'o5i03spo': {
      'en': 'Remove',
      'sr': 'Uklonite',
    },
    '416374bw': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // FollowersFollowingOther
  {
    'nup3f36c': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // EditPost
  {
    'oa6pkmqq': {
      'en': 'Edit info',
      'sr': 'Uredi post',
    },
    '96ddolcf': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
    'toqbooea': {
      'en': 'Cancel',
      'sr': 'Otkaži',
    },
    'r3ipo7ga': {
      'en': 'Add a caption...',
      'sr': 'Dodajte naslov...',
    },
    'gkuft5hw': {
      'en': 'Select Location',
      'sr': '',
    },
    '5igc6un2': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Messages
  {
    'ds56s33p': {
      'en': '  •  ',
      'sr': '•',
    },
    '2at2abnm': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // NewMessage
  {
    've7ks3hc': {
      'en': 'Search',
      'sr': 'Traži',
    },
    'x9weosgb': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // IndividualMessage
  {
    '2mcbm88f': {
      'en': ' ',
      'sr': '',
    },
    'kb0c8vdh': {
      'en': ' ',
      'sr': '',
    },
    'z5jbckj7': {
      'en': ' ',
      'sr': '',
    },
    'mpxhbf9a': {
      'en': ' ',
      'sr': '',
    },
    'h2kcau4t': {
      'en': 'Message...',
      'sr': 'Poruka...',
    },
    'vityl4ga': {
      'en': 'Send',
      'sr': 'Pošalji',
    },
    'khm1yjzb': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Get_Started
  {
    'hoilc5d8': {
      'en': 'Image Sharing Social Media App',
      'sr': 'Апликација за дељење слика на друштвеним мрежама',
    },
    '5nltg63s': {
      'en':
          'This template is essentially ready to use out of the box except for one API. Watch the video below on how to set up the API, or follow instructions in the video to delete it:',
      'sr':
          'Овај шаблон је у суштини спреман за употребу из кутије осим једног АПИ-ја. Погледајте видео испод о томе како да подесите АПИ или пратите упутства у видеу да бисте га избрисали:',
    },
    'encg5aha': {
      'en': 'Watch Overview Video',
      'sr': 'Погледајте видео преглед',
    },
    'pik1pf09': {
      'en': 'Watch API Setup Video',
      'sr': 'Погледајте видео о подешавању АПИ-ја',
    },
    '4ojhkduf': {
      'en': 'Home',
      'sr': 'Хоме',
    },
  },
  // assistantGPT
  {
    '3azwpadk': {
      'en': 'Your own personal 24/7 AI\nNutricition & Fitness expert',
      'sr': 'Vaš lični AI 24/7\nstručnjak za ishranu i fitnes',
    },
    'upl25b7g': {
      'en':
          'Here to help and answer all your\nquestions related to nutricitions,\nfitness and workout in general.',
      'sr':
          'Ovde da vam pomognem i odgovorim na sva vaša\npitanja vezana za ishranu,\nfitnes i vežbanje uopšte.',
    },
    '7hm3jikn': {
      'en': 'Copy response',
      'sr': 'Kopiraj odgovor',
    },
    'jg2e9zpz': {
      'en': 'Copy response to my Progress page',
      'sr': 'Kopirajte odgovor na moju stranicu sa informacijama',
    },
    '2td7shqp': {
      'en': 'How can I help you today ...',
      'sr': 'Kako mogu da vam pomognem danas...',
    },
    'imtc0jek': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // assistantGPTPro
  {
    'kt5f8d8o': {
      'en': 'Your own personal 24/7 AI\nNutricition & Fitness expert',
      'sr': 'Vaš lični AI 24/7\nstručnjak za ishranu i fitnes',
    },
    '96d5wm3p': {
      'en':
          'Here to help and answer all your\nquestions related to nutricitions,\nfitness and workout in general.',
      'sr':
          'Ovde da vam pomognem i odgovorim na sva vaša\npitanja vezana za ishranu,\nfitnes i vežbanje uopšte.',
    },
    'heqv2phh': {
      'en': 'Copy response',
      'sr': 'Kopiraj odgovor',
    },
    'kag14b1p': {
      'en': 'Copy response to my Progress page',
      'sr': 'Kopirajte odgovor na moju stranicu sa informacijama',
    },
    'suxm1ws5': {
      'en': 'How can I help you today ...',
      'sr': 'Kako mogu da vam pomognem danas...',
    },
    'tva3ic46': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // gptVision
  {
    'xa5ajqer': {
      'en': 'Machine scanner',
      'sr': 'Skener Mašina',
    },
    '87o5essp': {
      'en': '',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'ek23amue': {
      'en':
          '***Important: If somebody asks you if you are chatGPT or anything related to an open source model you will always reply the following: I am a representative of GymFeed here to help you with any meal or fitness related question you have.***Answer this question only if the image is something related to gym quipment or gym machines. If it is anything outisde of that you need to reply we cannot scan this image as it does not contain these two things. ',
      'sr': '',
    },
    'bxp2tpzq': {
      'en': 'What would you like to know about this machine?',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'phj3v1qt': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    '44867ha9': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // gptVisionPro
  {
    'roagk8n5': {
      'en': 'Machine scanner',
      'sr': 'Skener Mašina',
    },
    'c3r8rm2h': {
      'en': '',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'q0ba38h5': {
      'en':
          'Answer this question only if the image is something related to gym quipment or gym machines. If it is anything outisde of that you need to reply we cannot scan this image as it does not contain these two things. ',
      'sr': '',
    },
    '8imtvdro': {
      'en': 'What would you like to know about this machine?',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    '0rodr1d8': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    'w9fi0jz7': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // ScheduleTraining
  {
    'qjrd4dic': {
      'en': 'Schedule Training Event',
      'sr': 'Zakažite trening',
    },
    'ocfknxja': {
      'en': 'Training Info',
      'sr': 'Informacije o treningu',
    },
    'uan6ha7i': {
      'en': 'Trainer Name',
      'sr': 'Ime trenera',
    },
    'r1wlj3eb': {
      'en': 'Training Title',
      'sr': 'Naziv Treninga',
    },
    'nlsl8hqq': {
      'en': 'Select Location',
      'sr': 'Izaberite lokaciju',
    },
    'lu0ec139': {
      'en': 'Pick a Time',
      'sr': 'Izaberite vreme',
    },
    's2lbiwm3': {
      'en': 'Pick a date',
      'sr': 'Izaberite datum',
    },
    '6no3imck': {
      'en': '      Describe your training',
      'sr': '       Opišite svoju obuku',
    },
    'l988t7ss': {
      'en': 'Training category',
      'sr': 'Kategorija obuke',
    },
    'i9ybrmc2': {
      'en': 'Search for an item...',
      'sr': 'Potražite stavku...',
    },
    '1tl9puwv': {
      'en': 'Cardio',
      'sr': 'Kardio',
    },
    'fy9fur1o': {
      'en': 'Muscle Mass',
      'sr': 'Mišićna masa',
    },
    'oqirygjt': {
      'en': 'Calisthenics',
      'sr': 'Kalisteniks',
    },
    'eunmdrej': {
      'en': 'CrossFit',
      'sr': 'CrossFit',
    },
    '2ibpwpy6': {
      'en': 'Zumba',
      'sr': 'Zumba',
    },
    'pqqb67hg': {
      'en': 'Yoga',
      'sr': 'Joga',
    },
    'das8fm7w': {
      'en': 'Training Level',
      'sr': 'Nivo obuke',
    },
    'xj5nbu8d': {
      'en': 'Search for an item...',
      'sr': 'Pretražite stavku...',
    },
    'no4ivz4x': {
      'en': 'Beginner',
      'sr': 'Početnik',
    },
    'uxu6e7il': {
      'en': 'Intermediate',
      'sr': 'Srednji',
    },
    't1ceswmy': {
      'en': 'Advanced',
      'sr': 'Napredni',
    },
    'c66qd7yn': {
      'en': '      Set duration in minutes',
      'sr': '      Trajanje u minutima',
    },
    'w06b7kn8': {
      'en': 'Upload Image',
      'sr': 'Učitaj sliku',
    },
    '2enbpcg6': {
      'en': 'Upload cover image here',
      'sr': 'Učitaj pozadinsku sliku',
    },
    'o8iqzo0p': {
      'en': 'Delete photo',
      'sr': 'Izbriši fotografiju',
    },
    '0q31cy2t': {
      'en': 'Add a photo',
      'sr': 'Dodajte fotografiju',
    },
    'parftidf': {
      'en': 'Upload Video',
      'sr': 'Dodaj video',
    },
    'jyj1whij': {
      'en': 'Upload workout video here',
      'sr': 'Dodaj video za trening',
    },
    'pzac4zbm': {
      'en': 'All videos over 60 seconds\nwill be rejected upon upload',
      'sr': '',
    },
    'n94ldcnq': {
      'en': 'Delete Video',
      'sr': 'Izbriši video',
    },
    'vu82jjkv': {
      'en': 'Add a Video',
      'sr': 'Dodaj video',
    },
    'ak6fn8qq': {
      'en': ', ',
      'sr': ',',
    },
    'cmyx6313': {
      'en': ', ',
      'sr': ',',
    },
    'n726c48w': {
      'en': ', ',
      'sr': ',',
    },
    'e32mtyu6': {
      'en': 'Schedule a Training',
      'sr': 'Zakaži trening',
    },
    '08vuf3ph': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // editTraining
  {
    '0iwdror9': {
      'en': 'Edit a Training Event',
      'sr': 'Uredi trening',
    },
    '5gyrf83n': {
      'en': 'Training Info',
      'sr': 'Trening Info',
    },
    'ghh3z7zg': {
      'en': 'Trainer Name',
      'sr': 'Ime trenera',
    },
    'bwqu6gy8': {
      'en': 'Pick a Title',
      'sr': 'Izaberite naslov',
    },
    'ljezgrkr': {
      'en': 'Pick a Time',
      'sr': 'Izaberite vreme',
    },
    'wnjguy7f': {
      'en': 'Pick a date',
      'sr': 'Izaberite datum',
    },
    'qihlqd3p': {
      'en': 'Describe your training',
      'sr': 'Opisite svoju obuku',
    },
    '11svtp23': {
      'en': 'Training category',
      'sr': 'Trening kategorija',
    },
    '1rqb1ttj': {
      'en': 'Search for an item...',
      'sr': 'Potražite stavku...',
    },
    'grbmmvjf': {
      'en': 'Cardio',
      'sr': 'Kardio',
    },
    'yh1xnk2c': {
      'en': 'Muscle Mass',
      'sr': 'Mišićna masa',
    },
    'hmcsqxdz': {
      'en': 'Calisthenics',
      'sr': 'Kalistenika',
    },
    'n6yfcief': {
      'en': 'CrossFit',
      'sr': 'CrossFit',
    },
    'jz8m33y9': {
      'en': 'Zumba',
      'sr': 'Zumba',
    },
    '4hqw9dk1': {
      'en': 'Yoga',
      'sr': 'Joga',
    },
    'zwxo3cs4': {
      'en': 'Training Level',
      'sr': 'Nivo obuke',
    },
    '50zy3i48': {
      'en': 'Search for an item...',
      'sr': 'Potražite stavku...',
    },
    '0nrnng04': {
      'en': 'Beginner',
      'sr': 'Početnik',
    },
    'cj6jh7az': {
      'en': 'Intermediate',
      'sr': 'Srednji nivo',
    },
    'd5egdn60': {
      'en': 'Advanced',
      'sr': 'Napredni',
    },
    'n09j3l7x': {
      'en': 'Professional',
      'sr': 'Profesionalno',
    },
    '9z7f0860': {
      'en': 'Select Location',
      'sr': 'Izaberite lokaciju',
    },
    '08v5whqm': {
      'en': 'Enter duration in minutes',
      'sr': 'Unesite trajanje u minutima',
    },
    'gp9eq6kd': {
      'en': 'Upload Image',
      'sr': 'Učitaj sliku',
    },
    's9prvx78': {
      'en': 'Delete photo',
      'sr': 'Izbriši fotografiju',
    },
    'wxx1wwbp': {
      'en': 'Add a photo',
      'sr': 'Dodajte fotografiju',
    },
    'q8dkmpm2': {
      'en': 'Upload Video',
      'sr': 'Dodajte video',
    },
    'dyulwlyb': {
      'en': 'Delete Video',
      'sr': 'Izbriši video',
    },
    'z65bavu7': {
      'en': 'Add a Video',
      'sr': 'Dodajte video',
    },
    '5lnh1fps': {
      'en': ', ',
      'sr': ',',
    },
    'hsly1ul6': {
      'en': ', ',
      'sr': ',',
    },
    '90am1ti5': {
      'en': ', ',
      'sr': ',',
    },
    'mrze4a13': {
      'en': 'Update Scheduled Training',
      'sr': 'Ažurirajte zakazani trening',
    },
    'qxtsurte': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // trainingpostDetails
  {
    '4ub4y33g': {
      'en': 'Withdraw',
      'sr': 'Povuci se',
    },
    'h9733vef': {
      'en': 'Join',
      'sr': 'Pridruži se',
    },
    '38prz7tg': {
      'en': 'No video uploaded',
      'sr': 'Ni jedan video snimak \nnije otpremljen',
    },
    '4zudhrsd': {
      'en': 'Program',
      'sr': 'Program',
    },
    '8kb2o5wk': {
      'en': 'Informations',
      'sr': 'Informacije',
    },
    'isd0cepi': {
      'en': 'Duration',
      'sr': 'Trajanje',
    },
    'uwz9ft7v': {
      'en': 'Category',
      'sr': 'Kategorija',
    },
    'de5zbfss': {
      'en': 'Date',
      'sr': 'Datum',
    },
    'uuh227zk': {
      'en': 'Time',
      'sr': 'Vreme',
    },
    '67mgovgf': {
      'en': 'Level',
      'sr': 'Nivo',
    },
    'g9psm3ze': {
      'en': 'Description',
      'sr': 'Opis',
    },
    'owg7hhgs': {
      'en': 'Location',
      'sr': 'Lokacija',
    },
    '0qmjapx6': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // trainingHome
  {
    'jv2ipu5l': {
      'en': 'GymFeed',
      'sr': 'GymFeed',
    },
    'rvra8dqj': {
      'en': 'Upcoming activites',
      'sr': 'Predstojeće aktivnosti',
    },
    'mmpsqqwf': {
      'en': 'View more',
      'sr': 'Pogledaj još',
    },
    '0v7xify1': {
      'en': 'With: ',
      'sr': '',
    },
    'hnk2og52': {
      'en': 'Body Scanner',
      'sr': '',
    },
    'ac7usq07': {
      'en':
          'Snap, scan, and discover your body\'s insights with AI technology.',
      'sr': '',
    },
    'f7dwkzuc': {
      'en': 'Get Started',
      'sr': '',
    },
    'hoobycnm': {
      'en': 'Search',
      'sr': '',
    },
    'oxqv1oge': {
      'en': 'All',
      'sr': '',
    },
    'xb4v7a66': {
      'en': 'Muscle Mass',
      'sr': '',
    },
    '54oa9mku': {
      'en': 'Chalistenics',
      'sr': '',
    },
    '75b5mk28': {
      'en': 'CrossFit',
      'sr': '',
    },
    '9a4nedmy': {
      'en': 'Zumba',
      'sr': '',
    },
    '8qhh10ly': {
      'en': 'Yoga',
      'sr': '',
    },
    'yev3a9mm': {
      'en': 'Cardio',
      'sr': '',
    },
    '7dxhijq6': {
      'en': 'All',
      'sr': '',
    },
    '3bj5epna': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    '2quumxgg': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    '9br2pfnj': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'hscbwboa': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    'kqwz202s': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    'yl8j8iz2': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'cfces1i5': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    '4cukm8pq': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    '86scpt2m': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'opfebpri': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    'g6t1dwxv': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    '8mnqgsry': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'tnzdwywo': {
      'en': 'GymFeed',
      'sr': 'Početna',
    },
  },
  // JoinTraining
  {
    'zmc4z528': {
      'en': 'Active schedule',
      'sr': 'Activan raspored',
    },
    'xuu9gv38': {
      'en': 'Joined',
      'sr': 'Pridruzio',
    },
    'olvfi91o': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    'illeei8u': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    'fty5aiqy': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'h0egm65g': {
      'en': 'My Trainings',
      'sr': 'Moji treninzi',
    },
    '4y9nkgkh': {
      'en': 'Time: ',
      'sr': 'Vreme:',
    },
    'x5ligzew': {
      'en': 'Date: ',
      'sr': 'Datum:',
    },
    'h6we9nik': {
      'en': 'Category: ',
      'sr': 'Kategorija:',
    },
    'a7hbbnko': {
      'en': 'Progress',
      'sr': 'Napredak',
    },
    'fssvhjse': {
      'en': 'Hello ',
      'sr': '',
    },
    'af33q4nd': {
      'en': ',',
      'sr': '',
    },
    'zrf2eufv': {
      'en': 'You have ',
      'sr': '',
    },
    'jlr97bbp': {
      'en': ' tasks for today,',
      'sr': '',
    },
    'gkvlwjhf': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // progressDetails
  {
    '3ajswltp': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
    'u2cevxl1': {
      'en': ' sets x ',
      'sr': 'serije х',
    },
    '5q7d9zo3': {
      'en': ' reps x ',
      'sr': 'ponavljanja x',
    },
    'hnfgmaqk': {
      'en': ' kg',
      'sr': 'kg',
    },
    'azyq3aov': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // ExplorePage
  {
    '4prrud18': {
      'en': 'Explore',
      'sr': 'Istražite',
    },
    'irglmjjl': {
      'en': 'Explore',
      'sr': 'Istražite',
    },
    '3pmk43v3': {
      'en': 'Search',
      'sr': 'Traži',
    },
    'e6dj2fem': {
      'en': 'Explore media',
      'sr': 'Istražite medije',
    },
    'mcjpcved': {
      'en': 'Meals',
      'sr': 'Obroci',
    },
    'ylnab2fb': {
      'en': 'Search',
      'sr': 'Traži',
    },
    'tumt6aas': {
      'en': 'Explore food',
      'sr': 'Istraži hranu',
    },
    'rlj5iwz7': {
      'en': 'Friends',
      'sr': 'Prijatelji',
    },
    'xka0aqsx': {
      'en': 'Search',
      'sr': 'Traži',
    },
    'kr8zuomy': {
      'en': 'People you may know',
      'sr': 'Ljudi koje možda poznajete',
    },
    'ava651zw': {
      'en': 'Explore',
      'sr': 'Istraži',
    },
  },
  // blockedPage
  {
    'i2v78g9v': {
      'en': 'You are',
      'sr': 'Vi ste',
    },
    'nmwox82n': {
      'en': 'Blocked by this user !',
      'sr': 'Blokirani od strane ovog korisnika',
    },
    'khy7q0xf': {
      'en': 'Go back',
      'sr': 'Idite nazad',
    },
    '1v3898os': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // createFoodPost
  {
    'mhw3xekx': {
      'en': 'Food Post',
      'sr': 'Hrana i Zdravlje',
    },
    '6qjiw2kb': {
      'en': 'Meal Insights',
      'sr': 'Informacije o Obrocima',
    },
    'kiouc00p': {
      'en': 'Name of the Dish',
      'sr': 'Naziv jela',
    },
    '5b6n7a0k': {
      'en': 'Delicious Meal Post...',
      'sr': 'Objava ukusnog obroka...',
    },
    'mpggvh1u': {
      'en': 'Recipe',
      'sr': 'Recept',
    },
    'i78j1jk0': {
      'en': 'Craft Your Culinary Story...',
      'sr': 'Napravite svoju kulinarsku pricu...',
    },
    'f4jvmnco': {
      'en': 'Preparation Time (minutes)',
      'sr': 'Vreme pripreme (minuti)',
    },
    'j3cicxpd': {
      'en': 'From Kitchen to Table in No Time..',
      'sr': 'Od kuhinje do stola za kratko \nvreme.',
    },
    'kyyfbr7b': {
      'en': 'Nutrition',
      'sr': 'Ishrana',
    },
    'w2wgrc7c': {
      'en': 'Fuel Your Wellness Journey..',
      'sr': 'Napunite svoje Wellness Punotavnje..',
    },
    '9trtkw2l': {
      'en': 'Meal type',
      'sr': 'Vrska obroka',
    },
    'jon0qs9k': {
      'en': 'Please select...',
      'sr': 'Molimo izaberite..',
    },
    'dacjbjvb': {
      'en': 'Search for an item...',
      'sr': 'Potražite stavku...',
    },
    'hvcht5vi': {
      'en': 'Breakfast',
      'sr': 'Doručak',
    },
    't02k3u5g': {
      'en': 'Lunch',
      'sr': 'Ručak',
    },
    '2g6bus3n': {
      'en': 'Dinner',
      'sr': 'Večera',
    },
    'e5tv8esi': {
      'en': 'Snack',
      'sr': 'Užina',
    },
    'mmi65ouj': {
      'en': 'Desert',
      'sr': 'Dezert',
    },
    'dtibfafa': {
      'en': 'Calories',
      'sr': 'Kalorije',
    },
    '652h4dg7': {
      'en': 'Calories',
      'sr': 'Kalorije',
    },
    'sh1zbhtb': {
      'en': 'Protein in grams',
      'sr': 'Proteini u gramima',
    },
    'tcfh57cy': {
      'en': 'Protein',
      'sr': 'Proteini',
    },
    'n8zba6ob': {
      'en': 'Carbs',
      'sr': 'Proteini u gramima',
    },
    'zubavkmg': {
      'en': 'Protein',
      'sr': 'Proteini',
    },
    'jdyvm0u0': {
      'en': 'Fats',
      'sr': 'Proteini u gramima',
    },
    'qc76m39r': {
      'en': 'Protein',
      'sr': 'Proteini',
    },
    'zmql9jte': {
      'en': 'Hide like and view counts on post',
      'sr': 'Sakrij preglede na postu',
    },
    'h7t1139t': {
      'en': 'Hide comments on post',
      'sr': 'Sakrij komentare',
    },
    '1slcm8sf': {
      'en': 'Add call to action',
      'sr': 'Dodaj duge za link',
    },
    'uepjqhvq': {
      'en': 'Tag people',
      'sr': 'Taguj prijatelje',
    },
    'lzjb5w1c': {
      'en': 'Upload Photo/Video',
      'sr': 'Uploadujte fotografiju/video',
    },
    'u23ijxuj': {
      'en': 'Capture Your Culinary Creations. Upload a \nphoto or a video',
      'sr':
          'Snimite svoje kulinarske kreacije. Otpremite\n fotografiju ili video snimak.',
    },
    'cbo4j5bn': {
      'en':
          'Please note that all videos over 60 seconds will\nbe removed upon upload',
      'sr': '',
    },
    'vpx4f0hk': {
      'en':
          'Please note that all videos over 60 seconds\nwill be rejected upon upload',
      'sr': 'Dodaj sliku ili video',
    },
    'u3wvqhoh': {
      'en': 'Add a video',
      'sr': 'Dodajte video',
    },
    'jtc66eju': {
      'en': 'Delete video',
      'sr': 'Izbriši video',
    },
    'mt70s486': {
      'en': 'Add a photo',
      'sr': 'Dodajte fotografiju',
    },
    '619xeud9': {
      'en': 'Delete photo',
      'sr': 'Izbriši fotografiju',
    },
    '9ajp4qh4': {
      'en': 'Post',
      'sr': 'Objavi',
    },
    'qdol4m43': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // WelcomePage
  {
    '2e4q3pli': {
      'en': 'Welcome to\n',
      'sr': 'Dobro došli',
    },
    '1yzauz3e': {
      'en': 'GymFeed!',
      'sr': 'GymFeed!',
    },
    'ybv9sj6l': {
      'en': 'Log In',
      'sr': 'Uloguj se',
    },
    'kf3atym4': {
      'en': 'Get Started',
      'sr': 'Registruj profil',
    },
    'edm53ja0': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // login
  {
    'c1ehj28p': {
      'en': 'Welcome Back,',
      'sr': 'Dobrodošli nazad,',
    },
    'riwni3bz': {
      'en': 'Sign in your email and pasword to continue',
      'sr': 'Prijavite se na svoju e-adresui lozinku',
    },
    'li15iyby': {
      'en': 'Email',
      'sr': 'E-adresa',
    },
    'bhtkzgir': {
      'en': 'Password',
      'sr': 'Lozinka',
    },
    'axz8elqg': {
      'en': 'Forgot your password?',
      'sr': 'Zaboravili ste svoju lozinku?',
    },
    'mqtlvlu6': {
      'en': 'Log In',
      'sr': 'Prijavite se',
    },
    '51a3x585': {
      'en': 'User Policy',
      'sr': 'Uslovi Korišćenja',
    },
    'wxtdarw6': {
      'en': 'Don’t have an account? ',
      'sr': 'Nemate nalog?',
    },
    'dwa1h78r': {
      'en': ' Sing Up',
      'sr': ' Registrujte se',
    },
    'of8pk5no': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // CreateAccount
  {
    'dk7timc8': {
      'en': 'Register Account',
      'sr': 'Registrujte nalog',
    },
    'kiv2xtyv': {
      'en': 'Complete your details or continue with\nsocial media',
      'sr': 'Popunite svoje podatke ili nastavite sa društvenim mrežama',
    },
    '6hzdsl8f': {
      'en': 'Email',
      'sr': 'E-adresa',
    },
    'jee2sy1v': {
      'en': 'Password',
      'sr': 'Lozinka',
    },
    'hru44mjn': {
      'en': 'Confirm Password',
      'sr': 'Potvrdite lozinku',
    },
    '3gwhcs8r': {
      'en': 'Forgot your password?',
      'sr': 'Заборавили сте лозинку?',
    },
    'oulrg36u': {
      'en': 'Sign Up',
      'sr': 'Prijavite se',
    },
    'h4k1k61q': {
      'en': 'User Policy',
      'sr': 'Uslovi korišćenja',
    },
    'lospyb63': {
      'en': 'Already have an account? ',
      'sr': 'Već imate nalog?',
    },
    'raat6q9a': {
      'en': ' Log In',
      'sr': ' Prijavite se',
    },
    'oo7uh6yz': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // forgotPassword
  {
    '8v66okq8': {
      'en': 'Forgot Password',
      'sr': 'Zaboravili ste lozinku',
    },
    'icuy6sud': {
      'en': 'Enter your email',
      'sr': 'Унесите своју е-пошту',
    },
    'vf01hsij': {
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account above.',
      'sr':
          'Poslaćemo vam poruku sa vezom za resetovanje lozinke na unesenu e-adresu.',
    },
    'avv7cwgl': {
      'en': 'Send Reset Link',
      'sr': 'Pošaljite vezu za resetovanje',
    },
    'ccag63lt': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // EmailVerification
  {
    '7gpeuqpk': {
      'en': 'Verify your email',
      'sr': 'Potvrdite svoju\ne-adresu',
    },
    'z9xgek67': {
      'en': 'Complete verification in order to move forward',
      'sr': 'Završite verifikaciju kako biste nastavili dalje.',
    },
    'f69lmhss': {
      'en': 'Forgot your password?',
      'sr': 'Заборавили сте лозинку?',
    },
    'xblxh8nn': {
      'en': 'Continue',
      'sr': 'Nastavite',
    },
    'fzamx1j2': {
      'en': 'Email did not get to you?',
      'sr': 'Poruka nije stigla do vas?',
    },
    'ze3poz6d': {
      'en': ' Resend',
      'sr': ' Pošaljite ponovo',
    },
    '4f0pam8k': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // AllMostDone
  {
    'kzc2m147': {
      'en': 'Nice one!',
      'sr': 'Lepo uradjeno!',
    },
    'seo2zdw0': {
      'en': 'Few more steps!',
      'sr': 'Još nekoliko koraka!',
    },
    'b9ct6gbw': {
      'en': 'Continue with creating your new profile',
      'sr': 'Nastavite sa kreiranjem novog \nprofila',
    },
    '52lvokpi': {
      'en':
          'The next questions will be asked so we can \ncreate a personal meal and workout plan \nfor the first month. This information\nis only visible to you on your Progress Page',
      'sr':
          'Naredna pitanja će biti postavljena da bismo mogli kreirati lični plan obroka i vežbanja za prvi mesec. Ove informacije su vidljive samo vama na vašoj stranici Napretka.',
    },
    'ewwwvy2d': {
      'en': 'Continue',
      'sr': 'Sledeći korak',
    },
    'xbzjf1h7': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // ProfilePicture
  {
    'gc7345nz': {
      'en': 'Add Your\nProfile picture',
      'sr': 'Dodajte svoju\nprofilnu sliku',
    },
    '8s0ftc3c': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    'tvxh13ck': {
      'en': 'Remove profile image',
      'sr': 'Ukloni sliku',
    },
    'zu89k0sl': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    'h58zwn6z': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Gender2
  {
    'wl3bbsxp': {
      'en': 'Tell Us something\nAbout Yourself',
      'sr': 'Reci nam nešto\no sebi',
    },
    'uquyopd4': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke kako biste \nnastavili dalje',
    },
    '77gqcag6': {
      'en': 'Male',
      'sr': 'Muško',
    },
    'lthmeie4': {
      'en': 'Female',
      'sr': 'Žensko',
    },
    'gg94jj8q': {
      'en': 'Other',
      'sr': 'Ostalo',
    },
    'k2bczhpd': {
      'en': 'Next',
      'sr': 'Sledeće',
    },
    '09skq7cw': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // HowOldAreYou
  {
    'bo39l9gg': {
      'en': 'How old are you?',
      'sr': 'Kada ste rodjeni?',
    },
    'xxjbgo2e': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Унесите своје податке да бисте наставили даље',
    },
    '8of7jaxs': {
      'en': 'Next',
      'sr': 'Sledeće',
    },
    '3r95t55e': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Weight
  {
    '60uh1ihd': {
      'en': 'What is \nYour Weight?',
      'sr': 'Koja je \nvaša težina?',
    },
    'jcbm0pre': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    'sqosqkkj': {
      'en': 'Weight (kg)',
      'sr': 'Težina (kg)',
    },
    'ckr5ubtw': {
      'en': 'Field is required',
      'sr': 'Polje je obavezno',
    },
    'p1gihw49': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg \nmenija',
    },
    'vjj9d03z': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    '6qb8mxti': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Height
  {
    '6q588k9s': {
      'en': 'What is \nYour Height ?',
      'sr': 'Koja je vaša visina?',
    },
    '59sibsxi': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Унесите своје податке да бисте наставили даље',
    },
    'd8mrpzmx': {
      'en': 'Height (cm)',
      'sr': 'Visina (cm)',
    },
    'zoc63j3t': {
      'en': 'Field is required',
      'sr': 'Polje je obavezno ',
    },
    'iyufy96u': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju padajućeg menija',
    },
    'lhlbc3kb': {
      'en': 'Next',
      'sr': 'Sledeće',
    },
    '76llrexw': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // WorkOutLevel
  {
    'aqgs2yxr': {
      'en': 'What is Your\n workout level?',
      'sr': 'Kakav je vaš\nnivo treninga?',
    },
    'hc3d95tx': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    '6zu7w4e3': {
      'en': 'Begginer',
      'sr': 'Početnik',
    },
    'wk7tgwl5': {
      'en': 'Intermediate',
      'sr': 'Srednji',
    },
    'zn7kd6jt': {
      'en': 'Advanced',
      'sr': 'Napredni',
    },
    '93jni08m': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    'nxaen6py': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // FiveQuestions
  {
    'jsg3uaf1': {
      'en': 'Almost done !',
      'sr': 'Skoro gotovo !',
    },
    'rwe5ok1i': {
      'en': 'Five more questions!',
      'sr': 'Još pet pitanja!',
    },
    'f0anio79': {
      'en': 'Continue',
      'sr': 'Sledeći korak',
    },
    '7po1gpdu': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Goals
  {
    'vsi7fdfo': {
      'en': 'What are Your\n goals?',
      'sr': 'Šta su vaši\nciljevi?',
    },
    'm2crfc5n': {
      'en': 'Lose weight, gain muscle mass, etc..',
      'sr': 'Smršati, dobiti mišićnu masu itd...',
    },
    'w29g3np8': {
      'en': 'Lose weight',
      'sr': 'Smršati',
    },
    '54woh1wd': {
      'en': 'Gain Muscle',
      'sr': 'Povećati mišićnu masu',
    },
    'h1xh116l': {
      'en': 'Improved Strength',
      'sr': 'Povećati snagu',
    },
    'v02xfkp4': {
      'en': 'Enhanced Cardiovascular Health',
      'sr': 'Pojačati kondiciju',
    },
    'awbtxs0r': {
      'en': 'Next',
      'sr': 'Sledeće',
    },
    '17lx8qql': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Meals
  {
    'dz6e2h7a': {
      'en': 'How many meals do\nYou have in a day?',
      'sr': 'Koliko obroka treba da\n imate za jedan dan?',
    },
    '1zxvkgb8': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    '49grn7c7': {
      'en': '2-3',
      'sr': '2-3',
    },
    's61nmlwu': {
      'en': '3-4',
      'sr': '3-4',
    },
    'yxhpsjde': {
      'en': '4-5',
      'sr': '4-5',
    },
    'eezogqhz': {
      'en': '5+',
      'sr': '5+',
    },
    '1y5it0e3': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    'do2jcjg0': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // workoutDays
  {
    'xfscyw93': {
      'en': 'Number of \nworkouts per week?',
      'sr': 'Broj \ntreninga nedeljno?',
    },
    'xz2xq125': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    '0h6mxoz5': {
      'en': '1',
      'sr': '1',
    },
    'scw439fv': {
      'en': '2-3',
      'sr': '2-3',
    },
    'lg3z7a57': {
      'en': '3-4',
      'sr': '3-4',
    },
    'puugdine': {
      'en': '5+',
      'sr': '5+',
    },
    '91v3zm72': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    'xiuljuwy': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // workoutWhen
  {
    'lefo5qbp': {
      'en': 'When do You\nusually workout?',
      'sr': 'Kada\nobično vežbaš?',
    },
    '1eeefcxm': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    '97yq50cv': {
      'en': 'Morning',
      'sr': 'Jutro',
    },
    'frq4an7q': {
      'en': 'Afternoon',
      'sr': 'Popodne',
    },
    '4l8jf5vi': {
      'en': 'Evening',
      'sr': 'Veče',
    },
    'r6wnhwde': {
      'en': 'Midnight',
      'sr': 'Ponoć',
    },
    'ksj1y5hf': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    '3sy0zgf7': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // workoutLenght
  {
    '88h9sbf2': {
      'en': 'What is Your daily\nworkout lenght?',
      'sr': 'Šta je vaša dnevna\ndužina treninga?',
    },
    'rw8jfz9z': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    '5o0qyerd': {
      'en': '15min or less',
      'sr': '15 min ili manje',
    },
    'u0s5ft46': {
      'en': '20-30 min',
      'sr': '20-30 min',
    },
    'vqmm6per': {
      'en': '40-50 min',
      'sr': '40-50 min',
    },
    'x4ujz6l9': {
      'en': '60 min or more',
      'sr': '60 min ili više',
    },
    '9to4qtfh': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    'a7qqp9nt': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // allDone2
  {
    '7ccvamuc': {
      'en': 'Congratulations!',
      'sr': 'Čestitamo!\n',
    },
    'spdgonnh': {
      'en': '\nYou may proceed with the app, enjoy',
      'sr': 'Možete da nastavite sa aplikacijom, uživajte!',
    },
    'rik83e12': {
      'en': 'Label here...',
      'sr': 'Oznaćite ovde...',
    },
    'eiqzoe24': {
      'en': 'Continue',
      'sr': 'Nastavite',
    },
    '45yrrvoq': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // Username
  {
    'wrlstcwj': {
      'en': 'Register Account',
      'sr': 'Registrujte nalog',
    },
    '1snt80ux': {
      'en': 'Complete your details to move forward',
      'sr': 'Popunite svoje podatke da biste krenuli dalje.',
    },
    'utkymid7': {
      'en': 'First Name',
      'sr': 'Ime',
    },
    '2mmf7vl1': {
      'en': 'Field is required',
      'sr': 'Polje je obavezno',
    },
    'khezqyfe': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg \nmenija',
    },
    'k1ojg4jj': {
      'en': 'Bio (tell us about you)',
      'sr': 'Biografija (recite nam o sebi)',
    },
    '3ui1u67g': {
      'en': 'Field is required',
      'sr': 'Polje je obavezno',
    },
    'pwcckki3': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg \nmenija',
    },
    'wkqq2tz2': {
      'en': 'Username',
      'sr': 'Korisničko ime',
    },
    '8ub9aa54': {
      'en': 'Field is required',
      'sr': 'Polje je obavezno',
    },
    't47uqdfl': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju iz padajućeg \nmenija',
    },
    '2uhdht8t': {
      'en': 'Forgot your password?',
      'sr': 'Zaboravili ste lozinku?',
    },
    'vpqghjnz': {
      'en': 'Sign Up',
      'sr': 'Prijavi se',
    },
    '31xcn972': {
      'en': 'Already have an account? ',
      'sr': 'Već imate nalog?',
    },
    '73z12ib1': {
      'en': 'Log In',
      'sr': 'Prijavi se ',
    },
    '9u4xl2r0': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // changePassword
  {
    '0vtpdpsb': {
      'en': 'Change Password',
      'sr': 'Promeni lozinku',
    },
    'x1yqaa85': {
      'en': 'Enter your email',
      'sr': 'Unesite svoju e-adresu',
    },
    'xpim2cuo': {
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account above.',
      'sr':
          'Poslaćemo vam poruku sa vezom za resetovanje lozinke na unesenu e-adresu.',
    },
    '6nwxpl94': {
      'en': 'Send Reset Link',
      'sr': 'Pošaljite vezu za resetovanje',
    },
    'tdtgbg43': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // unblockList
  {
    'rj87swaw': {
      'en': 'Blocked accounts',
      'sr': 'Blokirani nalozi',
    },
    'nler6e50': {
      'en': 'Unblock',
      'sr': 'Odblokirajte',
    },
    'q2wykx1g': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // savedPosts
  {
    'hd9u39c1': {
      'en': 'Saved',
      'sr': 'Sačuvano',
    },
    'au4a6oys': {
      'en': 'Post items',
      'sr': 'Postovi',
    },
    'ggwbxgih': {
      'en': 'FitClips',
      'sr': 'FitKlipovi',
    },
    'lxkt5yes': {
      'en': 'Food Posts',
      'sr': 'Postovi o ishrani',
    },
    'x4dviz29': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // myInfo
  {
    'zbgf2o39': {
      'en': 'My progress',
      'sr': 'Moj napredak',
    },
    'mi98m7bw': {
      'en': 'Activity',
      'sr': 'Aktivnost',
    },
    'qpim5rir': {
      'en': 'Workout per week',
      'sr': 'Vežbanja nedeljno',
    },
    '8z4nhsak': {
      'en': 'Workout length',
      'sr': 'Trajanje treninga',
    },
    'wsmxt7y2': {
      'en': 'Workout Level',
      'sr': 'Nivo Fizičke Spremnosti',
    },
    'euzo600r': {
      'en': 'Information',
      'sr': 'Informacije',
    },
    '0zi2akrs': {
      'en': 'Your Weight in kg',
      'sr': 'Vaša tešina u kg',
    },
    'zehj56m6': {
      'en': 'Your Height in cm',
      'sr': 'Vaša visina u cm',
    },
    'di8ypwmd': {
      'en': 'Personal Trainer Suggestions',
      'sr': 'Predloyi Personalnog Trenera',
    },
    'm5kjvufz': {
      'en': 'My workout plan',
      'sr': 'Moj plan vežbanja',
    },
    '3e4960v7': {
      'en': 'Your progress by month',
      'sr': 'Moj plan vežbanja',
    },
    'eyxb3tug': {
      'en': 'Upload your monthly progress',
      'sr': 'Moj plan vežbanja',
    },
    '4072uqx1': {
      'en': 'Month 1',
      'sr': 'Moj plan vežbanja',
    },
    'vjowxmf1': {
      'en': 'Month 2',
      'sr': 'Moj plan vežbanja',
    },
    'c4ocufvw': {
      'en': 'Month 3',
      'sr': 'Moj plan vežbanja',
    },
    '5ufdpenn': {
      'en': 'Month 4',
      'sr': 'Moj plan vežbanja',
    },
    'mqs3cfyo': {
      'en': 'Month 5',
      'sr': 'Moj plan vežbanja',
    },
    '9g6kf1eh': {
      'en': 'Month 6',
      'sr': 'Moj plan vežbanja',
    },
    'qluwru9b': {
      'en': 'Month 12',
      'sr': 'Moj plan vežbanja',
    },
    'kgr11f99': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // myInfoEdit
  {
    '55147dqa': {
      'en': 'Edit my Info',
      'sr': 'Promeni moje informacije',
    },
    'j5utcu1t': {
      'en': 'Weight',
      'sr': 'Težina',
    },
    '5rej43ae': {
      'en': 'Height',
      'sr': 'Visina',
    },
    'xs0l8cy6': {
      'en': 'Number of workouts',
      'sr': 'Broj treninga',
    },
    'dqd7q9l3': {
      'en': 'Please select...',
      'sr': 'Molimo izaberite...',
    },
    'xe1hpnfb': {
      'en': 'Search for an item...',
      'sr': 'Istraži stavku...',
    },
    'gk9zjjvr': {
      'en': '1',
      'sr': '1',
    },
    '0lvvcd6g': {
      'en': '2-3',
      'sr': '2-3',
    },
    '0yb94nag': {
      'en': '3-4',
      'sr': '3-4',
    },
    '6pijaq3w': {
      'en': '5+',
      'sr': '5+',
    },
    'v1r98m31': {
      'en': 'Workout lenght',
      'sr': 'Dužina treninga',
    },
    'u5hb1lz7': {
      'en': 'Please select...',
      'sr': 'Molimo izaberite...',
    },
    'z0ic9rm5': {
      'en': 'Search for an item...',
      'sr': 'Istraži stavku...',
    },
    'ghj2114d': {
      'en': '15min or less',
      'sr': '15 мин или мање',
    },
    't0l1fa7m': {
      'en': '20-30 min',
      'sr': '20-30 мин',
    },
    '4fl6bar1': {
      'en': '40-50 min',
      'sr': '40-50 мин',
    },
    's9n2czev': {
      'en': '60 min or more',
      'sr': '60 мин или више',
    },
    'jj9ldvl2': {
      'en': 'Workout level',
      'sr': 'Težina treninga',
    },
    'g11atnsv': {
      'en': 'Please select...',
      'sr': 'Molimo izaberite...',
    },
    'mdyvx8t3': {
      'en': 'Search for an item...',
      'sr': 'Istraži stavku...',
    },
    'hhfkazsx': {
      'en': 'Begginer',
      'sr': 'Početnik',
    },
    'agmqtq64': {
      'en': 'Intermediate',
      'sr': 'Srednji',
    },
    '6lf0tq3a': {
      'en': 'Advanced',
      'sr': 'Napredni',
    },
    'fj2nepke': {
      'en': 'Save',
      'sr': 'Sačuvaj',
    },
    'vzk03k9e': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // videoReels
  {
    '7y0kypyo': {
      'en': 'Training',
      'sr': '',
    },
    'de9iu25e': {
      'en': 'FitClips',
      'sr': 'FitKlipovi',
    },
  },
  // Language
  {
    '78a8tfvc': {
      'en': 'Language',
      'sr': 'Jezik',
    },
    'ysbktld5': {
      'en': 'English',
      'sr': 'Engleski',
    },
    'ff7k93pr': {
      'en': 'Serbian',
      'sr': 'Srpski',
    },
    'h0oxgsje': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // detailsExercisePage
  {
    'xtozpx37': {
      'en': 'Program',
      'sr': 'Program',
    },
    'n869xoqy': {
      'en': 'Informations',
      'sr': 'Informacije',
    },
    '6nmd8xy3': {
      'en': 'Sets',
      'sr': 'Trajanje',
    },
    '1rq67393': {
      'en': 'Reps',
      'sr': 'Kategorija',
    },
    '8cn31npv': {
      'en': 'Kg',
      'sr': 'Datum',
    },
    'tnkzwygf': {
      'en': 'Rest Time in mins',
      'sr': 'Vreme',
    },
    '9pndsoo6': {
      'en': 'Intensity',
      'sr': 'Nivo',
    },
    '9jeyrjsx': {
      'en': 'Description',
      'sr': 'Opis',
    },
    '1sxoyr43': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // mealScanner
  {
    'cr1u611p': {
      'en': 'Meal scanner',
      'sr': 'Skener Mašina',
    },
    '2mq61r5h': {
      'en':
          ' Food Items, list all of the food items for the most precise asnwer ',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    '139rnpy6': {
      'en': 'Portion Sizes',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'pvpkpamp': {
      'en': 'Cooking Methods',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'l7oe8vo9': {
      'en': 'Ingredient Details',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'batt9it6': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    'hx0tbap8': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // mealScannerPro
  {
    '814r0ius': {
      'en': 'Machine scanner',
      'sr': 'Skener Mašina',
    },
    'wrgf7txw': {
      'en': '',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    '0almjv3g': {
      'en':
          '***Answer this question only if the image is something related to food. If it is anything outisde of that you need to reply we cannot scan this image as it does not contain these two things.***I am providing an image of a plate of food. Analyze the image and identify the following details about the food: Food Identification: List each food item on the plate. Describe the preparation method (e.g., baked, fried, steamed, raw, etc.). Mention if any sauces, dressings, or toppings are present. Portion Sizes: Estimate the weight or volume of each food item. Include references to standard measurements (e.g., grams, cups, tablespoons). Caloric and Nutritional Breakdown: Provide the estimated calorie count for each food item. Break down macronutrients (carbohydrates, proteins, fats) per item. Include any notable micronutrients (vitamins, minerals) if identifiable. Cooking Ingredients: Specify any additional ingredients used during cooking (e.g., oils, butter, spices). Highlight potential allergens or dietary considerations (e.g., gluten, nuts, dairy). Plate Summary: Sum up the total estimated calories and macronutrient content for the entire plate. Return the response in clear bullet-point format, with proper structuring and indentation for readability. If certain details cannot be determined from the image alone, mention the assumption or reasoning for the estimate.',
      'sr': '',
    },
    'j2f4860p': {
      'en':
          ' Food Items, list all of the food items for the most precise asnwer ',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'xxpwneyo': {
      'en': 'Portion Sizes',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'vfgymllz': {
      'en': 'Cooking Methods',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    '0fpbn1c6': {
      'en': 'Ingredient Details',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'j7eri19i': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    '4zqb7r7o': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // bodyScanner
  {
    'ht5oryog': {
      'en': 'Body scanner',
      'sr': 'Skener Mašina',
    },
    '5v143dx6': {
      'en': '',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'ge87albk': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    '83zp2o7y': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // bodyScannerPro
  {
    'wi1jpsah': {
      'en': 'Machine scanner',
      'sr': 'Skener Mašina',
    },
    'dzoaz3x3': {
      'en': '',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'mqzu2vo6': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    '6ctt5rjk': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // report
  {
    '16xyx902': {
      'en': 'Hello, ',
      'sr': '',
    },
    'osegzoev': {
      'en': 'Your body scan report is now ready! Check it out!',
      'sr': '',
    },
    'lyvy2g0o': {
      'en': 'My Insight',
      'sr': '',
    },
    'wvrxaaxj': {
      'en': 'Workout Level',
      'sr': '',
    },
    '12zeez3n': {
      'en': 'Information',
      'sr': '',
    },
    'pqu57avt': {
      'en': 'kg',
      'sr': '',
    },
    'ver56wxh': {
      'en': 'Your weight',
      'sr': '',
    },
    'kw0kort6': {
      'en': 'cm',
      'sr': '',
    },
    'psy72ux0': {
      'en': 'Your height',
      'sr': '',
    },
    'bphds6pz': {
      'en': 'Your age',
      'sr': '',
    },
    'qqmzgjgs': {
      'en': 'Your gender',
      'sr': '',
    },
    '5iv3g7mp': {
      'en': 'Goal',
      'sr': '',
    },
    'ee5xc1gu': {
      'en':
          'This report serves as a valuable reference, \nbut it\'s essential to consult a medical \nprofessional before making any decisions \nregarding your health and well-being.',
      'sr': '',
    },
    'ar4d59hm': {
      'en': 'First, let\'s see your body \ncomposition',
      'sr': '',
    },
    'g0z1dib9': {
      'en': 'Essential fat',
      'sr': '',
    },
    'rlc8p1pa': {
      'en': 'Lean Mass',
      'sr': '',
    },
    'dmxlajkh': {
      'en': 'Benefitial fat',
      'sr': '',
    },
    '5ec462ol': {
      'en': 'Unbenefitial fat',
      'sr': '',
    },
    'qdylvmrt': {
      'en': 'Essential fat',
      'sr': '',
    },
    'ixs0x5lj': {
      'en': '%',
      'sr': '',
    },
    '4onvlzxo': {
      'en': 'Lean Mass',
      'sr': '',
    },
    'rbso00kz': {
      'en': '%',
      'sr': '',
    },
    '4dk4z3xd': {
      'en': 'Benefitial fat',
      'sr': '',
    },
    '1ltswxpv': {
      'en': '%',
      'sr': '',
    },
    '2zrjv3zr': {
      'en': 'Unbenefitial fat',
      'sr': '',
    },
    'wywmc8ls': {
      'en': '%',
      'sr': '',
    },
    '0rezo67g': {
      'en': 'Let\'s see what your\nnumbers have to say \nabout you.',
      'sr': '',
    },
    'lbjh8cq8': {
      'en': 'Essential fat',
      'sr': '',
    },
    'av9p59jx': {
      'en': '',
      'sr': '',
    },
    'syo6bhh4': {
      'en': 'Functions of Essential Fats:',
      'sr': '',
    },
    'm002z8qi': {
      'en': 'Brain Health',
      'sr': '',
    },
    'll9azkt9': {
      'en': 'Cell Membranes',
      'sr': '',
    },
    'jnbpvnvt': {
      'en': 'Hormone Production',
      'sr': '',
    },
    'ufa786dc': {
      'en': 'Heart Health',
      'sr': '',
    },
    '17mwxccq': {
      'en': 'Inflammation Control',
      'sr': '',
    },
    'o9e0g6dq': {
      'en': 'The two primary categories \nof essential fats are:',
      'sr': '',
    },
    'asdxtsr3': {
      'en': 'Omega-3 Fatty Acids',
      'sr': '',
    },
    'byoooal5': {
      'en':
          'Found in foods like fish (e.g., salmon, mackerel, sardines), flaxseeds, chia seeds, walnuts, and canola oil.',
      'sr': '',
    },
    'p71v9qor': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    'zjexjq10': {
      'en': 'Reduces inflammation.',
      'sr': '',
    },
    '1po0s1ks': {
      'en': '\nSupports heart health.',
      'sr': '',
    },
    'zuk3tvws': {
      'en': '\nImproves brain function and development.',
      'sr': '',
    },
    'aeu31oj4': {
      'en': '\nMay reduce the risk of depression and anxiety.',
      'sr': '',
    },
    'efp35wxt': {
      'en': 'Omega-6 Fatty Acids',
      'sr': '',
    },
    'e7h6uap1': {
      'en':
          'Found in foods like vegetable oils (e.g., sunflower, corn, soybean), nuts, and seeds.',
      'sr': '',
    },
    '4m5q6haj': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    'ry1b99ww': {
      'en': 'Helps with energy production',
      'sr': '',
    },
    '007s67nx': {
      'en': '\nPlays a role in immune function.',
      'sr': '',
    },
    'xgpdvw9b': {
      'en': '\nSupports skin and hair health.',
      'sr': '',
    },
    '80xntq5k': {
      'en': 'Recommended Sources of Essential Fats:',
      'sr': '',
    },
    'w1mhktcc': {
      'en': 'Fish: Salmon, mackerel, sardines, herring.\n',
      'sr': '',
    },
    '9cfxz7ul': {
      'en': 'Seeds: Flaxseeds, chia seeds, hemp seeds.',
      'sr': '',
    },
    'ncrxbrc6': {
      'en': '\nNuts: Walnuts, almonds.',
      'sr': '',
    },
    'gmj2n0yi': {
      'en': '\nOils: Canola oil, soybean oil, flaxseed oil.',
      'sr': '',
    },
    'o5ymqb83': {
      'en':
          '\nOther: Algae-based omega-3 supplements (for vegetarians/vegans).',
      'sr': '',
    },
    'v0hrrl3h': {
      'en': 'Unbenifical fat',
      'sr': '',
    },
    'i8h0gh8w': {
      'en': '',
      'sr': '',
    },
    'ky9b2lhk': {
      'en': 'Functions of Essential Fats:',
      'sr': '',
    },
    't8v1ri44': {
      'en': 'Weight Gain and Obesity',
      'sr': '',
    },
    'jpttx3dm': {
      'en': 'Heart Health',
      'sr': '',
    },
    'qvgv7azl': {
      'en': 'Inflammation',
      'sr': '',
    },
    'oe2kud6z': {
      'en': 'Poor Brain Health',
      'sr': '',
    },
    '8d3v04kv': {
      'en': 'Fatty Liver Disease',
      'sr': '',
    },
    'qnszmifj': {
      'en': 'Types of Unbeneficial Fats:',
      'sr': '',
    },
    'a5y0i6tf': {
      'en': 'Trans Fats',
      'sr': '',
    },
    'f7kgtmgh': {
      'en':
          'Artificially created fats made by adding hydrogen to liquid vegetable oils (a process called hydrogenation).\n',
      'sr': '',
    },
    '3ge2z3rk': {
      'en': 'Sources:\n',
      'sr': '',
    },
    '4vu7g9gw': {
      'en': 'Packaged baked goods',
      'sr': '',
    },
    '14hemrzp': {
      'en': '\nFried foods',
      'sr': '',
    },
    '3v2ygsg2': {
      'en': '\nProcessed snacks',
      'sr': '',
    },
    'c7fejg7l': {
      'en': 'Negative Effects:\n',
      'sr': '',
    },
    'bl2jm0e7': {
      'en':
          'Increases bad cholesterol (LDL) and decreases good cholesterol (HDL)',
      'sr': '',
    },
    '31v7g352': {
      'en': '\nRaises the risk of heart disease, stroke, and type 2 diabetes',
      'sr': '',
    },
    'og0qrtz8': {
      'en': '\nPromotes inflammation',
      'sr': '',
    },
    '50jnxqrh': {
      'en': 'Saturated Fats',
      'sr': '',
    },
    '85fvtlcx': {
      'en':
          'Found naturally in some foods but harmful when consumed in excess.\n',
      'sr': '',
    },
    'zdqr99km': {
      'en': 'Sources:\n',
      'sr': '',
    },
    'q8gvgivh': {
      'en': 'Fatty cuts of meat',
      'sr': '',
    },
    'zv0zhx0x': {
      'en': '\nFull-fat dairy products',
      'sr': '',
    },
    'yzlp3ql1': {
      'en': '\nCoconut oil',
      'sr': '',
    },
    'hmba2qzf': {
      'en': 'Negative Effects:\n',
      'sr': '',
    },
    'sxcy3oxe': {
      'en': 'Increases levels of bad cholesterol (LDL)',
      'sr': '',
    },
    '4bbeh3u3': {
      'en':
          '\nContributes to the buildup of plaque in arteries (atherosclerosis).',
      'sr': '',
    },
    'j6tfe7pq': {
      'en': '\nRaises the risk of cardiovascular disease.',
      'sr': '',
    },
    'vk5wz1co': {
      'en': 'Tips to Reduce Unbeneficial Fat Intake',
      'sr': '',
    },
    'aa70rwk9': {
      'en': 'Choose Healthy Cooking Methods\n',
      'sr': '',
    },
    'txm6j6ri': {
      'en':
          'Read Labels: Avoid foods with \"partially hydrogenated oils\" or high saturated fat content',
      'sr': '',
    },
    'er0zxxv0': {
      'en': '\nUse Healthy Oils',
      'sr': '',
    },
    'c99jgm6x': {
      'en': '\nFocus on Whole Foods',
      'sr': '',
    },
    'tzg0byz4': {
      'en': 'Pro Tip:',
      'sr': '',
    },
    'ztbd2res': {
      'en':
          'Completely avoid trans fats as they provide no nutritional benefit.\nLimit saturated fats to no more than 10% of your daily calorie intake.',
      'sr': '',
    },
    'xdnwbbfu': {
      'en': 'Lean mass',
      'sr': '',
    },
    'ohyy1gz4': {
      'en': '',
      'sr': '',
    },
    '0gs41phn': {
      'en': 'How to Build and Maintain Lean Mass:',
      'sr': '',
    },
    'fzb2ku9x': {
      'en': 'Strength Training',
      'sr': '',
    },
    'iasnd69e': {
      'en': 'Balanced Diet',
      'sr': '',
    },
    '7a2qf3ij': {
      'en': 'Adequate Protein Intake',
      'sr': '',
    },
    'nnu2zs5y': {
      'en': 'Stay Hydrated',
      'sr': '',
    },
    'jx1kdgum': {
      'en': 'Active Lifestyle',
      'sr': '',
    },
    '73cd898f': {
      'en': 'Why Lean Mass Is Important:',
      'sr': '',
    },
    'rua4ehxd': {
      'en':
          'Metabolic Function:\n\nMuscle tissue is metabolically active and burns more calories at rest than fat, contributing to a higher basal metabolic rate (BMR).\nPhysical Strength and Mobility:\n\nLean mass, especially muscle, is essential for strength, mobility, and endurance.\nBone Health:\n\nBone mass contributes to lean mass, and higher lean mass is often associated with stronger bones.\nBody Composition:\n\nA higher lean mass percentage generally correlates with lower body fat, improved fitness, and better health outcomes.\nDisease Prevention:\n\nAdequate lean mass can reduce the risk of chronic diseases such as osteoporosis, diabetes, and cardiovascular diseases.',
      'sr': '',
    },
    'na3ym40h': {
      'en': 'Pro Tip:',
      'sr': '',
    },
    '9co3tg24': {
      'en':
          'Focus on maintaining or increasing lean mass through strength training and proper nutrition, especially as you age, because lean mass naturally declines with time (a process called sarcopenia). Preventing this decline improves long-term health and mobility.',
      'sr': '',
    },
    'ew2rb8yt': {
      'en': 'Beneficial fat',
      'sr': '',
    },
    'mhny9g8c': {
      'en': '',
      'sr': '',
    },
    'z629txsj': {
      'en': 'Functions of Beneficial Fats:',
      'sr': '',
    },
    '46x2s6px': {
      'en': 'Energy Source',
      'sr': '',
    },
    'hszk05rw': {
      'en': 'Heart Health',
      'sr': '',
    },
    '5auj91uk': {
      'en': 'Cell Function',
      'sr': '',
    },
    'qpxoi0s7': {
      'en': 'Absorption of Vitamins',
      'sr': '',
    },
    '75b3rxct': {
      'en': 'Brain Development',
      'sr': '',
    },
    'ru5q6hnq': {
      'en': 'Types of Beneficial Fats:',
      'sr': '',
    },
    '8aewf72q': {
      'en': 'MUFAs',
      'sr': '',
    },
    'l4vyci1r': {
      'en':
          'Found in foods like avocados, olive oil, nuts (almonds, cashews), and seeds.\n',
      'sr': '',
    },
    'vfqmtqyz': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    '4ruru8xb': {
      'en': 'Improves heart health by lowering bad cholesterol (LDL).',
      'sr': '',
    },
    'fjeu4ama': {
      'en': '\nReduces the risk of cardiovascular diseases.',
      'sr': '',
    },
    '45jfyrqr': {
      'en': '\nSupports weight management.',
      'sr': '',
    },
    '0x65pmi9': {
      'en': '\nEnhances insulin sensitivity and blood sugar control.',
      'sr': '',
    },
    '4gnfxic8': {
      'en': 'PUFAs',
      'sr': '',
    },
    'dk0kctem': {
      'en':
          'Found in fatty fish, walnuts, flaxseeds, chia seeds, and sunflower oil.\n',
      'sr': '',
    },
    '1cegd9f8': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    'te2rjesm': {
      'en': 'Reduces inflammation.',
      'sr': '',
    },
    '53r2rczn': {
      'en': '\nImproves brain health and cognitive function.',
      'sr': '',
    },
    '0ph5r33w': {
      'en': '\nSupports healthy skin and hair.',
      'sr': '',
    },
    'w686649w': {
      'en': '\nPromotes joint health.',
      'sr': '',
    },
    'kays1xrt': {
      'en': 'Recommended Sources of Beneficial Fats:',
      'sr': '',
    },
    '58xg4i5e': {
      'en': 'Avocados: High in monounsaturated fats and fiber.\n',
      'sr': '',
    },
    '3zxtpljp': {
      'en': 'Seeds: Flaxseeds, chia seeds, hemp seeds, sunflower seeds.',
      'sr': '',
    },
    '8g6sjcx9': {
      'en': '\nNuts: Almonds, walnuts, cashews, pistachios.',
      'sr': '',
    },
    'b57g71qh': {
      'en': '\nOils: Olive oil, canola oil, flaxseed oil, avocado oil.',
      'sr': '',
    },
    '7zbnddqc': {
      'en': '\nFish: Salmon, mackerel, trout, sardines (rich in Omega-3).',
      'sr': '',
    },
    '42feaf3d': {
      'en': 'Pro Tip:',
      'sr': '',
    },
    '16yxm1p7': {
      'en':
          'When consuming beneficial fats, moderation is key. Focus on whole, unprocessed sources and avoid overconsuming foods high in Omega-6 (e.g., processed vegetable oils) to maintain a proper balance with Omega-3 fatty acids.',
      'sr': '',
    },
    '4lvxi53q': {
      'en': 'Lean Mass Index',
      'sr': '',
    },
    'izrprgug': {
      'en': 'Fat Mass Index',
      'sr': '',
    },
    'ni0xlk12': {
      'en': 'Low',
      'sr': '',
    },
    '2yz1sgr1': {
      'en': 'Average',
      'sr': '',
    },
    'l5kj6c0h': {
      'en': 'Fitness',
      'sr': '',
    },
    '97bgl33t': {
      'en': 'Athletic',
      'sr': '',
    },
    'htd1zu89': {
      'en': 'Low',
      'sr': '',
    },
    '28gzkgn1': {
      'en': 'Average',
      'sr': '',
    },
    'mdg0ydmc': {
      'en': 'Healthy',
      'sr': '',
    },
    '3qeptewt': {
      'en': 'High',
      'sr': '',
    },
    'k9xjyc1y': {
      'en': 'Athletic',
      'sr': '',
    },
    'hq52fi9y': {
      'en': '24-26',
      'sr': '',
    },
    'xr5b8dbb': {
      'en': 'High',
      'sr': '',
    },
    'fwgqx9l9': {
      'en': '>8',
      'sr': '',
    },
    'bq2mfq52': {
      'en': 'Fitness',
      'sr': '',
    },
    'h6kiwi93': {
      'en': '21-23',
      'sr': '',
    },
    '42mm9pv2': {
      'en': 'Healthy',
      'sr': '',
    },
    'cgj0viog': {
      'en': '5-8',
      'sr': '',
    },
    'lqlqiwe1': {
      'en': 'Average',
      'sr': '',
    },
    'bsmgmo66': {
      'en': '19-20',
      'sr': '',
    },
    'htxggkv7': {
      'en': 'Average',
      'sr': '',
    },
    'xr0tb4gt': {
      'en': '2-5',
      'sr': '',
    },
    '5huvlusq': {
      'en': '',
      'sr': '',
    },
    'oc5sttqj': {
      'en': 'Low',
      'sr': '',
    },
    '5j1koqkf': {
      'en': '13-18',
      'sr': '',
    },
    'ptxm3yh4': {
      'en': 'Low',
      'sr': '',
    },
    '8uew456h': {
      'en': '<2',
      'sr': '',
    },
    'qzvk6cj1': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // workoutWhere
  {
    'id8drkd6': {
      'en': 'When do You\nusually workout?',
      'sr': 'Kada\nobično vežbaš?',
    },
    '8i8mff45': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Unesite svoje podatke da biste nastavili dalje.',
    },
    '38inhtgw': {
      'en': 'Gym',
      'sr': 'Jutro',
    },
    'vh9brzsg': {
      'en': 'Outside',
      'sr': 'Popodne',
    },
    '8lklg317': {
      'en': 'Home',
      'sr': 'Veče',
    },
    'pnvl7876': {
      'en': 'Next',
      'sr': 'Sledeći korak',
    },
    '3eku1f93': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // foodAlergies
  {
    'z00u2g4o': {
      'en': 'Do you have\nany food alergies?',
      'sr': 'Koja je vaša visina?',
    },
    'w8n8zvy1': {
      'en': 'Complete your details to proceed futher',
      'sr': 'Унесите своје податке да бисте наставили даље',
    },
    '8oxrowcg': {
      'en': 'Food Alergies',
      'sr': 'Visina (cm)',
    },
    '106pj2va': {
      'en': 'Field is required',
      'sr': 'Polje je obavezno ',
    },
    'x39bjzok': {
      'en': 'Please choose an option from the dropdown',
      'sr': 'Izaberite opciju padajućeg menija',
    },
    'le2tr8pg': {
      'en': 'Next',
      'sr': 'Sledeće',
    },
    '4yqmf7qc': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // test
  {
    '344m75d7': {
      'en': 'Hello ',
      'sr': '',
    },
    'mp3whwl6': {
      'en': ',',
      'sr': '',
    },
    '0bnxkbu2': {
      'en': 'You have ',
      'sr': '',
    },
    'f9g9v6fg': {
      'en': ' tasks for today,',
      'sr': '',
    },
    '1rp46xdc': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // addingMeals
  {
    'xy5dv6lw': {
      'en': 'Nutrition',
      'sr': 'Sastojci',
    },
    '8j01k2v0': {
      'en': 'Calroies',
      'sr': 'Kalorije',
    },
    '5vfkzl49': {
      'en': 'Protein',
      'sr': 'Proteini',
    },
    'qspgv1h9': {
      'en': 'Carbs',
      'sr': 'Kalorije',
    },
    '678xyfk8': {
      'en': 'Fats',
      'sr': 'Proteini',
    },
    'v2ldphbv': {
      'en': 'Add meal',
      'sr': 'Nastavite',
    },
    'wuclbydb': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // mealScannerCopy
  {
    'ztn4inuq': {
      'en': 'Meal scanner',
      'sr': 'Skener Mašina',
    },
    '5uhjgbpr': {
      'en': '',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'gwcpqrck': {
      'en':
          '***Important: If somebody asks you if you are chatGPT or anything related to an open source model you will always reply the following: I am a representative of GymFeed here to help you with any meal or fitness related question you have.******Answer this question only if the image is something related to food. If it is anything outisde of that you need to reply we cannot scan this image as it does not contain these two things.***I am providing an image of a plate of food. Analyze the image and identify the following details about the food: Food Identification: List each food item on the plate. Describe the preparation method (e.g., baked, fried, steamed, raw, etc.). Mention if any sauces, dressings, or toppings are present. Portion Sizes: Estimate the weight or volume of each food item. Include references to standard measurements (e.g., grams, cups, tablespoons). Caloric and Nutritional Breakdown: Provide the estimated calorie count for each food item. Break down macronutrients (carbohydrates, proteins, fats) per item. Include any notable micronutrients (vitamins, minerals) if identifiable. Cooking Ingredients: Specify any additional ingredients used during cooking (e.g., oils, butter, spices). Highlight potential allergens or dietary considerations (e.g., gluten, nuts, dairy). Plate Summary: Sum up the total estimated calories and macronutrient content for the entire plate. Return the response in clear bullet-point format, with proper structuring and indentation for readability. If certain details cannot be determined from the image alone, mention the assumption or reasoning for the estimate.',
      'sr': '',
    },
    'pmto6c9g': {
      'en':
          ' Food Items, list all of the food items for the most precise asnwer ',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'fysnb4mw': {
      'en': 'Portion Sizes',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'ufzx8339': {
      'en': 'Cooking Methods',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    'nyrzayuw': {
      'en': 'Ingredient Details',
      'sr': 'Šta bi ste želeli da znate o vašoj mašini?',
    },
    's9hxz5kx': {
      'en': 'Scan',
      'sr': 'Skeniraj',
    },
    '0as6jzv3': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // detailsExercisePage2
  {
    'jm6elin1': {
      'en': 'Program',
      'sr': 'Program',
    },
    'i3ovdnk4': {
      'en': 'Informations',
      'sr': 'Informacije',
    },
    't4xt7bjg': {
      'en': 'Sets',
      'sr': 'Trajanje',
    },
    'h0wabopm': {
      'en': 'Reps',
      'sr': 'Kategorija',
    },
    'ay46qc42': {
      'en': 'Kg',
      'sr': 'Datum',
    },
    'xpfxugy5': {
      'en': 'Rest Time in mins',
      'sr': 'Vreme',
    },
    'ma6a7x4d': {
      'en': 'Intensity',
      'sr': 'Nivo',
    },
    'nt0a1q1k': {
      'en': 'Description',
      'sr': 'Opis',
    },
    '9j7asgyl': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // videoCompress
  {
    'zi1l0ti0': {
      'en': 'Button',
      'sr': '',
    },
    'l4grnhad': {
      'en': 'Page Title',
      'sr': '',
    },
    'coqp0faj': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // videoCompressCopy
  {
    '87nam5hv': {
      'en': 'Button',
      'sr': '',
    },
    'ymrg9ucb': {
      'en': 'Page Title',
      'sr': '',
    },
    '2b3d62lg': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // addingMealsCopy
  {
    'rza76byp': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // mealCollection
  {
    'mxbvxujw': {
      'en': 'Meal collection',
      'sr': '',
    },
    '1f0mxes7': {
      'en': 'Hello World',
      'sr': '',
    },
    'xduk70eo': {
      'en': 'Hello ',
      'sr': '',
    },
    'cpwn2mde': {
      'en': ',',
      'sr': '',
    },
    'he74e6n8': {
      'en': 'You have added ',
      'sr': '',
    },
    'xb626292': {
      'en': ' meals for today,',
      'sr': '',
    },
    '9m2r9ft8': {
      'en': 'kcal',
      'sr': '',
    },
    'z50ttvor': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // videoCompressCopyCopy
  {
    'jaro3tqe': {
      'en': 'Button',
      'sr': '',
    },
    'ruolu83m': {
      'en': '50%',
      'sr': '',
    },
    'cpkc6q72': {
      'en': 'Button',
      'sr': '',
    },
    'y2x49yz0': {
      'en': 'Page Title',
      'sr': '',
    },
    'puzxqry3': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // videoCompressCopyCopyCopy
  {
    'rgfabfuv': {
      'en': 'Button',
      'sr': '',
    },
    'f97x1g4d': {
      'en': '50%',
      'sr': '',
    },
    '9zdpoodl': {
      'en': 'Page Title',
      'sr': '',
    },
    'zff8ocsl': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // reportCopy
  {
    'gsddjgsx': {
      'en': 'Scan date:',
      'sr': '',
    },
    'rskyoyc3': {
      'en': 'Hello World',
      'sr': '',
    },
    'rzhznufx': {
      'en': 'Scan time:',
      'sr': '',
    },
    '2gehi9qk': {
      'en': 'Hello World',
      'sr': '',
    },
    '76hp3qo7': {
      'en': 'Hey, ',
      'sr': '',
    },
    'xsg2s109': {
      'en':
          'Your body scan report is now ready ! \nAll insights and information, ready to start ?',
      'sr': '',
    },
    '85za92v2': {
      'en': 'Sex',
      'sr': '',
    },
    'w5zzqpna': {
      'en': 'Age',
      'sr': '',
    },
    's6lqftrl': {
      'en': 'Height',
      'sr': '',
    },
    'n0npsngj': {
      'en': 'Weight',
      'sr': '',
    },
    '9mqecdkv': {
      'en': 'Level',
      'sr': '',
    },
    'k9iq955d': {
      'en': 'Goal',
      'sr': '',
    },
    '3209wn0d': {
      'en':
          'This report serves as a valuable reference, \nbut it\'s essential to consult a medical \nprofessional before making any decisions \nregarding your health and well-being.',
      'sr': '',
    },
    'ha0t2a9e': {
      'en': 'Body composition',
      'sr': '',
    },
    'e1nzshoa': {
      'en': 'First things first, let\'s check out\nyour body composition',
      'sr': '',
    },
    'o6qwcwsy': {
      'en': 'bfat',
      'sr': '',
    },
    'bqdlsqw7': {
      'en': 'efat',
      'sr': '',
    },
    'k1ybzoz0': {
      'en': 'ufat',
      'sr': '',
    },
    'jbsroa6p': {
      'en': 'leanmass',
      'sr': '',
    },
    '0wm3olny': {
      'en': 'Essential fat',
      'sr': '',
    },
    'zj7pxo1q': {
      'en': '%',
      'sr': '',
    },
    'rswfmwqz': {
      'en': 'Beneficial fat',
      'sr': '',
    },
    'f2x77bu0': {
      'en': '%',
      'sr': '',
    },
    's0tuofe8': {
      'en': 'Unbeneficial fat',
      'sr': '',
    },
    'who7rzsw': {
      'en': '%',
      'sr': '',
    },
    'j9mf7bcv': {
      'en': 'Lean mass',
      'sr': '',
    },
    'aosokmc1': {
      'en': '%',
      'sr': '',
    },
    'm5omkunu': {
      'en': 'Body insights',
      'sr': '',
    },
    '3j268zoy': {
      'en': 'Let\'s see what your\n numbers have to say \nabout you.',
      'sr': '',
    },
    'b54wd64h': {
      'en': 'Essential fat',
      'sr': '',
    },
    'j4ia3wai': {
      'en': '%',
      'sr': '',
    },
    'inwtojdh': {
      'en': 'The two primary categories \nof essential fats are:',
      'sr': '',
    },
    '3ecl769d': {
      'en': 'Omega-3 Fatty Acids',
      'sr': '',
    },
    '5xf32gfa': {
      'en':
          'Found in foods like fish (e.g., salmon, mackerel, sardines), flaxseeds, chia seeds, walnuts, and canola oil.',
      'sr': '',
    },
    'jw9bobc0': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    '0i1qs331': {
      'en': 'Reduces inflammation.',
      'sr': '',
    },
    'ugbbpe90': {
      'en': '\nSupports heart health.',
      'sr': '',
    },
    'ncpt80ee': {
      'en': '\nImproves brain function and development.',
      'sr': '',
    },
    'owqjy9ws': {
      'en': '\nMay reduce the risk of depression and anxiety.',
      'sr': '',
    },
    '9a8fjppu': {
      'en': 'Omega-6 Fatty Acids',
      'sr': '',
    },
    '7jeyd2p8': {
      'en':
          'Found in foods like vegetable oils (e.g., sunflower, corn, soybean), nuts, and seeds.',
      'sr': '',
    },
    't5jkdi4r': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    'eb8t8h1z': {
      'en': 'Helps with energy production',
      'sr': '',
    },
    'ngych3px': {
      'en': '\nPlays a role in immune function.',
      'sr': '',
    },
    'v84fmylp': {
      'en': '\nSupports skin and hair health.',
      'sr': '',
    },
    'px1a2d76': {
      'en': 'Functions of Essential Fats:',
      'sr': '',
    },
    'dl1zybyu': {
      'en': 'Brain Health',
      'sr': '',
    },
    'fl3bmblk': {
      'en': 'Cell Membranes',
      'sr': '',
    },
    '61598bpg': {
      'en': 'Hormone Production',
      'sr': '',
    },
    '8bdg1pxy': {
      'en': 'Heart Health',
      'sr': '',
    },
    'dw4qo0cv': {
      'en': 'Inflammation Control',
      'sr': '',
    },
    'n1fmixz3': {
      'en': 'Recommended Sources of Essential Fats:',
      'sr': '',
    },
    'kmsdvs3o': {
      'en': 'Fish: Salmon, mackerel, sardines, herring.\n',
      'sr': '',
    },
    '8a7uekmu': {
      'en': 'Seeds: Flaxseeds, chia seeds, hemp seeds.',
      'sr': '',
    },
    'hv6uiq57': {
      'en': '\nNuts: Walnuts, almonds.',
      'sr': '',
    },
    'ltga4hh6': {
      'en': '\nOils: Canola oil, soybean oil, flaxseed oil.',
      'sr': '',
    },
    'e3dmidrj': {
      'en':
          '\nOther: Algae-based omega-3 supplements (for vegetarians/vegans).',
      'sr': '',
    },
    'rnyyauo9': {
      'en': 'Beneficial fat',
      'sr': '',
    },
    'zf5dczpj': {
      'en': '%',
      'sr': '',
    },
    '9t3ufj6b': {
      'en': 'Types of Beneficial Fats:',
      'sr': '',
    },
    'sm064pn6': {
      'en': 'MUFAs',
      'sr': '',
    },
    'ijp500ht': {
      'en':
          'Found in foods like avocados, olive oil, nuts (almonds, cashews), and seeds.\n',
      'sr': '',
    },
    '9l7x2ipy': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    'hec1av11': {
      'en': 'Improves heart health by lowering bad cholesterol (LDL).',
      'sr': '',
    },
    'j1v7j1n5': {
      'en': '\nReduces the risk of cardiovascular diseases.',
      'sr': '',
    },
    'aau3ycm9': {
      'en': '\nSupports weight management.',
      'sr': '',
    },
    'bnivp5oh': {
      'en': '\nEnhances insulin sensitivity and blood sugar control.',
      'sr': '',
    },
    '4ry3m8z2': {
      'en': 'PUFAs',
      'sr': '',
    },
    'uaaou4as': {
      'en':
          'Found in fatty fish, walnuts, flaxseeds, chia seeds, and sunflower oil.\n',
      'sr': '',
    },
    'smymchek': {
      'en': 'Benefits:\n',
      'sr': '',
    },
    'phas2e2b': {
      'en': 'Reduces inflammation.',
      'sr': '',
    },
    '32zvf54t': {
      'en': '\nImproves brain health and cognitive function.',
      'sr': '',
    },
    'qxxnt5df': {
      'en': '\nSupports healthy skin and hair.',
      'sr': '',
    },
    'lk4l7qw8': {
      'en': '\nPromotes joint health.',
      'sr': '',
    },
    'htqpyo6b': {
      'en': 'Functions of Essential Fats:',
      'sr': '',
    },
    '6sw9zahw': {
      'en': 'Energy Source',
      'sr': '',
    },
    '7evae9fk': {
      'en': 'Heart Health',
      'sr': '',
    },
    '39fet74q': {
      'en': 'Cell Function',
      'sr': '',
    },
    'mx9l6bxh': {
      'en': 'Absorption of Vitamins',
      'sr': '',
    },
    'jk8jumg3': {
      'en': 'Brain Development',
      'sr': '',
    },
    'kmtuewr8': {
      'en': 'Recommended Sources of Beneficial Fats',
      'sr': '',
    },
    'hnzakmrq': {
      'en': 'Avocados: High in monounsaturated fats and fiber.\n',
      'sr': '',
    },
    'rqwetie5': {
      'en': 'Seeds: Flaxseeds, chia seeds, hemp seeds, sunflower seeds.',
      'sr': '',
    },
    'a92r8ezs': {
      'en': '\nNuts: Almonds, walnuts, cashews, pistachios.',
      'sr': '',
    },
    'jrj5b25a': {
      'en': '\nOils: Olive oil, canola oil, flaxseed oil, avocado oil.',
      'sr': '',
    },
    '9qyde59w': {
      'en': '\nFish: Salmon, mackerel, trout, sardines (rich in Omega-3).',
      'sr': '',
    },
    '45oyy3a3': {
      'en': 'Pro Tip:',
      'sr': '',
    },
    'hx601nxl': {
      'en':
          'When consuming beneficial fats, moderation is key. Focus on whole, unprocessed sources and avoid overconsuming foods high in Omega-6 (e.g., processed vegetable oils) to maintain a proper balance with Omega-3 fatty acids.',
      'sr': '',
    },
    'wkw2ul6w': {
      'en': 'Unbeneficial fat',
      'sr': '',
    },
    'dv3ryu8z': {
      'en': '%',
      'sr': '',
    },
    'hopxcneg': {
      'en': 'Types of Unbeneficial Fats:',
      'sr': '',
    },
    '2mkkef1p': {
      'en': 'Trans Fats',
      'sr': '',
    },
    '4xodqv9i': {
      'en':
          'Artificially created fats made by adding hydrogen to liquid vegetable oils (a process called hydrogenation).\n',
      'sr': '',
    },
    '10rz4628': {
      'en': 'Sources:\n',
      'sr': '',
    },
    'b5iof195': {
      'en': 'Packaged baked goods',
      'sr': '',
    },
    'uv5l0jpb': {
      'en': '\nFried foods',
      'sr': '',
    },
    'x9kpj9a7': {
      'en': '\nProcessed snacks',
      'sr': '',
    },
    '0x52q9fu': {
      'en': 'Negative Effects:\n',
      'sr': '',
    },
    'v0tqpsqx': {
      'en':
          'Increases bad cholesterol (LDL) and decreases good cholesterol (HDL)',
      'sr': '',
    },
    'x09oqryn': {
      'en': '\nRaises the risk of heart disease, stroke, and type 2 diabetes',
      'sr': '',
    },
    'ehcehnjd': {
      'en': '\nPromotes inflammation',
      'sr': '',
    },
    '28uza3a4': {
      'en': 'Saturated Fats',
      'sr': '',
    },
    'mmv34j7g': {
      'en':
          'Found naturally in some foods but harmful when consumed in excess.\n',
      'sr': '',
    },
    'n2rolzff': {
      'en': 'Sources:\n',
      'sr': '',
    },
    'pojwkl44': {
      'en': 'Fatty cuts of meat',
      'sr': '',
    },
    'hc43b40f': {
      'en': '\nFull-fat dairy products',
      'sr': '',
    },
    'imo5q745': {
      'en': '\nCoconut oil',
      'sr': '',
    },
    'vh9oybqp': {
      'en': 'Negative Effects:\n',
      'sr': '',
    },
    'qdsd8x27': {
      'en': 'Increases levels of bad cholesterol (LDL)',
      'sr': '',
    },
    'wo141wqe': {
      'en':
          '\nContributes to the buildup of plaque in arteries (atherosclerosis).',
      'sr': '',
    },
    'y3ribw8z': {
      'en': '\nRaises the risk of cardiovascular disease.',
      'sr': '',
    },
    'y00lihgp': {
      'en': 'Functions of Essential Fats:',
      'sr': '',
    },
    '2vb9qvd8': {
      'en': 'Weight Gain and Obesity',
      'sr': '',
    },
    '63egni15': {
      'en': 'Heart Health',
      'sr': '',
    },
    'twrt913i': {
      'en': 'Inflammation',
      'sr': '',
    },
    'h1xap4r6': {
      'en': 'Poor Brain Health',
      'sr': '',
    },
    '693do318': {
      'en': 'Fatty Liver Disease',
      'sr': '',
    },
    '7j02grpi': {
      'en': 'Tips to Reduce Unbeneficial Fat Intake',
      'sr': '',
    },
    'ry6x6km9': {
      'en': 'Choose Healthy Cooking Methods\n',
      'sr': '',
    },
    'irqacog0': {
      'en':
          'Read Labels: Avoid foods with \"partially hydrogenated oils\" or high saturated fat content',
      'sr': '',
    },
    'r8iqnoze': {
      'en': '\nUse Healthy Oils',
      'sr': '',
    },
    'ri4vk3m9': {
      'en': '\nFocus on Whole Foods',
      'sr': '',
    },
    '6e2hev32': {
      'en': 'Pro Tip:',
      'sr': '',
    },
    'ffqlkwp6': {
      'en':
          'Completely avoid trans fats as they provide no nutritional benefit.\nLimit saturated fats to no more than 10% of your daily calorie intake.',
      'sr': '',
    },
    'lzu7m5ow': {
      'en': 'Lean mass',
      'sr': '',
    },
    'v40pf05j': {
      'en': '%',
      'sr': '',
    },
    'zm6hjp1c': {
      'en': 'Why Lean Mass Is Important:',
      'sr': '',
    },
    'eysk86oh': {
      'en':
          'Metabolic Function:\n\nMuscle tissue is metabolically active and burns more calories at rest than fat, contributing to a higher basal metabolic rate (BMR).\nPhysical Strength and Mobility:\n\nLean mass, especially muscle, is essential for strength, mobility, and endurance.\nBone Health:\n\nBone mass contributes to lean mass, and higher lean mass is often associated with stronger bones.\nBody Composition:\n\nA higher lean mass percentage generally correlates with lower body fat, improved fitness, and better health outcomes.\nDisease Prevention:\n\nAdequate lean mass can reduce the risk of chronic diseases such as osteoporosis, diabetes, and cardiovascular diseases.',
      'sr': '',
    },
    'vizjxk2c': {
      'en': 'How to Build and Maintain Lean Mass:',
      'sr': '',
    },
    'de5i7woe': {
      'en': 'Strength Training',
      'sr': '',
    },
    'utwlegsr': {
      'en': 'Balanced Diet',
      'sr': '',
    },
    'i05vc9k8': {
      'en': 'Adequate Protein Intake',
      'sr': '',
    },
    'ui4ksw90': {
      'en': 'Stay Hydrated',
      'sr': '',
    },
    'wxkoi0je': {
      'en': 'Active Lifestyle',
      'sr': '',
    },
    'qa32g4d2': {
      'en': 'Pro Tip:',
      'sr': '',
    },
    '45v63gd6': {
      'en':
          'Focus on maintaining or increasing lean mass through strength training and proper nutrition, especially as you age, because lean mass naturally declines with time (a process called sarcopenia). Preventing this decline improves long-term health and mobility.',
      'sr': '',
    },
    'j4fqexc1': {
      'en': 'Lean mass index',
      'sr': '',
    },
    'meaka5tf': {
      'en': 'Low',
      'sr': '',
    },
    's4b3imqr': {
      'en': 'Average',
      'sr': '',
    },
    'kmw7gw5g': {
      'en': 'Fitness',
      'sr': '',
    },
    'o182jn0i': {
      'en': 'Athletic',
      'sr': '',
    },
    'hkf5oep6': {
      'en': 'Low',
      'sr': '',
    },
    'ge4m3wuv': {
      'en': '13-18',
      'sr': '',
    },
    '4krq4ubl': {
      'en': 'Average',
      'sr': '',
    },
    '2l8tetkc': {
      'en': '19-20',
      'sr': '',
    },
    'moj4q6cj': {
      'en': 'Fitness',
      'sr': '',
    },
    'ymdq7yli': {
      'en': '21-23',
      'sr': '',
    },
    'qi98ykas': {
      'en': 'Athletic',
      'sr': '',
    },
    'qehdj03z': {
      'en': '23-26',
      'sr': '',
    },
    '8m1aqtwq': {
      'en':
          'The Lean Mass Index (LMI) is a metric used to measure the amount of lean mass (muscle, bones, organs, water, etc.) in relation to a person\'s height. It provides insight into a person\'s muscular development and is often used by athletes, bodybuilders, and fitness enthusiasts to assess their progress in building muscle while maintaining a healthy body composition.',
      'sr': '',
    },
    'lwxa0q47': {
      'en': 'Fat mass index',
      'sr': '',
    },
    'ti9aagh5': {
      'en': 'Low',
      'sr': '',
    },
    'qrqt45og': {
      'en': 'Average',
      'sr': '',
    },
    '5nri7jji': {
      'en': 'Healthy',
      'sr': '',
    },
    '1si2h908': {
      'en': 'High',
      'sr': '',
    },
    '9zi00kwf': {
      'en': 'Low',
      'sr': '',
    },
    '4m2h6akn': {
      'en': '<2',
      'sr': '',
    },
    '7841xodc': {
      'en': 'Average',
      'sr': '',
    },
    'hi5cw6da': {
      'en': '2-5',
      'sr': '',
    },
    'o4fqxa2d': {
      'en': 'Healthy',
      'sr': '',
    },
    'y0axtq8q': {
      'en': '5-8',
      'sr': '',
    },
    'kf7619p1': {
      'en': 'High',
      'sr': '',
    },
    'yl4queok': {
      'en': '>8',
      'sr': '',
    },
    'kahaaai1': {
      'en':
          'The Fat Mass Index (FMI) is a metric used to assess the amount of body fat relative to height. It provides a more detailed evaluation of body composition compared to the Body Mass Index (BMI).',
      'sr': '',
    },
    '21djt2i5': {
      'en': 'Calories burnt at rest',
      'sr': '',
    },
    '72thgxsg': {
      'en': 'Resting metabolic rate',
      'sr': '',
    },
    'ksca7ohu': {
      'en': 'kcal',
      'sr': '',
    },
    'yz8ho25u': {
      'en': ' * ',
      'sr': '',
    },
    'oreea708': {
      'en': 'per day',
      'sr': '',
    },
    'pj37i3xv': {
      'en': 'Now let\'s reach your goal:',
      'sr': '',
    },
    '2plqdv22': {
      'en': 'Overall summary',
      'sr': '',
    },
    'y6esldeb': {
      'en': ', it is time to find some balance.',
      'sr': '',
    },
    'kn2x1j5r': {
      'en':
          ' To reach your body composition goals, you could benefit from dropping to healthy ranges of fat mass. GymFeed is here for you. We will support you all the way in your journey. ',
      'sr': '',
    },
    'uspsyt8n': {
      'en':
          '  .Great job maintaining a healthy fat mass range! Keep up the excellent work with your fitness and nutrition routine. GymFeed is here to help you stay on track and reach new goals!',
      'sr': '',
    },
    'glpg6sbx': {
      'en':
          '  .Your fat mass is below the healthy range. To maintain optimal health, consider incorporating balanced nutrition and resistance training into your routine. GymFeed is here to guide you toward achieving a well-rounded body composition.',
      'sr': '',
    },
    'rtfbjs4r': {
      'en':
          '  .Great job maintaining a healthy fat mass range! Keep up the excellent work with your fitness and nutrition routine. GymFeed is here to help you stay on track and reach new goals!',
      'sr': '',
    },
    'x8dzpc6w': {
      'en': 'Recommendations',
      'sr': '',
    },
    '9nquij5j': {
      'en':
          'To achieve your body composition goals, you should aim to eat less than what you burn in a day. GymFeed will create a personalized meal plan and strategy to help you on your journey!',
      'sr': '',
    },
    'm8aqrwxi': {
      'en':
          'To maintain your healthy fat mass range, balance your daily calorie intake with your energy expenditure. GymFeed will craft a tailored meal plan and strategy to keep you at your best!',
      'sr': '',
    },
    'i625tfp9': {
      'en':
          'Your body needs more energy to stay healthy and balanced. Focus on eating more nutrient-rich meals to support your activity level. GymFeed will create a meal plan and strategy to help you reach optimal health!',
      'sr': '',
    },
    'u3u3g095': {
      'en':
          'To maintain your healthy fat mass range, balance your daily calorie intake with your energy expenditure. GymFeed will craft a tailored meal plan and strategy to keep you at your best!',
      'sr': '',
    },
    '1fqpep1p': {
      'en': 'Things that you can do',
      'sr': '',
    },
    'qp88vigt': {
      'en':
          'Watch out for excessive stress. It not only impedes muscle growth but also promotes fat storage around your gut and organs. Managing stress effectively will be a key part of your journey. GymFeed is here to support you with the right tools and strategies!',
      'sr': '',
    },
    'axpjk2is': {
      'en':
          'Even with a healthy fat mass range, excessive stress can hinder muscle growth and encourage fat storage around your midsection. Stay mindful of stress levels, and let GymFeed help you maintain your balance and achieve peak performance!',
      'sr': '',
    },
    '9g9f15b0': {
      'en':
          'Excessive stress can negatively affect your health, even with a low fat mass. It may impede muscle growth and lead to fat storage around your organs. Focus on stress management and let GymFeed guide you toward a balanced and healthy body composition!',
      'sr': '',
    },
    'ipx91j9p': {
      'en':
          'Even with a healthy fat mass range, excessive stress can hinder muscle growth and encourage fat storage around your midsection. Stay mindful of stress levels, and let GymFeed help you maintain your balance and achieve peak performance!',
      'sr': '',
    },
    'fq66kyos': {
      'en': 'Workout summary',
      'sr': '',
    },
    'xzknce5g': {
      'en': 'Calories that you need to burn',
      'sr': '',
    },
    'gd41sukv': {
      'en': 'Calories that we recommend you take',
      'sr': '',
    },
    'lotrt3rw': {
      'en': 'Here is your custom workout plan for 3 months',
      'sr': '',
    },
    '7l6o9lyp': {
      'en': 'Pro tips',
      'sr': '',
    },
    'ixtjvw7n': {
      'en':
          'Now lets get your diet in order, like all greats say fitness is 90% in the kitchen and 10% in the gym',
      'sr': '',
    },
    '2dsg9l7g': {
      'en': 'Nutrition plan',
      'sr': '',
    },
    'b7hvxmxy': {
      'en':
          'Alright, listen up, champ! We’ve put together a solid meal plan to keep you fueled and ready to crush your day. This isn’t about cutting corners or packing on size—it’s about giving your body the good stuff it needs to perform at its best. Stick to the plan, hit those macros, and make every meal count. Remember, food isn’t just fuel—it’s your secret weapon. Let’s get after it!',
      'sr': '',
    },
    'udrh87tf': {
      'en': 'Total kcal',
      'sr': '',
    },
    'xfc9tujs': {
      'en': 'Proteins in grams',
      'sr': '',
    },
    '9szoiqhv': {
      'en': 'fats in grams',
      'sr': '',
    },
    '7pvikbu3': {
      'en': 'carbs in grams',
      'sr': '',
    },
    'akk5qk5p': {
      'en': 'Our recommendations:',
      'sr': '',
    },
    'ecyskoeb': {
      'en': 'Motivational quotes',
      'sr': '',
    },
    'nuto647d': {
      'en': 'Button',
      'sr': '',
    },
    'l2dswja2': {
      'en': 'Upload',
      'sr': '',
    },
    'foh0h7ez': {
      'en': 'back',
      'sr': '',
    },
    'do0at54a': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // bodyscanner2
  {
    'skbfcjhb': {
      'en': 'Welcome to Your 3-Month Fitness & Meal Plan Report',
      'sr': '',
    },
    '2v75rgin': {
      'en':
          'You\'re about to receive a customized 3-month fitness and meal plan, along with key insights into your BMI, Lean Mass Index,  Fat Mass Index and much more. This report will be tailored to your body composition and goals, helping you track progress and optimize your training and nutrition.\n\nTo get the most accurate results, we need a one thing from you:',
      'sr': '',
    },
    'xvb8ttwi': {
      'en':
          'Two images of yourself \n(front & side view) for \nbody composition analysis',
      'sr': '',
    },
    'qbmfn3it': {
      'en':
          '💡 Tip: Wear form-fitting clothes and take photos in a well-lit area for the best accuracy.',
      'sr': '',
    },
    '65ljpqs9': {
      'en': 'Let\'s go!',
      'sr': '',
    },
    'jln9bhxr': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // bodyscanner3
  {
    'dug3me5m': {
      'en': 'Your Data is Safe with Us',
      'sr': '',
    },
    'how3fxo2': {
      'en':
          'We take your privacy seriously. Here\'s how we protect your data:\n\n🔒 Secure Processing – Your photos are used only for body composition analysis and are never shared.\n🗑️ Automatic Deletion – Images are not stored permanently and are removed after generating your report.\n🛡️ Data Encryption – Your information is encrypted and protected at all times.\n\nYour trust and security are our top priorities. If you have any concerns, feel free to check our Privacy Policy before continuing.',
      'sr': '',
    },
    'xmi0y0iy': {
      'en':
          'I agree that GymFeed can use \nmy photos and train an AI to provide \nbetter results.',
      'sr': '',
    },
    'omjhx0i9': {
      'en': ' Privacy Policy',
      'sr': '',
    },
    'nl73ep4g': {
      'en':
          '💡 Tip: Wear form-fitting clothes and take photos in a well-lit area for the best accuracy.',
      'sr': '',
    },
    'anskf7km': {
      'en': 'Next',
      'sr': '',
    },
    '9wfiv83q': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // bodyscanner4
  {
    'aesjm0v7': {
      'en': 'Generating Your Personalized Report',
      'sr': '',
    },
    'kc0c95x1': {
      'en':
          '🔄 Please wait while we analyze your data and create a customized fitness & nutrition plan tailored just for you.\n\n💪 What’s happening now?\n✅ Processing your body composition\n✅ Calculating BMI, Lean Mass Index, and Fat Mass Index\n✅ Crafting a 3-month structured workout and meal plan\n\nThis may take a few moments. Stay tuned for your results!',
      'sr': '',
    },
    '6t4iiibm': {
      'en': 'Before we begin you need to follow a few steps',
      'sr': '',
    },
    '2sxydfp3': {
      'en':
          'To generate your personalized report, please upload two images of yourself:\n\n📸 Front View – Stand naturally facing the camera\n📸 Side View – Stand sideways with arms relaxed\n\n🔹 These images help estimate body fat percentage, muscle mass, and composition changes over time.\n🔹 Your photos will remain private and secure—they are only used for your report.\n\n💡 Pro Tip: Take photos with a plain background and consistent lighting to ensure the most precise results.',
      'sr': '',
    },
    'hn4q3w1e': {
      'en': 'Upload photos',
      'sr': '',
    },
    'r1v2ncxn': {
      'en': 'Once you\'ve taken the photos, please upload them here',
      'sr': '',
    },
    'sr3tmdr6': {
      'en': 'Delete  photos',
      'sr': '',
    },
    'zj8plo7u': {
      'en': 'Upload first photo',
      'sr': '',
    },
    'ihrcccd7': {
      'en': 'Upload second photo',
      'sr': '',
    },
    'cjdaniel': {
      'en': 'Next',
      'sr': '',
    },
    'tasoiv8x': {
      'en': 'Generate report',
      'sr': '',
    },
    'lu2cusqw': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // workoutPlan
  {
    'n71thkq9': {
      'en': 'Workout Plan',
      'sr': '',
    },
    'bura6n26': {
      'en':
          'Get ready to take your fitness journey to the next level with a plan built around your personal goals, preferences, and lifestyle. \nLet’s work together to make every rep count!',
      'sr': '',
    },
    '7ufqoc2r': {
      'en': 'Daily request',
      'sr': '',
    },
    'd2m3xaft': {
      'en': 'Calories Intake',
      'sr': '',
    },
    '5a3vv070': {
      'en': 'Calories to Burn',
      'sr': '',
    },
    'i6dozrqx': {
      'en': 'Get 7-8 hours of sleeep per night',
      'sr': '',
    },
    'x1f3u3se': {
      'en': 'Minimum 6000 steps per day',
      'sr': '',
    },
    'vfvf2eua': {
      'en': 'Stay hidrated up to 8 glasses of water',
      'sr': '',
    },
    'z7h3r4wy': {
      'en': 'Balance your stress level',
      'sr': '',
    },
    'opqtoyel': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // mealPlan
  {
    '2lb0hp5f': {
      'en': 'Meal Plan',
      'sr': '',
    },
    'u4m39u10': {
      'en':
          'Alright, listen up, champ! We’ve put together a solid meal plan to keep you fueled and ready to crush your day. This isn’t about cutting corners or packing on size—it’s about giving your body the good stuff it needs to perform at its best. Stick to the plan, hit those macros, and make every meal count. Remember, food isn’t just fuel—it’s your secret weapon. \nLet’s get after it!',
      'sr': '',
    },
    'jdthd9su': {
      'en': 'Daily request',
      'sr': '',
    },
    '3vb3u8h9': {
      'en': 'Total kcal',
      'sr': '',
    },
    'i97kexjb': {
      'en': 'Proteins',
      'sr': '',
    },
    'jhi7xuog': {
      'en': 'g',
      'sr': '',
    },
    '7nfg1xar': {
      'en': 'Fats',
      'sr': '',
    },
    'kvr6lkwt': {
      'en': 'g',
      'sr': '',
    },
    'hj5kbahe': {
      'en': 'Carbs',
      'sr': '',
    },
    'zav2mo6x': {
      'en': 'g',
      'sr': '',
    },
    't1yd5ggx': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // jebemtimater
  {
    'ixguanaz': {
      'en': 'Button',
      'sr': '',
    },
    'kg2je3uz': {
      'en': 'Page Title',
      'sr': '',
    },
    'dy037def': {
      'en': 'Home',
      'sr': 'Početna',
    },
  },
  // videoReelsCopy
  {
    'ttfpxk0s': {
      'en': 'Training',
      'sr': '',
    },
    'v3yi0jkg': {
      'en': 'FitClips',
      'sr': 'FitKlipovi',
    },
  },
  // postOptions
  {
    '3fyk404o': {
      'en': 'Report Post',
      'sr': '',
    },
  },
  // personalPostOptions
  {
    '8whembj2': {
      'en': 'Edit',
      'sr': 'Uključite lajkove',
    },
    '0ce67ztd': {
      'en': 'Turn off likes',
      'sr': '',
    },
    'cfyzvca0': {
      'en': 'Turn on likes',
      'sr': '',
    },
    '1bgdf9zo': {
      'en': 'Turn off commenting',
      'sr': 'Isključi komentare',
    },
    'nxteuht5': {
      'en': 'Turn on commenting',
      'sr': 'Uključite komentare',
    },
    'ko7jhzm7': {
      'en': 'Delete Post',
      'sr': 'Izbriši objavu',
    },
  },
  // post
  {
    'jg5jldjk': {
      'en': ' ',
      'sr': '',
    },
    'c3h7q1qk': {
      'en': 'View 1 comment',
      'sr': 'Pogledaj 1 komentar',
    },
    '8ah32r9c': {
      'en': ' ',
      'sr': '',
    },
    'srf8xl01': {
      'en': 'Add a comment...',
      'sr': 'Dodaj komentar...',
    },
  },
  // taggedUsers
  {
    'ngnzsw46': {
      'en': 'In this photo',
      'sr': 'Na ovoj fotografiji',
    },
  },
  // AddExcercise
  {
    '8wymoyk3': {
      'en': 'Create Workout',
      'sr': 'Kreiraj trening',
    },
    'q2ustxx5': {
      'en': 'Enter Exercise name',
      'sr': 'Unesite naziv vežbe',
    },
    'wve6whwf': {
      'en': 'Enter day',
      'sr': 'Unesite dan',
    },
    'cfdio4b0': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
  },
  // CreateExercise
  {
    'mxer4m7g': {
      'en': 'Add Exercise',
      'sr': 'Dodaj vežbu',
    },
    '6hc86d8d': {
      'en': 'Enter Exercise title',
      'sr': 'Unesite naziv vežbe',
    },
    'avkjaoli': {
      'en': 'Enter Exercise description',
      'sr': 'Unesite naziv vežbe',
    },
    'glbfzmf4': {
      'en': 'Select...',
      'sr': '',
    },
    'etg9zt1m': {
      'en': 'Search...',
      'sr': '',
    },
    'avu78yir': {
      'en': 'Light Intensity',
      'sr': '',
    },
    'fezbdi1g': {
      'en': 'Moderate Intensity',
      'sr': '',
    },
    '9j5ldzkc': {
      'en': 'Maximal Intensity',
      'sr': '',
    },
    'vkqw9h1r': {
      'en': 'Enter sets',
      'sr': 'Unesite serije',
    },
    'yvrcom5c': {
      'en': 'Enter reps',
      'sr': 'Unesite ponavljanja',
    },
    'ig0s7hdb': {
      'en': 'Kg per set',
      'sr': 'Kg po seriji',
    },
    'jvvt4ket': {
      'en': 'Rest Time in minutes',
      'sr': 'Kg po seriji',
    },
    'n1mpl589': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
  },
  // UpdateExercise
  {
    'dk5aum5h': {
      'en': 'Update Exercise',
      'sr': 'Ažuriraj vežbu',
    },
    'r8evvtzd': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
  },
  // payment
  {
    'hg4a0ro4': {
      'en': 'Restore',
      'sr': 'Ресторе',
    },
    '7y0r5f75': {
      'en': 'Premium',
      'sr': 'Премиум',
    },
    'rxy6q03a': {
      'en': 'Unlock Your Fitness Journey \nwith Premium Access',
      'sr': 'Otključajte svoje fitnes \nputovanje\nsa Premium pristupom!',
    },
    'z26cfenh': {
      'en':
          'Elevate your fitness experience with our exclusive premium membership. Gain access to 1,000 personalized conversations with our expert fitness trainer each month, and enhance your progress tracking with 100 image uploads to our state-of-the-art machine scanner.',
      'sr':
          'Unapredite svoje fitnes iskustvo uz\nnaše ekskluzivno Premium članstvo. Dobijte pristup 1000 personalizovanih razgovora sa našim stručnim fitnes\ntrenerom svakog meseca i poboljšajte\npraćenje napretka pomoću 100\notpremanja slika na naš najsavremeniji\nmašinski skener.',
    },
    'aw5agg00': {
      'en': 'Per month',
      'sr': 'Mesečno',
    },
    'vmfb4591': {
      'en': 'Premium plan',
      'sr': 'Premijum plan',
    },
    'dsr9estq': {
      'en': 'Customer Support',
      'sr': 'Korisnićka podrška',
    },
    'k5rflovy': {
      'en': 'Unlimited number of creations',
      'sr': 'Neograničen broj kreiranja',
    },
    'gfwpnmx8': {
      'en': 'Premium profile icon',
      'sr': 'Икона Премиум профила',
    },
    '3ucb136e': {
      'en': 'Up to 500 conversations with AI trainer',
      'sr': 'Do 1000 poruka sa AI trenerom',
    },
    'r0ih60b5': {
      'en': 'Up to 50 uploads with Machine, \nBody and Meal Scanner',
      'sr': 'Do 100 poslatih slika sa Skenerom mašina',
    },
    '5amgj3n7': {
      'en':
          'This subscription will automatically \nrenew unless auto-renew is turned off at least \n24 hours before the end of the current period.',
      'sr':
          'Ova predplata će se automatski\nobnoviti osim ako automatsko\nobnavljnaje nije isključeno\n24 sata pre tekućeg perioda.',
    },
    'bnqxybus': {
      'en': 'Subscribe',
      'sr': 'Predplati se',
    },
    'sqbsxagi': {
      'en': 'By continuing you agree to our',
      'sr': 'Ako nastavite slažete se sa našim',
    },
    'yyg9uu8f': {
      'en': ' \nTerms of Use(EULA)',
      'sr': '\nUslovi korišćenja (EULA)',
    },
    'ppoftbes': {
      'en': ' and ',
      'sr': 'I',
    },
    'ugugrax7': {
      'en': 'Privacy Policy',
      'sr': 'Politika privatnosti',
    },
  },
  // EULA
  {
    'nne4ms2p': {
      'en':
          'Acceptable Use Policy\nBy using GymFeed, you agree to adhere to our Acceptable Use Policy, which prohibits the following behaviors:\n\nObjectionable Content: You may not post or share content that is obscene, offensive, hateful, or promotes violence or discrimination based on race, sex, religion, nationality, disability, sexual orientation, or age. This includes, but is not limited to, explicit language, graphic violence, and sexually explicit material.\n\nAbusive Behavior: You may not engage in any behavior that is threatening, harassing, defamatory, or invasive of another\'s privacy. This includes cyberbullying, stalking, and any form of intimidation or aggression toward other users.\n\nIllegal Activities: You may not use GymFeed for any unlawful purposes or in furtherance of illegal activities. This includes, but is not limited to, posting or sharing content that violates intellectual property rights, conducting fraud, or distributing malware.\n\nGymFeed reserves the right to remove any content that violates these guidelines and to suspend or terminate the accounts of users who engage in abusive behavior. We are committed to maintaining a safe and respectful community for all our users.',
      'sr':
          'Politika prihvatljivog korišćenja\nKorišćenjem GimFeed-a, saglasni ste da ćete se pridržavati naše Politike prihvatljivog korišćenja, koja zabranjuje sledeća ponašanja:\n\nNeprihvatljiv sadržaj: Ne smete da postavljate ili delite sadržaj koji je opscen, uvredljiv, mržnje ili promoviše nasilje ili diskriminaciju na osnovu rase, pola, vere, nacionalnosti, invaliditeta, seksualne orijentacije ili starosti. Ovo uključuje, ali nije ograničeno na, eksplicitan jezik, eksplicitno nasilje i seksualno eksplicitan materijal.\n\nUvredljivo ponašanje: Ne smete da se upuštate u bilo kakvo ponašanje koje predstavlja pretnju, uznemiravanje, klevetu ili narušavanje tuđe privatnosti. Ovo uključuje maltretiranje putem interneta, uhođenje i bilo koji oblik zastrašivanja ili agresije prema drugim korisnicima.\n\nIlegalne aktivnosti: Ne smete da koristite GimFeed u bilo koje nezakonite svrhe ili za unapređenje nelegalnih aktivnosti. Ovo uključuje, ali nije ograničeno na, postavljanje ili deljenje sadržaja koji krši prava intelektualne svojine, vršenje prevare ili distribuciju malvera.\n\nGimFeed zadržava pravo da ukloni bilo koji sadržaj koji krši ove smernice i da suspenduje ili ukine naloge korisnika koji se bave uvredljivim ponašanjem. Posvećeni smo održavanju bezbedne zajednice sa poštovanjem za sve naše korisnike.',
    },
  },
  // PrivacyPlocy
  {
    'dev5w4fg': {
      'en':
          'GymFeed Privacy Policy\n\nIntroduction\n\nWelcome to GymFeed! We prioritize your privacy and are committed to protecting your personal and sensitive data. This Privacy Policy outlines how we handle your information within the GymFeed app, a social media/fitness platform for sharing pictures, videos, and text. We assure you that your data is not used for marketing or advertising purposes and is handled with the utmost care and security.\n\n## Personal and Sensitive User Data\n\nAt GymFeed, we handle various types of personal and sensitive user data, which may include:\n\n- Personally identifiable information\n- Financial and payment information\n- Authentication information\n- Phonebook and contacts\n- Device location\n- SMS and call-related data\n- Health and Health Connect data\n- Inventory of other apps on the device\n- Microphone and camera access\n- Other sensitive device or usage data\n\nWe commit to:\n\n1. **Limiting Data Usage**: We restrict the access, collection, use, and sharing of personal and sensitive data to purposes that are essential for the app’s functionality and those reasonably expected by you, the user.\n\n2. **Secure Handling**: All personal and sensitive user data is transmitted and stored securely, using modern cryptography, such as HTTPS.\n\n3. **Runtime Permissions**: We use runtime permissions requests before accessing data gated by Android permissions.\n\n4. **No Sale of Data**: We do not sell your personal and sensitive user data.\n\n5. **Legal Compliance**: We may transfer data to service providers or for legal reasons, such as complying with government requests, laws, or in case of mergers or acquisitions, with legally adequate notice to you.\n\n## Prominent Disclosure & Consent\n\nIn scenarios where data access, collection, use, or sharing may not align with your expectations:\n\n1. **In-App Disclosure**: We provide an in-app disclosure detailing our data practices, which is easily accessible during normal app usage.\n\n2. **User Consent**: We seek your explicit consent for data collection and access, ensuring that consent is informed and unambiguous.\n\n3. **Legal Bases**: For processing personal and sensitive data without consent (e.g., under EU GDPR), we comply with all legal requirements, including providing appropriate disclosures.\n\n## Example of Prominent Disclosure\n\n“GymFeed collects and uses location data to enhance your fitness tracking experience, even when the app is not actively in use.”\n\n## Third-Party Code\n\nIf GymFeed integrates third-party code that collects personal and sensitive data, we ensure compliance with our Prominent Disclosure and Consent policy and provide evidence of such compliance to Google Play as required.\n\n## Privacy Policy Accessibility\n\nOur Privacy Policy is:\n\n- Available on GymFeed’s store listing page in the Play Console.\n- Accessible within the GymFeed app itself.\n- Clearly labeled as a privacy policy.\n\n## Contact and Queries\n\nDeveloper: Aleksandar Zivkovic\nFor privacy-related inquiries or concerns, please contact us at aleksandar.zivkovc@gmail.com.\n\n## Comprehensive Disclosure\n\nWe fully disclose:\n\n- The types of personal and sensitive user data accessed, collected, used, and shared.\n- Parties with whom any personal or sensitive user data is shared.\n- Our secure data handling procedures.\n- Our data retention and deletion policy, which allows you to delete your data upon profile deletion.\n\nThank you for choosing GymFeed. We are committed to safeguarding your privacy and ensuring a secure and enjoyable experience.\n\n',
      'sr':
          '**GimFeed politika privatnosti**\n\n**Uvod**\n\nDobrodošli u GimFeed! Dajemo prioritet vašoj privatnosti i posvećeni smo zaštiti vaših ličnih i osetljivih podataka. Ova politika privatnosti opisuje kako postupamo sa vašim informacijama u aplikaciji GimFeed, platformi društvenih medija/fitnes za deljenje slika, video zapisa i teksta. Uveravamo vas da se vaši podaci ne koriste u marketinške ili reklamne svrhe i da se njima rukuje sa najvećom pažnjom i sigurnošću.\n\n## Lični i osetljivi podaci korisnika\n\nU GimFeed-u obrađujemo različite vrste ličnih i osetljivih korisničkih podataka, koji mogu uključivati:\n\n- Lične informacije\n- Finansijske i informacije o plaćanju\n- Informacije o autentifikaciji\n- Imenik i kontakti\n- Lokacija uređaja\n- SMS i podaci u vezi sa pozivima\n- Health and Health Connect podaci\n- Inventar drugih aplikacija na uređaju\n- Pristup mikrofonu i kameri\n- Drugi osetljivi uređaji ili podaci o upotrebi\n\nObavezujemo se da:\n\n1. **Ograničavanje upotrebe podataka**: Ograničavamo pristup, prikupljanje, korišćenje i deljenje ličnih i osetljivih podataka na svrhe koje su ključne za funkcionalnost aplikacije i one koje razumno očekujete od vas, korisnika.\n\n2. **Bezbedno rukovanje**: Svi lični i osetljivi korisnički podaci se prenose i čuvaju bezbedno, koristeći modernu kriptografiju, kao što je HTTPS.\n\n3. **Dozvole za vreme izvršavanja**: Koristimo zahteve za dozvole za vreme izvršavanja pre pristupa podacima ograničenim Android dozvolama.\n\n4. **Nema prodaje podataka**: Ne prodajemo vaše lične i osetljive korisničke podatke.\n\n5. **Usklađenost sa zakonima**: Možemo da prenesemo podatke dobavljačima usluga ili iz pravnih razloga, kao što je usklađenost sa zahtevima vlade, zakonima ili u slučaju spajanja ili akvizicije, uz zakonski odgovarajuće obaveštenje.\n\n## Istaknuto otkrivanje podataka i saglasnost\n\nU situacijama u kojima pristup podacima, prikupljanje, korišćenje ili deljenje možda neće biti u skladu sa vašim očekivanjima:\n\n1. **Otkrivanje u aplikaciji**: Pružamo otkrivanje u aplikaciji sa detaljima o našoj praksi podataka, koje je lako dostupno tokom normalnog korišćenja aplikacije.\n\n2. **Saglasnost korisnika**: Tražimo vašu izričitu saglasnost za prikupljanje podataka i pristup, osiguravajući da pristanak bude informisan i nedvosmislen.\n\n3. **Pravne osnove**: Za obradu ličnih i osetljivih podataka bez pristanka (npr. prema EU GDPR), poštujemo sve zakonske zahteve, uključujući obezbeđivanje odgovarajućeg otkrivanja podataka.\n\n## Primer istaknutog obelodanjivanja\n\n„GimFeed prikuplja i koristi podatke o lokaciji kako bi poboljšao vaše iskustvo praćenja fitnesa, čak i kada se aplikacija aktivno ne koristi.\n\n## Kod treće strane\n\nAko GimFeed integriše kod treće strane koji prikuplja lične i osetljive podatke, mi obezbeđujemo usklađenost sa našim smernicama za istaknuto otkrivanje podataka i saglasnost i pružamo dokaze o takvoj usklađenosti sa Google Play-om po potrebi.\n\n## Politika privatnosti Pristupačnost\n\nNaša politika privatnosti je:\n\n– Dostupna na stranici unosa u prodavnici GimFeed-a u Play konzoli.\n- Dostupna unutar same aplikacije GimFeed.\n– Jasno označena kao politika privatnosti.\n\n## Kontakt i upiti\n\nProgramer: Aleksandar Živković\nZa upite ili nedoumice u vezi sa privatnošću kontaktirajte nas na aleksandar.zivkovc@gmail.com.\n\n## Sveobuhvatno obelodanjivanje\n\nU potpunosti otkrivamo:\n\n– Vrste ličnih i osetljivih korisničkih podataka kojima se pristupa, prikupljaju, koriste i dele.\n- Strane sa kojima se dele bilo koji lični ili osetljivi podaci korisnika.\n- Naše bezbedne procedure rukovanja podacima.\n- Naša politika zadržavanja i brisanja podataka, koja vam omogućava da izbrišete svoje podatke nakon brisanja profila.\n\nHvala vam što ste izabrali GimFeed. Posvećeni smo zaštiti vaše privatnosti i obezbeđivanju bezbednog i prijatnog iskustva.',
    },
  },
  // markReel
  {
    '3bwusn6b': {
      'en': 'Report',
      'sr': 'Prijavi',
    },
  },
  // reportStatusReel
  {
    'lkev49ko': {
      'en': 'I just dont like it',
      'sr': 'Samo mi se ne svidja',
    },
    '5emuvz7r': {
      'en': 'This is spaming me',
      'sr': 'Ovo me spamuje',
    },
    '9kfxso7t': {
      'en': 'Nudity or sexual activity',
      'sr': 'Golotinja ili seksualna aktivnost',
    },
    '8bot2c9j': {
      'en': 'Hate speech or symbols',
      'sr': 'Govor mržnje ili simboli',
    },
    'pkntpf8i': {
      'en': 'Violence or dangerous organizations',
      'sr': 'Nasilje ili opasne ograniyacije',
    },
    '5i8i8lux': {
      'en': 'False information',
      'sr': 'Lazne informacije',
    },
    '49k1xuca': {
      'en': 'Bullying or harassment',
      'sr': 'Maltretiranje ili uznemiravanje',
    },
    '45ns9swp': {
      'en': 'Scam or fraud',
      'sr': 'Prevara',
    },
    '9wy0lt03': {
      'en': 'Suicide or self-injury',
      'sr': 'Samoubistvo ili povredjivanje',
    },
    '4jixnp7j': {
      'en': 'Sale of illegal or regulated goods',
      'sr': 'Prodaja ilegalne robe',
    },
    'sdr9brc4': {
      'en': 'Intellectual property violation',
      'sr': 'Krsenje intelektualnih svojina',
    },
    'lp3kau8h': {
      'en': 'Eating disorders',
      'sr': 'Poremecaji u ishrani',
    },
    '1lf2d8w2': {
      'en': 'Drugs',
      'sr': 'Droga',
    },
    '9vmyldkh': {
      'en': 'Something else',
      'sr': 'Nesto drugo',
    },
    'xcek6vb8': {
      'en': 'Submit report',
      'sr': 'Pošalji izveštaj',
    },
  },
  // reportdialog
  {
    'o8yh0ctq': {
      'en': 'Report Submitted',
      'sr': 'Izveštaj poslat',
    },
    '84hlcrlu': {
      'en': 'Block User',
      'sr': 'Blokiraj korisnika',
    },
    'tfwjmi03': {
      'en': 'Cancel',
      'sr': 'Poništi',
    },
  },
  // blocked
  {
    'm8uv372e': {
      'en': 'Do you want to block this user?',
      'sr': '',
    },
    'xpgq5hsy': {
      'en': 'Block',
      'sr': 'Blokiraj',
    },
    '6hkul85x': {
      'en': 'Cancel',
      'sr': '',
    },
  },
  // deletefoodpost
  {
    'jknxp90i': {
      'en': 'Delete Post',
      'sr': 'Izbriši objavu',
    },
    'yi53k2aw': {
      'en': 'Cancel',
      'sr': 'Otkaži',
    },
  },
  // markFood
  {
    'wgvioz1m': {
      'en': 'Report',
      'sr': 'Prijavi',
    },
  },
  // reportStatusFood
  {
    'hrs0x28a': {
      'en': 'I just dont like it',
      'sr': 'Samo mi se ne svidja',
    },
    'b2xd59wf': {
      'en': 'This is spaming me',
      'sr': 'Ovo me spama',
    },
    'zeqebbvc': {
      'en': 'Nudity or sexual activity',
      'sr': 'Golotinja ili seksualna aktivnost',
    },
    '2rochx8w': {
      'en': 'Hate speech or symbols',
      'sr': 'Govor mržnje ili simboli',
    },
    's480w05z': {
      'en': 'Violence or dangerous organizations',
      'sr': 'Nasilje ili opasne ograniyacije',
    },
    'cyaqx1fk': {
      'en': 'False information',
      'sr': 'Lazne informacije',
    },
    'b31qm3mt': {
      'en': 'Bullying or harassment',
      'sr': 'Maltretiranje ili uznemiravanje',
    },
    '4wj297ok': {
      'en': 'Scam or fraud',
      'sr': 'Prevara',
    },
    '1nttwdgn': {
      'en': 'Suicide or self-injury',
      'sr': 'Samoubistvo ili povredjivanje',
    },
    '7na8wngz': {
      'en': 'Sale of illegal or regulated goods',
      'sr': 'Prodaja ilegalne robe',
    },
    's1ftjzmm': {
      'en': 'Intellectual property violation',
      'sr': 'Krsenje intelektualnih svojina',
    },
    '9gdch31p': {
      'en': 'Eating disorders',
      'sr': 'Poremecaji u ishrani',
    },
    'jsale30d': {
      'en': 'Drugs',
      'sr': 'Droga',
    },
    'jmjnm9sa': {
      'en': 'Something else',
      'sr': 'Nesto drugo',
    },
    'ubkp7pe3': {
      'en': 'Submit report',
      'sr': 'Pošalji izveštaj',
    },
  },
  // emailResend
  {
    'up0qun3t': {
      'en': 'Email Verification',
      'sr': 'Verifikacija e-adrese',
    },
    '0o7gjxcj': {
      'en':
          'An email has been sent to your inbox. Please click on the verification link to complete the process orignore this message if you already have',
      'sr':
          'Poruka e-pošte je poslata u vaše prijemno sanduče. Kliknite na vezu za verifikaciju da biste dovršili proces.',
    },
    '0yuctbwh': {
      'en': 'Resend Verification Email',
      'sr': 'Ponovo pošalji verifikacioni email',
    },
  },
  // editsettings
  {
    '2nc3e9q1': {
      'en': 'Edit Profile',
      'sr': 'Uredi profil',
    },
    'z3t3m6pe': {
      'en': 'Contact Support',
      'sr': 'Kontaktiraj podršku',
    },
    '0bqetyl6': {
      'en': 'Language',
      'sr': 'Jezik',
    },
    '511cgxq8': {
      'en': 'Change Password',
      'sr': 'Promeni lozinku',
    },
    'fkdxk27q': {
      'en': 'Blocked Users',
      'sr': 'Blokirani korisnici',
    },
    '2kcrf2yf': {
      'en': 'Saved Posts',
      'sr': 'Sačuvani postovi',
    },
    'fc99io04': {
      'en': 'Privacy Policy',
      'sr': 'Pravila privatnosti',
    },
    'mvcw6otv': {
      'en': 'Delete Profile',
      'sr': 'Izbriši profil',
    },
    'tfdcvty7': {
      'en': 'Log Out',
      'sr': 'Odjavi se',
    },
  },
  // deleteAccountSecondStep
  {
    '2swnvhav': {
      'en': 'Delete account ?',
      'sr': 'Izbrisati nalog?',
    },
    'ebx2bhhb': {
      'en':
          'By doing this you will \npermanetly delete account \nand all of you data',
      'sr': 'Radeći ovo cete\ntrajno obrisati nalog\ni sve vaše podatke',
    },
    'drygbd8a': {
      'en': 'Delete',
      'sr': 'Izbriši',
    },
    'dncgy46j': {
      'en': 'Cancel',
      'sr': 'Otkaži',
    },
  },
  // create
  {
    'js5zikf0': {
      'en': 'Create Post',
      'sr': 'Kreiraj post',
    },
    't1t0tfp9': {
      'en': 'Create workout',
      'sr': 'Kreiraj trening',
    },
    'tux9ws0u': {
      'en': 'Create food post',
      'sr': 'Kreiraj post o ishrani',
    },
  },
  // NavBar
  {
    '5l5hq4lu': {
      'en': 'Home',
      'sr': 'Početna',
    },
    'x5pwi5zt': {
      'en': 'Explore',
      'sr': 'Istražite',
    },
    'r6zo6wta': {
      'en': 'GymFeed',
      'sr': 'GymFeed',
    },
    'q6dytyut': {
      'en': 'FitClips',
      'sr': 'FitClips',
    },
    'xoc4fmlt': {
      'en': 'Profile',
      'sr': 'Profil',
    },
  },
  // reportStatus
  {
    'ngffo1s9': {
      'en': 'I just dont like it',
      'sr': 'Samo mi se ne svidja',
    },
    '7hr7b52e': {
      'en': 'This is spaming me',
      'sr': 'Ovo me spamuje',
    },
    'p7lbe1m8': {
      'en': 'Nudity or sexual activity',
      'sr': 'Golotinja ili seksualna aktivnost',
    },
    '2bosdn41': {
      'en': 'Hate speech or symbols',
      'sr': 'Govor mržnje ili simboli',
    },
    'wq9bgzst': {
      'en': 'Violence or dangerous organizations',
      'sr': 'Nasilje ili opasne ograniyacije',
    },
    'a19lsbj3': {
      'en': 'False information',
      'sr': 'Lazne informacije',
    },
    '2c8alb31': {
      'en': 'Bullying or harassment',
      'sr': 'Maltretiranje ili uznemiravanje',
    },
    'l548bday': {
      'en': 'Scam or fraud',
      'sr': 'Prevara',
    },
    'xpxdla5m': {
      'en': 'Suicide or self-injury',
      'sr': 'Samoubistvo ili povredjivanje',
    },
    'qdb522j5': {
      'en': 'Sale of illegal or regulated goods',
      'sr': 'Prodaja ilegalne robe',
    },
    'vk78b9ud': {
      'en': 'Intellectual property violation',
      'sr': 'Krsenje intelektualnih svojina',
    },
    'wza1prz0': {
      'en': 'Eating disorders',
      'sr': 'Poremecaji u ishrani',
    },
    'g16n0fa3': {
      'en': 'Drugs',
      'sr': 'Droga',
    },
    'mg8oemdb': {
      'en': 'Something else',
      'sr': 'Nesto drugo',
    },
    'ma690eie': {
      'en': 'Submit report',
      'sr': 'Pošalji izveštaj',
    },
  },
  // postFood
  {
    '6io4czbf': {
      'en': ' ',
      'sr': '',
    },
    'xthfqp3u': {
      'en': 'View 1 comment',
      'sr': 'Pogledaj 1 komentar',
    },
    '961cy50r': {
      'en': ' ',
      'sr': '',
    },
    '8trwzgv6': {
      'en': 'Add a comment...',
      'sr': 'Dodaj komentar...',
    },
    '2fib5uvj': {
      'en': 'Informations',
      'sr': 'Informacije',
    },
    '3ihvnhfb': {
      'en': 'Preparation time',
      'sr': 'Vreme pripreme',
    },
    '1lnewlq7': {
      'en': 'Meal type',
      'sr': 'Tip obroka',
    },
    '39cbzkza': {
      'en': 'Name of the dish',
      'sr': 'Ime jela',
    },
    'o9qcggzl': {
      'en': 'Nutrition Facts',
      'sr': 'Nutritivne vrednosti',
    },
    'ozorrep8': {
      'en': 'Ingredients',
      'sr': 'Sastojci',
    },
    'uwgrbx5b': {
      'en': 'Calroies',
      'sr': 'Kalorije',
    },
    '7vz017rj': {
      'en': 'Protein',
      'sr': 'Proteini',
    },
    '19xqsc4j': {
      'en': 'Carbs',
      'sr': 'Kalorije',
    },
    'm49dtge4': {
      'en': 'Fats',
      'sr': 'Proteini',
    },
    'bgpfn8re': {
      'en': 'Recipe',
      'sr': 'Recept',
    },
  },
  // Aiworkout
  {
    'ty8jwsnz': {
      'en': 'Personal Ai fitness expert',
      'sr': 'Personalni Ai fitness expert',
    },
    'r61ewmig': {
      'en': 'Limit reached',
      'sr': 'Personalni Ai fitness expert',
    },
    '0oxhzu2l': {
      'en': 'Machine scanner',
      'sr': 'Skener mašina',
    },
    '8yziu2q2': {
      'en': 'Limit reached',
      'sr': 'Skener mašina',
    },
    'yd35hy2n': {
      'en': 'Meal scanner',
      'sr': 'Skener mašina',
    },
    '3pjj2pcb': {
      'en': 'Limit reached',
      'sr': 'Skener mašina',
    },
    'qmrkfb7r': {
      'en': 'Subscribe to get more',
      'sr': 'Skener mašina',
    },
  },
  // AiworkoutPro
  {
    'm3d453qn': {
      'en': 'Personal Ai fitness expert',
      'sr': 'Personalni Ai fitness expert',
    },
    'ot89mber': {
      'en': 'Machine scanner',
      'sr': 'Skener mašina',
    },
    '37is4453': {
      'en': 'Meal scanner',
      'sr': 'Skener mašina',
    },
  },
  // storyDelete
  {
    'hl6rg135': {
      'en': 'Remove this story',
      'sr': '',
    },
    'ub10iles': {
      'en': 'Delete story',
      'sr': '',
    },
    '60s4xl3o': {
      'en': 'Cancel',
      'sr': '',
    },
  },
  // storyUpload
  {
    'btbt98g3': {
      'en': 'Upload picture or video to your gym day',
      'sr': 'Dodaj sliku ili video na tvoj gym dan',
    },
    '73aoa54q': {
      'en': 'Image',
      'sr': 'Slika',
    },
    'bzr8xnu1': {
      'en': 'Video',
      'sr': 'Video',
    },
  },
  // editTrainingPre
  {
    'ma4g44v1': {
      'en': 'Edit Profile',
      'sr': 'Uredi profil',
    },
    'hdqd25p7': {
      'en': 'Edit Training',
      'sr': 'Pravila privatnosti',
    },
    'bk5auagn': {
      'en': 'Delete Training',
      'sr': 'Izbriši profil',
    },
  },
  // paymentFree
  {
    'flvi5kjb': {
      'en': 'Restore',
      'sr': 'Ресторе',
    },
    'etw2xh86': {
      'en': 'Premium',
      'sr': 'Премиум',
    },
    '5rnc2g2q': {
      'en': 'Unlock Your Fitness Journey \nwith Premium Access',
      'sr': 'Otključajte svoje fitnes \nputovanje\nsa Premium pristupom!',
    },
    'paxch3hf': {
      'en':
          'Elevate your fitness experience with our exclusive premium membership. Gain access to 500 personalized conversations with our expert fitness trainer each month, and enhance your progress tracking with 50 image uploads to our state-of-the-art machine scanner.',
      'sr':
          'Unapredite svoje fitnes iskustvo uz\nnaše ekskluzivno Premium članstvo. Dobijte pristup 1000 personalizovanih razgovora sa našim stručnim fitnes\ntrenerom svakog meseca i poboljšajte\npraćenje napretka pomoću 100\notpremanja slika na naš najsavremeniji\nmašinski skener.',
    },
    'izdhdkm8': {
      'en': 'FREE',
      'sr': '',
    },
    'g1eqiidi': {
      'en':
          'Last call to subscribe free for \npremium features is on 31st January',
      'sr': 'Mesečno',
    },
    'bel4irj0': {
      'en': 'Premium plan',
      'sr': 'Premijum plan',
    },
    'b2vxcjw4': {
      'en': 'Customer Support',
      'sr': 'Korisnićka podrška',
    },
    'xvhvqftk': {
      'en': 'Unlimited number of creations',
      'sr': 'Neograničen broj kreiranja',
    },
    '2pv6q4uf': {
      'en': 'Up to 500 conversations with AI trainer',
      'sr': 'Do 1000 poruka sa AI trenerom',
    },
    'g48epezv': {
      'en': 'Up to 50 uploads with Machine, \nBody and Meal Scanner',
      'sr': 'Do 100 poslatih slika sa Skenerom mašina',
    },
    'wxxc6ax4': {
      'en':
          'This trial will be closed when you reach 500 conversations with AI trainer and 50 uploads with Machine, Body and Meal Scanner. When the trial runs out you will be opted to subscribe',
      'sr':
          'Ova predplata će se automatski\nobnoviti osim ako automatsko\nobnavljnaje nije isključeno\n24 sata pre tekućeg perioda.',
    },
    'ayj1s0fy': {
      'en': 'START FREE TRIAL',
      'sr': '',
    },
    'exhxuzac': {
      'en': 'By continuing you agree to our',
      'sr': 'Ako nastavite slažete se sa našim',
    },
    '1b2v48lv': {
      'en': ' \nTerms of Use(EULA)',
      'sr': '\nUslovi korišćenja (EULA)',
    },
    '1gs1qjyq': {
      'en': ' and ',
      'sr': 'I',
    },
    'vw6qokwl': {
      'en': 'Privacy Policy',
      'sr': 'Politika privatnosti',
    },
  },
  // AddExcerciseCopy
  {
    'taceeeak': {
      'en': 'Create Workout',
      'sr': 'Kreiraj trening',
    },
    'a7kmrv7e': {
      'en': 'Enter Exercise name',
      'sr': 'Unesite naziv vežbe',
    },
    'fgvd14x5': {
      'en': 'Enter date',
      'sr': '',
    },
    'ftbuf549': {
      'en': 'Select...',
      'sr': '',
    },
    'b57ur52b': {
      'en': 'Search...',
      'sr': '',
    },
    'urd2ne1v': {
      'en': 'Light Intensity',
      'sr': '',
    },
    'ju3i3epl': {
      'en': 'Moderate Intensity',
      'sr': '',
    },
    'o0q6rc17': {
      'en': 'Maximal Intensity',
      'sr': '',
    },
    'l03h9say': {
      'en': 'Rest Time in minutes',
      'sr': 'Kg po seriji',
    },
    '40l5094t': {
      'en': 'Enter Exercise description',
      'sr': 'Unesite naziv vežbe',
    },
    '8mx9anmq': {
      'en': 'Enter Exercise sets',
      'sr': 'Unesite naziv vežbe',
    },
    '4kbj6cd8': {
      'en': 'Enter Exercise reps',
      'sr': 'Unesite naziv vežbe',
    },
    'q88x8a8v': {
      'en': 'Enter Exercise kg',
      'sr': 'Unesite naziv vežbe',
    },
    'g2revttf': {
      'en': 'Done',
      'sr': 'Gotovo',
    },
  },
  // uploadChoice
  {
    'n0n4ygw1': {
      'en': 'Chose Gallery or Camera',
      'sr': 'Dodaj sliku ili video na tvoj gym dan',
    },
  },
  // paymentReport
  {
    'qa9yigis': {
      'en': 'Restore',
      'sr': 'Ресторе',
    },
    'n43mhnjm': {
      'en': 'Premium',
      'sr': 'Премиум',
    },
    'ks1w7xwu': {
      'en': 'Unlock Your Personalized 3-Month Fitness & Meal Plan!',
      'sr': 'Otključajte svoje fitnes \nputovanje\nsa Premium pristupom!',
    },
    '2luaomjp': {
      'en':
          '💪 Transform Your Body with a Science-Backed Plan\nGet a customized 3-month fitness and meal plan designed just for you! Our AI-driven analysis considers your goal, your current measures, body composition, BMI, lean mass, and fat mass index to create the most effective program tailored to your goals.',
      'sr':
          'Unapredite svoje fitnes iskustvo uz\nnaše ekskluzivno Premium članstvo. Dobijte pristup 1000 personalizovanih razgovora sa našim stručnim fitnes\ntrenerom svakog meseca i poboljšajte\npraćenje napretka pomoću 100\notpremanja slika na naš najsavremeniji\nmašinski skener.',
    },
    'f32viivh': {
      'en': 'One time payment',
      'sr': 'Mesečno',
    },
    'pgo6ex2p': {
      'en': '3-Month Plan',
      'sr': 'Premijum plan',
    },
    '8es510ld': {
      'en': 'Personalized Workout Plan',
      'sr': 'Korisnićka podrška',
    },
    'cmwd8nmj': {
      'en': 'Custom Meal Plan',
      'sr': 'Neograničen broj kreiranja',
    },
    '861vxypj': {
      'en': 'Detailed Body Analysis',
      'sr': 'Икона Премиум профила',
    },
    'ilx79lbi': {
      'en': 'Shopping list',
      'sr': 'Do 1000 poruka sa AI trenerom',
    },
    'js7mqfin': {
      'en': 'And much more',
      'sr': 'Do 100 poslatih slika sa Skenerom mašina',
    },
    '7ee1vtkd': {
      'en':
          '🚀 Invest in Your Health Today!\nTake control of your fitness journey with a structured plan that works. No guesswork, just results!\n\n🔒 Secure Payment – One-Time Purchase, No Hidden Fees',
      'sr':
          'Ova predplata će se automatski\nobnoviti osim ako automatsko\nobnavljnaje nije isključeno\n24 sata pre tekućeg perioda.',
    },
    '484v90ud': {
      'en': 'Start',
      'sr': 'Predplati se',
    },
    'rkkojgtn': {
      'en': 'By continuing you agree to our',
      'sr': 'Ako nastavite slažete se sa našim',
    },
    'dfffqvq7': {
      'en': ' \nTerms of Use(EULA)',
      'sr': '\nUslovi korišćenja (EULA)',
    },
    'mimxwy4p': {
      'en': ' and ',
      'sr': 'I',
    },
    'vjy6jbzs': {
      'en': 'Privacy Policy',
      'sr': 'Politika privatnosti',
    },
  },
  // Miscellaneous
  {
    'gcg2106a': {
      'en':
          'Our app requires access to your camera to allow you to capture photos and videos directly within the app. This feature enables you to create and share new content with your friends and followers on our social network. For example, you can take a selfie or record a video message to post on your profile.',
      'sr':
          'Наша апликација захтева приступ вашој камери да бисте могли да снимате фотографије и видео записе директно у апликацији. Ова функција вам омогућава да креирате и делите нови садржај са својим пријатељима и пратиоцима на нашој друштвеној мрежи. На пример, можете да направите селфи или снимите видео поруку да бисте је поставили на свој профил.',
    },
    'l5lwdygu': {
      'en':
          'Our app needs access to your photo library so you can select and upload images or videos from your device to share with your network. This feature allows you to choose existing content from your gallery to post on our platform. For example, you can pick a memorable photo from your library to share as a throwback post with your friends.',
      'sr':
          'Нашој апликацији је потребан приступ вашој библиотеци фотографија да бисте могли да изаберете и отпремите слике или видео записе са свог уређаја да бисте их делили са својом мрежом. Ова функција вам омогућава да изаберете постојећи садржај из ваше галерије за објављивање на нашој платформи. На пример, можете да изаберете незаборавну фотографију из своје библиотеке да бисте је поделили са пријатељима као повратну објаву.',
    },
    'jw8efk4w': {
      'en':
          'We need to use your device\'s microphone to record audio for your videos. For example, if you\'re making a video blog, the app will use the microphone to capture your voice as you speak.',
      'sr':
          'Морамо да користимо микрофон вашег уређаја за снимање звука за ваше видео снимке. На пример, ако правите видео блог, апликација ће користити микрофон да сними ваш глас док говорите.',
    },
    'yz340nsx': {
      'en':
          'Enable push notifications to stay up to date with actions inside of Instagram.',
      'sr':
          'Омогућите пусх обавештења да бисте били у току са радњама унутар Инстаграма.',
    },
    'huukiqrx': {
      'en': '',
      'sr': '',
    },
    'za8q212g': {
      'en': '',
      'sr': '',
    },
    'lxtfsg8r': {
      'en': '',
      'sr': '',
    },
    'ys5qf4m9': {
      'en': '',
      'sr': '',
    },
    'ffkac8jj': {
      'en': '',
      'sr': '',
    },
    'thsvqtp0': {
      'en': '',
      'sr': '',
    },
    '5ony4v3q': {
      'en': '',
      'sr': '',
    },
    'mrvmih5m': {
      'en': '',
      'sr': '',
    },
    'bvxh2hwk': {
      'en': '',
      'sr': '',
    },
    'glh93phq': {
      'en': '',
      'sr': '',
    },
    'j5g3hwna': {
      'en': '',
      'sr': '',
    },
    'kfza44m1': {
      'en': '',
      'sr': '',
    },
    'gosssd4n': {
      'en': '',
      'sr': '',
    },
    't39savls': {
      'en': '',
      'sr': '',
    },
    'fprfdypk': {
      'en': '',
      'sr': '',
    },
    'mt1h6dfx': {
      'en': '',
      'sr': '',
    },
    's5u8dvbg': {
      'en': '',
      'sr': '',
    },
    '16dfnoe7': {
      'en': '',
      'sr': '',
    },
    'imysya8p': {
      'en': '',
      'sr': '',
    },
    'l0jzlzd4': {
      'en': '',
      'sr': '',
    },
    'ocioc69n': {
      'en': '',
      'sr': '',
    },
    'l6bhyrmy': {
      'en': '',
      'sr': '',
    },
    's4a2vvls': {
      'en': '',
      'sr': '',
    },
    'zah6v0rd': {
      'en': '',
      'sr': '',
    },
    'lh65xiyp': {
      'en': '',
      'sr': '',
    },
    'poletj6s': {
      'en':
          'By clicking here you can access your custom meal and training plan !',
      'sr':
          'Кликом овде можете приступити свом прилагођеном плану оброка и тренинга и још много тога!',
    },
    'uoxtqdvp': {
      'en':
          'Personal machine scanner, meal calories counter and much more plus your Personal Trainer',
      'sr':
          'Лични машински скенер, бројач калорија у оброку и још много тога плус ваш лични тренер',
    },
    'v2pmtg65': {
      'en':
          'Click here to view joined trainigs, create trainings and to create you personal workout plan',
      'sr':
          'Кликните овде да видите удружене тренинге, креирате тренинге и да креирате свој лични план вежбања',
    },
    'hwgngl7b': {
      'en': 'Workouts that you have joined.',
      'sr': 'Вежбе којима сте се придружили.',
    },
    'u2dty5mv': {
      'en': 'Workouts that you have created.',
      'sr': 'Вежбе које сте креирали.',
    },
    'vdvlkmci': {
      'en': 'Create you own custom workout plan.',
      'sr': 'Направите сопствени прилагођени план вежбања.',
    },
    'ijn5uj3i': {
      'en': 'Create your new training today!',
      'sr': 'Креирајте свој нови тренинг данас!',
    },
  },
].reduce((a, b) => a..addAll(b));
