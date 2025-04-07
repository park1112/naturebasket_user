import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FormatHelper {
  static String formatPrice(num price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }

  static String formatNumber(int number) {
    final formatNumber = NumberFormat('#,###');
    return formatNumber.format(number);
  }

  static String formatPhoneNumber(String phoneNumber) {
    // 숫자만 추출
    String numbers = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 6)}-${numbers.substring(6)}';
    }

    return phoneNumber; // 포맷팅할 수 없는 경우 원본 반환
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (text.isEmpty) return newValue;

    // 숫자만 추출
    text = text.replaceAll(RegExp(r'[^\d]'), '');

    // 11자리를 초과하지 않도록 제한
    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    var newText = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 7) {
        newText += '-';
      }
      newText += text[i];
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
