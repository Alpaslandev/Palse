import 'package:flutter/material.dart';
import 'package:palseapp/features/city_events/model/event_model.dart';

class CityEventView extends StatelessWidget {
  final EventModel event;
  const CityEventView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(event.name),
    );
  }
}
