class GateModel {
  final int gateId;
  final int terminalId;
  final String gateCode;
  final String? terminalCode;
  final double? terminalSize;
  final String? terminalType;
  final bool isAvailable;

  const GateModel({
    required this.gateId,
    required this.terminalId,
    required this.gateCode,
    this.terminalCode,
    this.terminalSize,
    this.terminalType,
    this.isAvailable = true,
  });

  factory GateModel.fromJson(Map<String, dynamic> json) => GateModel(
        gateId:       (json['gate_id'] as num).toInt(),
        terminalId:   (json['terminal_id'] as num).toInt(),
        gateCode:     json['gate_code'] as String,
        terminalCode: json['terminal_code'] as String?,
        terminalSize: (json['terminal_size'] as num?)?.toDouble(),
        terminalType: json['terminal_type'] as String?,
        isAvailable:  json['is_available'] as bool? ?? true,
      );
}