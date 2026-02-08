import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightColors {
  static const Color primary = Color(0xFF6B4EFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE5DEFF);
  static const Color onPrimaryContainer = Color(0xFF4A3599);
  
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE5F0);
  static const Color onSecondaryContainer = Color(0xFF8C1D42);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color surfaceDim = Color(0xFFE8E8E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  
  static const Color inverseSurface = Color(0xFF2E2E2E);
  static const Color inverseOnSurface = Color(0xFFF5F5F5);
  static const Color inversePrimary = Color(0xFFA78BFA);
  
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F8F8);
  static const Color surfaceContainer = Color(0xFFF0F0F0);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE0E0E0);
  
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF6B6B6B);
  
  static const Color outline = Color(0xFF999999);
  static const Color outlineVariant = Color(0xFFCCCCCC);
  
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

class DarkColors {
  static const Color primary = Color(0xFFA78BFA);
  static const Color onPrimary = Color(0xFF1F0A4D);
  static const Color primaryContainer = Color(0xFF4C1D95);
  static const Color onPrimaryContainer = Color(0xFFE9D5FF);
  
  static const Color secondary = Color(0xFFF472B6);
  static const Color onSecondary = Color(0xFF4A0E26);
  static const Color secondaryContainer = Color(0xFF831843);
  static const Color onSecondaryContainer = Color(0xFFFFD9E8);
  
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  
  static const Color surfaceDim = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceBright = Color(0xFF2A2A2A);
  
  static const Color inverseSurface = Color(0xFFE8E8E8);
  static const Color inverseOnSurface = Color(0xFF2E2E2E);
  static const Color inversePrimary = Color(0xFF6B4EFF);
  
  static const Color surfaceContainerLowest = Color(0xFF0F0F0F);
  static const Color surfaceContainerLow = Color(0xFF1A1A1A);
  static const Color surfaceContainer = Color(0xFF1E1E1E);
  static const Color surfaceContainerHigh = Color(0xFF252525);
  static const Color surfaceContainerHighest = Color(0xFF303030);
  
  static const Color onSurface = Color(0xFFF5F5F5);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  
  static const Color outline = Color(0xFF666666);
  static const Color outlineVariant = Color(0xFF3D3D3D);
  
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);
  
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: LightColors.primary,
        onPrimary: LightColors.onPrimary,
        primaryContainer: LightColors.primaryContainer,
        onPrimaryContainer: LightColors.onPrimaryContainer,
        
        secondary: LightColors.secondary,
        onSecondary: LightColors.onSecondary,
        secondaryContainer: LightColors.secondaryContainer,
        onSecondaryContainer: LightColors.onSecondaryContainer,
        
        error: LightColors.error,
        onError: LightColors.onError,
        errorContainer: LightColors.errorContainer,
        onErrorContainer: LightColors.onErrorContainer,
        
        surface: LightColors.surface,
        onSurface: LightColors.onSurface,
        onSurfaceVariant: LightColors.onSurfaceVariant,
        
        outline: LightColors.outline,
        outlineVariant: LightColors.outlineVariant,
        
        inverseSurface: LightColors.inverseSurface,
        onInverseSurface: LightColors.inverseOnSurface,
        inversePrimary: LightColors.inversePrimary,
        
        scrim: LightColors.scrim,
        shadow: LightColors.shadow,
      ),
      
      scaffoldBackgroundColor: Color(0xFFFAFAFA),
      
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: LightColors.onSurface,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: LightColors.onSurface,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LightColors.onSurface,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: LightColors.onSurface,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: LightColors.onSurfaceVariant,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: LightColors.primaryContainer,
        foregroundColor: LightColors.onPrimaryContainer,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LightColors.onPrimaryContainer,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.primary,
          foregroundColor: LightColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LightColors.primary,
          side: const BorderSide(color: LightColors.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LightColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LightColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LightColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LightColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LightColors.error, width: 2),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: LightColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: LightColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LightColors.inverseSurface,
        contentTextStyle: const TextStyle(color: LightColors.inverseOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: DarkColors.primary,
        onPrimary: DarkColors.onPrimary,
        primaryContainer: DarkColors.primaryContainer,
        onPrimaryContainer: DarkColors.onPrimaryContainer,
        
        secondary: DarkColors.secondary,
        onSecondary: DarkColors.onSecondary,
        secondaryContainer: DarkColors.secondaryContainer,
        onSecondaryContainer: DarkColors.onSecondaryContainer,
        
        error: DarkColors.error,
        onError: DarkColors.onError,
        errorContainer: DarkColors.errorContainer,
        onErrorContainer: DarkColors.onErrorContainer,
        
        surface: DarkColors.surface,
        onSurface: DarkColors.onSurface,
        onSurfaceVariant: DarkColors.onSurfaceVariant,
        
        outline: DarkColors.outline,
        outlineVariant: DarkColors.outlineVariant,
        
        inverseSurface: DarkColors.inverseSurface,
        onInverseSurface: DarkColors.inverseOnSurface,
        inversePrimary: DarkColors.inversePrimary,
        
        scrim: DarkColors.scrim,
        shadow: DarkColors.shadow,
      ),
      
      scaffoldBackgroundColor: Color(0xFF0A0A0A),
      
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: DarkColors.onSurface,
        ),
        displayMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: DarkColors.onSurface,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DarkColors.onSurface,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: DarkColors.onSurface,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: DarkColors.onSurfaceVariant,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: DarkColors.primaryContainer,
        foregroundColor: DarkColors.onPrimaryContainer,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DarkColors.onPrimaryContainer,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.primary,
          foregroundColor: DarkColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DarkColors.primary,
          side: const BorderSide(color: DarkColors.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkColors.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DarkColors.error, width: 2),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: DarkColors.surfaceContainerHigh,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: DarkColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DarkColors.inverseSurface,
        contentTextStyle: const TextStyle(color: DarkColors.inverseOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}