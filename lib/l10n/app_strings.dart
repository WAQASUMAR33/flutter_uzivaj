import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/locale_provider.dart';

class AppStrings {
  final bool _isHR;
  const AppStrings._(this._isHR);

  static AppStrings of(BuildContext context, {bool? listen}) {
    String code = 'hr';
    try {
      final shouldListen = listen ?? (context.owner?.debugBuilding == true);
      final provider = shouldListen
          ? Provider.of<LocaleProvider>(context, listen: true)
          : Provider.of<LocaleProvider>(context, listen: false);
      code = provider.locale.languageCode;
    } catch (_) {
      try {
        code = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
      } catch (_) {
        try {
          code = Localizations.localeOf(context).languageCode;
        } catch (_) {
          code = 'hr';
        }
      }
    }
    return AppStrings._(code == 'hr');
  }

  // ── Onboarding ──────────────────────────────────────────────────────────────
  String get skip => _isHR ? 'Preskoči' : 'Skip';
  String get next => _isHR ? 'Dalje →' : 'Next →';
  String get startExploring =>
      _isHR ? 'Počni istraživati →' : 'Start exploring →';
  String get onboarding1Title =>
      _isHR ? 'Uživaj više.\nPlati manje.' : 'Enjoy more.\nPay less.';
  String get onboarding1Desc => _isHR
      ? 'Uživaj je ugostiteljsko članstvo koje vam daje pristup ekskluzivnim ponudama "Kupi 1 Dobij 1 besplatno" u najboljim restoranima, kafićima i barovima Zagreba.'
      : "Užívaj is a dining membership that gives you access to exclusive Buy 1 Get 1 Free offers at Zagreb's best restaurants, cafés and bars.";
  String get onboarding2Title =>
      _isHR ? 'Korištenje je\njednostavno.' : 'Redeeming is\nsimple.';
  String get onboarding2Desc => _isHR
      ? 'Odaberi ponudu i predaj telefon konobaru. Unose PIN restorana i ponuda se odmah potvrđuje. Bez QR kodova, bez tiskanja.'
      : "Pick an offer, hand your phone to the waiter. They enter the restaurant's PIN and the offer is instantly confirmed. No QR codes, no printing.";
  String get onboarding3Title =>
      _isHR ? 'Tvoj grad,\ntvoj stol.' : 'Your city,\nyour table.';
  String get onboarding3Desc => _isHR
      ? 'Jedna večera vani pokriva cijelu godišnju pretplatu. Sve ostalo su čiste uštedine. Krenimo.'
      : "One dinner out covers your entire year's membership. Everything else is pure saving. Let's get started.";
  String get tapAnOffer => _isHR ? 'Odaberi ponudu' : 'Tap an offer';
  String get chooseBogo =>
      _isHR ? 'Odaberi BOGO ili popust' : 'Choose BOGO or discount';
  String get handToWaiter => _isHR ? 'Predaj konobaru' : 'Hand to waiter';
  String get enterPin =>
      _isHR ? 'Unose 4-znamenkasti PIN' : 'They enter their 4-digit PIN';
  String get offerUnlocked => _isHR ? 'Ponuda otključana!' : 'Offer unlocked!';
  String get enjoyMeal => _isHR ? 'Uživajte u obroku' : 'Enjoy your meal';
  String get offersPerRestaurant =>
      _isHR ? '3 ponude po restoranu' : '3 offers per restaurant';
  String get eachRedeemableOnce =>
      _isHR ? 'Svaka jedanput iskoristiva' : 'Each redeemable once';
  String get zagrebVenues =>
      _isHR ? '50+ objekata u Zagrebu' : '50+ Zagreb venues';
  String get newPlacesMonthly =>
      _isHR ? 'Novi prostori svaki mjesec' : 'New places added monthly';
  String get oneDinnerPaysBack =>
      _isHR ? 'Jedna večera pokrije troškove' : 'One dinner pays it back';
  String get pricePerYear =>
      _isHR ? '€39/god. = €3,25/mj.' : '€39/year = €3.25/month';

