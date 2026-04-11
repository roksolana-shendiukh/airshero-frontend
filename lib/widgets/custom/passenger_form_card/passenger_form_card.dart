import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../../models/passenger_model.dart';
import '../../../services/reference_api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/passenger_api_service.dart';
import '../custom_input_field.dart';
import '../custom_select_field.dart';
import '../custom_button.dart';
import '../custom_single_date_picker.dart';
import '../../passenger_search_bar.dart';
import '../../passenger_name_search_bar.dart';
import 'date_input_formatter.dart';

part 'passenger_form_validators.dart';
part 'passenger_form_handlers.dart';
part 'passenger_form_date_picker.dart';
part 'passenger_form_build.dart';

const Map<String, String> _docHints = {
  'PAS': 'Format: AB1234567 (2 letters + 7 digits)',
  'INT': 'Format: AB1234567 (2 letters + 7 digits)',
  'OFF': 'Format: A1234567 (1 letter + 7 digits)',
  'ID':  'Format: 123456789 (9 digits)',
};

enum _DatePickerType { dateOfBirth, documentIssue, documentExpire }
enum _AgeCategory { adult, child, infant, unknown }

class PassengerFormCard extends StatefulWidget {
  final int passengerIndex;
  final String passengerType;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic>? initialData;
  final AuthService authService;
  final String sessionId;
  final Set<String> usedDocumentNumbers;
  final String searchDocumentNumber;
  final ValueChanged<String> onSearchDocumentChanged;
  final DateTime departDate;

