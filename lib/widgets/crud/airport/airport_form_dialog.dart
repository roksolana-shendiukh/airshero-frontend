import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../services/auth_service.dart';
import '../../../services/object_crud_service.dart';
import '../../custom/custom_input_field.dart';
import '../../custom/custom_select_field.dart';
import '../../custom/custom_button.dart';

class AirportFormDialog extends StatefulWidget {
  final Map<String, dynamic>? airport;
  const AirportFormDialog({super.key, this.airport});

  @override
  State<AirportFormDialog> createState() => _AirportFormDialogState();
}

class _AirportFormDialogState extends State<AirportFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _address = '';
  String _code = '';
  String _lat = '';
  String _lng = '';
  int? _selectedCityId;
  String? _selectedCityName;

  List<Map<String, dynamic>> _cities = [];
  bool _isLoadingCities = true;
  bool _isLoadingCoords = false;
  bool _isSaving = false;

  final Map<String, bool> _touched = {
    'city': false,
    'name': false,
    'address': false,
    'code': false,
    'lat': false,
    'lng': false,
  };

  final _englishRegex = RegExp(r'^[a-zA-Z\s\d.,\-\/]+$');
  final _coordsFormatter = FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'));

  @override
  void initState() {
    super.initState();
    if (widget.airport != null) {
      _prefill();
    }
    _loadCities();
  }

  void _prefill() {
    final a = widget.airport!;
    _name = (a['airport_name'] ?? a['airportName'] ?? '').toString();
    _address = (a['airport_address'] ?? a['airportAddress'] ?? '').toString();
    _code = (a['airport_code'] ?? a['airportCode'] ?? '').toString();
    _lat = (a['latitude'] ?? '').toString();
    _lng = (a['longitude'] ?? '').toString();
    _selectedCityId = a['city_id'] ?? a['cityId'];
    _selectedCityName = (a['city_name'] ?? a['cityName'] ?? '').toString();

    _touched.updateAll((k, v) => true);
  }

  String? _getNameError(String v) {
    if (v.trim().isEmpty) return 'Required';
    if (v.length > 60) return 'Max 60 characters';
    if (!_englishRegex.hasMatch(v)) return 'English letters only';
    return null;
  }

  String? _getCodeError(String v) {
    if (v.trim().isEmpty) return 'Required';
    if (v.length != 3) return 'Must be 3 letters';
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v)) return 'Letters only';
    return null;
  }

  String? _getAddressError(String v) {
    if (v.trim().isEmpty) return 'Required';
    if (v.length > 200) return 'Max 200 characters';
    if (!_englishRegex.hasMatch(v)) return 'English letters only';
    return null;
  }

  String? _getCoordError(String v, double min, double max) {
    if (v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null) return 'Invalid number';
    if (n < min || n > max) return 'Out of range';
    return null;
  }

  bool get _isValid {
    return _selectedCityId != null &&
        _getNameError(_name) == null &&
        _getCodeError(_code) == null &&
        _getAddressError(_address) == null &&
        _getCoordError(_lat, -90, 90) == null &&
        _getCoordError(_lng, -180, 180) == null;
  }

  Future<void> _loadCities() async {
    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final cities = await api.getCities();
      if (mounted) setState(() { _cities = cities; _isLoadingCities = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  Future<void> _fetchCoordinates() async {
    if (_name.isEmpty || _getNameError(_name) != null) return;
    setState(() => _isLoadingCoords = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': _name, 'format': 'json', 'limit': 1},
        options: Options(headers: {'User-Agent': 'AirShero/1.0'}),
      );
      final results = response.data as List<dynamic>;
      if (results.isNotEmpty && mounted) {
        final place = results.first as Map<String, dynamic>;
        setState(() {
          _lat = double.parse(place['lat']).toStringAsFixed(6);
          _lng = double.parse(place['lon']).toStringAsFixed(6);
          _touched['lat'] = true;
          _touched['lng'] = true;
        });
      }
    } catch (_) {} 
    finally { if (mounted) setState(() => _isLoadingCoords = false); }
  }

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _isSaving = true);
    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final data = {
        'cityId': _selectedCityId!,
        'airportName': _name.trim(),
        'airportAddress': _address.trim(),
        'airportCode': _code.trim().toUpperCase(),
        'latitude': double.parse(_lat),
        'longitude': double.parse(_lng),
      };
      if (widget.airport != null) {
        final id = widget.airport!['airport_id'] ?? widget.airport!['airportId'];
        await api.updateAirport(id, data);
      } else {
        await api.createAirport(data);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEdit = widget.airport != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Row(
                children: [
                  Icon(isEdit ? Icons.edit_location : Icons.add_location, color: colors.primary),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Edit Airport' : 'Add Airport',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CustomSelectField(
                      label: 'City',
                      icon: Icons.location_city,
                      value: _selectedCityName ?? '',
                      items: _cities.map((c) => (c['cityName'] ?? c['city_name']).toString()).toList(),
                      searchable: true,
                      errorText: (_touched['city']! && _selectedCityId == null) ? 'Required' : null,
                      onChanged: (val) {
                        final city = _cities.firstWhere(
                          (c) => (c['cityName'] ?? c['city_name']) == val, 
                          orElse: () => {}
                        );
                        setState(() {
                          _selectedCityId = city['cityId'] ?? city['city_id'];
                          _selectedCityName = val;
                          _touched['city'] = true;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Airport name',
                      icon: Icons.flight,
                      value: _name,
                      errorText: _touched['name']! ? _getNameError(_name) : null,
                      inputFormatters: [LengthLimitingTextInputFormatter(60)],
                      onChanged: (v) => setState(() { _name = v; _touched['name'] = true; }),
                      onEditingComplete: _fetchCoordinates,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Address',
                      icon: Icons.place,
                      value: _address,
                      errorText: _touched['address']! ? _getAddressError(_address) : null,
                      inputFormatters: [LengthLimitingTextInputFormatter(200)],
                      onChanged: (v) => setState(() { _address = v; _touched['address'] = true; }),
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Airport Code (IATA)',
                      icon: Icons.tag,
                      value: _code,
                      errorText: _touched['code']! ? _getCodeError(_code) : null,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      onChanged: (v) => setState(() { _code = v.toUpperCase(); _touched['code'] = true; }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomInputField(
                            label: 'Latitude',
                            icon: Icons.my_location,
                            value: _lat,
                            errorText: _touched['lat']! ? _getCoordError(_lat, -90, 90) : null,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [_coordsFormatter],
                            onChanged: (v) => setState(() { _lat = v; _touched['lat'] = true; }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomInputField(
                            label: 'Longitude',
                            icon: Icons.my_location,
                            value: _lng,
                            errorText: _touched['lng']! ? _getCoordError(_lng, -180, 180) : null,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            inputFormatters: [_coordsFormatter],
                            onChanged: (v) => setState(() { _lng = v; _touched['lng'] = true; }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : CustomButton(
                          label: isEdit ? 'Save Changes' : 'Create Airport',
                          onPressed: _isValid ? _save : null,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}