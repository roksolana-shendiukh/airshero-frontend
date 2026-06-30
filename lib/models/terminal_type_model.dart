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