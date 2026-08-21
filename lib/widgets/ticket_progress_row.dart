import 'package:flutter/material.dart';

class TicketProgressRow extends StatelessWidget {
  final List<String> tickets;
  final String current;
  final Color bubbleColor;
  final Color bubbleTextColor;
  final Color activeColor;
  final Color activeTextColor;
  final Color lineColor;
  final Color captionColor;

  const TicketProgressRow({
    super.key,
    required this.tickets,
    required this.current,
    required this.bubbleColor,
    required this.bubbleTextColor,
    required this.activeColor,
    required this.activeTextColor,
    required this.lineColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tickets.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 36),
          child: Container(width: 14, height: 2, color: lineColor),
        ));
      }
      final ticket = tickets[i];
      final isActive = ticket == current;
      children.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              child: isActive ? Icon(Icons.arrow_drop_down, size: 20, color: activeColor) : null,
            ),
            Container(
              width: isActive ? 50 : 38,
              height: isActive ? 50 : 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? activeColor : bubbleColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(
                ticket,
                style: TextStyle(
                  fontSize: isActive ? 13 : 11,
                  fontWeight: FontWeight.w800,
                  color: isActive ? activeTextColor : bubbleTextColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 14,
              child: isActive
                  ? Text('A sua vez', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: captionColor))
                  : null,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
