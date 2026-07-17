part of 'checkin_search_step.dart';

extension _CheckInSearchValidators on _CheckInSearchStepState {
  bool get _isFormValid => _controller.text.trim().isNotEmpty;
}