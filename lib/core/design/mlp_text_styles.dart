import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mlp_colors.dart';

class MlpTextStyles {
  const MlpTextStyles._();

  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w800, color: MlpColors.text1,
        letterSpacing: -0.5,
      );
  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700, color: MlpColors.text1,
      );
  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: MlpColors.text1,
      );
  static TextStyle get h4 => GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w600, color: MlpColors.text1,
      );
  static TextStyle get body1 => GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w400, color: MlpColors.text1, height: 1.5,
      );
  static TextStyle get body2 => GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w400, color: MlpColors.text2, height: 1.4,
      );
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w400, color: MlpColors.text3,
      );
  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w600, color: MlpColors.text2,
        letterSpacing: 0.5,
      );
  static TextStyle get buttonLabel => GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w700, color: MlpColors.text1,
        letterSpacing: 0.2,
      );
  static TextStyle get chip => GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w500, color: MlpColors.text1,
      );
}
