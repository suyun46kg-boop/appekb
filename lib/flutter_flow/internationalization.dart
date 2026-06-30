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

  static List<String> languages() => ['ru', 'ky'];

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
    String? ruText = '',
    String? kyText = '',
  }) =>
      [ruText, kyText][languageIndex] ?? '';

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
  // avtoryzasia
  {
    'b23siiyt': {
      'ru': 'Авторизация',
      'ky': 'Авторизация',
    },
    '2b0ulefp': {
      'ru': ' 11',
      'ky': '11',
    },
    'bmucv0b5': {
      'ru': '+7',
      'ky': '+7',
    },
    'tsagqfgt': {
      'ru': 'номер телефона',
      'ky': 'Телефон номери',
    },
    'tcqkbk1z': {
      'ru': 'номер должен начинаться с 9',
      'ky': 'Номер 9 санынан башталуусу керек',
    },
    'mojwaje4': {
      'ru': 'пароль',
      'ky': 'Пароль',
    },
    'vj80esvf': {
      'ru': ' 22',
      'ky': '22',
    },
    'runv4yix': {
      'ru': 'забыл пароль',
      'ky': 'Парольду унуттум',
    },
    '0cagfuef': {
      'ru': 'авторизация',
      'ky': 'Авторизация',
    },
    'kbl08rsq': {
      'ru': 'у меня нет аккаунта,',
      'ky': 'Менде акант жок',
    },
    'uglilzyw': {
      'ru': 'создать аккаунт',
      'ky': 'Акаунт ачуу',
    },
  },
  // registrasia
  {
    'j76pkpsz': {
      'ru': 'Регистрация',
      'ky': 'Регистрация',
    },
    '6x9p57c5': {
      'ru': 'Имия',
      'ky': 'Аты',
    },
    'bxxhwa85': {
      'ru': '+7',
      'ky': '+7',
    },
    'ehrfrdcl': {
      'ru': 'телефон номер',
      'ky': 'Телефон номери',
    },
    '40hofkj8': {
      'ru': 'Номер должен начинаться с 9 (без +7 или 8)',
      'ky': 'Номер 9 санынан башталуусу керек',
    },
    'iddpkkyn': {
      'ru': '   пароль',
      'ky': '   пароль',
    },
    'mjp8jm3a': {
      'ru': 'пароль должень состаить минимим из 8 символов',
      'ky': 'Пароль минимум  8 символдон турушу керек',
    },
    'h5721474': {
      'ru': '  повторите пороль',
      'ky': 'Парольду кайтаруу',
    },
    '6ycrlpth': {
      'ru': 'повтарите пароля',
      'ky': 'Парольду кайтаруу',
    },
    'qy7d86gi': {
      'ru': 'создать аккаунт',
      'ky': 'Акаунт ачуу',
    },
    'xormy5ux': {
      'ru': 'у меня есть ',
      'ky': 'менде Акаунт бар',
    },
    's9u462x1': {
      'ru': 'Акаунт',
      'ky': 'Акаунт',
    },
    'xuue1ksb': {
      'ru': 'Регистрация',
      'ky': 'Регистрация',
    },
  },
  // searchpage22
  {
    '0oyhvz3d': {
      'ru': 'найти',
      'ky': 'Издоо',
    },
    'kykez2yz': {
      'ru': '.',
      'ky': '.',
    },
    'sov2bc4k': {
      'ru': '.',
      'ky': '.',
    },
    '6hkxr549': {
      'ru': 'p',
      'ky': 'p',
    },
    'f9es88w8': {
      'ru': 'нечего не найдено ',
      'ky': 'эчтеке табылган жок',
    },
    '6pwnu7xf': {
      'ru': 'Найти',
      'ky': 'Табуу',
    },
  },
  // CreateListingPageCopy
  {
    'ucddso9j': {
      'ru': 'заполните страницу',
      'ky': 'страницаны толтурунуз',
    },
    'pmvpysvu': {
      'ru': 'категория',
      'ky': 'категория',
    },
    'i3864gzx': {
      'ru': '*',
      'ky': '*',
    },
    'rvbs5vhd': {
      'ru': 'называние товара',
      'ky': 'товардын аты',
    },
    'fpoz2irm': {
      'ru': 'пишите называние товара...',
      'ky': 'товардын атын жазыныз...',
    },
    '8rowymcu': {
      'ru': 'Описание',
      'ky': 'Описание',
    },
    '6cmz1roo': {
      'ru': 'подробно опищите товра...',
      'ky': 'кенен маалымат жазыныз',
    },
    '7clhjum9': {
      'ru': 'цена',
      'ky': 'цена',
    },
    '2nx86b48': {
      'ru': '0.00',
      'ky': '0.00',
    },
    'jb1kv8r8': {
      'ru': 'Контакты',
      'ky': 'Контакттар',
    },
    'x90g6s5i': {
      'ru': 'номер телефона',
      'ky': 'Телефон номери',
    },
    '8pcnmgyb': {
      'ru': '+79089197909',
      'ky': '+79089197909',
    },
    '6gy357ko': {
      'ru': '     Адрес...',
      'ky': '     Адрес...',
    },
    'h252jkl7': {
      'ru': 'Фото',
      'ky': 'Фото',
    },
    'tyg5vjcc': {
      'ru': 'загрузить фото',
      'ky': 'Фото жуктоо',
    },
    'i3w2hise': {
      'ru': 'Публиковать',
      'ky': 'жуктоо',
    },
    '3gfvwxa5': {
      'ru': 'Обявления',
      'ky': 'Обявления',
    },
  },
  // tovarypocategoy
  {
    'sqacjfy3': {
      'ru': 'Гланая',
      'ky': 'Гланая',
    },
  },
  // pagpage
  {
    'auncdw0p': {
      'ru': 'информации',
      'ky': 'информации',
    },
    'au4pejr1': {
      'ru': 'категория',
      'ky': 'категория',
    },
    'z3v0tnuw': {
      'ru': 'адрес',
      'ky': 'адреси',
    },
    'jo0q04xo': {
      'ru': 'контакты',
      'ky': 'контактар',
    },
    'ns1xslou': {
      'ru': 'дата публикации',
      'ky': 'дата публикации',
    },
    '9vvhfb6t': {
      'ru': 'описании',
      'ky': 'описаниясы',
    },
    'ijfz6pvx': {
      'ru': 'Контакты',
      'ky': 'Контакты',
    },
    '7l64c59t': {
      'ru': 'Позванить',
      'ky': 'чалуу',
    },
    '5ltjqd81': {
      'ru': 'Гланая',
      'ky': 'Гланая',
    },
  },
  // Profile
  {
    'kiy9k1h8': {
      'ru': 'маи обиявлении',
      'ky': 'Менин обявлениям',
    },
    'wrj9lx0v': {
      'ru': 'поддержка',
      'ky': 'поддержка',
    },
    '6ay3t2sd': {
      'ru': 'политика конфиденциальности',
      'ky': 'политика конфиденциальности',
    },
    'jfhc2a2b': {
      'ru': 'Выйти',
      'ky': 'чыгуу',
    },
    'wg3pzmio': {
      'ru': 'профиль',
      'ky': 'профиль',
    },
  },
  // dbdd
  {
    'fmw9cm8g': {
      'ru': 'Найти',
      'ky': 'Табуу',
    },
    'l8qpitx7': {
      'ru': 'KG',
      'ky': 'KG',
    },
    'qai395nv': {
      'ru': 'RU',
      'ky': 'RU',
    },
    'zvs9dp80': {
      'ru': 'Категории',
      'ky': 'Категории',
    },
    'cukp48gd': {
      'ru': 'квартира',
      'ky': 'квартира',
    },
    'me5sh2dc': {
      'ru': 'робота',
      'ky': 'робота',
    },
    '4lwpgqmm': {
      'ru': 'граница',
      'ky': 'граница',
    },
    'r4qsbrdp': {
      'ru': 'авто',
      'ky': 'авто',
    },
    'vp95t6yz': {
      'ru': 'белет',
      'ky': 'белет',
    },
    'ccc9cors': {
      'ru': 'услуги',
      'ky': 'услуги',
    },
    'pnpqtuk7': {
      'ru': 'сатылат',
      'ky': 'сатылат',
    },
    'noun7do1': {
      'ru': 'халтура',
      'ky': 'халтура',
    },
    'xy92q7cu': {
      'ru': 'последные обявлении',
      'ky': 'последные обявлении',
    },
    'gf7pmm28': {
      'ru': 'р',
      'ky': 'р',
    },
    '528yx56i': {
      'ru': 'Гланая',
      'ky': 'Гланая',
    },
  },
  // politpage
  {
    '1x09yf4i': {
      'ru': 'Условия и политика',
      'ky': 'эрежелер жана политикалар',
    },
    'ta0e90v5': {
      'ru': 'Ознакомьтесь с правилами',
      'ky': 'эрежелер менен танышыныз',
    },
    '0adnrtq1': {
      'ru': 'Условия использования',
      'ky': 'колдонуу эрежелери',
    },
    'daf8557q': {
      'ru':
          'Используя наш сервис, вы соглашаетесь соблюдать настоящие условия. Пожалуйста, внимательно прочитайте их перед использованием платформы. Мы оставляем за собой право изменять условия в любое время. Продолжение использования сервиса означает ваше согласие с обновлёнными условиями.',
      'ky':
          'Используя наш сервис, вы соглашаетесь соблюдать настоящие условия. Пожалуйста, внимательно прочитайте их перед использованием платформы. Мы оставляем за собой право изменять условия в любое время. Продолжение использования сервиса означает ваше согласие с обновлёнными условиями.',
    },
    'o8n3z1wt': {
      'ru':
          'Пользователи обязуются не нарушать законодательство, не публиковать запрещённый контент и не использовать платформу в мошеннических целях. Нарушение условий может привести к блокировке аккаунта без предварительного уведомления.',
      'ky':
          'Пользователи обязуются не нарушать законодательство, не публиковать запрещённый контент и не использовать платформу в мошеннических целях. Нарушение условий может привести к блокировке аккаунта без предварительного уведомления.',
    },
    'gz8m61r5': {
      'ru': 'Политика конфиденциальности',
      'ky': 'Политика конфиденциальности',
    },
    '1rfa4veg': {
      'ru':
          'Мы уважаем вашу конфиденциальность и стремимся защитить ваши персональные данные. Настоящая политика описывает, какие данные мы собираем, как мы их используем и какие меры принимаем для их защиты.',
      'ky':
          'Мы уважаем вашу конфиденциальность и стремимся защитить ваши персональные данные. Настоящая политика описывает, какие данные мы собираем, как мы их используем и какие меры принимаем для их защиты.',
    },
    'p55qtrla': {
      'ru':
          'Мы можем собирать следующие данные: имя, адрес электронной почты, номер телефона, данные об устройстве и информацию об использовании сервиса. Эти данные используются для улучшения качества услуг, персонализации контента и обеспечения безопасности платформы.',
      'ky':
          'Мы можем собирать следующие данные: имя, адрес электронной почты, номер телефона, данные об устройстве и информацию об использовании сервиса. Эти данные используются для улучшения качества услуг, персонализации контента и обеспечения безопасности платформы.',
    },
    'ykqa7gkh': {
      'ru':
          'Мы не передаём ваши данные третьим лицам без вашего согласия, за исключением случаев, предусмотренных законодательством. Вы вправе запросить удаление своих данных в любое время, обратившись в службу поддержки.',
      'ky':
          'Мы не передаём ваши данные третьим лицам без вашего согласия, за исключением случаев, предусмотренных законодательством. Вы вправе запросить удаление своих данных в любое время, обратившись в службу поддержки.',
    },
    '3x5a0tt5': {
      'ru': 'Продолжая, вы принимаете условия и политику конфиденциальности',
      'ky': 'Продолжая, вы принимаете условия и политику конфиденциальности',
    },
    'hm2u4oin': {
      'ru': 'Продолжить',
      'ky': 'Продолжить',
    },
    'c5j5d6pi': {
      'ru': 'обявление',
      'ky': 'обявление',
    },
  },
  // mylisting
  {
    'wmxh68pv': {
      'ru': 'маи обявдении',
      'ky': 'Менин обявленияларым',
    },
    '6wax1f78': {
      'ru': 'Гланая',
      'ky': 'Гланая',
    },
  },
  // Miscellaneous
  {
    'to03kj40': {
      'ru': '',
      'ky': '',
    },
    '5cef488d': {
      'ru': '',
      'ky': '',
    },
    '4hxmszze': {
      'ru': '',
      'ky': '',
    },
    'yenlsh58': {
      'ru': '',
      'ky': '',
    },
    'jhdwy4vr': {
      'ru': '',
      'ky': '',
    },
    'mxybur3z': {
      'ru': '',
      'ky': '',
    },
    'd0m7u1kh': {
      'ru': '',
      'ky': '',
    },
    'mpctqsav': {
      'ru': '',
      'ky': '',
    },
    '21gpocdb': {
      'ru': '',
      'ky': '',
    },
    '5m8jef9f': {
      'ru': '',
      'ky': '',
    },
    'xsshaar0': {
      'ru': '',
      'ky': '',
    },
    'y69u9ukt': {
      'ru': '',
      'ky': '',
    },
    '1o0kp7yk': {
      'ru': '',
      'ky': '',
    },
    '8tp4kckz': {
      'ru': '',
      'ky': '',
    },
    '68kzakl1': {
      'ru': '',
      'ky': '',
    },
    'nlfggc0n': {
      'ru': '',
      'ky': '',
    },
    'b9v4ol2v': {
      'ru': '',
      'ky': '',
    },
    'ih2iwz92': {
      'ru': '',
      'ky': '',
    },
    'q03yn9if': {
      'ru': '',
      'ky': '',
    },
    'so6xnwx7': {
      'ru': '',
      'ky': '',
    },
    '0pbr4nl7': {
      'ru': '',
      'ky': '',
    },
    'wqa730ts': {
      'ru': '',
      'ky': '',
    },
    'a6ipuudh': {
      'ru': '',
      'ky': '',
    },
    'dwpu1o7c': {
      'ru': '',
      'ky': '',
    },
    'jfm9hccw': {
      'ru': '',
      'ky': '',
    },
    'igtqgybj': {
      'ru': '',
      'ky': '',
    },
    'gufy9rmx': {
      'ru': '',
      'ky': '',
    },
  },
].reduce((a, b) => a..addAll(b));
