import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3A5ACB);
  static const Color secondaryColor = Color(0xFF007AFF);
  static const Color accentColor = Color(0xFF007AFF);
  static const Color leaderBoardColor = Color(0xFF3A5ACB);

  static ThemeData get theme => ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        tabBarTheme: TabBarTheme(
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          dividerHeight: 0.2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            iconColor: Colors.white,
            disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            iconColor: primaryColor,
            side: BorderSide(color: primaryColor),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            iconColor: primaryColor,
          ),
        ),

        cardTheme: CardTheme(
          color: Colors.white.withValues(alpha: 0.9),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        indicatorColor: primaryColor,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primaryColor,
        ),
        switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return Colors.grey.shade300;
          }),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          }),
          trackOutlineWidth: WidgetStateProperty.all(0),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: primaryColor,
          labelStyle: TextStyle(color: Colors.white),
          shape: StadiumBorder(side: BorderSide.none),
          iconTheme: IconThemeData(color: Colors.white),
          deleteIconColor: Colors.white,
        ),
        // TextFormField için daha kapsamlı bir tema tanımlayalım
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: primaryColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(color: Colors.red),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          labelStyle: TextStyle(color: Colors.grey),
          floatingLabelStyle: TextStyle(color: primaryColor),
          hintStyle: TextStyle(color: Colors.grey),
        ),
      );
}
