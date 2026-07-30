import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldRaw = oldValue.text.replaceAll('.', '');
    final newRaw = newValue.text.replaceAll('.', '');

    if (newRaw.length < oldRaw.length || newValue.text.length < oldValue.text.length) {
      if (newRaw.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      final raw = (newRaw.length == oldRaw.length && newValue.text.length < oldValue.text.length)
          ? newRaw.substring(0, newRaw.length - 1)
          : newRaw;
      if (raw.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      final formatted = _format(raw);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    if (newRaw == oldRaw) return oldValue;
    if (newRaw.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(newRaw)) {
      return oldValue;
    }
    if (newRaw.length > 8) {
      return oldValue;
    }
    if (newRaw.length >= 1 && int.parse(newRaw[0]) > 3) {
      return oldValue;
    }
    if (newRaw.length >= 2) {
      final day = int.parse(newRaw.substring(0, 2));
      if (day > 31 || day == 0) {
        return oldValue;
      }
    }
    if (newRaw.length >= 3 && int.parse(newRaw[2]) > 1) {
      return oldValue;
    }
    if (newRaw.length >= 4) {
      final month = int.parse(newRaw.substring(2, 4));
      if (month > 12 || month == 0) {
        return oldValue;
      }
    }
    if (newRaw.length >= 5 &&
        int.parse(newRaw[4]) != 1 &&
        int.parse(newRaw[4]) != 2) {
      return oldValue;
    }

    final formatted = _format(newRaw);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String raw) {
    String result = '';
    for (int i = 0; i < raw.length; i++) {
      result += raw[i];
      if (i == 1 || i == 3) result += '.';
    }
    return result;
  }
}