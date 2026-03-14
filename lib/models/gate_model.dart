class GateModel {
  final int gateId;
  final String gateCode;
  final int terminalId;
  final String? terminalCode;
  final int? terminalSize;

  const GateModel({
    required this.gateId,
    required this.gateCode,
    required this.terminalId,
    this.terminalCode,
    this.terminalSize,
  });

  factory GateModel.fromJson(Map<String, dynamic> json) => GateModel(
        gateId:       (json['gateId'] as num).toInt(),
        gateCode:     json['gateCode'] as String,
        terminalId:   (json['terminalId'] as num).toInt(),
        terminalCode: json['terminalCode'] as String?,
        terminalSize: (json['terminalSize'] as num?)?.toInt(),
      );

  String get label =>
      terminalCode != null ? 'T$terminalCode · $gateCode' : gateCode;
}