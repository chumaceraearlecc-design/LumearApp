import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color darkMaroon = Color(0xFF62191C);
  static const Color maroon = Color(0xFF873632);
  static const Color brownBeige = Color(0xFF9E7161);
  static const Color lightBeige = Color(0xFFCAAE9F);
  static const Color cream = Color(0xFFE0CFC2);

  // Success color that matches the warm theme
  static const Color successColor = Color(0xFFB88A5A);

  // Muted error color
  static const Color errorColor = Color(0xFF9B4A47);

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;
  bool _useEmail = true;

  // 0 = Enter Email / Phone
  // 1 = OTP Verification
  // 2 = Create New Password
  // 3 = Password Changed
  int _step = 0;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _otpChecking = false;
  bool _otpVerified = false;
  bool _otpError = false;

  double _verifyButtonOffset = 0;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  OverlayEntry? _topNotificationEntry;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final node in _otpFocusNodes) {
      node.dispose();
    }

    _topNotificationEntry?.remove();

    super.dispose();
  }

  // ============================================================
  // NOTIFICATION
  // ============================================================

  void _showTopNotification(
    String message, {
    IconData? icon,
    Color? backgroundColor,
  }) {
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -30 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor ?? darkMaroon,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon ?? Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _topNotificationEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      if (_topNotificationEntry == entry) {
        entry.remove();
        _topNotificationEntry = null;
      }
    });
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return regex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    return digits.length == 10 && digits.startsWith('9');
  }

  // ============================================================
  // RESET OTP
  // ============================================================

  void _resetOtpState() {
    _otpChecking = false;
    _otpVerified = false;
    _otpError = false;
    _verifyButtonOffset = 0;
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  // ============================================================
  // SEND CODE
  // ============================================================

  Future<void> _sendVerificationCode() async {
    FocusScope.of(context).unfocus();

    if (_useEmail) {
      final email = _emailController.text.trim();

      if (email.isEmpty) {
        _showTopNotification(
          'Please enter your registered email.',
          icon: Icons.email_outlined,
        );
        return;
      }

      if (!_isValidEmail(email)) {
        _showTopNotification(
          'Please enter a valid email address.',
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
    } else {
      final phone = _phoneController.text.trim();

      if (phone.isEmpty) {
        _showTopNotification(
          'Please enter your registered phone number.',
          icon: Icons.phone_outlined,
        );
        return;
      }

      if (!_isValidPhone(phone)) {
        _showTopNotification(
          'Enter a valid PH mobile number.',
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // DEMO ONLY
    // Replace this with your real backend later.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _resetOtpState();
      _clearOtp();
      _step = 1;
    });

    _showTopNotification(
      _useEmail
          ? 'Verification code sent to your email.'
          : 'Verification code sent to your phone.',
      icon: _useEmail ? Icons.mark_email_read_outlined : Icons.sms_outlined,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  // ============================================================
  // RESEND CODE
  // ============================================================

  Future<void> _resendCode() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _resetOtpState();
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _clearOtp();
    });

    _showTopNotification(
      _useEmail
          ? 'A new code was sent to your email.'
          : 'A new code was sent to your phone.',
      icon: _useEmail ? Icons.email_outlined : Icons.sms_outlined,
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  // ============================================================
  // SHAKE BUTTON
  // ============================================================

  Future<void> _shakeVerifyButton() async {
    const positions = <double>[-12, 12, -10, 10, -7, 7, -4, 4, 0];

    for (final position in positions) {
      if (!mounted) return;

      setState(() {
        _verifyButtonOffset = position;
      });

      await Future.delayed(const Duration(milliseconds: 45));
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 4) {
      setState(() {
        _otpError = true;
      });

      await _shakeVerifyButton();

      if (!mounted) return;

      _showTopNotification(
        'Please enter the complete 4-digit code.',
        icon: Icons.warning_amber_rounded,
        backgroundColor: errorColor,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _otpError = false;
      });

      return;
    }

    // Start verification animation
    setState(() {
      _otpChecking = true;
      _otpError = false;
      _otpVerified = false;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    // DEMO OTP ONLY
    // Replace with backend verification later.
    if (otp != '1234') {
      setState(() {
        _otpChecking = false;
        _otpError = true;
      });

      await _shakeVerifyButton();

      if (!mounted) return;

      _showTopNotification(
        'Incorrect verification code.',
        icon: Icons.close_rounded,
        backgroundColor: errorColor,
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      setState(() {
        _otpError = false;
      });

      return;
    }

    // Correct OTP
    setState(() {
      _otpChecking = false;
      _otpVerified = true;
    });

    _showTopNotification(
      'Code verified successfully.',
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: successColor,
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _step = 2;
    });
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    final password = _newPasswordController.text.trim();

    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      _showTopNotification(
        'Please enter your new password.',
        icon: Icons.lock_outline,
      );
      return;
    }

    if (password.length < 6) {
      _showTopNotification(
        'Password must contain at least 6 characters.',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showTopNotification(
        'Please confirm your new password.',
        icon: Icons.lock_reset_outlined,
      );
      return;
    }

    if (password != confirmPassword) {
      _showTopNotification(
        'Passwords do not match.',
        icon: Icons.warning_amber_rounded,
        backgroundColor: errorColor,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // DEMO ONLY
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _step = 3;
    });
  }

  // ============================================================
  // SWITCH EMAIL / PHONE
  // ============================================================

  void _switchMethod(bool useEmail) {
    if (_isLoading) return;

    setState(() {
      _useEmail = useEmail;
      _step = 0;
      _resetOtpState();
      _clearOtp();
    });
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: brownBeige, fontSize: 13),
      prefixIcon: Icon(icon, color: maroon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.65),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: maroon, width: 2),
      ),
    );
  }

  // ============================================================
  // METHOD SELECTOR
  // ============================================================

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: lightBeige.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _methodButton(
              title: 'Email',
              icon: Icons.email_outlined,
              selected: _useEmail,
              onTap: () {
                _switchMethod(true);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _methodButton(
              title: 'Phone',
              icon: Icons.phone_outlined,
              selected: !_useEmail,
              onTap: () {
                _switchMethod(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? darkMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: selected ? Colors.white : darkMaroon),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : darkMaroon,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHONE FIELD
  // ============================================================

  Widget _buildPhoneField() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.phone_outlined, color: maroon, size: 22),
          const SizedBox(width: 12),
          const Text(
            '+63',
            style: TextStyle(
              color: darkMaroon,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 25,
            color: brownBeige.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(color: darkMaroon, fontSize: 14),
              decoration: const InputDecoration(
                hintText: '9123456789',
                hintStyle: TextStyle(color: brownBeige, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ============================================================
  // OTP BOX
  // ============================================================

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 58,
      height: 62,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        enabled: !_otpChecking && !_otpVerified,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: darkMaroon,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _otpVerified
              ? successColor.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.65),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: lightBeige),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: maroon, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _otpVerified ? successColor : lightBeige,
              width: _otpVerified ? 2 : 1,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _otpFocusNodes[index + 1].requestFocus();
          }

          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  // ============================================================
  // VERIFY BUTTON
  // ============================================================

  Widget _buildVerifyButton() {
    final compact = _otpChecking || _otpVerified;

    final buttonWidth = compact ? 58.0 : MediaQuery.of(context).size.width;

    Color buttonColor = darkMaroon;

    if (_otpError) {
      buttonColor = errorColor;
    }

    if (_otpVerified) {
      buttonColor = successColor;
    }

    return Center(
      child: Transform.translate(
        offset: Offset(_verifyButtonOffset, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          width: buttonWidth,
          height: 58,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(compact ? 100 : 15),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withValues(alpha: 0.25),
                blurRadius: compact ? 16 : 7,
                spreadRadius: compact ? 1 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _otpChecking || _otpVerified ? null : _verifyOtp,
              borderRadius: BorderRadius.circular(100),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _otpChecking
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : _otpVerified
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('verified'),
                          color: Colors.white,
                          size: 34,
                        )
                      : _otpError
                      ? const Icon(
                          Icons.close_rounded,
                          key: ValueKey('error'),
                          color: Colors.white,
                          size: 30,
                        )
                      : const Text(
                          'Verify Code',
                          key: ValueKey('normal'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 0 - EMAIL / PHONE
  // ============================================================

  Widget _buildRequestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMethodSelector(),

        const SizedBox(height: 24),

        Text(
          _useEmail ? 'Email Address' : 'Phone Number',
          style: const TextStyle(
            color: darkMaroon,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 8),

        if (_useEmail)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              hint: 'Enter your registered email',
              icon: Icons.email_outlined,
            ),
          )
        else
          _buildPhoneField(),

        const SizedBox(height: 12),

        Text(
          _useEmail
              ? 'We will send a 4-digit verification code to your registered email.'
              : 'We will send a 4-digit verification code to your registered phone number.',
          style: const TextStyle(color: brownBeige, fontSize: 11, height: 1.4),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkMaroon,
              foregroundColor: Colors.white,
              disabledBackgroundColor: brownBeige,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Send Verification Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 1 - OTP
  // ============================================================

  Widget _buildOtpStep() {
    final destinationText = _useEmail
        ? _emailController.text.trim()
        : '+63${_phoneController.text.trim()}';

    return Column(
      children: [
        Icon(
          _useEmail ? Icons.mark_email_read_outlined : Icons.sms_outlined,
          color: darkMaroon,
          size: 65,
        ),

        const SizedBox(height: 18),

        const Text(
          'Enter Verification Code',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _useEmail
              ? 'We sent a 4-digit verification code to\n$destinationText'
              : 'We sent a 4-digit verification code to\n$destinationText',
          textAlign: TextAlign.center,
          style: const TextStyle(color: brownBeige, fontSize: 13, height: 1.5),
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) => _buildOtpBox(index)),
        ),

        const SizedBox(height: 20),

        if (!_otpVerified)
          const Text(
            'For testing, use code: 1234',
            style: TextStyle(color: brownBeige, fontSize: 11),
          ),

        const SizedBox(height: 8),

        if (!_otpChecking && !_otpVerified)
          TextButton(
            onPressed: _isLoading ? null : _resendCode,
            child: Text(
              _useEmail
                  ? "Didn't receive the email code? Resend"
                  : "Didn't receive the SMS code? Resend",
              style: const TextStyle(
                color: darkMaroon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const SizedBox(height: 18),

        _buildVerifyButton(),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _otpVerified
              ? Container(
                  key: const ValueKey('verified-message'),
                  margin: const EdgeInsets.only(top: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: successColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: successColor,
                        size: 21,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Code verified successfully',
                        style: TextStyle(
                          color: successColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        if (!_otpChecking && !_otpVerified) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _step = 0;
                _resetOtpState();
                _clearOtp();
              });
            },
            icon: const Icon(Icons.edit_outlined, color: darkMaroon, size: 18),
            label: Text(
              _useEmail ? 'Change email address' : 'Change phone number',
              style: const TextStyle(
                color: darkMaroon,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // STEP 2 - NEW PASSWORD
  // ============================================================

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(Icons.lock_reset_outlined, color: darkMaroon, size: 70),
        ),

        const SizedBox(height: 18),

        const Center(
          child: Text(
            'Create New Password',
            style: TextStyle(
              color: darkMaroon,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            'Create a new password for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: brownBeige, fontSize: 13, height: 1.4),
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'New Password',
          style: TextStyle(color: darkMaroon, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            hint: 'Enter new password',
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: maroon,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Confirm Password',
          style: TextStyle(color: darkMaroon, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: _inputDecoration(
            hint: 'Confirm new password',
            icon: Icons.lock_reset_outlined,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: maroon,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkMaroon,
              foregroundColor: Colors.white,
              disabledBackgroundColor: brownBeige,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 3 - SUCCESS
  // ============================================================

  Widget _buildSuccessStep() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: successColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
        ),

        const SizedBox(height: 24),

        const Text(
          'Password Changed',
          style: TextStyle(
            color: darkMaroon,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Your password has been changed successfully. You can now log in using your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: brownBeige, fontSize: 13, height: 1.5),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: darkMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (_step) {
      case 1:
        content = _buildOtpStep();
        break;

      case 2:
        content = _buildNewPasswordStep();
        break;

      case 3:
        content = _buildSuccessStep();
        break;

      default:
        content = _buildRequestStep();
    }

    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: darkMaroon,
        leading: IconButton(
          onPressed: () {
            if (_otpChecking || _otpVerified) {
              return;
            }

            if (_step == 0) {
              Navigator.pop(context);
            } else if (_step == 1) {
              setState(() {
                _step = 0;
                _resetOtpState();
                _clearOtp();
              });
            } else if (_step == 2) {
              setState(() {
                _step = 1;
                _resetOtpState();
                _clearOtp();
              });
            }
          },
          icon: const Icon(Icons.arrow_back, color: darkMaroon),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: darkMaroon, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              if (_step == 0) ...[
                const Center(
                  child: Icon(
                    Icons.lock_reset_outlined,
                    color: darkMaroon,
                    size: 70,
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Reset Your Password',
                    style: TextStyle(
                      color: darkMaroon,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Choose where you want to receive your verification code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: brownBeige, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 30),
              ],

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
                child: Container(key: ValueKey(_step), child: content),
              ),

              const SizedBox(height: 24),

              if (_step == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Remember your password?',
                      style: TextStyle(color: brownBeige),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: darkMaroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
