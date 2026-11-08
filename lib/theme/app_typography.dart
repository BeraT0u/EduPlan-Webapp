import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

final TextTheme appTextTheme = TextTheme(
  headlineLarge: GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.015,
    color: AppColors.textPrimary,
  ),
  headlineMedium: GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.01,
    color: AppColors.textPrimary,
  ),
  titleMedium: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  ),
  bodyLarge: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  ),
  bodyMedium: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textPrimary,
  ),
  bodySmall: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textSecondary,
  ),
);
