import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MangaColors {
  static const Color bgCream = Color(0xFFFBF5E8);
  static const Color surfaceWhite = Color(0xFFFFFDFA);
  static const Color ticketListBg = Color(0xFFFDF9F0);
  static const Color ticketFooterBg = Color(0xFFFFF9E6);
  static const Color softCream = Color(0xFFFAF5E9);
  static const Color cardImageBg = Color(0xFFF0EBD9);

  static const Color primaryOrange = Color(0xFFFF5A1F);
  static const Color primaryOrangeHover = Color(0xFFE0450D);
  static const Color accentYellow = Color(0xFFFFCB11);
  static const Color accentCyan = Color(0xFF00B4D8);
  static const Color accentCyanDark = Color(0xFF0099B8);
  static const Color accentMint = Color(0xFF85F8C4);
  static const Color accentMintDark = Color(0xFF68DBA9);
  static const Color badgeSoftBlue = Color(0xFFDBE1FF);
  static const Color dangerSoftRed = Color(0xFFFFDAD6);
  static const Color dangerRed = Color(0xFFC62828);
  static const Color successGreen = Color(0xFF15803D);
  static const Color black = Color(0xFF000000);
  static const Color darkDot = Color(0xFF1E1E1E);

  static Color fromHex(String? hex, {Color fallback = primaryOrange}) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      final val = int.tryParse('FF$cleaned', radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }
}

class MangaShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 0),
  ];
  static const List<BoxShadow> pressed = [
    BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5), blurRadius: 0),
  ];
}

class MangaFonts {
  static TextStyle comic({
    double fontSize = 20,
    Color color = Colors.black,
    double letterSpacing = 0.8,
    double? height,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.bangers(
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height ?? 1.1,
      shadows: shadows,
    );
  }

  static TextStyle sans({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w700,
    Color color = Colors.black,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}

