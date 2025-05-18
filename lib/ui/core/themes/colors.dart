import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color white = Color.fromRGBO(255, 255, 255, 1);
  static const Color black = Color.fromRGBO(16, 16, 16, 1);
  static const Color blue =  Color.fromRGBO(33, 150, 243, 1);
  static const Color darkBlue = Color.fromRGBO(12, 20, 60, 1);
  static const Color greyBlue = Color.fromRGBO(128, 136, 175, 1);
  static const Color lightPurple = Color.fromRGBO(140, 158, 240, 1);
  static const Color grey = Color.fromRGBO(115, 115, 115, 1); 
  static const Color whiteGrey = Color.fromRGBO(224, 224, 224, 1);
  static const Color lightGrey = Color.fromRGBO(238, 238, 238, 1);
  static const Color darkGrey = Color.fromRGBO(77, 77, 77, 1); 
  static const Color red = Color.fromRGBO(231, 76, 60, 1);
  static const Color redWhite = Color.fromRGBO(255, 247, 250, 1);
  static const Color whiteTransparent = Color.fromRGBO(255, 255, 255, 0.302);
  static const Color blackTransparent = Color.fromRGBO(0, 0, 0, 0.302);

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.black,
    onPrimary: AppColors.white,
    secondary: AppColors.black,
    onSecondary: AppColors.white,
    surface: Colors.white,
    onSurface: AppColors.black,
    error: AppColors.white,
    onError: AppColors.red,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.white,
    onPrimary: AppColors.black,
    secondary: AppColors.white,
    onSecondary: AppColors.black,
    surface: AppColors.black,
    onSurface: AppColors.white,
    error: AppColors.black,
    onError: AppColors.red,
  );
}
