class ScheduleGroup {
  Set<int> dayIds;
  String departureTime;

  ScheduleGroup({
    Set<int>? dayIds,
    this.departureTime = '',
  }) : dayIds = dayIds ?? {};

  Map<String, dynamic> toMap() => {
        'dayIds': dayIds.toList(),
        'departureTime': departureTime,
      };

  factory ScheduleGroup.fromMap(Map<String, dynamic> map) => ScheduleGroup(
        dayIds: Set<int>.from(map['dayIds'] as List),
        departureTime: map['departureTime'] as String,
      );
}