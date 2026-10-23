// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appName => 'Skanner';

  @override
  String get language => 'Dil';

  @override
  String get languageEnglish => 'İngilis dili';

  @override
  String get languageAzerbaijani => 'Azərbaycan dili';

  @override
  String get languageRussian => 'Rus dili';

  @override
  String get soundOn => 'Səs aktivdir';

  @override
  String get soundOff => 'Səs deaktivdir';

  @override
  String get signOut => 'Çıxış';

  @override
  String get loginSubtitle => 'Skan etmək üçün daxil olun.';

  @override
  String get username => 'İstifadəçi adı';

  @override
  String get password => 'Şifrə';

  @override
  String get showPassword => 'Şifrəni göstər';

  @override
  String get hidePassword => 'Şifrəni gizlət';

  @override
  String get usernameRequired => 'İstifadəçi adını daxil edin.';

  @override
  String get passwordRequired => 'Şifrəni daxil edin.';

  @override
  String get signIn => 'Daxil ol';

  @override
  String demoAccess(String username, String password) {
    return 'Demo giriş: $username / $password';
  }

  @override
  String get cameraAfterSignIn =>
      'Kamera icazəsi daxil olduqdan sonra istənilir.';

  @override
  String get authMissingFields => 'İstifadəçi adını və şifrəni daxil edin.';

  @override
  String get authInvalidCredentials => 'İstifadəçi adı və ya şifrə yanlışdır.';

  @override
  String get authFailed => 'Daxil olmaq alınmadı. Yenidən cəhd edin.';

  @override
  String get authTimedOut => 'Daxil olma vaxtı bitdi. Yenidən cəhd edin.';

  @override
  String get authUnreachable =>
      'Serverə qoşulmaq alınmadı. Bağlantını yoxlayın.';

  @override
  String get authUnexpected => 'Server gözlənilməz cavab qaytardı.';

  @override
  String welcome(String username) {
    return 'Xoş gəldiniz, $username';
  }

  @override
  String get homePrompt =>
      'Məhsulun məlumatlarını və anbar qalığını yoxlamaq üçün QR kod və ya barkod skan edin.';

  @override
  String get scanButton => 'Kodu skan et';

  @override
  String get scanComplete => 'Skan tamamlandı';

  @override
  String get modeQr => 'QR';

  @override
  String get modeBarcode => 'Barkod';

  @override
  String get hintQr => 'Kameranı QR koda yönəldin';

  @override
  String get hintBarcode => 'Barkodu çərçivənin içinə yerləşdirin';

  @override
  String get permissionTitle => 'Kamera icazəsi tələb olunur';

  @override
  String get permissionRationale =>
      'Tətbiqə kodları skan etmək üçün kamera icazəsi lazımdır. Şəkillər saxlanmır və yüklənmir.';

  @override
  String get permissionDenied =>
      'Kamera icazəsi bloklanıb. Tətbiq parametrlərini açıb Kameraya icazə verin.';

  @override
  String get allowCamera => 'Kameraya icazə ver';

  @override
  String get openSettings => 'Parametrləri aç';

  @override
  String get cameraUnavailable => 'Kamera əlçatmazdır';

  @override
  String get cameraUnavailableMessage =>
      'Kamera işə salına bilmədi. Onu istifadə edən digər tətbiqləri bağlayın və yenidən cəhd edin.';

  @override
  String get retryCamera => 'Kameranı yenidən yoxla';

  @override
  String get readyTitle => 'Skan etməyə hazırdır';

  @override
  String get readyHint =>
      'QR və ya Barkod seçin, kodu çərçivədə sabit saxlayın.';

  @override
  String lookingUp(String code) {
    return '$code axtarılır…';
  }

  @override
  String get productFound => 'Məhsul tapıldı';

  @override
  String get notInStock => 'Stokda yoxdur';

  @override
  String get inStock => 'Stokda var';

  @override
  String get unavailable => 'Mövcud deyil';

  @override
  String get noSuchProduct => 'Belə məhsul yoxdur';

  @override
  String noProductMatches(String code) {
    return '“$code” ilə uyğun məhsul yoxdur. Kodu yoxlayıb yenidən cəhd edin.';
  }

  @override
  String get unsupportedCode => 'Dəstəklənməyən kod';

  @override
  String get invalidHint =>
      'Kod oxundu, lakin istifadə edilə bilmədi. Başqa kod yoxlayın.';

  @override
  String get couldNotLoadProduct => 'Məhsulu yükləmək alınmadı';

  @override
  String get tryAgain => 'Yenidən cəhd et';

  @override
  String get scanAnotherCode => 'Başqa kod skan et';

  @override
  String get idLabel => 'ID';

  @override
  String get colorLabel => 'Rəng';

  @override
  String get stockLabel => 'Stok';

  @override
  String get barcodeLabel => 'Barkod';

  @override
  String quantityInStock(int count) {
    return '$count ədəd stokda';
  }

  @override
  String get outOfStock => 'Stokda yoxdur';

  @override
  String get notAvailableDepot => 'Bu məhsul anbarda mövcud deyil.';

  @override
  String get lookupUnauthorized => 'Bu məhsula baxmaq icazəniz yoxdur.';

  @override
  String get lookupServerUnavailable =>
      'Server əlçatmazdır. Sonra yenidən cəhd edin.';

  @override
  String lookupRequestFailed(int statusCode) {
    return 'Sorğu alınmadı (HTTP $statusCode).';
  }

  @override
  String get lookupUnreachable =>
      'Serverə qoşulmaq alınmadı. Bağlantını yoxlayın.';

  @override
  String get lookupUnexpected => 'Server gözlənilməz cavab qaytardı.';

  @override
  String get lookupTimeout => 'Sorğunun vaxtı bitdi. Yenidən cəhd edin.';

  @override
  String get lookupLocalData => 'Yerli məhsul məlumatlarını oxumaq alınmadı.';

  @override
  String get addToDepot => 'Anbara əlavə et';

  @override
  String get addProductTitle => 'Anbara məhsul əlavə et';

  @override
  String get addProductCode => 'Skan edilmiş kod';

  @override
  String get productNameLabel => 'Məhsulun adı';

  @override
  String get productDescriptionLabel => 'Təsvir (könüllü)';

  @override
  String get productColorLabel => 'Rəng (könüllü)';

  @override
  String get productQuantityLabel => 'Anbardakı miqdar';

  @override
  String get saveProduct => 'Məhsulu saxla';

  @override
  String get cancelAction => 'Ləğv et';

  @override
  String get nameRequired => 'Məhsulun adını daxil edin.';

  @override
  String get registerDuplicate => 'Bu kod artıq anbardadır.';

  @override
  String get registerFailed =>
      'Məhsulu saxlamaq mümkün olmadı. Bağlantını yoxlayıb yenidən cəhd edin.';

  @override
  String get modePhone => 'Telefon';

  @override
  String get phoneHint =>
      'Telefonun arxa tərəfini göstərin, sonra Tanı düyməsinə basın';

  @override
  String get identifyButton => 'Tanı';

  @override
  String get identifying => 'Tanınır…';

  @override
  String identifiedAs(String name, int percent) {
    return '$name kimi tanındı ($percent%)';
  }

  @override
  String notInDepotModel(String name) {
    return '$name anbarda yoxdur.';
  }

  @override
  String get notAPhone => 'Telefon tapılmadı. Kameranı telefona yönəldin.';

  @override
  String get lowConfidence =>
      'Əmin deyiləm. Bütün telefon çərçivədə olsun və yenidən cəhd edin.';

  @override
  String get recognitionNotConfigured => 'Telefon tanıma serverdə qurulmayıb.';

  @override
  String get identifyAnother => 'Başqa telefonu tanı';

  @override
  String get phoneCameraError => 'Kameranı açmaq mümkün olmadı.';

  @override
  String notInDepotColor(String name, String color, String colors) {
    return '$name ($color) anbarda yoxdur. Anbarda bu model bu rənglərdə var: $colors.';
  }

  @override
  String get colorNotDetected =>
      'Rəngi müəyyən etmək olmadı. Uyğun olub-olmadığını yoxlayın.';
}