  // ── Login ───────────────────────────────────────────────────────────────────
  String get welcomeBack => _isHR ? 'Dobrodošli natrag' : 'Welcome back';
  String get signInToContinue =>
      _isHR ? 'Prijavite se za nastavak' : 'Sign in to continue';
  String get emailLabel => _isHR ? 'E-MAIL' : 'EMAIL';
  String get passwordLabel => _isHR ? 'LOZINKA' : 'PASSWORD';
  String get forgotPassword =>
      _isHR ? 'Zaboravili ste lozinku?' : 'Forgot password?';
  String get resetPasswordScreenTitle =>
      _isHR ? 'Nova lozinka' : 'Reset Password';
  String get enterNewPasswordDesc => _isHR
      ? 'Unesite svoju novu lozinku u nastavku'
      : 'Enter your new password below';
  String get resetPasswordBtn =>
      _isHR ? 'Postavi novu lozinku' : 'Reset Password';
  String get passwordResetSuccess =>
      _isHR ? 'Lozinka uspješno promijenjena' : 'Password successfully reset';
  String get resetPasswordTitle =>
      _isHR ? 'Zaboravili ste lozinku?' : 'Forgot Password?';
  String get resetPasswordDesc => _isHR
      ? 'Unesite svoju e-mail adresu za primanje koda za ponovno postavljanje lozinke.'
      : 'Enter your email address to receive a password reset code.';
  String get verifyCodeTitle => _isHR ? 'Potvrdi kod' : 'Verify Code';
  String verifyCodeDesc(String email) => _isHR
      ? 'Unesite 6-znamenkasti kod poslan na $email'
      : 'Enter the 6-digit code sent to $email';
  String get verificationCodeLabel =>
      _isHR ? 'Verifikacijski kod' : 'Verification Code';
  String get resendOtp => _isHR ? 'Ponovno pošalji kod' : 'Resend OTP';
  String get codeRequired => _isHR ? 'Kod je obavezan' : 'Code is required';
  String get codeLength =>
      _isHR ? 'Kod mora imati 6 znamenki' : 'Code must be 6 digits';
  String get otpResent => _isHR
      ? 'Kod je ponovno poslan na vaš e-mail'
      : 'OTP has been resent to your email';
  String get sendResetLink => _isHR ? 'Pošalji poveznicu' : 'Send reset link';
  String get cancel => _isHR ? 'Odustani' : 'Cancel';
  String get resetLinkSent => _isHR
      ? 'Ako račun postoji, poslana je poveznica za resetiranje.'
      : "If an account exists, a reset link has been sent.";
  String get signIn => _isHR ? 'Prijava' : 'Sign In';
  String get orContinueWith => _isHR ? 'ili nastavite s' : 'or continue with';
  String get continueAsGuest =>
      _isHR ? 'Nastavi kao gost' : 'Continue as guest';
  String get noAccount => _isHR ? 'Nemate račun? ' : 'No account? ';
  String get signUp => _isHR ? 'Registrirajte se' : 'Sign up';
  String get emailRequired =>
      _isHR ? 'E-mail je obavezan' : 'Email is required';
  String get emailInvalid =>
      _isHR ? 'Unesite valjanu e-mail adresu' : 'Enter a valid email address';
  String get passwordRequired =>
      _isHR ? 'Lozinka je obavezna' : 'Password is required';
  String get passwordLength => _isHR
      ? 'Lozinka mora imati između 8 i 20 znakova'
      : 'Password must be between 8 and 20 characters';
  String get passwordLowercase => _isHR
      ? 'Mora sadržavati barem 1 malo slovo'
      : 'Must contain at least 1 lowercase letter';
  String get passwordUppercase => _isHR
      ? 'Mora sadržavati barem 1 veliko slovo'
      : 'Must contain at least 1 uppercase letter';
  String get passwordDigit =>
      _isHR ? 'Mora sadržavati barem 1 broj' : 'Must contain at least 1 digit';