  const PassengerFormCard({
    super.key,
    required this.passengerIndex,
    required this.passengerType,
    required this.onDataChanged,
    required this.authService,
    required this.sessionId,
    this.initialData,
    this.usedDocumentNumbers = const {},
    required this.searchDocumentNumber,
    required this.onSearchDocumentChanged,
    required this.departDate,
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
  late TextEditingController _emailController;
  bool _emailInvalid = false;
  bool _emailTouched = false;

  bool _dateOfBirthInvalid        = false;
  bool _documentNumberInvalid     = false;
  bool _firstNameInvalid          = false;
  bool _lastNameInvalid           = false;
  bool _firstNameTouched          = false;
  bool _lastNameTouched           = false;
  bool _firstNameEdited           = false;
  bool _lastNameEdited            = false;
  bool _documentNumberExistsError = false;
  bool _dateOfBirthTouched        = false;
  bool _documentIssueTouched      = false;
  bool _documentExpireTouched     = false;
  bool _citizenshipTouched        = false;
  bool _documentTypeTouched       = false;
  bool _documentNumberTouched     = false;
  bool _sexTouched                = false;
  bool _documentIssueInvalid      = false;
  bool _isPassengerSaved = false;

  bool _documentSearched       = false;
  bool _passengerSearchVisible = false;
  bool _editingDocument        = false;
  bool _changingDocumentOnly   = false;

  String?   _editOriginalDocumentNumber;
  DateTime? _editOriginalDocumentIssue;
  DateTime? _editOriginalDocumentExpire;
  int?      _editOriginalCitizenshipId;
  int?      _editOriginalDocumentTypeId;

  String?   _selectedSexId;
  DateTime? _dateOfBirth;
  DateTime? _documentIssue;
  DateTime? _documentExpire;

  List<Map<String, dynamic>> _sexes         = [];
  List<Map<String, dynamic>> _citizenships  = [];
  List<Map<String, dynamic>> _documentTypes = [];
  int?  _selectedCitizenshipId;
  int?  _selectedDocumentTypeId;
  bool  _referencesLoading = true;

  bool _isSaved   = false;
  bool _isSaving  = false;

  int?    _foundPassengerId;
  String? _originalDocumentNumber;
  String? _originalDocumentExpire;
  bool    _documentChanged      = false;
  bool    _isAddingNewDocument  = false;
  int?    _originalCitizenshipId;
  int?    _originalDocumentTypeId;
  PassengerModel? _existingPassengerFound;

  final LayerLink _dateOfBirthLayerLink    = LayerLink();
  final LayerLink _documentIssueLayerLink  = LayerLink();
  final LayerLink _documentExpireLayerLink = LayerLink();
  final FocusNode _dateOfBirthFocusNode    = FocusNode();
  final FocusNode _documentNumberFocusNode = FocusNode();
  final FocusNode _firstNameFocusNode      = FocusNode();
  final FocusNode _lastNameFocusNode       = FocusNode();
  final FocusNode _documentIssueFocusNode  = FocusNode();
  final FocusNode _documentExpireFocusNode = FocusNode();

  OverlayEntry? _datePickerOverlay;
  OverlayEntry? _datePickerBarrier;
  Timer? _datePickerDebounce;

  bool get _hasChanges =>
    _firstNameController.text != (widget.initialData?['firstName'] ?? '') ||
    _lastNameController.text  != (widget.initialData?['lastName'] ?? '')  ||
    _dateOfBirth              != widget.initialData?['dateOfBirth']        ||
    _selectedSexId            != widget.initialData?['sexId']?.toString()  ||
    _selectedCitizenshipId    != widget.initialData?['citizenshipId']      ||
    _selectedDocumentTypeId   != widget.initialData?['documentTypeId']     ||
    _documentNumberController.text != (widget.initialData?['documentNumber'] ?? '') ||
    _documentIssue            != widget.initialData?['documentIssue']      ||
    _documentExpire           != widget.initialData?['documentExpire'] ||
    _emailController.text     != (widget.initialData?['email'] ?? '');  
    

  bool get _documentFieldsLocked =>
      (_documentSearched || _foundPassengerId != null) && !_isAddingNewDocument;

  bool get _passengerBlockHidden =>
      _isAddingNewDocument && !_passengerSearchVisible && !_editingDocument && !_changingDocumentOnly;

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
      _documentSearched       = widget.initialData!['documentSearched'] ?? false;
      _isAddingNewDocument    = widget.initialData!['isAddingNewDocument'] ?? false;
      _passengerSearchVisible = widget.initialData!['passengerSearchVisible'] ?? false;
      _editingDocument        = widget.initialData!['editingDocument'] ?? false;
      _changingDocumentOnly   = widget.initialData!['changingDocumentOnly'] ?? false;
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

    _firstNameController      = TextEditingController(text: widget.initialData?['firstName'] ?? '');
    _lastNameController       = TextEditingController(text: widget.initialData?['lastName'] ?? '');
    _documentNumberController = TextEditingController(text: widget.initialData?['documentNumber'] ?? '');
    _emailController          = TextEditingController(text: widget.initialData?['email'] ?? ''); 
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
        _documentSearched       = widget.initialData?['documentSearched'] ?? false;
        _documentChanged        = false;
        _isAddingNewDocument    = widget.initialData?['isAddingNewDocument'] ?? false;
        _passengerSearchVisible = widget.initialData?['passengerSearchVisible'] ?? false;
        _editingDocument        = widget.initialData?['editingDocument'] ?? false;
        _changingDocumentOnly   = widget.initialData?['changingDocumentOnly'] ?? false;
        _emailController.text = widget.initialData?['email'] ?? '';
        _emailInvalid = false;
        _emailTouched = false;

        _dateOfBirthTouched     = false;
        _documentIssueTouched   = false;
        _documentExpireTouched  = false;
        _citizenshipTouched     = false;
        _documentTypeTouched    = false;
        _documentNumberTouched  = false;
        _documentIssueInvalid   = false;
        _documentNumberInvalid     = false;
        _documentNumberExistsError = false;

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

      if (oldWidget.passengerIndex != widget.passengerIndex) {
        _removeDatePicker();
      }
    }
  }

  @override
  Widget build(BuildContext context) => _buildForm(context);

  @override
  void dispose() {
    _datePickerDebounce?.cancel();
    _removeDatePicker();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _documentNumberController.dispose();
    _documentIssueController.dispose();
    _documentExpireController.dispose();
    _emailController.dispose();

    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _dateOfBirthFocusNode.dispose();
    _documentNumberFocusNode.dispose();
    _documentIssueFocusNode.dispose();
    _documentExpireFocusNode.dispose();

    super.dispose();
  }
}