import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter', // Modern font family
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.primaryColorValue),
        brightness: Brightness.light,
        surface: const Color(AppConstants.surfaceColorValue),
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: const Color(AppConstants.surfaceColorValue),
      
      // AppBar theme - Modern gradient design
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      
      // Card theme - Modern elevated design
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: const Color(AppConstants.cardColorValue),
        margin: EdgeInsets.all(8.w),
        surfaceTintColor: Colors.transparent,
      ),
      
      // Button themes - Modern with gradients
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          minimumSize: Size(120.w, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
          shadowColor: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColorValue),
          minimumSize: Size(120.w, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          side: BorderSide(
            color: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
            width: 1.5,
          ),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Input decoration theme - Modern clean design
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColorValue),
            width: 2.5,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 16.h,
        ),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Bottom navigation bar theme - Modern floating design
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(AppConstants.primaryColorValue),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      
      // DataTable theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(
          const Color(AppConstants.primaryColorValue).withOpacity(0.08),
        ),
        dataRowMinHeight: 64.h,
        dataRowMaxHeight: 80.h,
        headingTextStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: const Color(AppConstants.primaryColorValue),
          letterSpacing: 0.3,
        ),
        dataTextStyle: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(AppConstants.primaryColorValue).withOpacity(0.15),
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      
      // Text theme - Modern typography hierarchy
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade900,
          letterSpacing: -1.2,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
          letterSpacing: -0.8,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
          letterSpacing: -0.3,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          letterSpacing: 0,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
          height: 1.4,
        ),
      ),
    );
  }
  
  // Modern color palette
  static const Color primaryColor = Color(AppConstants.primaryColorValue);
  static const Color primaryDark = Color(AppConstants.primaryDarkValue);
  static const Color successColor = Color(AppConstants.accentColorValue);
  static const Color errorColor = Color(AppConstants.errorColorValue);
  static const Color warningColor = Color(AppConstants.warningColorValue);
  static const Color infoColor = Color(0xFF3B82F6); // Modern blue
  static const Color surfaceColor = Color(AppConstants.surfaceColorValue);
  static const Color cardColor = Color(AppConstants.cardColorValue);
  
  // Modern gradient collection
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(AppConstants.primaryColorValue),
      Color(AppConstants.primaryDarkValue),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [
      Color(AppConstants.accentColorValue),
      Color(0xFF059669),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [
      Color(AppConstants.warningColorValue),
      Color(0xFFD97706),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [
      Color(AppConstants.errorColorValue),
      Color(0xFFDC2626),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glassmorphism effect
  static BoxDecoration get glassmorphismDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(16.r),
    color: Colors.white.withOpacity(0.25),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Modern card shadow
  static List<BoxShadow> get modernCardShadow => [
    BoxShadow(
      color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}

// Extension to create lighter versions of gradients
extension LinearGradientExtension on LinearGradient {
  LinearGradient scale(double opacity) {
    return LinearGradient(
      colors: colors.map((color) => color.withOpacity(opacity)).toList(),
      begin: begin,
      end: end,
      stops: stops,
    );
  }
}