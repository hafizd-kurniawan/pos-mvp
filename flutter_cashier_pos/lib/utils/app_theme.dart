import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.primaryColorValue),
        brightness: Brightness.light,
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(8.w),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          minimumSize: Size(120.w, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppConstants.primaryColorValue),
          minimumSize: Size(120.w, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          side: const BorderSide(
            color: Color(AppConstants.primaryColorValue),
            width: 1.5,
          ),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColorValue),
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade600,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(AppConstants.primaryColorValue),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // DataTable theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(
          const Color(AppConstants.primaryColorValue).withOpacity(0.1),
        ),
        dataRowMinHeight: 56.h,
        dataRowMaxHeight: 72.h,
        headingTextStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(AppConstants.primaryColorValue),
        ),
        dataTextStyle: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade800,
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      
      // Text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
        headlineMedium: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        titleLarge: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        titleMedium: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          color: Colors.grey.shade700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade700,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
  
  // Common colors for status indicators
  static const Color successColor = Color(AppConstants.accentColorValue);
  static const Color errorColor = Color(AppConstants.errorColorValue);
  static const Color warningColor = Color(AppConstants.warningColorValue);
  static const Color infoColor = Color(AppConstants.primaryColorValue);
  
  // Custom gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(AppConstants.primaryColorValue),
      Color(0xFF1976D2),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [
      Color(AppConstants.accentColorValue),
      Color(0xFF00C853),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}