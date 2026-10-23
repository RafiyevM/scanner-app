import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get appName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAzerbaijani.
  ///
  /// In en, this message translates to:
  /// **'Azərbaycan dili'**
  String get languageAzerbaijani;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get soundOff;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start scanning.'**
  String get loginSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your username.'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @demoAccess.
  ///
  /// In en, this message translates to:
  /// **'Demo access: {username} / {password}'**
  String demoAccess(String username, String password);

  /// No description provided for @cameraAfterSignIn.
  ///
  /// In en, this message translates to:
  /// **'Camera access is requested after sign-in.'**
  String get cameraAfterSignIn;

  /// No description provided for @authMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Enter your username and password.'**
  String get authMissingFields;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Try again.'**
  String get authFailed;

  /// No description provided for @authTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign-in timed out. Try again.'**
  String get authTimedOut;

  /// No description provided for @authUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get authUnreachable;

  /// No description provided for @authUnexpected.
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response.'**
  String get authUnexpected;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}'**
  String welcome(String username);

  /// No description provided for @homePrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or barcode to check a product\'s details and depot stock.'**
  String get homePrompt;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get scanButton;

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get scanComplete;

  /// No description provided for @modeQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get modeQr;

  /// No description provided for @modeBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get modeBarcode;

  /// No description provided for @hintQr.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a QR code'**
  String get hintQr;

  /// No description provided for @hintBarcode.
  ///
  /// In en, this message translates to:
  /// **'Align the barcode inside the frame'**
  String get hintBarcode;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access needed'**
  String get permissionTitle;

  /// No description provided for @permissionRationale.
  ///
  /// In en, this message translates to:
  /// **'The app needs camera access to scan codes. No photos are stored or uploaded.'**
  String get permissionRationale;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Open app settings and allow Camera, then return here.'**
  String get permissionDenied;

  /// No description provided for @allowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get allowCamera;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @cameraUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started. Close other apps using it and try again.'**
  String get cameraUnavailableMessage;

  /// No description provided for @retryCamera.
  ///
  /// In en, this message translates to:
  /// **'Retry camera'**
  String get retryCamera;

  /// No description provided for @readyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan'**
  String get readyTitle;

  /// No description provided for @readyHint.
  ///
  /// In en, this message translates to:
  /// **'Choose QR or Barcode, then hold the code steady inside the frame.'**
  String get readyHint;

  /// No description provided for @lookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up {code}…'**
  String lookingUp(String code);

  /// No description provided for @productFound.
  ///
  /// In en, this message translates to:
  /// **'Product found'**
  String get productFound;

  /// No description provided for @notInStock.
  ///
  /// In en, this message translates to:
  /// **'Not in stock'**
  String get notInStock;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @noSuchProduct.
  ///
  /// In en, this message translates to:
  /// **'No such product'**
  String get noSuchProduct;

  /// No description provided for @noProductMatches.
  ///
  /// In en, this message translates to:
  /// **'No product matches “{code}”. Check the code and try again.'**
  String noProductMatches(String code);

  /// No description provided for @unsupportedCode.
  ///
  /// In en, this message translates to:
  /// **'Unsupported code'**
  String get unsupportedCode;

  /// No description provided for @invalidHint.
  ///
  /// In en, this message translates to:
  /// **'The code was read but could not be used. Try a different code.'**
  String get invalidHint;

  /// No description provided for @couldNotLoadProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not load the product'**
  String get couldNotLoadProduct;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @scanAnotherCode.
  ///
  /// In en, this message translates to:
  /// **'Scan another code'**
  String get scanAnotherCode;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockLabel;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @quantityInStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String quantityInStock(int count);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @notAvailableDepot.
  ///
  /// In en, this message translates to:
  /// **'This product is not available in the depot.'**
  String get notAvailableDepot;

  /// No description provided for @lookupUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to view this product.'**
  String get lookupUnauthorized;

  /// No description provided for @lookupServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server is unavailable. Try again later.'**
  String get lookupServerUnavailable;

  /// No description provided for @lookupRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The request failed (HTTP {statusCode}).'**
  String lookupRequestFailed(int statusCode);

  /// No description provided for @lookupUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get lookupUnreachable;

  /// No description provided for @lookupUnexpected.
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response.'**
  String get lookupUnexpected;

  /// No description provided for @lookupTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Try again.'**
  String get lookupTimeout;

  /// No description provided for @lookupLocalData.
  ///
  /// In en, this message translates to:
  /// **'Could not read the local product data.'**
  String get lookupLocalData;

  /// No description provided for @addToDepot.
  ///
  /// In en, this message translates to:
  /// **'Add to depot'**
  String get addToDepot;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add product to depot'**
  String get addProductTitle;

  /// No description provided for @addProductCode.
  ///
  /// In en, this message translates to:
  /// **'Scanned code'**
  String get addProductCode;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @productDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get productDescriptionLabel;

  /// No description provided for @productColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get productColorLabel;

  /// No description provided for @productQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity in stock'**
  String get productQuantityLabel;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save product'**
  String get saveProduct;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the product name.'**
  String get nameRequired;

  /// No description provided for @registerDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This code is already in the depot.'**
  String get registerDuplicate;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the product. Check your connection and try again.'**
  String get registerFailed;

  /// No description provided for @modePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get modePhone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Show the back of a phone, then tap Identify'**
  String get phoneHint;

  /// No description provided for @identifyButton.
  ///
  /// In en, this message translates to:
  /// **'Identify'**
  String get identifyButton;

  /// No description provided for @identifying.
  ///
  /// In en, this message translates to:
  /// **'Identifying…'**
  String get identifying;

  /// No description provided for @identifiedAs.
  ///
  /// In en, this message translates to:
  /// **'Identified as {name} ({percent}%)'**
  String identifiedAs(String name, int percent);

  /// No description provided for @notInDepotModel.
  ///
  /// In en, this message translates to:
  /// **'{name} is not in the depot.'**
  String notInDepotModel(String name);

  /// No description provided for @notAPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone found. Point the camera at a phone.'**
  String get notAPhone;

  /// No description provided for @lowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Not sure. Try again with the whole phone in the frame.'**
  String get lowConfidence;

  /// No description provided for @recognitionNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Phone recognition is not set up on the server.'**
  String get recognitionNotConfigured;

  /// No description provided for @identifyAnother.
  ///
  /// In en, this message translates to:
  /// **'Identify another phone'**
  String get identifyAnother;

  /// No description provided for @phoneCameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera.'**
  String get phoneCameraError;

  /// No description provided for @notInDepotColor.
  ///
  /// In en, this message translates to:
  /// **'{name} in {color} is not in the depot. The depot has this model in: {colors}.'**
  String notInDepotColor(String name, String color, String colors);

  /// No description provided for @colorNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Could not tell the color. Check that it matches.'**
  String get colorNotDetected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
