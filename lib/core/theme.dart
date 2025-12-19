import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette
  static const Color _primaryEmerald = Color(0xFF064E3B);
  static const Color _accentGold = Color(0xFFD4AF37);
  
  // Light Mode Colors
  static const Color _lightBG = Color(0xFFF9FBF9);
  static const Color _lightCard = Colors.white;
  
  // Dark Mode Colors
  static const Color _darkBG = Color(0xFF0A110F); // Very deep green-black
  static const Color _darkCard = Color(0xFF121D1A);

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        backgroundColor: _lightBG,
        cardColor: _lightCard,
        primaryText: _primaryEmerald,
        bodyText: Colors.black87,
        navBarBg: Colors.white,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        backgroundColor: _darkBG,
        cardColor: _darkCard,
        primaryText: Colors.white,
        bodyText: Colors.white70,
        navBarBg: _darkCard,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color cardColor,
    required Color primaryText,
    required Color bodyText,
    required Color navBarBg,
  }) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: _primaryEmerald,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryEmerald,
        brightness: brightness,
        primary: _primaryEmerald,
        secondary: _accentGold,
        surface: cardColor,
        onPrimary: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _darkBG : _primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark 
              ? BorderSide(color: Colors.white.withOpacity(0.05)) 
              : BorderSide.none,
        ),
      ),

      // Beautiful Typography
      textTheme: TextTheme(
        headlineSmall: GoogleFonts.montserrat(
          color: primaryText,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.montserrat(
          color: primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.lato(
          color: bodyText,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.lato(
          color: bodyText.withOpacity(0.8),
          fontSize: 14,
        ),
      ),

      // Global Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryEmerald,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Modern Navigation Bar styling (Google Nav Bar compatibility)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBarBg,
        selectedItemColor: _accentGold,
        unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      
      // Divider styling
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        thickness: 1,
      ),
    );
  }
}