import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PookieBrandMark extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;
  final bool isDark;

  const PookieBrandMark({
    super.key,
    this.size = 32,
    this.showText = true,
    this.fontSize = 20,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.32),
          topRight: Radius.circular(size * 0.32),
          bottomRight: Radius.circular(size * 0.32),
          bottomLeft: Radius.circular(size * 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withOpacity(0.3),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: size * 0.58,
        ),
      ),
    );

    if (!showText) return iconBox;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconBox,
        const SizedBox(width: 9),
        // Flexible + scaleDown lets the wordmark shrink on narrow screens
        // instead of overflowing its parent Row.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Pookie Match',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.ink,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