  // ── Signup ──────────────────────────────────────────────────────────────────
  String get createAccount => _isHR ? 'Stvori račun' : 'Create Account';
  String get joinUzivaj => _isHR ? 'Pridruži se Uživaj' : 'Join Uživaj';
  String get fullNameLabel => _isHR ? 'PUNO IME' : 'FULL NAME';
  String get fullNameHint => _isHR ? 'Ivan Horvat' : 'John Doe';
  String get mobileLabel => _isHR ? 'BROJ MOBITELA' : 'MOBILE NUMBER';
  String get dobLabel => _isHR ? 'DATUM ROĐENJA' : 'DATE OF BIRTH';
  String get dobHint => _isHR ? 'DD / MM / GGGG' : 'DD / MM / YYYY';
  String get nationalityLabel => _isHR ? 'NACIONALNOST' : 'NATIONALITY';
  String get selectNationality =>
      _isHR ? 'Odaberite nacionalnost' : 'Select nationality';
  String get genderLabel => _isHR ? 'SPOL' : 'GENDER';
  String get male => _isHR ? 'Muško' : 'Male';
  String get female => _isHR ? 'Žensko' : 'Female';
  String get preferNotToSay => _isHR ? 'Ne želim reći' : 'Prefer not to say';
  String get confirmPasswordLabel =>
      _isHR ? 'POTVRDI LOZINKU' : 'CONFIRM PASSWORD';
  String get createStrongPassword =>
      _isHR ? 'Stvorite jaku lozinku' : 'Create a strong password';
  String get repeatPassword =>
      _isHR ? 'Ponovite lozinku' : 'Repeat your password';
  String get iAgreeTo => _isHR ? 'Slažem se s ' : 'I agree to the ';
  String get termsOfService =>
      _isHR ? 'Uvjetima korištenja' : 'Terms and Conditions';
  String get andText => _isHR ? ' i ' : ' and ';
  String get privacyPolicy =>
      _isHR ? 'Politikom privatnosti' : 'Privacy Policy';
  String get pleaseSelectGender =>
      _isHR ? 'Molimo odaberite spol' : 'Please select a gender';
  String get pleaseAgreeTerms => _isHR
      ? 'Molimo prihvatite Uvjete korištenja'
      : 'Please agree to the Terms of Service';
  String get fullNameRequired =>
      _isHR ? 'Puno ime je obavezno' : 'Full name is required';
  String get mobileRequired =>
      _isHR ? 'Broj mobitela je obavezan' : 'Mobile number is required';
  String get mobileInvalid => _isHR
      ? 'Unesite valjani broj mobitela'
      : 'Enter a valid mobile phone number';
  String get dobRequired =>
      _isHR ? 'Datum rođenja je obavezan' : 'Date of birth is required';
  String get nationalityRequired =>
      _isHR ? 'Nacionalnost je obavezna' : 'Nationality is required';
  String get confirmPasswordRequired =>
      _isHR ? 'Molimo potvrdite lozinku' : 'Please confirm your password';
  String get passwordsMismatch =>
      _isHR ? 'Lozinke se ne podudaraju' : 'Passwords do not match';
  String get searchCountryHint =>
      _isHR ? 'Pretraži zemlju...' : 'Search country...';

