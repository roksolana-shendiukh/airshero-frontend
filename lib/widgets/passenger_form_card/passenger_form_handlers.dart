part of 'passenger_form_card.dart';

extension PassengerFormHandlers on _PassengerFormCardState {
  void _onFormChanged() {
    if (_isSaved) setState(() => _isSaved = false);
    _notifyParent();
  }

  void _onDocumentNumberChanged() {
    if (_isSaved) setState(() => _isSaved = false);
    final number = _documentNumberController.text;
    setState(() {
      if (number.isEmpty) {
        _documentNumberInvalid = false;
      } else {
        _documentNumberInvalid = !_isDocumentNumberPartiallyValid(number);
      }
    });
    _checkDocumentChanged();
    _notifyParent();
  }

  void _checkDocumentChanged() {
    if (_foundPassengerId == null) return;
    final numberChanged = _documentNumberController.text != _originalDocumentNumber;
    final expireChanged = _documentExpire?.toIso8601String().split('T')[0] != _originalDocumentExpire;
    setState(() => _documentChanged = numberChanged || expireChanged);
  }

void _notifyParent() {
  Future.microtask(() {
    if (!mounted) return;

    final data = {
      'firstName':        _firstNameController.text,
      'lastName':         _lastNameController.text,
      'sexId':            _selectedSexId,
      'sex':              _sexIdToName(_selectedSexId),
      'dateOfBirth':      _dateOfBirth,
      'citizenshipId':    _selectedCitizenshipId,
      'documentTypeId':   _selectedDocumentTypeId,
      'documentNumber':   _documentNumberController.text,
      'documentIssue':    _documentIssue,
      'documentExpire':   _documentExpire,
      'isSaved':          _isSaved,
      'foundPassengerId': _foundPassengerId,
      'documentChanged':  _documentChanged,
    };

    widget.onDataChanged(data);
  });
}

  void _handleDateOfBirthInput() {
    final text = _dateOfBirthController.text;
    if (text.isEmpty) {
      setState(() {
        _dateOfBirth = null;
        _dateOfBirthInvalid = false;
      });
      _notifyParent();
      return;
    }
    if (text.length != 10) {
      setState(() => _dateOfBirthInvalid = false);
      return;
    }
    try {
      final parts = text.split('.');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      if (date.isAfter(DateTime.now())) {
        setState(() {
          _dateOfBirth = null;
          _dateOfBirthInvalid = true;
        });
        return;
      }
      setState(() {
        _dateOfBirth = date;
        _dateOfBirthInvalid = false;
      });
      _notifyParent();
    } catch (_) {
      setState(() {
        _dateOfBirth = null;
        _dateOfBirthInvalid = true;
      });
    }
  }

  void _handleDocumentIssueInput() {
    final text = _documentIssueController.text;
    if (text.isEmpty) {
      setState(() => _documentIssue = null);
      _notifyParent();
      return;
    }
    if (text.length != 10) return;
    try {
      final parts = text.split('.');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      if (date.isAfter(DateTime.now())) return;
      setState(() => _documentIssue = date);
      _checkDocumentChanged();
      _notifyParent();
    } catch (_) {}
  }

  void _handleDocumentExpireInput() {
    final text = _documentExpireController.text;
    if (text.isEmpty) {
      setState(() => _documentExpire = null);
      _notifyParent();
      return;
    }
    if (text.length != 10) return;
    try {
      final parts = text.split('.');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      if (date.isBefore(DateTime.now())) return;
      setState(() {
        _documentExpire = date;
        _checkDocumentChanged();
      });
      _notifyParent();
    } catch (_) {}
  }

