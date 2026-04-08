import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class EasyianLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool white;

  const EasyianLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Mark - Red square with E
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.logoRed,
            borderRadius: BorderRadius.circular(size * 0.12),
          ),
          child: Center(
            child: Text(
              'E',
              style: GoogleFonts.inter(
                fontSize: size * 0.58,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.2),
          Text(
            'Easyian',
            style: GoogleFonts.inter(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
              color: white ? Colors.white : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkText
                  : AppColors.lightText),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class EasyianLogoSmall extends StatelessWidget {
  final double size;

  const EasyianLogoSmall({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.logoRed,
        borderRadius: BorderRadius.circular(size * 0.12),
      ),
      child: Center(
        child: Text(
          'E',
          style: GoogleFonts.inter(
            fontSize: size * 0.58,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
