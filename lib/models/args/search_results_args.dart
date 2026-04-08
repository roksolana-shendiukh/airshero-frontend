import '../../models/booking_group_draft.dart';

class SearchResultsArguments {
  final int fromCityId;
  final String fromCity;
  final int toCityId;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final BookingGroupDraft? bookingGroupDraft;
  final DateTime? leg2Date;

  SearchResultsArguments({
    required this.fromCityId,
    required this.fromCity,
    required this.toCityId,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    this.bookingGroupDraft,
    this.leg2Date,
  });
}