  // ── Home ────────────────────────────────────────────────────────────────────
  String get discoverZagreb =>
      _isHR ? 'Otkrij drugačije.' : 'Discover differently.';
  String get searchHint =>
      _isHR ? 'Pretraži restorane, kafiće...' : 'Search restaurants, cafés...';
  String get categoriesLabel => _isHR ? 'KATEGORIJE' : 'CATEGORIES';
  String get allCategory => _isHR ? 'Sve' : 'All';
  String get nearbyOffers => _isHR ? 'Ponude u blizini' : 'Nearby offers';
  String get viewAll => _isHR ? 'Vidi sve →' : 'View all →';
  String get noOffersInCategory => _isHR
      ? 'Još nema ponuda u ovoj kategoriji.'
      : 'No offers in this category yet.';
  String get homeTab => _isHR ? 'Početna' : 'Home';
  String get searchTab => _isHR ? 'Pretraga' : 'Search';
  String get nearbyTab => _isHR ? 'U blizini' : 'Nearby';
  String get profileTab => _isHR ? 'Profil' : 'Profile';
  String get mySubscriptions => _isHR ? 'Moje pretplate' : 'My Subscriptions';
  String get redeemHistory =>
      _isHR ? 'Povijest iskorištavanja' : 'Redeem History';
  String get termsAndConditions =>
      _isHR ? 'Uvjeti i odredbe' : 'Terms & Conditions';
  String get welcome => _isHR ? 'Dobrodošli!' : 'Welcome!';
  String get guest => _isHR ? 'Gost' : 'Guest';
  String get aboutApp => _isHR ? 'O aplikaciji' : 'About App';
  String get help => _isHR ? 'Pomoć' : 'Help';
  String get logout => _isHR ? 'Odjava' : 'Logout';
  String get noResultsFound =>
      _isHR ? 'Nema pronađenih rezultata.' : 'No results found.';
  String get allVenuesLabel =>
      _isHR ? 'SVI OBJEKTI · NAJBLIŽI PRVI' : 'ALL VENUES · NEAREST FIRST';
  String get language => _isHR ? 'Jezik / Language' : 'Language / Jezik';
  String searchResultsLabel(int count) {
    if (_isHR)
      return '$count ${count == 1 ? 'REZULTAT' : 'REZULTATA'} · SORTIRANO PO UDALJENOSTI';
    return '$count RESULT${count != 1 ? 'S' : ''} · SORTED BY DISTANCE';
  }

  // ── Nearby ──────────────────────────────────────────────────────────────────
  String get locationServicesOff =>
      _isHR ? 'Lokacijske usluge isključene' : 'Location services off';
  String get enableLocationServices => _isHR
      ? 'Uključite lokacijske usluge u postavkama uređaja kako biste vidjeli restorane u blizini.'
      : 'Enable location services in your device settings to see restaurants near you.';
  String get openSettings => _isHR ? 'Otvori postavke' : 'Open Settings';
  String get locationAccessNeeded =>
      _isHR ? 'Potreban pristup lokaciji' : 'Location access needed';
  String get allowLocationAccess => _isHR
      ? 'Dopustite pristup lokaciji kako biste otkrili restorane i kafiće u blizini.'
      : 'Allow location access to discover restaurants and cafés near you.';
  String get grantPermission => _isHR ? 'Daj dopuštenje' : 'Grant permission';
  String get noVenuesAvailable =>
      _isHR ? 'Nema dostupnih objekata.' : 'No venues available.';
  String get venueLocationsUnavailable => _isHR
      ? 'Lokacije objekata još nisu dostupne.'
      : 'Venue locations are not available yet.';
  String nearbyCount(int count) => _isHR ? '$count u blizini' : '$count nearby';

