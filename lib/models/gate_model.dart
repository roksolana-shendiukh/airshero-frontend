class GateModel {
  final int gateId;
  final int terminalId;
  final String gateCode;

  const GateModel({
    required this.gateId,
    required this.terminalId,
    required this.gateCode,
  });

  factory GateModel.fromJson(Map<String, dynamic> json) => GateModel(
        gateId:     (json['gate_id'] as num).toInt(),
        terminalId: (json['terminal_id'] as num).toInt(),
        gateCode:   json['gate_code'] as String,
      );
}