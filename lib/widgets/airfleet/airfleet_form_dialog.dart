import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/airfleet_crud_api_service.dart';

class AirfleetFormDialog extends StatefulWidget {
  final AirfleetCrudApiService api;
  final Map<String, dynamic>? airfleet;
  final List<Map<String, dynamic>> manufacturers;

  const AirfleetFormDialog({
    super.key,
    required this.api,
    this.airfleet,
    required this.manufacturers,
  });

  @override
  State<AirfleetFormDialog> createState() => _AirfleetFormDialogState();
}

class _AirfleetFormDialogState extends State<AirfleetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _model;
  late final TextEditingController _seats;
  late final TextEditingController _speed;
  late final TextEditingController _range;
  late final TextEditingController _baggage;
  late final TextEditingController _fuel;

  int? _manufacturerId;
  bool _saving = false;

  // Фото
  final List<_PhotoEntry> _photos = [];
  bool _uploadingPhoto = false;

  bool get _isEdit => widget.airfleet != null;

  @override
  void initState() {
    super.initState();
    final a = widget.airfleet;
    _model   = TextEditingController(text: a?['aircraftModel'] ?? '');
    _seats   = TextEditingController(text: a?['seatCapacity']?.toString() ?? '');
    _speed   = TextEditingController(text: a?['aircraftSpeed']?.toString() ?? '');
    _range   = TextEditingController(text: a?['aircraftRangeKm']?.toString() ?? '');
    _baggage = TextEditingController(text: a?['baggageCapacity']?.toString() ?? '');
    _fuel    = TextEditingController(text: a?['aircraftFuelConsumption']?.toString() ?? '');
    _manufacturerId = a?['manufacturerId'] as int? ?? a?['airfleetManufacturerId'] as int?;
  }

  @override
  void dispose() {
    _model.dispose(); _seats.dispose(); _speed.dispose();
    _range.dispose(); _baggage.dispose(); _fuel.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (!_isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the aircraft first, then upload photos')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploadingPhoto = true);
    final airfleetId = widget.airfleet!['airfleetId'] as int;

    for (final file in result.files) {
      if (file.bytes == null) continue;
      final url = await widget.api.uploadAirfleetPhoto(
        airfleetId,
        file.bytes!,
        file.name,
      );
      if (url != null && mounted) {
        setState(() => _photos.add(_PhotoEntry(url: url, name: file.name)));
      }
    }
    if (mounted) setState(() => _uploadingPhoto = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_manufacturerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a manufacturer')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await widget.api.updateAirfleet(
          airfleetId:       widget.airfleet!['airfleetId'] as int,
          manufacturerId:   _manufacturerId!,
          model:            _model.text.trim(),
          rangeKm:          double.parse(_range.text),
          speed:            double.parse(_speed.text),
          seatCapacity:     int.parse(_seats.text),
          baggageCapacity:  double.parse(_baggage.text),
          fuelConsumption:  _fuel.text.isNotEmpty ? double.tryParse(_fuel.text) : null,
        );
      } else {
        await widget.api.createAirfleet(
          manufacturerId:  _manufacturerId!,
          model:           _model.text.trim(),
          rangeKm:         double.parse(_range.text),
          speed:           double.parse(_speed.text),
          seatCapacity:    int.parse(_seats.text),
          baggageCapacity: double.parse(_baggage.text),
          fuelConsumption: _fuel.text.isNotEmpty ? double.tryParse(_fuel.text) : null,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit Aircraft' : 'Add Aircraft',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Basic info'),
                      const SizedBox(height: 8),
                      _field('Model *', _model, required: true),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _manufacturerId,
                        decoration: _dec('Manufacturer *'),
                        items: widget.manufacturers
                            .map((m) => DropdownMenuItem<int>(
                                  value: m['manufacturerId'] as int,
                                  child: Text(m['manufacturerName'] as String),
                                ))
                            .toList(),
                        validator: (v) => v == null ? 'Required' : null,
                        onChanged: (v) => setState(() => _manufacturerId = v),
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel('Specifications'),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _field('Seats *', _seats, isNum: true, required: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Speed (km/h) *', _speed, isNum: true, required: true)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _field('Range (km) *', _range, isNum: true, required: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Baggage (kg) *', _baggage, isNum: true, required: true)),
                      ]),
                      const SizedBox(height: 10),
                      _field('Fuel consumption (L/h)', _fuel, isNum: true),
                      const SizedBox(height: 16),

                      // Photos section
                      _sectionLabel('Photos'),
                      const SizedBox(height: 8),
                      if (!_isEdit)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 15, color: colors.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Save the aircraft first, then you can upload photos',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Existing photos from airfleet
                        if (_photos.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _photos[i].url,
                                      width: 100,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        width: 100,
                                        height: 80,
                                        color: colors.surfaceContainerHigh,
                                        child: Icon(
                                            Icons.broken_image_outlined,
                                            color: colors.onSurfaceVariant),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      child: Container(
                                        width: 20, height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          icon: _uploadingPhoto
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.upload_rounded, size: 16),
                          label: Text(
                            _uploadingPhoto ? 'Uploading...' : 'Upload photos',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Save changes' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.4),
      );

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, bool isNum = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: _dec(label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );
}

class _PhotoEntry {
  final String url;
  final String name;
  _PhotoEntry({required this.url, required this.name});
}