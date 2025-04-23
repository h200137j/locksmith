import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

class LocksmithApp extends StatefulWidget {
  const LocksmithApp({super.key});

  @override
  State<LocksmithApp> createState() => _LocksmithAppState();
}

class _LocksmithAppState extends State<LocksmithApp> with SingleTickerProviderStateMixin {
  // Password configuration
  double _passwordLength = 12;
  bool _includeLowercase = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecial = false;
  String _generatedPassword = '';
  String _displayPassword = '';
  bool _isDecrypting = false;

  // Character sets
  final String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  final String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final String _numbers = '0123456789';
  final String _special = '!@#\$%^&*()-_=+[]{}|;:,.<>?/';

  // Animation controller
  late AnimationController _animationController;

  // Theme mode
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _generatePassword();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Generate password based on selected options
  void _generatePassword() {
    String charset = '';

    if (_includeLowercase) charset += _lowercase;
    if (_includeUppercase) charset += _uppercase;
    if (_includeNumbers) charset += _numbers;
    if (_includeSpecial) charset += _special;

    if (charset.isEmpty) {
      setState(() {
        _generatedPassword = '';
        _displayPassword = '';
      });
      return;
    }

    final random = Random.secure();
    final length = _passwordLength.toInt();
    String password = '';

    for (int i = 0; i < length; i++) {
      password += charset[random.nextInt(charset.length)];
    }

    setState(() {
      _generatedPassword = password;
      _isDecrypting = true;
    });

    _startDecryptAnimation(password);
  }

  void _startDecryptAnimation(String targetPassword) {
    const scrambleChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_=+[]{}|;:,.<>?/';
    final random = Random();
    int step = 0;
    final totalSteps = 8; // Number of animation steps

    // Start with random characters
    setState(() {
      _displayPassword = List.generate(targetPassword.length,
          (_) => scrambleChars[random.nextInt(scrambleChars.length)]).join();
    });

    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      step++;

      if (step >= totalSteps) {
        timer.cancel();
        setState(() {
          _displayPassword = targetPassword;
          _isDecrypting = false;
        });
        return;
      }

      // Gradually reveal more correct characters
      setState(() {
        final correctChars = (targetPassword.length * step / totalSteps).floor();
        String newDisplay = '';

        for (int i = 0; i < targetPassword.length; i++) {
          if (i < correctChars) {
            newDisplay += targetPassword[i];
          } else {
            newDisplay += scrambleChars[random.nextInt(scrambleChars.length)];
          }
        }
        _displayPassword = newDisplay;
      });
    });
  }

  // Determine password strength
  String _getPasswordStrength() {
    final length = _passwordLength.toInt();
    int typesCount = 0;

    if (_includeLowercase) typesCount++;
    if (_includeUppercase) typesCount++;
    if (_includeNumbers) typesCount++;
    if (_includeSpecial) typesCount++;

    if (length < 8) return 'Weak';
    if (length < 12 && typesCount <= 2) return 'Medium';
    if (length < 16 && typesCount == 3) return 'Strong';
    if (length >= 16 && typesCount >= 3) return 'Very Strong';
    return 'Strong';
  }

  // Get the color based on password strength
  Color _getStrengthColor() {
    final strength = _getPasswordStrength();
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      case 'Very Strong':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getStrengthIcon() {
    final strength = _getPasswordStrength();
    switch (strength) {
      case 'Weak':
        return Icons.shield_outlined;
      case 'Medium':
        return Icons.shield;
      case 'Strong':
        return Icons.verified;
      case 'Very Strong':
        return Icons.security;
      default:
        return Icons.help_outline;
    }
  }

  // Copy password to clipboard
  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied to clipboard')),
      );
    }
  }

  // Toggle theme mode
  void _toggleThemeMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a theme that respects the dark mode setting
    final ThemeData theme = _isDarkMode 
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return MaterialApp(
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
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.lock, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Locksmith',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleThemeMode,
              tooltip: _isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            ),
          ],
        ),
        backgroundColor: colorScheme.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                colorScheme.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Password display card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStrengthColor().withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStrengthIcon(),
                                        color: _getStrengthColor(),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getPasswordStrength(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _getStrengthColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _copyToClipboard,
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy to clipboard',
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.primaryContainer,
                                    foregroundColor: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _getStrengthColor().withOpacity(0.5),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Text(
                                _generatedPassword.isEmpty
                                    ? 'Select options to generate password'
                                    : _displayPassword,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Length slider
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.straighten,
                                        color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Password Length',
                                      style: textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _passwordLength.toInt().toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: colorScheme.primary,
                                inactiveTrackColor:
                                    colorScheme.primary.withOpacity(0.2),
                                thumbColor: colorScheme.primary,
                                overlayColor:
                                    colorScheme.primary.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _passwordLength,
                                min: 1,
                                max: 30,
                                divisions: 29,
                                label: _passwordLength.toInt().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _passwordLength = value;
                                  });
                                  _generatePassword();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Character options
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.category, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Character Types',
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildCheckboxTile(
                                'Lowercase (a-z)',
                                _includeLowercase,
                                Icons.text_fields,
                                colorScheme, (value) {
                              setState(() {
                                _includeLowercase = value ?? false;
                              });
                              _generatePassword();
                            }),
                            _buildCheckboxTile(
                                'Uppercase (A-Z)',
                                _includeUppercase,
                                Icons.title,
                                colorScheme, (value) {
                              setState(() {
                                _includeUppercase = value ?? false;
                              });
                              _generatePassword();
                            }),
                            _buildCheckboxTile(
                                'Numbers (0-9)',
                                _includeNumbers,
                                Icons.numbers,
                                colorScheme, (value) {
                              setState(() {
                                _includeNumbers = value ?? false;
                              });
                              _generatePassword();
                            }),
                            _buildCheckboxTile(
                                'Special (!@#\$...)',
                                _includeSpecial,
                                Icons.star,
                                colorScheme, (value) {
                              setState(() {
                                _includeSpecial = value ?? false;
                              });
                              _generatePassword();
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Generate button
                    ElevatedButton.icon(
                      onPressed: _isDecrypting ? null : _generatePassword,
                      icon: _isDecrypting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isDecrypting ? 'Decrypting...' : 'Generate New Password',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),

                    // Add footer
                    const SizedBox(height: 20),
                    Text(
                      'Made by Uriel',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Bottom padding for scrolling
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(
    String label,
    bool value,
    IconData icon,
    ColorScheme colorScheme,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: colorScheme.primary,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
