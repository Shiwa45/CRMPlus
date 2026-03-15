import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const Color primary       = Color(0xFF1A56DB);
  static const Color primaryHover  = Color(0xFF1347C0);
  static const Color primaryLight  = Color(0xFFEBF2FF);
  static const Color accent        = Color(0xFF0891B2);
  static const Color logoRed       = Color(0xFFD32F2F);

  // Semantic
  static const Color success       = Color(0xFF057A55);
  static const Color successBg     = Color(0xFFDEF7EC);
  static const Color warning       = Color(0xFFB45309);
  static const Color warningBg     = Color(0xFFFEF3C7);
  static const Color error         = Color(0xFFE02424);
  static const Color errorBg       = Color(0xFFFDE8E8);
  static const Color info          = Color(0xFF1C64F2);
  static const Color infoBg        = Color(0xFFEBF2FF);

  // Lead status
  static const Color statusNew         = Color(0xFF1C64F2);
  static const Color statusContacted   = Color(0xFF0891B2);
  static const Color statusQualified   = Color(0xFF057A55);
  static const Color statusProposal    = Color(0xFFD97706);
  static const Color statusNegotiation = Color(0xFF0891B2);
  static const Color statusWon         = Color(0xFF046C4E);
  static const Color statusLost        = Color(0xFFE02424);
  static const Color statusOnHold      = Color(0xFF6B7280);

  // Priority
  static const Color hot  = Color(0xFFDC2626);
  static const Color warm = Color(0xFFD97706);
  static const Color cold = Color(0xFF2563EB);

  // Light surface
  static const Color lightBg          = Color(0xFFF9FAFB);
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightSurface2    = Color(0xFFF3F4F6);
  static const Color lightBorder      = Color(0xFFE5E7EB);
  static const Color lightBorder2     = Color(0xFFD1D5DB);
  static const Color lightText        = Color(0xFF111827);
  static const Color lightTextSub     = Color(0xFF374151);
  static const Color lightTextMuted   = Color(0xFF6B7280);
  static const Color lightTextFaint   = Color(0xFF9CA3AF);
  static const Color lightTextSecondary = Color(0xFF4B5563);

  // Dark surface
  static const Color darkBg          = Color(0xFF0D1117);
  static const Color darkSurface     = Color(0xFF161B22);
  static const Color darkSurface2    = Color(0xFF21262D);
  static const Color darkBorder      = Color(0xFF30363D);
  static const Color darkBorder2     = Color(0xFF3D444D);
  static const Color darkText        = Color(0xFFE6EDF3);
  static const Color darkTextSub     = Color(0xFFCDD9E5);
  static const Color darkTextMuted   = Color(0xFF848D97);
  static const Color darkTextFaint   = Color(0xFF636E7B);
  static const Color darkTextSecondary = Color(0xFFA7B0BA);

  // Sidebar
  static const Color sidebarLight    = Color(0xFF1E293B);
  static const Color sidebarDark     = Color(0xFF0F172A);
  static const Color sidebarText     = Color(0xFFCBD5E1);
  static const Color sidebarMuted    = Color(0xFF64748B);
  static const Color sidebarActive   = Color(0xFF2563EB);
  static const Color sidebarActiveBg = Color(0xFF1E3A5F);

  // Charts
  static const List<Color> chart = [
    Color(0xFF1A56DB), Color(0xFF0891B2), Color(0xFF057A55),
    Color(0xFFD97706), Color(0xFF7C3AED), Color(0xFF059669),
    Color(0xFF2563EB), Color(0xFF0E7490),
  ];
}

class AppTheme {
  static TextTheme _textTheme(Color base) => GoogleFonts.interTextTheme().apply(
    bodyColor: base, displayColor: base,
  );

  static ThemeData get light {
    const c = AppColors.lightText;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.lightText,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _textTheme(c),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.lightBorder,
        titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.lightBorder2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.lightBorder2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextMuted),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextFaint),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightText,
        side: const BorderSide(color: AppColors.lightBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      )),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(AppColors.lightSurface2),
        dataRowColor: MaterialStateProperty.resolveWith((s) {
          if (s.contains(MaterialState.hovered)) return AppColors.lightSurface2;
          return AppColors.lightSurface;
        }),
        headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextMuted),
        dataTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightText),
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 44,
        columnSpacing: 16,
        horizontalMargin: 16,
        dividerThickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? AppColors.primary : Colors.transparent),
        side: const BorderSide(color: AppColors.lightBorder2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.lightTextSub, borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4B8EF0),
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: Color(0xFFFC8181),
        onPrimary: Colors.white,
        onSurface: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _textTheme(AppColors.darkText),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.darkBorder2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.darkBorder2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF4B8EF0), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkTextMuted),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkTextFaint),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        side: const BorderSide(color: AppColors.darkBorder2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      )),
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(AppColors.darkSurface2),
        dataRowColor: MaterialStateProperty.resolveWith((s) {
          if (s.contains(MaterialState.hovered)) return AppColors.darkSurface2;
          return AppColors.darkSurface;
        }),
        headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextMuted),
        dataTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkText),
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 44,
        columnSpacing: 16,
        horizontalMargin: 16,
        dividerThickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? const Color(0xFF2563EB) : Colors.transparent),
        side: const BorderSide(color: AppColors.darkBorder2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}
