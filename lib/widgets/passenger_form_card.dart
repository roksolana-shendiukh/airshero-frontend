import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/passenger_model.dart';
import '../services/reference_api_service.dart';
import '../services/auth_service.dart';
import '../services/local_passenger_service.dart';
import 'custom/custom_input_field.dart';
import 'custom/custom_select_field.dart';
import 'custom/custom_button.dart';
import 'custom/custom_single_date_picker.dart';
import 'passenger_search_bar.dart';
import '../services/passenger_api_service.dart';

const Map<String, String> _docHints = {
  'PAS': 'Format: AB1234567 (2 letters + 7 digits)',
  'INT': 'Format: AB1234567 (2 letters + 7 digits)',
  'OFF': 'Format: A1234567 (1 letter + 7 digits)',
  'ID':  'Format: 123456789 (9 digits)',
};

enum _DatePickerType { dateOfBirth, documentIssue, documentExpire }

enum _AgeCategory { adult, child, infant, unknown }

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

class PassengerFormCard extends StatefulWidget {
  final int passengerIndex;
  final String passengerType;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic>? initialData;
  final AuthService authService;
  final String sessionId;

  const PassengerFormCard({
    super.key,
    required this.passengerIndex,
    required this.passengerType,
    required this.onDataChanged,
    required this.authService,
    required this.sessionId,
    this.initialData,
  });

  @override
  State<PassengerFormCard> createState() => _PassengerFormCardState();
}