  // ── Profile ─────────────────────────────────────────────────────────────────
  String get myProfile => _isHR ? 'Moj profil' : 'My Profile';
  String memberSince(String date) =>
      _isHR ? 'Član od $date' : 'Member since $date';
  String renewsDate(String date) => _isHR ? 'Obnova: $date' : 'Renews: $date';
  String get estSaved => _isHR ? 'Procj. uštedina' : 'Est. saved';
  String get offersUsed => _isHR ? 'Iskorištene ponude' : 'Offers used';
  String get accountSection => _isHR ? 'RAČUN' : 'ACCOUNT';
  String get subscriptionSection => _isHR ? 'PRETPLATA' : 'SUBSCRIPTION';
  String get noActiveSubscription =>
      _isHR ? 'Nema aktivne pretplate' : 'No active subscription';
  String get subscribe => _isHR ? 'Pretplati se' : 'Subscribe';
  String get loginToSubscribe => _isHR
      ? 'Prijavite se za pretplatu'
      : 'Please log in to subscribe';
  String get subscriptionPlan =>
      _isHR ? 'Pretplatnički plan' : 'Subscription Plan';
  String get helpSection => _isHR ? 'POMOĆ' : 'HELP';
  String get howItWorks => _isHR ? 'Kako funkcionira' : 'How it works';
  String get howItWorksSub =>
      _isHR ? 'Ponovno pogledaj uvod' : 'Replay the intro walkthrough';
  String get contactSupport =>
      _isHR ? 'Kontaktirajte podršku' : 'Contact Support';
  String get contactSupportSub => _isHR
      ? 'Pošaljite nam poruku ako trebate pomoć'
      : 'Send us a message if you need assistance';
  String get supportSubject => _isHR ? 'Predmet' : 'Subject';
  String get supportMessage => _isHR ? 'Poruka' : 'Message';
  String get supportSubjectRequired =>
      _isHR ? 'Predmet je obavezan' : 'Subject is required';
  String get supportMessageRequired =>
      _isHR ? 'Poruka je obavezna' : 'Message is required';
  String get supportSuccess => _isHR
      ? 'Poruka podrške uspješno poslana'
      : 'Support message sent successfully';

  // ── Offer Redemption ────────────────────────────────────────────────────────
  String get redeemingAt => _isHR ? 'Iskorištavanje ponude u' : 'Redeeming at';
  String get waiterEntersPin =>
      _isHR ? 'Konobar unosi PIN' : 'Waiter enters the PIN';
  String get handPhoneToWaiter => _isHR
      ? 'Predajte telefon konobaru.\nOni unose 4-znamenkasti kod restorana.'
      : 'Hand your phone to the waiter.\nThey enter the restaurant\'s 4-digit code.';
  String get codeIsInvalid => _isHR ? 'Kod nije valjan' : 'Code is invalid';
  String get redeemedAt => _isHR ? 'Iskorišteno u' : 'Redeemed at';
  String get offerRedeemed => _isHR ? 'Ponuda iskorištena!' : 'Offer redeemed!';
  String get merchantRecordCode =>
      _isHR ? 'KOD ZAPISA TRGOVCA' : 'MERCHANT RECORD CODE';
  String get waiterWritesThis => _isHR
      ? 'Konobar ovo zapisuje u evidenciju'
      : 'Waiter writes this in their records';
  String get doneBtn => _isHR ? 'Završi' : 'Done';
  String get rateYourExperience =>
      _isHR ? 'Ocijenite svoje iskustvo' : 'Rate your experience';
  String get skipBtn => _isHR ? 'Preskoči' : 'Skip';
  String get submitBtn => _isHR ? 'Pošalji' : 'Submit';
  String get continueBtn => _isHR ? 'Nastavi' : 'Continue';
  String get thankYouForFeedback =>
      _isHR ? 'Hvala vam na osvrtu!' : 'Thank you for your feedback!';

