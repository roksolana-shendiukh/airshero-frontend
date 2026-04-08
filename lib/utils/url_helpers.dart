String buildSearchResultsUrl({
  required int fromCityId,
  required String fromCity,
  required int toCityId,
  required String toCity,
  required DateTime departDate,
  DateTime? returnDate,
  required Map<String, int> passengers,
}) {
  return Uri(
    path: '/search-results',
    queryParameters: {
      'fromId': fromCityId.toString(),
      'from': fromCity,
      'toId': toCityId.toString(),
      'to': toCity,
      'date': departDate.toIso8601String().substring(0, 10),
      if (returnDate != null)
        'returnDate': returnDate.toIso8601String().substring(0, 10),
      'adults': (passengers['adults'] ?? 1).toString(),
      'children': (passengers['children'] ?? 0).toString(),
      'infants': (passengers['infants'] ?? 0).toString(),
    },
  ).toString();
}