import 'package:flutter/material.dart';

class MettleLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const MettleLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: logoColor,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.6,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'METTLE',
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: logoColor,
            ),
          ),
        ],
      ],
    );
  }
}