  // ── Modals / Dialogs ────────────────────────────────────────────────────────────
  String get chooseYourPlan => _isHR ? 'Odaberi plan' : 'Choose your plan';
  String get annualOnly => _isHR
      ? 'Samo godišnje · Bez mjesečne opcije'
      : 'Annual only · No monthly option';
  String get foundingMemberBanner => _isHR
      ? 'OSNIVAČKI ČLAN — SAMO 500 MJESTA'
      : 'FOUNDING MEMBER — 500 SPOTS ONLY';
  String get annualFounding => _isHR ? 'Godišnje osnivačko' : 'Annual founding';
  String get priceLockedForever =>
      _isHR ? 'Cijena zaključana zauvijek' : 'Price locked forever';
  String get perYear => _isHR ? '/ god.' : '/ year';
  String get perMonth => _isHR ? '= €3,25/mj.' : '= €3.25/month';
  String get perMonthStandard => _isHR ? '= €4,00/mj.' : '= €4.00/month';
  String get bogoDinnerCovers => _isHR
      ? '⚡ Jedna BOGO večera pokrije cijelu godinu'
      : '⚡ One BOGO dinner covers your whole year';
  String get bogoAtRestaurants => _isHR
      ? 'BOGO u 50+ restorana u Zagrebu'
      : 'BOGO at 50+ Zagreb restaurants';
  String get uniqueOffersPerMerchant => _isHR
      ? '3 jedinstvene ponude po partneru'
      : '3 unique offers per merchant';
  String get priorityAccess => _isHR
      ? 'Prioritetni pristup novim gradovima'
      : 'Priority access to new cities';
  String get claimFoundingSpot =>
      _isHR ? 'Zatraži osnivačko mjesto' : 'Claim founding spot';
  String get annualStandard =>
      _isHR ? 'Godišnje standardno' : 'Annual standard';
  String get fullAccess =>
      _isHR ? 'Puni pristup, sve ponude' : 'Full access, all offers';
  String get zagrebNowSplitRijeka =>
      _isHR ? 'Zagreb sada · Split i Rijeka ' : 'Zagreb now · Split & Rijeka ';
  String get comingSoon => _isHR ? 'uskoro' : 'coming soon';
  String get selectStandard => _isHR ? 'Odaberi standardno' : 'Select standard';
  String get annualNoAutoRenewal => _isHR
      ? 'Samo godišnje · Bez automatskog obnavljanja bez vašeg pristanka'
      : 'Annual only · No auto-renewal without your consent';

  // ── Merchant Detail ─────────────────────────────────────────────────────────
  String get availableOffers => _isHR ? 'Dostupne ponude' : 'Available offers';
  String offersUseEach(int count) => _isHR
      ? '$count ${count == 1 ? 'ponuda' : 'ponude'} · 1 korištenje svake'
      : '$count offers · 1 use each';
  String get openLabel => _isHR ? 'Otvoreno' : 'Open';
  String get closedLabel => _isHR ? 'Zatvoreno' : 'Closed';
  String get callLabel => _isHR ? 'Nazovi' : 'Call';
  String get locationLabel => _isHR ? 'Lokacija' : 'Location';
  String get useAnOffer => _isHR ? 'Iskoristi ponudu' : 'Use an offer';
  String get noOffersAvailableBtn =>
      _isHR ? 'Nema dostupnih ponuda' : 'No offers available';
  String get chooseAnOffer =>
      _isHR ? 'Odaberi ponudu' : 'Choose an offer';
  String get usedLabel => _isHR ? 'ISKORIŠTENO' : 'USED';
  String get useLabel => _isHR ? 'KORISTI' : 'USE';
  String get saveBadge => _isHR ? 'Uštedi' : 'Save';
  String get offerAlreadyUsed =>
      _isHR ? 'Ova ponuda je već iskorištena' : 'This offer has already been used';

  // ── Promo Code ──────────────────────────────────────────────────────────────
  String get havePromoCode =>
      _isHR ? '+ Imate promo kod?' : '+ Have a promo code?';
  String get enterPromoCode =>
      _isHR ? 'Unesite promo kod' : 'Enter promo code';
  String get applyPromo => _isHR ? 'Primijeni' : 'Apply';
  String get promoApplied =>
      _isHR ? 'Promo kod primijenjen!' : 'Promo code applied!';
  String get removePromo => _isHR ? 'Ukloni' : 'Remove';
  String get promoDiscount => _isHR ? 'Popust' : 'Discount';
  String get invalidPromoCode =>
      _isHR ? 'Nevažeći promo kod' : 'Invalid promo code';
}
