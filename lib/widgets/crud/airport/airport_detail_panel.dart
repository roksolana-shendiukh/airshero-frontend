import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/object_crud_service.dart';
import '../../custom/custom_select_field.dart';
import 'airport_terminal_dialog.dart';
import 'airport_gate_dialog.dart';

class AirportDetailPanel extends StatefulWidget {
  final Map<String, dynamic> airport;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  const AirportDetailPanel({
    super.key,
    required this.airport,
    required this.onEdit,
    required this.onClose,
  });

  @override
  State<AirportDetailPanel> createState() => _AirportDetailPanelState();
}

class _AirportDetailPanelState extends State<AirportDetailPanel> {
  List<Map<String, dynamic>> _terminals = [];
  List<Map<String, dynamic>> _gates = [];

  bool _isLoadingTerminals = true;
  bool _isLoadingGates = false;

  String? _selectedTerminalName;
  Map<String, dynamic>? _selectedTerminal;

  String? _terminalError;
  String? _gateError;

  @override
  void initState() {
    super.initState();
    _loadTerminals();
  }

  @override
  void didUpdateWidget(AirportDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.airport['airportId'] != widget.airport['airportId']) {
      setState(() {
        _terminals = [];
        _gates = [];
        _selectedTerminal = null;
        _selectedTerminalName = null;
        _isLoadingTerminals = true;
        _terminalError = null;
        _gateError = null;
      });
      _loadTerminals();
    }
  }

  Future<void> _loadTerminals() async {
    setState(() {
      _isLoadingTerminals = true;
      _terminalError = null;
    });

    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final terminals = await api.getTerminals(widget.airport['airportId'] as int);
      if (mounted) {
        setState(() {
          _terminals = terminals;
          _isLoadingTerminals = false;
          
          if (_selectedTerminal != null) {
            final updated = terminals.firstWhere(
              (t) => t['terminalId'] == _selectedTerminal!['terminalId'],
              orElse: () => <String, dynamic>{},
            );
            if (updated.isEmpty) {
              _selectedTerminal = null;
              _selectedTerminalName = null;
              _gates = [];
            } else {
              _selectedTerminal = updated;
            }
          } else if (terminals.isNotEmpty) {
            _selectedTerminal = terminals.first;
            _selectedTerminalName = terminals.first['terminalCode'] as String?;
            _loadGates(_selectedTerminal!['terminalId'] as int);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _terminalError = e.toString().replaceAll('Exception: ', '');
          _isLoadingTerminals = false;
        });
      }
    }
  }

  Future<void> _loadGates(int terminalId) async {
    setState(() {
      _isLoadingGates = true;
      _gateError = null;
      _gates = [];
    });

    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final gates = await api.getGates(terminalId);
      if (mounted) {
        setState(() {
          _gates = gates;
          _isLoadingGates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gateError = e.toString().replaceAll('Exception: ', '');
          _isLoadingGates = false;
        });
      }
    }
  }

  void _onTerminalSelected(String? val) {
    if (val == null) return;
    final terminal = _terminals.firstWhere(
      (t) => t['terminalCode'] == val,
      orElse: () => <String, dynamic>{},
    );
    if (terminal.isEmpty) return;
    setState(() {
      _selectedTerminal = terminal;
      _selectedTerminalName = val;
      _terminalError = null;
      _gateError = null;
    });
    _loadGates(terminal['terminalId'] as int);
  }

  // --- ДОПОМІЖНИЙ ДІАЛОГ ДЛЯ ПОМИЛОК БЛОКУВАННЯ ---
  void _showBlockDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.block, color: Theme.of(ctx).colorScheme.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- ВИДАЛЕННЯ ТЕРМІНАЛУ ---
  Future<void> _deleteTerminal() async {
    if (_selectedTerminal == null) return;

    // ПЕРЕВІРКА ПЕРЕД ПІДТВЕРДЖЕННЯМ: Якщо є гейти - блокуємо одразу
    if (_gates.isNotEmpty) {
      _showBlockDialog(
        'Cannot Delete Terminal', 
        'This terminal currently has ${_gates.length} gate(s). Please delete all gates first.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Delete Terminal'),
          content: Text('Are you sure you want to delete terminal "${_selectedTerminal!['terminalCode']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _terminalError = null);

    try {
      final api = ObjectCrudService(context.read<AuthService>());
      await api.deleteTerminal(_selectedTerminal!['terminalId'] as int);
      
      if (mounted) {
        setState(() {
          _selectedTerminal = null;
          _selectedTerminalName = null;
          _gates = [];
        });
        _loadTerminals();
      }
    } catch (e) {
      if (mounted) {
        _showBlockDialog('Deletion Failed', 'Backend error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // --- ВИДАЛЕННЯ ГЕЙТУ ---
  Future<void> _deleteGate(Map<String, dynamic> gate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Delete Gate'),
          content: Text('Are you sure you want to delete gate "${gate['gateCode']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _gateError = null);

    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final gateId = gate['gateId'] ?? gate['gate_id'] ?? gate['id'];
      await api.deleteGate(gateId as int);
      
      if (mounted) {
        _loadGates(_selectedTerminal!['terminalId'] as int);
      }
    } catch (e) {
      if (mounted) {
        // Якщо бекенд не дав видалити через зв'язки з рейсами
        _showBlockDialog(
          'Cannot Delete Gate', 
          'This gate might be assigned to flight executions.\n\nDetails: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _openAddTerminal() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AirportTerminalDialog(airportId: widget.airport['airportId'] as int),
    );
    if (result == true) _loadTerminals();
  }

  Future<void> _openEditTerminal() async {
    if (_selectedTerminal == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AirportTerminalDialog(
        airportId: widget.airport['airportId'] as int,
        terminal: _selectedTerminal,
      ),
    );
    if (result == true) _loadTerminals();
  }

  Future<void> _openAddGate() async {
    if (_selectedTerminal == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AirportGateDialog(
        terminalId: _selectedTerminal!['terminalId'] as int,
        terminalCode: _selectedTerminal!['terminalCode'] as String,
      ),
    );
    if (result == true) _loadGates(_selectedTerminal!['terminalId'] as int);
  }

  Future<void> _openEditGate(Map<String, dynamic> gate) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AirportGateDialog(
        terminalId: _selectedTerminal!['terminalId'] as int,
        terminalCode: _selectedTerminal!['terminalCode'] as String,
        gate: gate,
      ),
    );
    if (result == true) _loadGates(_selectedTerminal!['terminalId'] as int);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTerminalSection(colors),
                if (_selectedTerminal != null) ...[
                  const SizedBox(height: 16),
                  _buildGateSection(colors),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.airport['airportCode'] ?? '—',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: colors.primary, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.airport['cityName'] ?? '—',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.airport['airportName'] ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // ОНОВЛЕНИЙ TERMINAL SECTION: Select завжди видимий, помилка відображається НАД ним
  Widget _buildTerminalSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Terminals',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant, letterSpacing: 0.4,
              ),
            ),
            Row(
              children: [
                if (_selectedTerminal != null) ...[
                  _iconAction(
                    icon: Icons.edit_outlined, tooltip: 'Edit terminal',
                    onTap: _openEditTerminal, color: colors.onSurfaceVariant,
                  ),
                  _iconAction(
                    icon: Icons.delete_outline, tooltip: 'Delete terminal',
                    onTap: _deleteTerminal, color: colors.error,
                  ),
                ],
                _iconAction(
                  icon: Icons.add, tooltip: 'Add terminal',
                  onTap: _openAddTerminal, color: colors.primary,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_terminalError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(_terminalError!, style: TextStyle(fontSize: 12, color: colors.error)),
          ),

        if (_isLoadingTerminals)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_terminals.isEmpty)
          Text('No terminals yet', style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant))
        else
          CustomSelectField(
            label: 'Select terminal',
            icon: Icons.apartment_outlined,
            value: _selectedTerminalName ?? '',
            items: _terminals.map((t) => t['terminalCode'] as String).toList(),
            itemLabels: _terminals.map((t) => 'Terminal ${t['terminalCode']} · ${t['terminalTypeName'] ?? ''}').toList(),
            onChanged: _onTerminalSelected,
          ),
      ],
    );
  }

  Widget _buildGateSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gates',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant, letterSpacing: 0.4,
              ),
            ),
            _iconAction(
              icon: Icons.add, tooltip: 'Add gate',
              onTap: _openAddGate, color: colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_gateError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(_gateError!, style: TextStyle(fontSize: 12, color: colors.error)),
          ),

        if (_isLoadingGates)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_gates.isEmpty)
          Text('No gates yet', style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant))
        else
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _gates.map((gate) => _buildGateChip(gate, colors)).toList(),
          ),
      ],
    );
  }

  Widget _buildGateChip(Map<String, dynamic> gate, ColorScheme colors) {
    return InputChip(
      label: Text(
        gate['gateCode'] ?? '—',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      deleteIconColor: colors.error,
      onPressed: () => _openEditGate(gate), 
      onDeleted: () => _deleteGate(gate),  
      tooltip: 'Tap to edit, click × to delete',
    );
  }

 
  Widget _iconAction({required IconData icon, required String tooltip, required VoidCallback onTap, required Color color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(4),
        child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 18, color: color)),
      ),
    );
  }
}