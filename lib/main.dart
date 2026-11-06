import 'package:flutter/material.dart';

import 'telas/inicio.dart';

void main() {
  runApp(const CasaBellaApp());
}

class CasaBellaApp extends StatelessWidget {
  const CasaBellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Casa Bella',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B1E2B),
          surface: const Color(0xFFFCFAF7),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F4F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFCFAF7),
          foregroundColor: Color(0xFF272322),
          centerTitle: false,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E1DC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7B1E2B), width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFEFEAE5)),
          ),
        ),
      ),
      home: const InicioPage(),
    );
  }
}
