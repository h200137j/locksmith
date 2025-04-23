import 'package:flutter/material.dart';
import 'locksmith.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocksmithTheme(
      child: LocksmithApp(),
    );
  }
}

class LocksmithTheme extends StatefulWidget {
  final Widget child;
  
  const LocksmithTheme({super.key, required this.child});

  @override
  State<LocksmithTheme> createState() => LocksmithThemeState();
}

class LocksmithThemeState extends State<LocksmithTheme> {
  bool _isDarkMode = true;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = _isDarkMode 
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    
    final colorScheme = theme.colorScheme;
    
    return MaterialApp(
      title: 'Locksmith',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        colorScheme: _isDarkMode 
            ? colorScheme.copyWith(
                primary: Colors.tealAccent,
                primaryContainer: Colors.teal.shade700,
                secondary: Colors.purpleAccent,
                surface: Colors.grey.shade900,
                background: Colors.black,
              )
            : colorScheme,
      ),
      home: widget.child,
    );
  }
}