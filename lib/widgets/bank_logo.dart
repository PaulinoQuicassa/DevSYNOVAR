import 'package:flutter/material.dart';

class BankLogo extends StatelessWidget {
  final String monogram;
  final Color color;
  final double size;

  const BankLogo({super.key, required this.monogram, required this.color, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.28)),
      alignment: Alignment.center,
      child: Text(
        monogram.length > 4 ? monogram.substring(0, 4) : monogram,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.24,
          letterSpacing: -0.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
