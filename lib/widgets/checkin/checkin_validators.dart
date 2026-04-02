part of 'checkin_search_step.dart';

extension CheckInSearchValidators on _CheckInSearchStepState {
  String? get _documentNumberError {
    if (!_documentNumberTouched) return null;
    if (_controller.text.trim().isEmpty) return 'Required field';
    return null;
  }

  bool get _isFormValid => _controller.text.trim().isNotEmpty;
}