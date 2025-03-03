import 'package:flutter/material.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/achievements.dart';

class XpEventsView extends StatelessWidget {
  const XpEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Sistemi ve Ödüller'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: XpEventGroup.values.length,
        itemBuilder: (context, index) {
          final group = XpEventGroup.values[index];

          final events = group.events;
          return _buildEventCard(group, events);
        },
      ),
    );
  }

  Widget _buildEventCard(XpEventGroup group, List<XpEvent> events) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(group.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                )),
            const SizedBox(height: 8),
            ...group.events.map((event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('• ${event.description}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  trailing: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('+${event.xpAmount} XP', style: const TextStyle(color: Colors.white)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
