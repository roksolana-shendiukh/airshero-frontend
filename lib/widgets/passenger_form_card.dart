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

const Map<String, String> _docHints = {
  'PAS': 'Format: AB1234567 (2 letters + 7 digits)',
  'INT': 'Format: AB1234567 (2 letters + 7 digits)',
  'OFF': 'Format: A1234567 (1 letter + 7 digits)',
  'ID':  'Format: 123456789 (9 digits)',
};

enum _DatePickerType { dateOfBirth, documentIssue, documentExpire }

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

  String _selectedSex = 'Male';
  DateTime? _dateOfBirth;
  DateTime? _documentIssue;
  DateTime? _documentExpire;

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
  OverlayEntry? _datePickerOverlay;

  String? get _selectedDocTypeCode {
    if (_selectedDocumentTypeId == null) return null;
    final found = _documentTypes.firstWhere(
      (d) => d['documentTypeId'] == _selectedDocumentTypeId,
      orElse: () => {},
    );
    return found['documentTypeCode'] as String?;
  }

  String? get _documentNumberFocusHint {
    final code = _selectedDocTypeCode;
    return code != null ? _docHints[code] : 'Select document type first';
  }

  String get _documentIssueFocusHint {
    if (_dateOfBirth != null) {
      return 'From ${_dateOfBirth!.year + 1} to today';
    }
    return 'Must not be in the future';
  }

  String get _documentExpireFocusHint {
    if (_documentIssue != null) {
      return 'Must be after ${DateFormat('dd.MM.yyyy').format(_documentIssue!)}';
    }
    return 'Must be after issue date';
  }

  @override
  void initState() {
    super.initState();

    _firstNameController      = TextEditingController(text: widget.initialData?['firstName'] ?? '');
    _lastNameController       = TextEditingController(text: widget.initialData?['lastName'] ?? '');
    _documentNumberController = TextEditingController(text: widget.initialData?['documentNumber'] ?? '');

    if (widget.initialData != null) {
      _selectedSex            = widget.initialData!['sex'] ?? 'Male';
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

    _loadReferences();
  }

  Future<void> _loadReferences() async {
    final ref = ReferenceApiService(widget.authService);
    final citizenships  = await ref.getCitizenships();
    final documentTypes = await ref.getDocumentTypes();

    if (!mounted) return;
    setState(() {
      _citizenships      = citizenships;
      _documentTypes     = documentTypes;
      _referencesLoading = false;

      if (_selectedCitizenshipId == null && _citizenships.isNotEmpty) {
        _selectedCitizenshipId = _citizenships.first['citizenshipId'] as int;
      }
      if (_selectedDocumentTypeId == null && _documentTypes.isNotEmpty) {
        _selectedDocumentTypeId = _documentTypes.first['documentTypeId'] as int;
      }
    });
    // _notifyParent() тут не потрібен — дефолтні значення не змінюють
    // дані пасажира, які батько вже зберіг.
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
        _selectedSex            = widget.initialData?['sex'] ?? 'Male';
        _dateOfBirth            = widget.initialData?['dateOfBirth'];
        _documentIssue          = widget.initialData?['documentIssue'];
        _documentExpire         = widget.initialData?['documentExpire'];
        _selectedCitizenshipId  = widget.initialData?['citizenshipId'];
        _selectedDocumentTypeId = widget.initialData?['documentTypeId'];
        _isSaved                = widget.initialData?['isSaved'] ?? false;
        _foundPassengerId       = widget.initialData?['foundPassengerId'];
        _documentChanged        = false;

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
      // _notifyParent() тут НЕ викликаємо — батько вже має ці дані,
      // зворотній виклик спричиняє нескінченний цикл rebuild.
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
            ? DateFormat('dd.MM.yyyy').format(_dateOfBirth!)
            : '';
      } else {
        _dateOfBirth = null;
        _dateOfBirthController.text = '';
      }

      final sex = passenger.sex;
      if (sex != null) {
        _selectedSex = sex == false ? 'Female' : 'Male';
      }

      if (doc != null) {
        _documentNumberController.text = doc.documentNumber ?? '';
        _originalDocumentNumber        = doc.documentNumber;
        _originalDocumentExpire        = doc.documentDateOfExpire?.toString();

        if (doc.documentDateOfIssue != null) {
          _documentIssue = doc.documentDateOfIssue is DateTime
              ? doc.documentDateOfIssue as DateTime
              : DateTime.tryParse(doc.documentDateOfIssue.toString());
          _documentIssueController.text = _documentIssue != null
              ? DateFormat('dd.MM.yyyy').format(_documentIssue!)
              : '';
        } else {
          _documentIssue = null;
          _documentIssueController.text = '';
        }

        if (doc.documentDateOfExpire != null) {
          _documentExpire = doc.documentDateOfExpire is DateTime
              ? doc.documentDateOfExpire as DateTime
              : DateTime.tryParse(doc.documentDateOfExpire.toString());
          _documentExpireController.text = _documentExpire != null
              ? DateFormat('dd.MM.yyyy').format(_documentExpire!)
              : '';
        } else {
          _documentExpire = null;
          _documentExpireController.text = '';
        }

        final citizenship = _citizenships.firstWhere(
          (c) => c['citizenshipId'] == doc.citizenshipId,
          orElse: () => _citizenships.isNotEmpty ? _citizenships.first : {},
        );
        _selectedCitizenshipId = citizenship.isNotEmpty
            ? citizenship['citizenshipId'] as int
            : _selectedCitizenshipId;

        final docType = _documentTypes.firstWhere(
          (d) => d['documentTypeId'] == doc.documentTypeId,
          orElse: () => _documentTypes.isNotEmpty ? _documentTypes.first : {},
        );
        _selectedDocumentTypeId = docType.isNotEmpty
            ? docType['documentTypeId'] as int
            : _selectedDocumentTypeId;
      } else {
        _documentNumberController.text = '';
        _documentIssue = null;
        _documentIssueController.text = '';
        _documentExpire = null;
        _documentExpireController.text = '';
        _originalDocumentNumber = null;
        _originalDocumentExpire = null;
      }

      _foundPassengerId = passenger.id != null ? int.tryParse(passenger.id!) : null;
      _documentChanged  = false;
      _isSaved          = false;
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

  void _handleDateOfBirthInput() {
    final text = _dateOfBirthController.text;
    if (text.length != 10) return;
    try {
      final parts = text.split('.');
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      if (date.isAfter(DateTime.now())) return;
      setState(() => _dateOfBirth = date);
      _notifyParent();
    } catch (_) {}
  }

  void _handleDocumentIssueInput() {
    final text = _documentIssueController.text;
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

  void _onDocumentNumberChanged() {
    if (_isSaved) setState(() => _isSaved = false);
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
      'sex':              _selectedSex,
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

    // Якщо зараз іде build — відкладаємо до наступного кадру,
    // інакше викликаємо одразу щоб уникнути зайвих перебудов.
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
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _dateOfBirth != null &&
        _documentNumberController.text.isNotEmpty &&
        _documentIssue != null &&
        _documentExpire != null &&
        _selectedCitizenshipId != null &&
        _selectedDocumentTypeId != null;
  }

  Future<void> _handleSave() async {
    if (!_validateForm()) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'firstName':        _firstNameController.text,
        'lastName':         _lastNameController.text,
        'sex':              _selectedSex,
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

    _datePickerOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeDatePicker,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
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
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_datePickerOverlay!);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                    if (_isSaved)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Saved',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: CustomInputField(
                        label: 'First Name *',
                        value: _firstNameController.text,
                        icon: Icons.person_outline,
                        focusHint: 'Latin letters only, max 30 characters',
                        onChanged: (v) => _firstNameController.text = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomInputField(
                        label: 'Last Name *',
                        value: _lastNameController.text,
                        icon: Icons.person_outline,
                        focusHint: 'Latin letters only, max 30 characters',
                        onChanged: (v) => _lastNameController.text = v,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomSelectField(
                        label: 'Sex *',
                        icon: Icons.wc,
                        value: _selectedSex,
                        items: const ['Male', 'Female', 'Other'],
                        onChanged: (value) {
                          setState(() => _selectedSex = value!);
                          _notifyParent();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CompositedTransformTarget(
                        link: _dateOfBirthLayerLink,
                        child: CustomInputField(
                          label: 'Date of Birth *',
                          value: _dateOfBirthController.text,
                          icon: Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_DateInputFormatter()],
                          focusHint: 'dd.mm.yyyy — must not be in the future',
                          onChanged: (v) => _dateOfBirthController.text = v,
                          onIconTap: () => _showDatePicker(
                              _dateOfBirthLayerLink, _DatePickerType.dateOfBirth),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (_referencesLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  CustomSelectField(
                    label: 'Citizenship',
                    icon: Icons.flag_outlined,
                    value: _selectedCitizenshipId?.toString() ?? '',
                    items: _citizenships.map((c) => c['citizenshipId'].toString()).toList(),
                    itemLabels: _citizenships.map((c) => c['citizenshipName'] as String).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCitizenshipId = int.tryParse(value ?? ''));
                      _notifyParent();
                    },
                  ),

                const SizedBox(height: 16),

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
                              items: _documentTypes
                                  .map((d) => d['documentTypeId'].toString())
                                  .toList(),
                              itemLabels: _documentTypes
                                  .map((d) => d['documentTypeName'] as String)
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDocumentTypeId = int.tryParse(value ?? '');
                                  _documentNumberController.clear();
                                });
                                _notifyParent();
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomInputField(
                        label: 'Document Number *',
                        value: _documentNumberController.text,
                        icon: Icons.contact_page_outlined,
                        focusHint: _documentNumberFocusHint,
                        onChanged: (v) => _documentNumberController.text = v,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CompositedTransformTarget(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CompositedTransformTarget(
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
    final text = newValue.text.replaceAll('.', '');

    if (text.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(text)) return oldValue;
    if (text.length > 8) return oldValue;

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 0 && int.parse(text[i]) > 3) return oldValue;
      if (i == 1 && text.length > 1) {
        final day = int.parse(text.substring(0, 2));
        if (day > 31 || day == 0) return oldValue;
      }
      if (i == 2 && int.parse(text[i]) > 1) return oldValue;
      if (i == 3 && text.length > 3) {
        final month = int.parse(text.substring(2, 4));
        if (month > 12 || month == 0) return oldValue;
      }
      if (i == 4 &&
          int.parse(text[i]) != 1 &&
          int.parse(text[i]) != 2) return oldValue;

      formatted += text[i];
      if (i == 1 || i == 3) formatted += '.';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}