  Future<void> _checkDocumentNumberExists(String number) async {
    try {
      final api = PassengerApiService(widget.authService);
      final passenger = await api.searchPassengerByDocument(number);

      if (!mounted || passenger == null) return;
      if (_foundPassengerId != null && passenger.passengerId == _foundPassengerId) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.info_outline, color: Colors.blue),
          title: const Text('Document already exists'),
          content: Text(
            'Document number "$number" is already registered.\n'
            'Would you like to fill the form with the existing passenger data?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _documentNumberInvalid     = true;
                  _documentNumberExistsError = true;
                });
              },
              child: const Text('Keep current'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fillFromPassenger(passenger);
              },
              child: const Text('Fill from existing'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  void _fillFromPassenger(PassengerModel passenger) {
    final doc = passenger.document;

    setState(() {
      _firstNameController.text = passenger.firstName;
      _lastNameController.text  = passenger.lastName;

      if (passenger.dateOfBirth != null) {
        _dateOfBirth = passenger.dateOfBirth is DateTime
            ? passenger.dateOfBirth as DateTime
            : DateTime.tryParse(passenger.dateOfBirth.toString());
        _dateOfBirthController.text = _dateOfBirth != null
            ? DateFormat('dd.MM.yyyy').format(_dateOfBirth!) : '';
      } else {
        _dateOfBirth = null;
        _dateOfBirthController.text = '';
      }

      _selectedSexId = _sexNameToId(passenger.sex) ?? _selectedSexId;

      if (doc != null) {
        _documentNumberController.text = doc.documentNumber ?? '';
        _originalDocumentNumber        = doc.documentNumber;
        _originalDocumentExpire        = doc.documentDateOfExpire?.toString();

        if (doc.documentDateOfIssue != null) {
          _documentIssue = doc.documentDateOfIssue is DateTime
              ? doc.documentDateOfIssue as DateTime
              : DateTime.tryParse(doc.documentDateOfIssue.toString());
          _documentIssueController.text = _documentIssue != null
              ? DateFormat('dd.MM.yyyy').format(_documentIssue!) : '';
        } else {
          _documentIssue = null;
          _documentIssueController.text = '';
        }

        if (doc.documentDateOfExpire != null) {
          _documentExpire = doc.documentDateOfExpire is DateTime
              ? doc.documentDateOfExpire as DateTime
              : DateTime.tryParse(doc.documentDateOfExpire.toString());
          _documentExpireController.text = _documentExpire != null
              ? DateFormat('dd.MM.yyyy').format(_documentExpire!) : '';
        } else {
          _documentExpire = null;
          _documentExpireController.text = '';
        }

        final citizenship = _citizenships.firstWhere(
          (c) => c['citizenshipId'] == doc.citizenshipId,
          orElse: () => _citizenships.isNotEmpty ? _citizenships.first : {},
        );
        if (citizenship.isNotEmpty) {
          _selectedCitizenshipId = citizenship['citizenshipId'] as int;
        }

        final docType = _documentTypes.firstWhere(
          (d) => d['documentTypeId'] == doc.documentTypeId,
          orElse: () => _documentTypes.isNotEmpty ? _documentTypes.first : {},
        );
        if (docType.isNotEmpty) {
          _selectedDocumentTypeId = docType['documentTypeId'] as int;
        }
      } else {
        _documentNumberController.text = '';
        _documentIssue                 = null;
        _documentIssueController.text  = '';
        _documentExpire                = null;
        _documentExpireController.text = '';
        _originalDocumentNumber        = null;
        _originalDocumentExpire        = null;
      }

      _foundPassengerId          = passenger.passengerId;
      _documentChanged           = false;
      _isSaved                   = false;
      _dateOfBirthInvalid        = false;
      _documentNumberInvalid     = false;
      _firstNameInvalid          = false;
      _lastNameInvalid           = false;
      _firstNameTouched          = false;
      _lastNameTouched           = false;
      _firstNameEdited           = false;
      _lastNameEdited            = false;
      _documentNumberExistsError = false;
    });

    _notifyParent();
  }

  void _clearFoundPassenger() {
    setState(() {
      _foundPassengerId       = null;
      _originalDocumentNumber = null;
      _originalDocumentExpire = null;
      _documentChanged        = false;
    });
    _notifyParent();
  }

  void _clearForm() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _documentNumberController.clear();
      _dateOfBirthController.clear();
      _documentIssueController.clear();
      _documentExpireController.clear();

      _selectedSexId          = _sexes.isNotEmpty ? _sexes.first['id'].toString() : null;
      _selectedCitizenshipId  = _citizenships.isNotEmpty ? _citizenships.first['citizenshipId'] as int : null;
      _selectedDocumentTypeId = _documentTypes.isNotEmpty ? _documentTypes.first['documentTypeId'] as int : null;

      _dateOfBirth    = null;
      _documentIssue  = null;
      _documentExpire = null;

      _foundPassengerId          = null;
      _originalDocumentNumber    = null;
      _originalDocumentExpire    = null;
      _documentChanged           = false;
      _isSaved                   = false;
      _dateOfBirthInvalid        = false;
      _documentNumberInvalid     = false;
      _firstNameInvalid          = false;
      _lastNameInvalid           = false;
      _firstNameTouched          = false;
      _lastNameTouched           = false;
      _firstNameEdited           = false;
      _lastNameEdited            = false;
      _documentNumberExistsError = false;
      _dateOfBirthTouched        = false;
      _documentIssueTouched      = false;
      _documentExpireTouched     = false;
      _citizenshipTouched        = false;
      _documentTypeTouched       = false;
      _documentNumberTouched     = false;
    });
    _notifyParent();
  }

  Future<void> _handleSave() async {
    setState(() {
      _firstNameTouched      = true;
      _lastNameTouched       = true;
      _firstNameInvalid      = _firstNameController.text.isEmpty || _firstNameController.text.length < 3;
      _lastNameInvalid       = _lastNameController.text.isEmpty || _lastNameController.text.length < 3;
      _documentNumberInvalid = !_isDocumentNumberValid(_documentNumberController.text);
      _dateOfBirthTouched    = true;
      _documentIssueTouched  = true;
      _documentExpireTouched = true;
      _citizenshipTouched    = true;
      _documentTypeTouched   = true;
      _sexTouched            = true;
      _documentNumberTouched = true;
    });

    if (_ageMismatchMessage != null) {
      _showErrorDialog(_ageMismatchMessage!);
      return;
    }
    if (!_validateForm()) {
      _showErrorDialog('Please fill in all required fields correctly.');
      return;
    }

    if (_isSaved) {
      final hasChanges =
          _firstNameController.text != (widget.initialData?['firstName'] ?? '') ||
          _lastNameController.text  != (widget.initialData?['lastName'] ?? '')  ||
          _dateOfBirth              != widget.initialData?['dateOfBirth']        ||
          _selectedSexId            != widget.initialData?['sexId']?.toString()  ||
          _selectedCitizenshipId    != widget.initialData?['citizenshipId']      ||
          _selectedDocumentTypeId   != widget.initialData?['documentTypeId']     ||
          _documentNumberController.text != (widget.initialData?['documentNumber'] ?? '') ||
          _documentIssue            != widget.initialData?['documentIssue']      ||
          _documentExpire           != widget.initialData?['documentExpire'];

      if (!hasChanges) {
        _showErrorDialog('No changes to update.');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'firstName':        _firstNameController.text,
        'lastName':         _lastNameController.text,
        'sexId':            _selectedSexId,
        'sex':              _sexIdToName(_selectedSexId),
        'dateOfBirth':      _dateOfBirth,
        'citizenshipId':    _selectedCitizenshipId,
        'documentTypeId':   _selectedDocumentTypeId,
        'documentNumber':   _documentNumberController.text,
        'documentIssue':    _documentIssue,
        'documentExpire':   _documentExpire,
        'isSaved':          true,
        'foundPassengerId': _foundPassengerId,
        'documentChanged':  _documentChanged,
      };

      await LocalPassengerService.savePassenger(
        widget.sessionId,
        widget.passengerIndex,
        data,
      );

      setState(() => _isSaved = true);
      _notifyParent();
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}