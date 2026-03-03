part of 'passenger_form_card.dart';

extension PassengerFormBuild on _PassengerFormCardState {
  Widget _buildForm(BuildContext context) {
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
                                inputFormatters: [DateInputFormatter()],
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
                              inputFormatters: [DateInputFormatter()],
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
                              inputFormatters: [DateInputFormatter()],
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