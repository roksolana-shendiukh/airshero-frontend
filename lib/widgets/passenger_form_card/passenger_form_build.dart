part of 'passenger_form_card.dart';

extension _PassengerFormBuild on _PassengerFormCardState {
  Widget _buildForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ageMismatch = _ageMismatchMessage;

    if (_isAddingNewDocument && !_changingDocumentOnly) {
      return _buildAddDocumentFlow(context, colors);
    }

    return _buildFullForm(context, colors, ageMismatch);
  }

  Widget _buildAddDocumentFlow(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassengerSearchBar(
          key: ValueKey('search_${widget.passengerIndex}'),
          authService: widget.authService,
          initialDocumentNumber: widget.searchDocumentNumber,
          usedDocumentNumbers: widget.usedDocumentNumbers,
          onPassengerFound: _fillFromPassenger,
          onClear: _clearFoundPassenger,
          onAddDocument: _onAddDocument,
          onSearched: () => setState(() => _documentSearched = true),
          onTextChanged: widget.onSearchDocumentChanged,
          passengerType: widget.passengerType.toLowerCase(),
          departDate: widget.departDate,
        ),
        const SizedBox(height: 12),

        _buildEditDocumentSection(context, colors),

        if (_passengerSearchVisible) ...[
          const SizedBox(height: 12),
          PassengerNameSearchBar(
            key: ValueKey('name_search_${widget.passengerIndex}'),
            authService: widget.authService,
            onPassengerFound: _fillFromPassengerOnly,
            onClear: () {},
            onNotFound: () => setState(() {}),
            passengerType: widget.passengerType.toLowerCase(),
            departDate: widget.departDate,
          ),
          const SizedBox(height: 12),
          _buildPassengerCard(context, colors),
        ],
      ],
    );
  }

  Widget _buildEditDocumentSection(BuildContext context, ColorScheme colors) {
    final hasChanges = _isSaved
        ? (_documentNumberController.text != (_editOriginalDocumentNumber ?? '') ||
            _documentIssue != _editOriginalDocumentIssue ||
            _documentExpire != _editOriginalDocumentExpire ||
            _selectedCitizenshipId != _editOriginalCitizenshipId ||
            _selectedDocumentTypeId != _editOriginalDocumentTypeId)
        : _validateDocumentFields();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSaved ? 'Edit Document' : 'Add Document',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearDocumentFieldsOnly,
                child: const Text('Clear',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDocumentFields(context, colors),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isSaving
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: _isSaved ? 'Update' : 'Save',
                    onPressed: hasChanges && _validateDocumentFields()
                        ? _handleSaveDocumentEdit
                        : null,
                  ),
          ),
        ],
      ),
    );
  }

  bool _validatePassengerOnly() {
    if (_ageMismatchMessage != null) return false;
    if (_firstNameController.text.length < 3) return false;
    if (_lastNameController.text.length < 3) return false;
    if (_dateOfBirth == null) return false;
    if (_selectedSexId == null) return false;
    final isAdult = widget.passengerType.toLowerCase() == 'adult';
    if (isAdult && _emailController.text.isEmpty) return false;
    if (_emailInvalid) return false;
    return true;
  }

  Widget _buildPassengerCard(BuildContext context, ColorScheme colors) {
    final ageMismatch = _ageMismatchMessage;
    final isAdult = widget.passengerType.toLowerCase() == 'adult';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passenger',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (_isPassengerSaved) ...[
                    Icon(Icons.check_circle_outline,
                        size: 18, color: colors.primary),
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
                    onPressed: _clearPassengerFields,
                    child: const Text('Clear',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFirstNameField(context, colors)),
              const SizedBox(width: 12),
              Expanded(child: _buildLastNameField(context, colors)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSexField(colors)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDateOfBirthField(context, colors, ageMismatch)),
            ],
          ),
          const SizedBox(height: 16),
          _buildEmailField(context, colors, isAdult: isAdult),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isSaving
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: _isPassengerSaved ? 'Update' : 'Save',
                    onPressed: _validatePassengerOnly() && !_isPassengerSaved
                        ? _handleSave
                        : null,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullForm(
      BuildContext context, ColorScheme colors, String? ageMismatch) {
    final isAdult = widget.passengerType.toLowerCase() == 'adult';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PassengerSearchBar(
          key: ValueKey('search_${widget.passengerIndex}'),
          authService: widget.authService,
          initialDocumentNumber: widget.searchDocumentNumber,
          usedDocumentNumbers: widget.usedDocumentNumbers,
          onPassengerFound: _fillFromPassenger,
          onClear: _clearFoundPassenger,
          onAddDocument: _onAddDocument,
          onSearched: () => setState(() => _documentSearched = true),
          onTextChanged: widget.onSearchDocumentChanged,
          passengerType: widget.passengerType.toLowerCase(),
          departDate: widget.departDate,
        ),
        const SizedBox(height: 16),

        if (_documentChanged) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: colors.tertiary, size: 18),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (_isSaved) ...[
                          Icon(Icons.check_circle_outline,
                              size: 18, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Saved',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_documentFieldsLocked) ...[
                          TextButton.icon(
                            onPressed: _onChangeDocument,
                            icon: const Icon(Icons.add_card_outlined,
                                size: 16),
                            label: const Text('Change Document',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 4),
                        ],
                        TextButton(
                          onPressed: _clearForm,
                          child: const Text('Clear',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildDocumentFields(context, colors),
                const SizedBox(height: 24),

                if (!_passengerBlockHidden) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFirstNameField(context, colors)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildLastNameField(context, colors)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSexField(colors)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDateOfBirthField(
                              context, colors, ageMismatch)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEmailField(context, colors, isAdult: isAdult),
                  const SizedBox(height: 24),
                ],

                Tooltip(
                  message: !_validateForm()
                      ? (_documentDatesMismatchMessage ??
                          _ageMismatchMessage ??
                          'Please fill in all required fields')
                      : '',
                  child: SizedBox(
                    width: double.infinity,
                    child: _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            label: _isAddingNewDocument && !_passengerSearchVisible
                                ? 'Save Document'
                                : _isSaved ? 'Update' : 'Save',
                            onPressed: _validateForm() && (!_isSaved || _hasChanges)
                                ? _handleSave
                                : null,
                          ),
                  ),
                ),       
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(
    BuildContext context,
    ColorScheme colors, {
    required bool isAdult,
  }) {
    final FocusNode emailFocusNode = FocusNode();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              focusNode: emailFocusNode,
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  setState(() {
                    _emailTouched = true;
                    _emailInvalid = _emailController.text.isNotEmpty &&
                        !_isValidEmail(_emailController.text);
                  });
                }
                setLocalState(() {});
              },
              child: CustomInputField(
                label: isAdult ? 'Email *' : 'Email (optional)',
                value: _emailController.text,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) {
                  _emailController.text = v;
                  setState(() {
                    _emailInvalid = v.isNotEmpty && !_isValidEmail(v);
                  });
                  _notifyParent();
                },
              ),
            ),
            if (emailFocusNode.hasFocus ||
                _emailInvalid ||
                (_emailTouched && isAdult && _emailController.text.isEmpty)) ...[
              const SizedBox(height: 4),
              Text(
                _emailInvalid
                    ? 'Invalid email format'
                    : (_emailTouched && isAdult && _emailController.text.isEmpty)
                        ? 'Required field'
                        : 'Format: example@domain.com',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (_emailInvalid ||
                              (_emailTouched &&
                                  isAdult &&
                                  _emailController.text.isEmpty))
                          ? colors.error
                          : colors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  Widget _buildDocumentFields(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _referencesLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomSelectField(
                label: 'Citizenship',
                icon: Icons.flag_outlined,
                value: _selectedCitizenshipId?.toString() ?? '',
                items: _citizenships
                    .map((c) => c['citizenshipId'].toString())
                    .toList(),
                itemLabels: _citizenships
                    .map((c) => c['citizenshipName'] as String)
                    .toList(),
                searchable: true,
                onSearch: (query) async {
                  final ref = ReferenceApiService(widget.authService);
                  final results = await ref.getCitizenships(query: query);
                  setState(() => _citizenships = results);
                },
                errorText:
                    (_citizenshipTouched && _selectedCitizenshipId == null)
                        ? 'Required field'
                        : null,
                onChanged: _documentFieldsLocked
                    ? (_) {}
                    : (value) {
                        _clearDocumentFields();
                        setState(() => _selectedCitizenshipId =
                            int.tryParse(value ?? ''));
                        _checkDocumentChanged();
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
                      errorText:
                          (_documentTypeTouched &&
                                  _selectedDocumentTypeId == null)
                              ? 'Required field'
                              : null,
                      onChanged: _documentFieldsLocked
                          ? (_) {}
                          : (value) {
                              _clearDocumentFields();
                              setState(() => _selectedDocumentTypeId =
                                  int.tryParse(value ?? ''));
                              _checkDocumentChanged();
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
                      readOnly: _documentFieldsLocked,
                      onChanged: _documentFieldsLocked
                          ? (_) {}
                          : (v) {
                              _documentNumberController.text = v;
                              setState(() {
                                _documentNumberExistsError = false;
                                _documentNumberInvalid = v.isNotEmpty &&
                                    !_isDocumentNumberPartiallyValid(v);
                              });
                            },
                    ),
                  ),
                  if (_documentNumberFocusNode.hasFocus ||
                      _documentNumberInvalid ||
                      _documentNumberExistsError ||
                      (_documentNumberTouched &&
                          _documentNumberController.text.isEmpty)) ...[
                    const SizedBox(height: 4),
                    Text(
                      _documentNumberExistsError
                          ? 'Document number already exists'
                          : (_documentNumberTouched &&
                                  _documentNumberController.text.isEmpty)
                              ? 'Required field'
                              : (_documentNumberFocusHint ?? ''),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (_documentNumberInvalid ||
                                    _documentNumberExistsError ||
                                    (_documentNumberTouched &&
                                        _documentNumberController
                                            .text.isEmpty))
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompositedTransformTarget(
                    link: _documentIssueLayerLink,
                    child: Focus(
                      focusNode: _documentIssueFocusNode,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          setState(() => _documentIssueTouched = true);
                        }
                      },
                      child: CustomInputField(
                        label: 'Document Issue *',
                        value: _documentIssueController.text,
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DateInputFormatter()],
                        readOnly: _documentFieldsLocked,
                        onChanged: _documentFieldsLocked
                            ? (_) {}
                            : (v) {
                                _documentIssueController.text = v;
                                setState(() {});
                              },
                        onIconTap: _documentFieldsLocked
                            ? null
                            : () => _showDatePicker(_documentIssueLayerLink,
                                _DatePickerType.documentIssue),
                      ),
                    ),
                  ),
                  if (_documentIssueFocusNode.hasFocus ||
                      _documentIssueInvalid ||
                      (_documentIssueTouched && _documentIssue == null)) ...[
                    const SizedBox(height: 4),
                    Text(
                      _documentIssueInvalid
                          ? 'Issue date cannot be in the future'
                          : (_documentIssueTouched && _documentIssue == null)
                              ? 'Required field'
                              : (_documentIssueFocusHint ?? 'DD.MM.YYYY'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (_documentIssueInvalid ||
                                    (!_documentIssueFocusNode.hasFocus &&
                                        _documentIssueTouched &&
                                        _documentIssue == null))
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
                  CompositedTransformTarget(
                    link: _documentExpireLayerLink,
                    child: Focus(
                      focusNode: _documentExpireFocusNode,
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          setState(() => _documentExpireTouched = true);
                        }
                      },
                      child: CustomInputField(
                        label: 'Document Expire *',
                        value: _documentExpireController.text,
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DateInputFormatter()],
                        readOnly: _documentFieldsLocked,
                        onChanged: _documentFieldsLocked
                            ? (_) {}
                            : (v) {
                                _documentExpireController.text = v;
                                setState(() {});
                              },
                        onIconTap: _documentFieldsLocked
                            ? null
                            : () => _showDatePicker(_documentExpireLayerLink,
                                _DatePickerType.documentExpire),
                      ),
                    ),
                  ),
                  if (_documentExpireFocusNode.hasFocus ||
                      (_documentDatesMismatchMessage != null &&
                          (_documentExpireTouched ||
                              _documentIssueTouched)) ||
                      (_documentExpireTouched &&
                          _documentExpire == null)) ...[
                    const SizedBox(height: 4),
                    Text(
                      (_documentDatesMismatchMessage != null &&
                              (_documentExpireTouched ||
                                  _documentIssueTouched))
                          ? _documentDatesMismatchMessage!
                          : (_documentExpireTouched && _documentExpire == null)
                              ? 'Required field'
                              : (_documentExpireFocusHint ?? 'DD.MM.YYYY'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ((_documentDatesMismatchMessage != null &&
                                        (_documentExpireTouched ||
                                            _documentIssueTouched)) ||
                                    (!_documentExpireFocusNode.hasFocus &&
                                        _documentExpireTouched &&
                                        _documentExpire == null))
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
      ],
    );
  }

  Widget _buildFirstNameField(BuildContext context, ColorScheme colors) {
    return Column(
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
                _firstNameInvalid =
                    _firstNameEdited && isDeleting && v.isNotEmpty && v.length < 3;
              });
              _notifyParent();
            },
          ),
        ),
        if (_firstNameFocusNode.hasFocus ||
            (_firstNameTouched &&
                !_firstNameFocusNode.hasFocus &&
                (_firstNameController.text.isEmpty ||
                    _firstNameInvalid))) ...[
          const SizedBox(height: 4),
          Text(
            _firstNameHint(_firstNameController.text),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: (_firstNameInvalid ||
                          (!_firstNameFocusNode.hasFocus &&
                              _firstNameTouched &&
                              _firstNameController.text.isEmpty))
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildLastNameField(BuildContext context, ColorScheme colors) {
    return Column(
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
                _lastNameInvalid =
                    _lastNameEdited && isDeleting && v.isNotEmpty && v.length < 3;
              });
            },
          ),
        ),
        if (_lastNameFocusNode.hasFocus ||
            (_lastNameTouched &&
                !_lastNameFocusNode.hasFocus &&
                (_lastNameController.text.isEmpty ||
                    _lastNameInvalid))) ...[
          const SizedBox(height: 4),
          Text(
            _lastNameHint(_lastNameController.text),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: (_lastNameInvalid ||
                          (!_lastNameFocusNode.hasFocus &&
                              _lastNameTouched &&
                              _lastNameController.text.isEmpty))
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildSexField(ColorScheme colors) {
    return _referencesLoading
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
          );
  }

  Widget _buildDateOfBirthField(
      BuildContext context, ColorScheme colors, String? ageMismatch) {
    return Column(
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
              inputFormatters: [DateInputFormatter()],
              readOnly: _foundPassengerId != null && !_isAddingNewDocument,
              onChanged: (v) => _dateOfBirthController.text = v,
              onIconTap: () => _showDatePicker(
                  _dateOfBirthLayerLink, _DatePickerType.dateOfBirth),
            ),
          ),
        ),
        if (_foundPassengerId != null && !_isAddingNewDocument) ...[
          const SizedBox(height: 4),
          Text(
            ageMismatch ??
                'Date of birth cannot be changed for existing passenger',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ageMismatch != null
                      ? colors.error
                      : colors.onSurfaceVariant,
                ),
          ),
        ] else if (_dateOfBirthFocusNode.hasFocus ||
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
    );
  }
}