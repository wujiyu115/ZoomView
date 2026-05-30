import 'package:flutter/material.dart';

class ColoredIconBox extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String? letter;
  final double size;
  final double borderRadius;
  final double iconSize;

  const ColoredIconBox({
    super.key,
    required this.color,
    this.icon,
    this.letter,
    this.size = 36,
    this.borderRadius = 10,
    this.iconSize = 18,
  }) : assert(icon != null || letter != null);

  const ColoredIconBox.settings({
    super.key,
    required this.color,
    this.icon,
    this.letter,
    this.iconSize = 18,
  })  : size = 30,
        borderRadius = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: iconSize, color: Colors.white)
          : Text(
              letter!,
              style: TextStyle(
                fontSize: size * 0.39,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }
}
