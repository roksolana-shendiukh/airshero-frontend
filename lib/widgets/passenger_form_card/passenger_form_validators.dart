part of 'passenger_form_card.dart';

_AgeCategory _getAgeCategory(DateTime? dob) {
  if (dob == null) return _AgeCategory.unknown;
  final now = DateTime.now();
  final age = now.year - dob.year -
      ((now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day))
          ? 1
          : 0);
  if (age >= 12) return _AgeCategory.adult;
  if (age >= 3)  return _AgeCategory.child;
  return _AgeCategory.infant;
}

extension PassengerFormValidators on _PassengerFormCardState {
  String? get _ageMismatchMessage {
    if (_dateOfBirth == null) return null;
    final category = _getAgeCategory(_dateOfBirth);
    final type = widget.passengerType.toLowerCase();
    switch (type) {
      case 'adult':
        if (category != _AgeCategory.adult)
          return 'Adult passengers must be 12 years or older';
        break;
      case 'child':
        if (category != _AgeCategory.child)
          return 'Child passengers must be between 3 and 11 years old';
        break;
      case 'infant':
        if (category != _AgeCategory.infant)
          return 'Infant passengers must be 2 years old or younger';
        break;
    }
    return null;
  }

  bool _isDocumentNumberValid(String number) {
    final code = _selectedDocTypeCode;
    if (code == null || number.isEmpty) return true;
    switch (code) {
      case 'PAS':
      case 'INT':
        return RegExp(r'^[A-Za-z]{2}\d{7}$').hasMatch(number);
      case 'OFF':
        return RegExp(r'^[A-Za-z]{1}\d{7}$').hasMatch(number);
      case 'ID':
        return RegExp(r'^\d{9}$').hasMatch(number);
      default:
        return true;
    }
  }

  bool _isDocumentNumberPartiallyValid(String number) {
    final code = _selectedDocTypeCode;
    if (code == null || number.isEmpty) return true;
    switch (code) {
      case 'PAS':
      case 'INT':
        if (number.length <= 2) return RegExp(r'^[A-Za-z]{1,2}$').hasMatch(number);
        return RegExp(r'^[A-Za-z]{2}\d{1,7}$').hasMatch(number);
      case 'OFF':
        if (number.length == 1) return RegExp(r'^[A-Za-z]$').hasMatch(number);
        return RegExp(r'^[A-Za-z]{1}\d{1,7}$').hasMatch(number);
      case 'ID':
        return RegExp(r'^\d{1,9}$').hasMatch(number);
      default:
        return true;
    }
  }

  bool _validateForm() {
    if (_ageMismatchMessage != null) return false;
    if (_documentDatesMismatchMessage != null) return false;
    if (_firstNameController.text.length < 3) return false;
    if (_lastNameController.text.length < 3) return false;
    if (_documentNumberInvalid) return false;
    if (!_isDocumentNumberValid(_documentNumberController.text)) return false;
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _dateOfBirth != null &&
        _selectedSexId != null &&
        _documentNumberController.text.isNotEmpty &&
        _documentIssue != null &&
        _documentExpire != null &&
        _selectedCitizenshipId != null &&
        _selectedDocumentTypeId != null;
  }

  String? get _documentDatesMismatchMessage {
    if (_documentIssue != null && _documentExpire != null) {
      if (!_documentExpire!.isAfter(_documentIssue!)) {
        return 'Expiry date must be after issue date';
      }
    }

    if (_documentExpire != null && _documentIssue != null) {
      final code = _selectedDocTypeCode;
      final minYears = const {
        'PAS': 4,
        'ID':  4,
        'INT': 5,
        'OFF': 1,
      }[code];

      if (minYears != null) {
        final minExpireFromIssue = DateTime(
          _documentIssue!.year + minYears,
          _documentIssue!.month,
          _documentIssue!.day,
        );
        if (_documentExpire!.isBefore(minExpireFromIssue)) {
          final label = const {
            'PAS': 'Passport',
            'ID':  'ID Card',
            'INT': 'International Passport',
            'OFF': 'Service Passport',
          }[code] ?? 'Document';
          return '$label must be valid for at least $minYears year${minYears > 1 ? 's' : ''} from issue date';
        }
      }
    }

    if (_documentExpire != null) {
      final minExpiry = DateTime(
        widget.departDate.year,
        widget.departDate.month + 2,
        widget.departDate.day,
      );
      if (_documentExpire!.isBefore(minExpiry)) {
        return 'Document must be valid for at least 2 months after departure date';
      }
    }

    return null;
  }

}