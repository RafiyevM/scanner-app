// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Сканер';

  @override
  String get language => 'Язык';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageAzerbaijani => 'Азербайджанский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get soundOn => 'Звук включён';

  @override
  String get soundOff => 'Звук выключен';

  @override
  String get signOut => 'Выйти';

  @override
  String get loginSubtitle => 'Войдите, чтобы начать сканирование.';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get usernameRequired => 'Введите имя пользователя.';

  @override
  String get passwordRequired => 'Введите пароль.';

  @override
  String get signIn => 'Войти';

  @override
  String demoAccess(String username, String password) {
    return 'Демо-доступ: $username / $password';
  }

  @override
  String get cameraAfterSignIn => 'Доступ к камере запрашивается после входа.';

  @override
  String get authMissingFields => 'Введите имя пользователя и пароль.';

  @override
  String get authInvalidCredentials => 'Неверное имя пользователя или пароль.';

  @override
  String get authFailed => 'Не удалось войти. Повторите попытку.';

  @override
  String get authTimedOut => 'Время входа истекло. Повторите попытку.';

  @override
  String get authUnreachable =>
      'Не удалось связаться с сервером. Проверьте подключение.';

  @override
  String get authUnexpected => 'Сервер вернул неожиданный ответ.';

  @override
  String welcome(String username) {
    return 'Добро пожаловать, $username';
  }

  @override
  String get homePrompt =>
      'Сканируйте QR-код или штрихкод, чтобы узнать информацию о товаре и остаток на складе.';

  @override
  String get scanButton => 'Сканировать код';

  @override
  String get scanComplete => 'Сканирование завершено';

  @override
  String get modeQr => 'QR';

  @override
  String get modeBarcode => 'Штрихкод';

  @override
  String get hintQr => 'Наведите камеру на QR-код';

  @override
  String get hintBarcode => 'Поместите штрихкод в рамку';

  @override
  String get permissionTitle => 'Требуется доступ к камере';

  @override
  String get permissionRationale =>
      'Приложению нужен доступ к камере для сканирования кодов. Фото не сохраняются и не загружаются.';

  @override
  String get permissionDenied =>
      'Доступ к камере заблокирован. Откройте настройки приложения и разрешите камеру.';

  @override
  String get allowCamera => 'Разрешить камеру';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get cameraUnavailable => 'Камера недоступна';

  @override
  String get cameraUnavailableMessage =>
      'Не удалось запустить камеру. Закройте другие приложения, использующие её, и повторите попытку.';

  @override
  String get retryCamera => 'Повторить';

  @override
  String get readyTitle => 'Готово к сканированию';

  @override
  String get readyHint => 'Выберите QR или штрихкод и держите код в рамке.';

  @override
  String lookingUp(String code) {
    return 'Поиск $code…';
  }

  @override
  String get productFound => 'Товар найден';

  @override
  String get notInStock => 'Нет в наличии';

  @override
  String get inStock => 'В наличии';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get noSuchProduct => 'Такого товара нет';

  @override
  String noProductMatches(String code) {
    return 'Нет товара, соответствующего «$code». Проверьте код и повторите попытку.';
  }

  @override
  String get unsupportedCode => 'Неподдерживаемый код';

  @override
  String get invalidHint =>
      'Код прочитан, но не может быть использован. Попробуйте другой код.';

  @override
  String get couldNotLoadProduct => 'Не удалось загрузить товар';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get scanAnotherCode => 'Сканировать другой код';

  @override
  String get idLabel => 'ID';

  @override
  String get colorLabel => 'Цвет';

  @override
  String get stockLabel => 'Остаток';

  @override
  String get barcodeLabel => 'Штрихкод';

  @override
  String quantityInStock(int count) {
    return '$count в наличии';
  }

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get notAvailableDepot => 'Этот товар отсутствует на складе.';

  @override
  String get lookupUnauthorized => 'У вас нет прав на просмотр этого товара.';

  @override
  String get lookupServerUnavailable =>
      'Сервер недоступен. Повторите попытку позже.';

  @override
  String lookupRequestFailed(int statusCode) {
    return 'Запрос не выполнен (HTTP $statusCode).';
  }

  @override
  String get lookupUnreachable =>
      'Не удалось связаться с сервером. Проверьте подключение.';

  @override
  String get lookupUnexpected => 'Сервер вернул неожиданный ответ.';

  @override
  String get lookupTimeout => 'Время запроса истекло. Повторите попытку.';

  @override
  String get lookupLocalData =>
      'Не удалось прочитать локальные данные о товарах.';

  @override
  String get addToDepot => 'Добавить на склад';

  @override
  String get addProductTitle => 'Добавить товар на склад';

  @override
  String get addProductCode => 'Отсканированный код';

  @override
  String get productNameLabel => 'Название товара';

  @override
  String get productDescriptionLabel => 'Описание (необязательно)';

  @override
  String get productColorLabel => 'Цвет (необязательно)';

  @override
  String get productQuantityLabel => 'Количество на складе';

  @override
  String get saveProduct => 'Сохранить товар';

  @override
  String get cancelAction => 'Отмена';

  @override
  String get nameRequired => 'Введите название товара.';

  @override
  String get registerDuplicate => 'Этот код уже есть на складе.';

  @override
  String get registerFailed =>
      'Не удалось сохранить товар. Проверьте соединение и повторите попытку.';

  @override
  String get modePhone => 'Телефон';

  @override
  String get phoneHint =>
      'Покажите заднюю панель телефона и нажмите «Определить»';

  @override
  String get identifyButton => 'Определить';

  @override
  String get identifying => 'Определяем…';

  @override
  String identifiedAs(String name, int percent) {
    return 'Определён как $name ($percent%)';
  }

  @override
  String notInDepotModel(String name) {
    return '$name нет на складе.';
  }

  @override
  String get notAPhone => 'Телефон не найден. Наведите камеру на телефон.';

  @override
  String get lowConfidence =>
      'Не уверен. Повторите, чтобы весь телефон был в кадре.';

  @override
  String get recognitionNotConfigured =>
      'Распознавание телефонов не настроено на сервере.';

  @override
  String get identifyAnother => 'Определить другой телефон';

  @override
  String get phoneCameraError => 'Не удалось открыть камеру.';

  @override
  String notInDepotColor(String name, String color, String colors) {
    return '$name цвета «$color» нет на складе. На складе эта модель есть в цветах: $colors.';
  }

  @override
  String get colorNotDetected =>
      'Не удалось определить цвет. Проверьте, что он совпадает.';
}
