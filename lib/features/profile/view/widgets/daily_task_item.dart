import 'package:flutter/material.dart';

// Günlük görev öğesi widget'ı
class DailyTaskItem extends StatelessWidget {
  final String text;
  final bool isCompleted;
  final int xpAmount;
  final int index;

  const DailyTaskItem({
    super.key,
    required this.text,
    required this.isCompleted,
    required this.xpAmount,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Görev numarası
          Text(
            '$index.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(width: 8),

          // Görev metni
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),

          // XP miktarı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$xpAmount XP',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),

          // Tik işareti (tamamlanmışsa)
          if (isCompleted)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child:
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
            ),
        ],
      ),
    );
  }
}
