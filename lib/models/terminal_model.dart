class TerminalTypeModel {
  final int terminalTypeId;
  final String? terminalTypeName;

  const TerminalTypeModel({
    required this.terminalTypeId,
    this.terminalTypeName,
  });

  factory TerminalTypeModel.fromJson(Map<String, dynamic> json) => TerminalTypeModel(
        terminalTypeId:   (json['terminal_type_id'] as num).toInt(),
        terminalTypeName: json['terminal_type_name'] as String?,
      );
}

class TerminalModel {
  final int terminalId;
  final int airportId;
  final int terminalTypeId;
  final String? terminalTypeName;
  final String terminalCode;
  final double terminalSize;

  const TerminalModel({
    required this.terminalId,
    required this.airportId,
    required this.terminalTypeId,
    this.terminalTypeName,
    required this.terminalCode,
    required this.terminalSize,
  });

  factory TerminalModel.fromJson(Map<String, dynamic> json) => TerminalModel(
        terminalId:       (json['terminal_id'] as num).toInt(),
        airportId:        (json['airport_id'] as num).toInt(),
        terminalTypeId:   (json['terminal_type_id'] as num).toInt(),
        terminalTypeName: json['terminal_type_name'] as String?,
        terminalCode:     json['terminal_code'] as String,
        terminalSize:     (json['terminal_size'] as num).toDouble(),
      );
}