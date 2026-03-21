class GateModel {
  final int gateId;
  final String gateCode;
  final int terminalId;
  final String? terminalCode;
  final double? terminalSize;
  final String? terminalType;
  final bool isAvailable;

  const GateModel({
    required this.gateId,
    required this.gateCode,
    required this.terminalId,
    this.terminalCode,
    this.terminalSize,
    this.terminalType,
    this.isAvailable = true,
  });

  factory GateModel.fromJson(Map<String, dynamic> json) => GateModel(
        gateId:       (json['gateId'] as num).toInt(),
        gateCode:     json['gateCode'] as String,
        terminalId:   (json['terminalId'] as num).toInt(),
        terminalCode: json['terminalCode'] as String?,
        terminalSize: (json['terminalSize'] as num?)?.toDouble(),
        terminalType: json['terminalType'] as String?,
        isAvailable:  json['isAvailable'] as bool? ?? true,
      );

  String get label =>
      terminalCode != null ? 'T$terminalCode · Gate $gateCode' : 'Gate $gateCode';
}