class _PassengerFormCardState extends State<PassengerFormCard> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _documentNumberController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _documentIssueController;
  late TextEditingController _documentExpireController;  
  bool _dateOfBirthInvalid = false;
  bool _documentNumberInvalid = false;
  bool _firstNameInvalid = false;
  bool _lastNameInvalid = false;
  bool _firstNameTouched = false;
  bool _lastNameTouched = false;
  bool _firstNameEdited = false;
  bool _lastNameEdited  = false;
  bool _documentNumberExistsError = false;
  bool _dateOfBirthTouched = false;
  bool _documentIssueTouched = false;
  bool _documentExpireTouched = false;
  bool _citizenshipTouched = false;
  bool _documentTypeTouched = false;
  bool _documentNumberTouched = false;
  bool _sexTouched = false;

  String? _selectedSexId;
  DateTime? _dateOfBirth;
  DateTime? _documentIssue;
  DateTime? _documentExpire;

  List<Map<String, dynamic>> _sexes = [];
  List<Map<String, dynamic>> _citizenships = [];
  List<Map<String, dynamic>> _documentTypes = [];
  int? _selectedCitizenshipId;
  int? _selectedDocumentTypeId;
  bool _referencesLoading = true;

  bool _isSaved = false;
  bool _isSaving = false;

  int? _foundPassengerId;
  String? _originalDocumentNumber;
  String? _originalDocumentExpire;
  bool _documentChanged = false;

  final LayerLink _dateOfBirthLayerLink    = LayerLink();
  final LayerLink _documentIssueLayerLink  = LayerLink();
  final LayerLink _documentExpireLayerLink = LayerLink();
  final FocusNode _dateOfBirthFocusNode    = FocusNode();
  final FocusNode _documentNumberFocusNode = FocusNode();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode  = FocusNode();

  OverlayEntry? _datePickerOverlay;
  OverlayEntry? _datePickerBarrier;

  String? get _selectedDocTypeCode {
    if (_selectedDocumentTypeId == null) return null;
    for (final d in _documentTypes) {
      final id = d['documentTypeId'];
      if (id == _selectedDocumentTypeId ||
          id.toString() == _selectedDocumentTypeId.toString()) {
        return d['documentTypeCode'] as String?;
      }
    }
    return null;
  }

  String? get _documentNumberFocusHint {
    final code = _selectedDocTypeCode;
    return code != null ? _docHints[code] : 'Select document type first';
  }

  String get _documentIssueFocusHint {
    if (_dateOfBirth != null) return 'From ${_dateOfBirth!.year + 1} to today';
    return 'Must not be in the future';
  }

  String get _documentExpireFocusHint {
    if (_documentIssue != null) {
      return 'Must be after ${DateFormat('dd.MM.yyyy').format(_documentIssue!)}';
    }
    return 'Must be after issue date';
  }

  String get _dateOfBirthHint {
    switch (widget.passengerType.toLowerCase()) {
      case 'adult':  return 'Adult: 12+ years old';
      case 'child':  return 'Child: 3–11 years old';
      case 'infant': return 'Infant: 0–2 years old';
      default:       return 'Date of birth';
    }
  }

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

  String? _sexNameToId(String? sexName) {
    if (sexName == null) return null;
    final found = _sexes.firstWhere(
      (s) => (s['name'] as String).toLowerCase() == sexName.toLowerCase(),
      orElse: () => {},
    );
    return found.isNotEmpty ? found['id'].toString() : null;
  }

  String _sexIdToName(String? sexId) {
    if (sexId == null) return '';
    final found = _sexes.firstWhere(
      (s) => s['id'].toString() == sexId,
      orElse: () => {},
    );
    return found.isNotEmpty ? found['name'] as String : '';
  }

  String _firstNameHint(String value) {
    if (value.isEmpty && _firstNameTouched && !_firstNameFocusNode.hasFocus) {
      return 'Required field';
    }
    return '3–30 characters, Latin letters only';
  }

  String _lastNameHint(String value) {
    if (value.isEmpty && _lastNameTouched && !_lastNameFocusNode.hasFocus) {
      return 'Required field';
    }
    return '3–30 characters, Latin letters only';
  }

  String get _documentNumberHintText {
    if (_documentNumberExistsError) return 'Document number already exists';
    return _documentNumberFocusHint ?? '';
  }
  List<TextInputFormatter> get _documentNumberFormatters {
    final code = _selectedDocTypeCode;
    if (code == null) return [];
    switch (code) {
      case 'PAS':
      case 'INT':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(9), 
        ];
      case 'OFF':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(8), 
        ];
      case 'ID':
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ];
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();

    _firstNameController      = TextEditingController(text: widget.initialData?['firstName'] ?? '');
    _lastNameController       = TextEditingController(text: widget.initialData?['lastName'] ?? '');
    _documentNumberController = TextEditingController(text: widget.initialData?['documentNumber'] ?? '');

    if (widget.initialData != null) {
      _selectedSexId          = widget.initialData!['sexId']?.toString();
      _dateOfBirth            = widget.initialData!['dateOfBirth'];
      _documentIssue          = widget.initialData!['documentIssue'];
      _documentExpire         = widget.initialData!['documentExpire'];
      _selectedCitizenshipId  = widget.initialData!['citizenshipId'];
      _selectedDocumentTypeId = widget.initialData!['documentTypeId'];
      _isSaved                = widget.initialData!['isSaved'] ?? false;
      _foundPassengerId       = widget.initialData!['foundPassengerId'];
    }

    _dateOfBirthController = TextEditingController(
      text: _dateOfBirth != null ? DateFormat('dd.MM.yyyy').format(_dateOfBirth!) : '',
    );
    _documentIssueController = TextEditingController(
      text: _documentIssue != null ? DateFormat('dd.MM.yyyy').format(_documentIssue!) : '',
    );
    _documentExpireController = TextEditingController(
      text: _documentExpire != null ? DateFormat('dd.MM.yyyy').format(_documentExpire!) : '',
    );
    

    _firstNameController.addListener(_onFormChanged);
    _lastNameController.addListener(_onFormChanged);
    _documentNumberController.addListener(_onDocumentNumberChanged);
    _dateOfBirthController.addListener(_handleDateOfBirthInput);
    _documentIssueController.addListener(_handleDocumentIssueInput);
    _documentExpireController.addListener(_handleDocumentExpireInput);
    _documentNumberFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          final number = _documentNumberController.text;
          if (_documentNumberFocusNode.hasFocus) {
            _documentNumberInvalid = false;
          } else {
            _documentNumberInvalid = number.isNotEmpty && !_isDocumentNumberValid(number);
          }
        });

        if (!_documentNumberFocusNode.hasFocus) {
          final number = _documentNumberController.text;
          if (number.isNotEmpty && _isDocumentNumberValid(number)) {
            _checkDocumentNumberExists(number);
          }
        }
      }
    });

    _firstNameFocusNode.addListener(() {
      if (mounted) setState(() {
        if (_firstNameFocusNode.hasFocus) {
          _firstNameTouched = true;
          _firstNameInvalid = false;
        } else {
         _firstNameInvalid = (_firstNameTouched && _firstNameController.text.isEmpty) ||
              (_firstNameEdited && _firstNameController.text.length < 3);
        }
      });
    });

    _lastNameFocusNode.addListener(() {
      if (mounted) setState(() {
        if (_lastNameFocusNode.hasFocus) {
          _lastNameTouched = true;
          _lastNameInvalid = false;
        } else {
          _lastNameInvalid = (_lastNameTouched && _lastNameController.text.isEmpty) ||
              (_lastNameEdited && _lastNameController.text.length < 3);
        }
      });
    });

    _dateOfBirthFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _loadReferences();
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
                  _documentNumberInvalid = true;
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
    } catch (_) {
    }
  }

  Future<void> _loadReferences() async {
    final ref = ReferenceApiService(widget.authService);
    final results = await Future.wait([
      ref.getSexes(),
      ref.getCitizenships(),
      ref.getDocumentTypes(),
    ]);

    if (!mounted) return;
    setState(() {
      _sexes         = results[0];
      _citizenships  = results[1];
      _documentTypes = results[2];
      _referencesLoading = false;

      if (_selectedSexId == null && _sexes.isNotEmpty) {
        _selectedSexId = _sexes.first['id'].toString();
      }
      if (_selectedCitizenshipId == null && _citizenships.isNotEmpty) {
        _selectedCitizenshipId = _citizenships.first['citizenshipId'] as int;
      }
      if (_selectedDocumentTypeId == null && _documentTypes.isNotEmpty) {
        _selectedDocumentTypeId = _documentTypes.first['documentTypeId'] as int;
      }
    });
  }

  @override
  void didUpdateWidget(PassengerFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.passengerIndex != widget.passengerIndex ||
        oldWidget.initialData != widget.initialData) {

      _firstNameController.removeListener(_onFormChanged);
      _lastNameController.removeListener(_onFormChanged);
      _documentNumberController.removeListener(_onDocumentNumberChanged);
      _dateOfBirthController.removeListener(_handleDateOfBirthInput);
      _documentIssueController.removeListener(_handleDocumentIssueInput);
      _documentExpireController.removeListener(_handleDocumentExpireInput);

      _firstNameController.text      = widget.initialData?['firstName'] ?? '';
      _lastNameController.text       = widget.initialData?['lastName'] ?? '';
      _documentNumberController.text = widget.initialData?['documentNumber'] ?? '';

      setState(() {
        _selectedSexId          = widget.initialData?['sexId']?.toString();
        _dateOfBirth            = widget.initialData?['dateOfBirth'];
        _documentIssue          = widget.initialData?['documentIssue'];
        _documentExpire         = widget.initialData?['documentExpire'];
        _selectedCitizenshipId  = widget.initialData?['citizenshipId'];
        _selectedDocumentTypeId = widget.initialData?['documentTypeId'];
        _isSaved                = widget.initialData?['isSaved'] ?? false;
        _foundPassengerId       = widget.initialData?['foundPassengerId'];
        _documentChanged        = false;
        _dateOfBirthTouched    = false;
        _documentIssueTouched  = false;
        _documentExpireTouched = false;
        _citizenshipTouched    = false;
        _documentTypeTouched   = false;
        _documentNumberTouched = false;

        if (_selectedSexId == null && _sexes.isNotEmpty) {
          _selectedSexId = _sexes.first['id'].toString();
        }
        if (_selectedCitizenshipId == null && _citizenships.isNotEmpty) {
          _selectedCitizenshipId = _citizenships.first['citizenshipId'] as int;
        }
        if (_selectedDocumentTypeId == null && _documentTypes.isNotEmpty) {
          _selectedDocumentTypeId = _documentTypes.first['documentTypeId'] as int;
        }

        _dateOfBirthController.text = _dateOfBirth != null
            ? DateFormat('dd.MM.yyyy').format(_dateOfBirth!) : '';
        _documentIssueController.text = _documentIssue != null
            ? DateFormat('dd.MM.yyyy').format(_documentIssue!) : '';
        _documentExpireController.text = _documentExpire != null
            ? DateFormat('dd.MM.yyyy').format(_documentExpire!) : '';
      });

      _firstNameController.addListener(_onFormChanged);
      _lastNameController.addListener(_onFormChanged);
      _documentNumberController.addListener(_onDocumentNumberChanged);
      _dateOfBirthController.addListener(_handleDateOfBirthInput);
      _documentIssueController.addListener(_handleDocumentIssueInput);
      _documentExpireController.addListener(_handleDocumentExpireInput);

      _removeDatePicker();
    }
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
        _documentIssue = null;
        _documentIssueController.text = '';
        _documentExpire = null;
        _documentExpireController.text = '';
        _originalDocumentNumber = null;
        _originalDocumentExpire = null;
      }

      _foundPassengerId = passenger.passengerId;
      _documentChanged  = false;
      _isSaved          = false;
      _dateOfBirthInvalid = false;
      _documentNumberInvalid = false;
      _firstNameInvalid  = false;
      _lastNameInvalid   = false;
      _firstNameTouched  = false;
      _lastNameTouched   = false;
      _firstNameEdited = false;
      _lastNameEdited  = false;
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

      _selectedSexId = _sexes.isNotEmpty ? _sexes.first['id'].toString() : null;
      _selectedCitizenshipId  = _citizenships.isNotEmpty ? _citizenships.first['citizenshipId'] as int : null;
      _selectedDocumentTypeId = _documentTypes.isNotEmpty ? _documentTypes.first['documentTypeId'] as int : null;

      _dateOfBirth    = null;
      _documentIssue  = null;
      _documentExpire = null;

      _foundPassengerId       = null;
      _originalDocumentNumber = null;
      _originalDocumentExpire = null;
      _documentChanged        = false;
      _isSaved                = false;
      _dateOfBirthInvalid = false;
      _documentNumberInvalid = false;
      _firstNameInvalid  = false;
      _lastNameInvalid   = false;
      _firstNameTouched  = false;
      _lastNameTouched   = false;
      _firstNameEdited = false;
      _lastNameEdited  = false;
      _documentNumberExistsError = false;
      _dateOfBirthTouched    = false;
      _documentIssueTouched  = false;
      _documentExpireTouched = false;
      _citizenshipTouched    = false;
      _documentTypeTouched   = false;
      _documentNumberTouched = false;
    });
    _notifyParent();
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

  void _onFormChanged() {
    if (_isSaved) setState(() => _isSaved = false);
    _notifyParent();
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

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onDataChanged(data);
      });
    } else {
      if (!mounted) return;
      widget.onDataChanged(data);
    }
  }

  bool _validateForm() {
    if (_ageMismatchMessage != null) return false;
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
  
  void _removeDatePicker() {
    _datePickerBarrier?.remove();
    _datePickerBarrier = null;
    _datePickerOverlay?.remove();
    _datePickerOverlay = null;
  }

  void _showDatePicker(LayerLink layerLink, _DatePickerType type) {
    _removeDatePicker();

    DateTime? selectedDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (type) {
      case _DatePickerType.dateOfBirth:
        selectedDate = _dateOfBirth;
        firstDate    = DateTime(1920);
        lastDate     = DateTime.now();
        break;
      case _DatePickerType.documentIssue:
        selectedDate = _documentIssue;
        firstDate    = _dateOfBirth != null ? DateTime(_dateOfBirth!.year + 1) : DateTime(1920);
        lastDate     = DateTime.now();
        break;
      case _DatePickerType.documentExpire:
        selectedDate = _documentExpire;
        firstDate    = _documentIssue != null
            ? _documentIssue!.add(const Duration(days: 1))
            : DateTime.now();
        lastDate     = DateTime(2050);
        break;
    }

    _datePickerBarrier = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeDatePicker,
        child: const SizedBox.expand(),
      ),
    );

    _datePickerOverlay = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 350,
              child: CustomSingleDatePicker(
                selectedDate: selectedDate,
                firstDate: firstDate,
                lastDate: lastDate,
                onDateSelected: (date) {
                  setState(() {
                    switch (type) {
                      case _DatePickerType.dateOfBirth:
                        _dateOfBirth = date;
                        _dateOfBirthController.text =
                            DateFormat('dd.MM.yyyy').format(date);
                        break;
                      case _DatePickerType.documentIssue:
                        _documentIssue = date;
                        _documentIssueController.text =
                            DateFormat('dd.MM.yyyy').format(date);
                        _checkDocumentChanged();
                        break;
                      case _DatePickerType.documentExpire:
                        _documentExpire = date;
                        _documentExpireController.text =
                            DateFormat('dd.MM.yyyy').format(date);
                        _checkDocumentChanged();
                        break;
                    }
                  });
                  _notifyParent();
                  _removeDatePicker();
                },
                onClose: _removeDatePicker,
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_datePickerBarrier!);
    overlay.insert(_datePickerOverlay!);
  }

  @override
  void dispose() {
    _removeDatePicker();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentNumberController.dispose();
    _dateOfBirthController.dispose();
    _documentIssueController.dispose();
    _documentExpireController.dispose();
    _dateOfBirthFocusNode.dispose();
    _documentNumberFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ageMismatch = _ageMismatchMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassengerSearchBar(
          authService: widget.authService,
          onPassengerFound: _fillFromPassenger,
          onClear: _clearFoundPassenger,
        ),

        const SizedBox(height: 16),

        if (_documentChanged) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: colors.tertiary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Document changed — a new document will be created on payment',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onTertiaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isSaved
                  ? colors.primary.withValues(alpha: 0.5)
                  : colors.outline.withValues(alpha: 0.2),
              width: _isSaved ? 1.5 : 1.0,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.passengerType} ${widget.passengerIndex + 1}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        if (_isSaved) ...[
                          Icon(Icons.check_circle_outline, size: 18, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Saved',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: _clearForm,
                          child: const Text('Clear',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // First Name / Last Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Focus(
                            focusNode: _firstNameFocusNode,
                            child: CustomInputField(
                              label: 'First Name *',
                              value: _firstNameController.text,
                              icon: Icons.person_outline,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                LengthLimitingTextInputFormatter(30),
                              ],
                              onChanged: (v) {
                                final prev = _firstNameController.text;
                                _firstNameController.value = TextEditingValue(
                                  text: v,
                                  selection: TextSelection.collapsed(offset: v.length),
                                );
                                setState(() {
                                  if (v.isNotEmpty) _firstNameEdited = true;
                                  final isDeleting = v.length < prev.length;
                                  _firstNameInvalid = _firstNameEdited && isDeleting && v.isNotEmpty && v.length < 3;
                                });
                                _notifyParent();
                              },
                            ),
                          ),
                          if (_firstNameFocusNode.hasFocus ||
                              (_firstNameTouched && !_firstNameFocusNode.hasFocus &&
                                  (_firstNameController.text.isEmpty || _firstNameInvalid))) ...[
                            const SizedBox(height: 4),
                            Text(
                              _firstNameHint(_firstNameController.text),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: (_firstNameInvalid ||
                                            (!_firstNameFocusNode.hasFocus && _firstNameTouched &&
                                                _firstNameController.text.isEmpty))
                                        ? colors.error
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Focus(
                            focusNode: _lastNameFocusNode,
                            child: CustomInputField(
                              label: 'Last Name *',
                              value: _lastNameController.text,
                              icon: Icons.person_outline,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                                LengthLimitingTextInputFormatter(30),
                              ],
                              onChanged: (v) {
                                final prev = _lastNameController.text;
                                _lastNameController.text = v;
                                setState(() {
                                  if (v.isNotEmpty) _lastNameEdited = true;
                                  final isDeleting = v.length < prev.length;
                                  _lastNameInvalid = _lastNameEdited && isDeleting && v.isNotEmpty && v.length < 3;
                                });
                              },
                            ),
                          ),
                          if (_lastNameFocusNode.hasFocus ||
                              (_lastNameTouched && !_lastNameFocusNode.hasFocus &&
                                  (_lastNameController.text.isEmpty || _lastNameInvalid))) ...[
                            const SizedBox(height: 4),
                            Text(
                              _lastNameHint(_lastNameController.text),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: (_lastNameInvalid ||
                                            (!_lastNameFocusNode.hasFocus && _lastNameTouched &&
                                                _lastNameController.text.isEmpty))
                                        ? colors.error
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sex / Date of Birth
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _referencesLoading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomSelectField(
                              label: 'Sex *',
                              icon: Icons.wc,
                              value: _selectedSexId ?? '',
                              items: _sexes.map((s) => s['id'].toString()).toList(),
                              itemLabels: _sexes.map((s) => s['name'] as String).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSexId = value);
                                _notifyParent();
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Focus(
                            focusNode: _dateOfBirthFocusNode,
                            child: CompositedTransformTarget(
                              link: _dateOfBirthLayerLink,
                              child: CustomInputField(
                                label: 'Date of Birth *',
                                value: _dateOfBirthController.text,
                                icon: Icons.calendar_today_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_DateInputFormatter()],
                                onChanged: (v) => _dateOfBirthController.text = v,
                                onIconTap: () => _showDatePicker(
                                    _dateOfBirthLayerLink, _DatePickerType.dateOfBirth),
                              ),
                            ),
                          ),
                          if (_dateOfBirthFocusNode.hasFocus ||
                              ageMismatch != null ||
                              _dateOfBirthInvalid ||
                              (_dateOfBirthTouched && _dateOfBirth == null)) ...[
                            const SizedBox(height: 4),
                            Text(
                              ageMismatch ??
                                  (_dateOfBirthTouched && _dateOfBirth == null
                                      ? 'Required field'
                                      : _dateOfBirthHint),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: (ageMismatch != null ||
                                            _dateOfBirthInvalid ||
                                            (_dateOfBirthTouched && _dateOfBirth == null))
                                        ? colors.error
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Citizenship
                _referencesLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomSelectField(
                        label: 'Citizenship',
                        icon: Icons.flag_outlined,
                        value: _selectedCitizenshipId?.toString() ?? '',
                        items: _citizenships.map((c) => c['citizenshipId'].toString()).toList(),
                        itemLabels: _citizenships.map((c) => c['citizenshipName'] as String).toList(),
                        searchable: true,
                        errorText: (_citizenshipTouched && _selectedCitizenshipId == null)
                            ? 'Required field'
                            : null,
                        onChanged: (value) {
                          setState(() => _selectedCitizenshipId = int.tryParse(value ?? ''));
                          _notifyParent();
                        },
                      ),
                const SizedBox(height: 16),

                // Document Type / Document Number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _referencesLoading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomSelectField(
                              label: 'Document Type *',
                              icon: Icons.badge_outlined,
                              value: _selectedDocumentTypeId?.toString() ?? '',
                              items: _documentTypes.map((d) => d['documentTypeId'].toString()).toList(),
                              itemLabels: _documentTypes.map((d) => d['documentTypeName'] as String).toList(),
                              errorText: (_documentTypeTouched && _selectedDocumentTypeId == null)
                                  ? 'Required field'
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDocumentTypeId = int.tryParse(value ?? '');
                                  _documentNumberController.clear();
                                  _documentNumberInvalid = false;
                                });
                                _notifyParent();
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Focus(
                            focusNode: _documentNumberFocusNode,
                            child: CustomInputField(
                              label: 'Document Number *',
                              value: _documentNumberController.text,
                              icon: Icons.contact_page_outlined,
                              inputFormatters: _documentNumberFormatters,
                              onChanged: (v) {
                                _documentNumberController.text = v;
                                setState(() {
                                  _documentNumberExistsError = false;
                                  if (v.isEmpty) {
                                    _documentNumberInvalid = false;
                                  } else {
                                    _documentNumberInvalid = !_isDocumentNumberPartiallyValid(v);
                                  }
                                });
                              },
                            ),
                          ),
                          if (_documentNumberFocusNode.hasFocus ||
                              _documentNumberInvalid ||
                              _documentNumberExistsError ||
                              (_documentNumberTouched && _documentNumberController.text.isEmpty)) ...[
                            const SizedBox(height: 4),
                            Text(
                              _documentNumberExistsError
                                  ? 'Document number already exists'
                                  : (_documentNumberTouched && _documentNumberController.text.isEmpty)
                                      ? 'Required field'
                                      : (_documentNumberFocusHint ?? ''),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: (_documentNumberInvalid ||
                                            _documentNumberExistsError ||
                                            (_documentNumberTouched &&
                                                _documentNumberController.text.isEmpty))
                                        ? colors.error
                                        : colors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Document Issue / Document Expire
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CompositedTransformTarget(
                            link: _documentIssueLayerLink,
                            child: CustomInputField(
                              label: 'Document Issue *',
                              value: _documentIssueController.text,
                              icon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_DateInputFormatter()],
                              focusHint: _documentIssueFocusHint,
                              onChanged: (v) => _documentIssueController.text = v,
                              onIconTap: () => _showDatePicker(
                                  _documentIssueLayerLink, _DatePickerType.documentIssue),
                            ),
                          ),
                          if (_documentIssueTouched && _documentIssue == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Required field',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.error,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CompositedTransformTarget(
                            link: _documentExpireLayerLink,
                            child: CustomInputField(
                              label: 'Document Expire *',
                              value: _documentExpireController.text,
                              icon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_DateInputFormatter()],
                              focusHint: _documentExpireFocusHint,
                              onChanged: (v) => _documentExpireController.text = v,
                              onIconTap: () => _showDatePicker(
                                  _documentExpireLayerLink, _DatePickerType.documentExpire),
                            ),
                          ),
                          if (_documentExpireTouched && _documentExpire == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Required field',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.error,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          label: _isSaved ? 'Update' : 'Save',
                          onPressed: _handleSave,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
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

    if (newRaw.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(newRaw)) return oldValue;
    if (newRaw.length > 8) return oldValue;

    if (newRaw.length >= 1 && int.parse(newRaw[0]) > 3) return oldValue;
    if (newRaw.length >= 2) {
      final day = int.parse(newRaw.substring(0, 2));
      if (day > 31 || day == 0) return oldValue;
    }
    if (newRaw.length >= 3 && int.parse(newRaw[2]) > 1) return oldValue;
    if (newRaw.length >= 4) {
      final month = int.parse(newRaw.substring(2, 4));
      if (month > 12 || month == 0) return oldValue;
    }
    if (newRaw.length >= 5 &&
        int.parse(newRaw[4]) != 1 &&
        int.parse(newRaw[4]) != 2) return oldValue;

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
