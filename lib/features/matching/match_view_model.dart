import 'package:flutter/material.dart';
import 'package:palseapp/features/city_events/service/city_event_service.dart';

class MatchViewModel extends ChangeNotifier {
  final CityEventService _cityEventService = CityEventService();
}
