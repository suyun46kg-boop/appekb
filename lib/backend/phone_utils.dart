import 'package:flutter/services.dart';

/// Номера телефонов в формате +7: 10 цифр после кода страны.

/// Десять цифр номера без кода страны из любого ввода:
/// «8 908 919-79-09», «+7(908)…», «9089197909».
String phoneDigits10(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 11 && (digits[0] == '7' || digits[0] == '8')) {
    digits = digits.substring(1);
  }
  return digits.length > 10 ? digits.substring(0, 10) : digits;
}

/// «9089197909» → «(908) 919-79-09»; неполный номер форматируется частично.
String formatPhoneMask(String digits10) {
  final d = digits10;
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 0) b.write('(');
    if (i == 3) b.write(') ');
    if (i == 6 || i == 8) b.write('-');
    b.write(d[i]);
  }
  return b.toString();
}

/// Единый формат для базы: «+79089197909».
String phoneToStorage(String digits10) => '+7$digits10';

/// Маска ввода «(908) 919-79-09»: только цифры, не больше 10.
class RuPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    // Удаление разделителя («-», «)») должно стирать и цифру перед ним.
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newValue.text.length < oldValue.text.length &&
        digits == oldDigits &&
        digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
    }
    // Вставка номера целиком с 8/7 впереди.
    if (digits.length == 11 && (digits[0] == '7' || digits[0] == '8')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    final text = formatPhoneMask(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
