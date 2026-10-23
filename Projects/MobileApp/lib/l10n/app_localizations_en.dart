// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Scanner';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAzerbaijani => 'Azərbaycan dili';

  @override
  String get languageRussian => 'Русский';

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String get signOut => 'Sign out';

  @override
  String get loginSubtitle => 'Sign in to start scanning.';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get usernameRequired => 'Enter your username.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get signIn => 'Sign in';

  @override
  String demoAccess(String username, String password) {
    return 'Demo access: $username / $password';
  }

  @override
  String get cameraAfterSignIn => 'Camera access is requested after sign-in.';

  @override
  String get authMissingFields => 'Enter your username and password.';

  @override
  String get authInvalidCredentials => 'Incorrect username or password.';

  @override
  String get authFailed => 'Sign-in failed. Try again.';

  @override
  String get authTimedOut => 'Sign-in timed out. Try again.';

  @override
  String get authUnreachable =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get authUnexpected => 'The server returned an unexpected response.';

  @override
  String welcome(String username) {
    return 'Welcome, $username';
  }

  @override
  String get homePrompt =>
      'Scan a QR code or barcode to check a product\'s details and depot stock.';

  @override
  String get scanButton => 'Scan code';

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get modeQr => 'QR';

  @override
  String get modeBarcode => 'Barcode';

  @override
  String get hintQr => 'Point the camera at a QR code';

  @override
  String get hintBarcode => 'Align the barcode inside the frame';

  @override
  String get permissionTitle => 'Camera access needed';

  @override
  String get permissionRationale =>
      'The app needs camera access to scan codes. No photos are stored or uploaded.';

  @override
  String get permissionDenied =>
      'Camera access is blocked. Open app settings and allow Camera, then return here.';

  @override
  String get allowCamera => 'Allow camera';

  @override
  String get openSettings => 'Open settings';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get cameraUnavailableMessage =>
      'The camera could not be started. Close other apps using it and try again.';

  @override
  String get retryCamera => 'Retry camera';

  @override
  String get readyTitle => 'Ready to scan';

  @override
  String get readyHint =>
      'Choose QR or Barcode, then hold the code steady inside the frame.';

  @override
  String lookingUp(String code) {
    return 'Looking up $code…';
  }

  @override
  String get productFound => 'Product found';

  @override
  String get notInStock => 'Not in stock';

  @override
  String get inStock => 'In stock';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get noSuchProduct => 'No such product';

  @override
  String noProductMatches(String code) {
    return 'No product matches “$code”. Check the code and try again.';
  }

  @override
  String get unsupportedCode => 'Unsupported code';

  @override
  String get invalidHint =>
      'The code was read but could not be used. Try a different code.';

  @override
  String get couldNotLoadProduct => 'Could not load the product';

  @override
  String get tryAgain => 'Try again';

  @override
  String get scanAnotherCode => 'Scan another code';

  @override
  String get idLabel => 'ID';

  @override
  String get colorLabel => 'Color';

  @override
  String get stockLabel => 'Stock';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String quantityInStock(int count) {
    return '$count in stock';
  }

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get notAvailableDepot => 'This product is not available in the depot.';

  @override
  String get lookupUnauthorized =>
      'You are not authorized to view this product.';

  @override
  String get lookupServerUnavailable =>
      'The server is unavailable. Try again later.';

  @override
  String lookupRequestFailed(int statusCode) {
    return 'The request failed (HTTP $statusCode).';
  }

  @override
  String get lookupUnreachable =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get lookupUnexpected => 'The server returned an unexpected response.';

  @override
  String get lookupTimeout => 'The request timed out. Try again.';

  @override
  String get lookupLocalData => 'Could not read the local product data.';

  @override
  String get addToDepot => 'Add to depot';

  @override
  String get addProductTitle => 'Add product to depot';

  @override
  String get addProductCode => 'Scanned code';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get productDescriptionLabel => 'Description (optional)';

  @override
  String get productColorLabel => 'Color (optional)';

  @override
  String get productQuantityLabel => 'Quantity in stock';

  @override
  String get saveProduct => 'Save product';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get nameRequired => 'Enter the product name.';

  @override
  String get registerDuplicate => 'This code is already in the depot.';

  @override
  String get registerFailed =>
      'Could not save the product. Check your connection and try again.';

  @override
  String get modePhone => 'Phone';

  @override
  String get phoneHint => 'Show the back of a phone, then tap Identify';

  @override
  String get identifyButton => 'Identify';

  @override
  String get identifying => 'Identifying…';

  @override
  String identifiedAs(String name, int percent) {
    return 'Identified as $name ($percent%)';
  }

  @override
  String notInDepotModel(String name) {
    return '$name is not in the depot.';
  }

  @override
  String get notAPhone => 'No phone found. Point the camera at a phone.';

  @override
  String get lowConfidence =>
      'Not sure. Try again with the whole phone in the frame.';

  @override
  String get recognitionNotConfigured =>
      'Phone recognition is not set up on the server.';

  @override
  String get identifyAnother => 'Identify another phone';

  @override
  String get phoneCameraError => 'Could not open the camera.';

  @override
  String notInDepotColor(String name, String color, String colors) {
    return '$name in $color is not in the depot. The depot has this model in: $colors.';
  }

  @override
  String get colorNotDetected =>
      'Could not tell the color. Check that it matches.';
}
