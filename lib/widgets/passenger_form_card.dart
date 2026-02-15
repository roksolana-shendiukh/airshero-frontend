import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/passenger_model.dart';
import 'custom_input_field.dart';
import 'custom_select_field.dart';
import 'custom_button.dart';
import 'custom_single_date_picker.dart';

class PassengerFormCard extends StatefulWidget {
  final int passengerIndex;
  final String passengerType; 
  final List<PassengerModel> savedPassengers;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSave;

  const PassengerFormCard({
    super.key,
    required this.passengerIndex,
    required this.passengerType,
    required this.savedPassengers,
    required this.onDataChanged,
    this.initialData,
    this.onSave,
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
  late TextEditingController _documentExpireController;
  
  String _selectedSex = 'Male';
  DateTime? _dateOfBirth;
  String _selectedCitizenship = 'Ukraine';
  String _selectedDocumentType = 'Passport';
  DateTime? _documentExpire;
  
  bool _showSavedPassengers = false;
  PassengerModel? _selectedSavedPassenger;
  
  final LayerLink _dateOfBirthLayerLink = LayerLink();
  final LayerLink _documentExpireLayerLink = LayerLink();
  OverlayEntry? _datePickerOverlay;

  @override
  void initState() {
    super.initState();
    
    _firstNameController = TextEditingController(text: widget.initialData?['firstName'] ?? '');
    _lastNameController = TextEditingController(text: widget.initialData?['lastName'] ?? '');
    _documentNumberController = TextEditingController(text: widget.initialData?['documentNumber'] ?? '');
    
    if (widget.initialData != null) {
      _selectedSex = widget.initialData!['sex'] ?? 'Male';
      _dateOfBirth = widget.initialData!['dateOfBirth'];
      _selectedCitizenship = widget.initialData!['citizenship'] ?? 'Ukraine';
      _selectedDocumentType = widget.initialData!['documentType'] ?? 'Passport';
      _documentExpire = widget.initialData!['documentExpire'];
    }
    
    _dateOfBirthController = TextEditingController(
      text: _dateOfBirth != null ? DateFormat('dd.MM.yyyy').format(_dateOfBirth!) : ''
    );
    _documentExpireController = TextEditingController(
      text: _documentExpire != null ? DateFormat('dd.MM.yyyy').format(_documentExpire!) : ''
    );
    
    _firstNameController.addListener(_notifyParent);
    _lastNameController.addListener(_notifyParent);
    _documentNumberController.addListener(_notifyParent);
    _dateOfBirthController.addListener(_handleDateOfBirthInput);
    _documentExpireController.addListener(_handleDocumentExpireInput);
  }

  @override
  void didUpdateWidget(PassengerFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.passengerIndex != widget.passengerIndex || 
        oldWidget.initialData != widget.initialData) {
      _firstNameController.text = widget.initialData?['firstName'] ?? '';
      _lastNameController.text = widget.initialData?['lastName'] ?? '';
      _documentNumberController.text = widget.initialData?['documentNumber'] ?? '';
      
      setState(() {
        _selectedSex = widget.initialData?['sex'] ?? 'Male';
        _dateOfBirth = widget.initialData?['dateOfBirth'];
        _selectedCitizenship = widget.initialData?['citizenship'] ?? 'Ukraine';
        _selectedDocumentType = widget.initialData?['documentType'] ?? 'Passport';
        _documentExpire = widget.initialData?['documentExpire'];
        _showSavedPassengers = false;
        _selectedSavedPassenger = null;
        
        _dateOfBirthController.text = _dateOfBirth != null 
            ? DateFormat('dd.MM.yyyy').format(_dateOfBirth!) 
            : '';
        _documentExpireController.text = _documentExpire != null 
            ? DateFormat('dd.MM.yyyy').format(_documentExpire!) 
            : '';
      });
      _removeDatePicker();
    }
  }

  void _handleDateOfBirthInput() {
    final text = _dateOfBirthController.text;
    if (text.length == 10) {
      try {
        final parts = text.split('.');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1920 || year > DateTime.now().year) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid date format. Use DD.MM.YYYY'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        final date = DateTime(year, month, day);
        
        if (date.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Date of birth cannot be in the future'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        setState(() {
          _dateOfBirth = date;
        });
        _notifyParent();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid date. Please check your input'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleDocumentExpireInput() {
    final text = _documentExpireController.text;
    if (text.length == 10) {
      try {
        final parts = text.split('.');
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        if (day < 1 || day > 31 || month < 1 || month > 12 || year < DateTime.now().year || year > 2050) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid date format. Use DD.MM.YYYY'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        final date = DateTime(year, month, day);
        
        if (date.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document expiry date cannot be in the past'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        setState(() {
          _documentExpire = date;
        });
        _notifyParent();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid date. Please check your input'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _notifyParent() {
    widget.onDataChanged({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'sex': _selectedSex,
      'dateOfBirth': _dateOfBirth,
      'citizenship': _selectedCitizenship,
      'documentType': _selectedDocumentType,
      'documentNumber': _documentNumberController.text,
      'documentExpire': _documentExpire,
    });
  }

  bool _validateForm() {
    return _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _dateOfBirth != null &&
           _documentNumberController.text.isNotEmpty &&
           _documentExpire != null;
  }

  void _handleSave() {
    if (_validateForm()) {
      widget.onSave?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passenger data saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _fillFromSavedPassenger(PassengerModel passenger) {
    setState(() {
      _selectedSavedPassenger = passenger;
      _firstNameController.text = passenger.firstName;
      _lastNameController.text = passenger.lastName;
      _selectedSex = passenger.sex;
      _dateOfBirth = passenger.dateOfBirth;
      _selectedCitizenship = passenger.citizenship;
      _selectedDocumentType = passenger.documentType;
      _documentNumberController.text = passenger.documentNumber;
      _documentExpire = passenger.documentExpire;
      _showSavedPassengers = false;
      
      _dateOfBirthController.text = DateFormat('dd.MM.yyyy').format(passenger.dateOfBirth);
      _documentExpireController.text = DateFormat('dd.MM.yyyy').format(passenger.documentExpire);
    });
    _notifyParent();
  }

  void _removeDatePicker() {
    _datePickerOverlay?.remove();
    _datePickerOverlay = null;
  }

  void _showDatePicker(LayerLink layerLink, bool isDateOfBirth) {
    _removeDatePicker();

    _datePickerOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeDatePicker,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
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
                      selectedDate: isDateOfBirth ? _dateOfBirth : _documentExpire,
                      firstDate: isDateOfBirth ? DateTime(1920) : DateTime.now(),
                      lastDate: isDateOfBirth ? DateTime.now() : DateTime(2050),
                      onDateSelected: (date) {
                        setState(() {
                          if (isDateOfBirth) {
                            _dateOfBirth = date;
                            _dateOfBirthController.text = DateFormat('dd.MM.yyyy').format(date);
                          } else {
                            _documentExpire = date;
                            _documentExpireController.text = DateFormat('dd.MM.yyyy').format(date);
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
    _documentExpireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.passengerType} ${widget.passengerIndex + 1}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.savedPassengers.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showSavedPassengers = !_showSavedPassengers;
                      });
                    },
                    icon: Icon(
                      _showSavedPassengers ? Icons.close : Icons.person_search,
                      size: 20,
                    ),
                    label: Text(
                      _showSavedPassengers ? 'Hide' : 'Use saved passenger',
                    ),
                  ),
              ],
            ),

            // SAVED PASSENGERS LIST
            if (_showSavedPassengers && widget.savedPassengers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select from previous passengers:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.savedPassengers.map((passenger) {
                      return InkWell(
                        onTap: () => _fillFromSavedPassenger(passenger),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: _selectedSavedPassenger?.id == passenger.id
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  passenger.fullName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // FIRST NAME & LAST NAME
            Row(
              children: [
                Expanded(
                  child: CustomInputField(
                    label: 'First Name *',
                    value: _firstNameController.text,
                    icon: Icons.person,
                    onChanged: (value) {
                      _firstNameController.text = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    label: 'Last Name *',
                    value: _lastNameController.text,
                    icon: Icons.person,
                    onChanged: (value) {
                      _lastNameController.text = value;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // SEX & DATE OF BIRTH
            Row(
              children: [
                Expanded(
                  child: CustomSelectField(
                    label: 'Sex *',
                    icon: Icons.wc,
                    value: _selectedSex,
                    items: ['Male', 'Female', 'Other'],
                    onChanged: (value) {
                      setState(() {
                        _selectedSex = value!;
                      });
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
                      icon: Icons.event,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _DateInputFormatter(),
                      ],
                      onChanged: (value) {
                        _dateOfBirthController.text = value;
                      },
                      onIconTap: () => _showDatePicker(_dateOfBirthLayerLink, true),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CITIZENSHIP
            CustomSelectField(
              label: 'Citizenship',
              icon: Icons.flag,
              value: _selectedCitizenship,
              items: ['Ukraine', 'Poland', 'Germany', 'USA', 'UK', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedCitizenship = value!;
                });
                _notifyParent();
              },
            ),

            const SizedBox(height: 16),

            // DOCUMENT TYPE & NUMBER
            Row(
              children: [
                Expanded(
                  child: CustomSelectField(
                    label: 'Document Type *',
                    icon: Icons.badge,
                    value: _selectedDocumentType,
                    items: ['Passport', 'ID Card', 'Driver License'],
                    onChanged: (value) {
                      setState(() {
                        _selectedDocumentType = value!;
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
                    icon: Icons.numbers,
                    onChanged: (value) {
                      _documentNumberController.text = value;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // DOCUMENT EXPIRE
            CompositedTransformTarget(
              link: _documentExpireLayerLink,
              child: CustomInputField(
                label: 'Document Expire *',
                value: _documentExpireController.text,
                icon: Icons.event,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  _DateInputFormatter(),
                ],
                onChanged: (value) {
                  _documentExpireController.text = value;
                },
                onIconTap: () => _showDatePicker(_documentExpireLayerLink, false),
              ),
            ),

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Save',
                onPressed: _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Форматтер для автоматичного додавання крапок та валідації
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', '');
    
    if (text.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(text)) {
      return oldValue;
    }
    
    if (text.length > 8) {
      return oldValue;
    }
    
    String formatted = '';
    
    for (int i = 0; i < text.length; i++) {
      if (i == 0 && int.parse(text[i]) > 3) {
        return oldValue;
      }
      if (i == 1 && text.length > 1) {
        final day = int.parse(text.substring(0, 2));
        if (day > 31 || day == 0) {
          return oldValue;
        }
      }
      
      if (i == 2 && int.parse(text[i]) > 1) {
        return oldValue;
      }
      if (i == 3 && text.length > 3) {
        final month = int.parse(text.substring(2, 4));
        if (month > 12 || month == 0) {
          return oldValue;
        }
      }
      
      if (i == 4 && int.parse(text[i]) != 1 && int.parse(text[i]) != 2) {
        return oldValue;
      }
      
      formatted += text[i];
      
      if (i == 1 || i == 3) {
        formatted += '.';
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}