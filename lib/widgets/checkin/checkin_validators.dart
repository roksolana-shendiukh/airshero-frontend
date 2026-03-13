part of 'checkin_search_step.dart';

extension CheckInSearchValidators on _CheckInSearchStepState {
  bool _isFlightNumberValid(String value) =>
      RegExp(r'^[A-Za-z][A-Za-z0-9]\d{1,4}$').hasMatch(value);

  bool _isFlightNumberPartiallyValid(String value) {
    if (value.isEmpty) return true;
    if (value.length == 1) return RegExp(r'^[A-Za-z]$').hasMatch(value);
    if (value.length == 2) return RegExp(r'^[A-Za-z][A-Za-z0-9]$').hasMatch(value);
    return RegExp(r'^[A-Za-z][A-Za-z0-9]\d{1,4}$').hasMatch(value);
  }

  String? get _documentNumberError {
    if (!_documentNumberTouched) return null;
    if (_documentNumberController.text.trim().isEmpty) return 'Required field';
    return null;
  }

  String? get _departDateError {
    if (!_departDateTouched) return null;
    if (_departDate == null) {
      return _departureDateController.text.isNotEmpty ? 'Invalid date format' : 'Required field';
    }
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (_departDate!.isBefore(today)) return 'Departure date cannot be in the past';
    final limit = DateTime(DateTime.now().year + 2, DateTime.now().month, DateTime.now().day);
    if (_departDate!.isAfter(limit)) return 'Departure date is too far in the future';
    return null;
  }

  bool get _isFormValid =>
      _documentNumberController.text.trim().isNotEmpty &&
      _flightNumberController.text.trim().isNotEmpty &&
      _isFlightNumberValid(_flightNumberController.text) &&
      _departDate != null &&
      _departDateError == null;
}