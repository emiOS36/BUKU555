import 'package:flutter/material.dart';

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size = 20;

  const CircleIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: color,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
