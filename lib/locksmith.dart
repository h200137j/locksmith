import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

class LocksmithApp extends StatefulWidget {
  const LocksmithApp({super.key});

  @override
  State<LocksmithApp> createState() => _LocksmithAppState();
}

class _LocksmithAppState extends State<LocksmithApp>
    with SingleTickerProviderStateMixin {
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

  // Password visibility
  bool _passwordVisible = true;

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
    const scrambleChars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_=+[]{}|;:,.<>?/';
    final random = Random();
    int step = 0;
    final totalSteps = 8; // Number of animation steps

    // Start with random characters
    setState(() {
      _displayPassword =
          List.generate(
            targetPassword.length,
            (_) => scrambleChars[random.nextInt(scrambleChars.length)],
          ).join();
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
        final correctChars =
            (targetPassword.length * step / totalSteps).floor();
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

  // Calculate password strength score (0-100)
  int _calculatePasswordStrengthScore() {
    final length = _passwordLength.toInt();
    String charset = '';
    int typesCount = 0;
    int baseScore = 0;

    // Count character types
    if (_includeLowercase) {
      charset += _lowercase;
      typesCount++;
    }

    if (_includeUppercase) {
      charset += _uppercase;
      typesCount++;
    }

    if (_includeNumbers) {
      charset += _numbers;
      typesCount++;
    }

    if (_includeSpecial) {
      charset += _special;
      typesCount++;
    }

    // No characters selected
    if (typesCount == 0) return 0;

    // Base score calculation
    // Length contribution (up to 60 points)
    if (length <= 4) {
      baseScore += length * 3; // 3 points per character
    } else if (length <= 8) {
      baseScore +=
          12 + (length - 4) * 4; // 12 + 4 points per additional character
    } else if (length <= 16) {
      baseScore +=
          28 + (length - 8) * 3; // 28 + 3 points per additional character
    } else {
      baseScore +=
          52 + (length - 16); // 52 + 1 point per additional character, max 60
      baseScore = baseScore > 60 ? 60 : baseScore;
    }

    // Character set diversity (up to 40 points)
    baseScore += typesCount * 10;

    // Analyze actual password content for bonus/penalty if password is generated
    if (_generatedPassword.isNotEmpty) {
      // Entropy bonus (up to +10)
      final double entropy = _calculateEntropy(_generatedPassword);
      if (entropy > 3.5) baseScore += 5;
      if (entropy > 4.0) baseScore += 5;

      // Pattern penalties
      if (_hasRepeatingPatterns(_generatedPassword)) {
        baseScore -= 10;
      }

      // Consecutive character penalties
      if (_hasConsecutiveCharacters(_generatedPassword)) {
        baseScore -= 5;
      }
    }

    // Ensure score is within 0-100 range
    return baseScore < 0 ? 0 : (baseScore > 100 ? 100 : baseScore);
  }

  // Calculate entropy of password (character diversity)
  double _calculateEntropy(String password) {
    if (password.isEmpty) return 0;

    Map<String, int> charFrequency = {};
    for (int i = 0; i < password.length; i++) {
      final char = password[i];
      charFrequency[char] = (charFrequency[char] ?? 0) + 1;
    }

    double entropy = 0;
    for (final entry in charFrequency.entries) {
      final probability = entry.value / password.length;
      entropy -= probability * (log(probability) / ln2);
    }

    return entropy;
  }

  // Check for repeating patterns
  bool _hasRepeatingPatterns(String password) {
    if (password.length < 6) return false;

    // Check for repeating patterns of length 2-3
    for (int patternLength = 2; patternLength <= 3; patternLength++) {
      for (int i = 0; i <= password.length - patternLength * 2; i++) {
        final pattern = password.substring(i, i + patternLength);
        final nextChars = password.substring(
          i + patternLength,
          i + patternLength * 2,
        );
        if (pattern == nextChars) return true;
      }
    }

    return false;
  }

  // Check for consecutive characters
  bool _hasConsecutiveCharacters(String password) {
    if (password.length < 3) return false;

    for (int i = 0; i < password.length - 2; i++) {
      final c1 = password.codeUnitAt(i);
      final c2 = password.codeUnitAt(i + 1);
      final c3 = password.codeUnitAt(i + 2);

      // Check for ascending or descending sequences
      if ((c1 + 1 == c2 && c2 + 1 == c3) || (c1 - 1 == c2 && c2 - 1 == c3)) {
        return true;
      }
    }

    return false;
  }

  // Determine password strength category based on score
  String _getPasswordStrength() {
    final score = _calculatePasswordStrengthScore();

    if (score < 20) return 'Critical';
    if (score < 35) return 'Very Weak';
    if (score < 50) return 'Weak';
    if (score < 65) return 'Moderate';
    if (score < 80) return 'Good';
    if (score < 90) return 'Strong';
    if (score < 100) return 'Very Strong';
    return 'Fortified';
  }

  // Get the color based on password strength
  Color _getStrengthColor() {
    final score = _calculatePasswordStrengthScore();

    if (score < 20) return Colors.grey.shade800;
    if (score < 35) return Colors.redAccent.shade700;
    if (score < 50) return Colors.red;
    if (score < 65) return Colors.orange;
    if (score < 80) return Colors.amber;
    if (score < 90) return Colors.green;
    if (score < 100) return Colors.blue.shade700;
    return Colors.deepPurple;
  }

  IconData _getStrengthIcon() {
    final strength = _getPasswordStrength();
    switch (strength) {
      case 'Critical':
        return Icons.dangerous;
      case 'Very Weak':
        return Icons.no_encryption;
      case 'Weak':
        return Icons.shield_outlined;
      case 'Moderate':
        return Icons.shield;
      case 'Good':
        return Icons.verified_outlined;
      case 'Strong':
        return Icons.verified;
      case 'Very Strong':
        return Icons.security;
      case 'Fortified':
        return Icons.gpp_good;
      default:
        return Icons.help_outline;
    }
  }

  // Add this method to get a human-readable description of password strength
  String _getStrengthDescription() {
    final strength = _getPasswordStrength();
    switch (strength) {
      case 'Critical':
        return 'Can be cracked instantly';
      case 'Very Weak':
        return 'Extremely vulnerable to brute force attacks';
      case 'Weak':
        return 'Could be cracked within minutes';
      case 'Moderate':
        return 'Provides basic protection for non-critical accounts';
      case 'Good':
        return 'Would take considerable effort to crack';
      case 'Strong':
        return 'Highly resistant to common cracking methods';
      case 'Very Strong':
        return 'Extremely difficult to compromise';
      case 'Fortified':
        return 'Virtually impenetrable with current technology';
      default:
        return '';
    }
  }

  // Get estimated time to crack based on strength score
  String _getTimeToCrack() {
    final score = _calculatePasswordStrengthScore();

    if (score < 20) return 'Instantly';
    if (score < 35) return 'Minutes to hours';
    if (score < 50) return 'Hours to days';
    if (score < 65) return 'Days to weeks';
    if (score < 80) return 'Weeks to months';
    if (score < 90) return 'Months to years';
    if (score < 100) return 'Many years';
    return 'Eons';
  }

  // Get the progress value (0.0 to 1.0) for the strength indicator
  double _getStrengthProgress() {
    return _calculatePasswordStrengthScore() / 100;
  }

  // Copy password to clipboard
  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Password copied to clipboard'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Toggle theme mode
  void _toggleThemeMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Material 3 theme
    final ThemeData theme =
        _isDarkMode
            ? ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.tealAccent,
            )
            : ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorSchemeSeed: Colors.teal,
            );

    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lock, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Locksmith',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          centerTitle: false,
          scrolledUnderElevation: 0,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          actions: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(_isDarkMode),
                icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleThemeMode,
                tooltip:
                    _isDarkMode
                        ? 'Switch to light mode'
                        : 'Switch to dark mode',
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Password display card with Material 3 styling
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    color: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStrengthColor().withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStrengthIcon(),
                                      color: _getStrengthColor(),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
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
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _togglePasswordVisibility,
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    tooltip:
                                        _passwordVisible
                                            ? 'Hide password'
                                            : 'Show password',
                                    style: IconButton.styleFrom(
                                      foregroundColor:
                                          colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _copyToClipboard,
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy to clipboard',
                                    style: IconButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Add a description of the password strength
                          if (_generatedPassword.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                _getStrengthDescription(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (_generatedPassword.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _getStrengthProgress(),
                                          backgroundColor:
                                              colorScheme.surfaceVariant,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _getStrengthColor(),
                                              ),
                                          minHeight: 8,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Fix the overflowing row by replacing with a more flexible layout
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            'Est. crack time: ${_getTimeToCrack()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _getStrengthColor(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 32,
                              horizontal: 24,
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(
                                0.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child:
                                _generatedPassword.isEmpty
                                    ? Text(
                                      'Select options to generate password',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontFamily: 'monospace',
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                    : Text(
                                      _passwordVisible
                                          ? _displayPassword
                                          : '•' * _displayPassword.length,
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontFamily: 'monospace',
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                        fontSize: 28,
                                      ),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Length slider with Material 3 styling
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    color: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Password Length',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _passwordLength.toInt().toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.surfaceVariant,
                              thumbColor: colorScheme.primary,
                              overlayColor: colorScheme.primary.withOpacity(
                                0.12,
                              ),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                                elevation: 2,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
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
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1', style: textTheme.bodySmall),
                              Text('30', style: textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Character options with Material 3 styling
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    color: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Character Types',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSwitchTile(
                            'Lowercase (a-z)',
                            _includeLowercase,
                            Icons.text_fields,
                            colorScheme,
                            (value) {
                              setState(() {
                                _includeLowercase = value ?? false;
                              });
                              _generatePassword();
                            },
                          ),
                          _buildSwitchTile(
                            'Uppercase (A-Z)',
                            _includeUppercase,
                            Icons.title,
                            colorScheme,
                            (value) {
                              setState(() {
                                _includeUppercase = value ?? false;
                              });
                              _generatePassword();
                            },
                          ),
                          _buildSwitchTile(
                            'Numbers (0-9)',
                            _includeNumbers,
                            Icons.numbers,
                            colorScheme,
                            (value) {
                              setState(() {
                                _includeNumbers = value ?? false;
                              });
                              _generatePassword();
                            },
                          ),
                          _buildSwitchTile(
                            'Special (!@#\$...)',
                            _includeSpecial,
                            Icons.star,
                            colorScheme,
                            (value) {
                              setState(() {
                                _includeSpecial = value ?? false;
                              });
                              _generatePassword();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Generate button with Material 3 styling
                  FilledButton.icon(
                    onPressed: _isDecrypting ? null : _generatePassword,
                    icon:
                        _isDecrypting
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                            : const Icon(Icons.refresh),
                    label: Text(
                      _isDecrypting ? 'Decrypting...' : 'Generate New Password',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  // Add footer
                  const SizedBox(height: 32),
                  Text(
                    'Locksmith by Uriel',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Bottom padding for scrolling
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isDecrypting ? null : _generatePassword,
          tooltip: 'Generate Password',
          child: const Icon(Icons.bolt),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String label,
    bool value,
    IconData icon,
    ColorScheme colorScheme,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
        activeColor: colorScheme.primary,
        activeTrackColor: colorScheme.primaryContainer,
        inactiveTrackColor: colorScheme.surfaceVariant,
        inactiveThumbColor: colorScheme.outline,
      ),
    );
  }
}

// Math constants for entropy calculation
const double ln2 = 0.693147180559945;
