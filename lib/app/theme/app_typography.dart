import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // =====================================
  // DISPLAY
  // =====================================

  static TextStyle display = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // =====================================
  // HEADINGS
  // =====================================

  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // =====================================
  // FINANCIAL VALUES
  // =====================================

  static TextStyle moneyLarge = GoogleFonts.poppins(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );

  static TextStyle moneyMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // =====================================
  // BODY
  // =====================================

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // =====================================
  // CAPTIONS
  // =====================================

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static TextStyle small = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}
