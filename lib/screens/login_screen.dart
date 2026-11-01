import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/sweet_alert.dart';

class LoginScreen extends StatefulWidget {
  final Function(String username) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _performLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usernameInput = _emailController.text.trim();
      final passwordInput = _passwordController.text.trim();

      final authData = await SupabaseService.adminLogin(
        usernameOrEmail: usernameInput,
        password: passwordInput,
      );

      if (!mounted) return;

      final name = authData['name']?.toString() ?? 'Admin User';

      await SweetAlert.showSuccess(
        context,
        'Welcome back, $name! Authenticated successfully.',
        title: 'Login Successful',
      );

      if (!mounted) return;
      widget.onLoginSuccess(name);
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
      SweetAlert.showError(
        context,
        msg,
        title: 'Login Failed',
      );
    }
  }

  void _showForgotPasswordModal() {
    final TextEditingController resetEmailController =
        TextEditingController(text: _emailController.text);
    bool isSending = false;
    String? modalError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: const Color(0xE60A3052),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x3838BDF8), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0x260284C7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0x4038BDF8)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF38BDF8), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Reset Admin Password',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close, size: 20, color: Color(0xFF7DD3FC)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const Divider(height: 28, color: Color(0x3838BDF8)),
                          const Text(
                            'Enter your registered admin email address to receive password reset instructions.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF93C5FD), height: 1.5),
                          ),
                          const SizedBox(height: 20),

                          if (modalError != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0x38EF4444),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x66EF4444)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFFCA5A5)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      modalError!,
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const Text(
                            'REGISTERED EMAIL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFF7DD3FC),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: resetEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'admin@aquasync.com',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF7DD3FC)),
                              filled: true,
                              fillColor: const Color(0x380A3052),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x3838BDF8)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0x3838BDF8)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                              ),
                            ),
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: isSending
                                    ? null
                                    : () async {
                                        final email = resetEmailController.text.trim();
                                        if (email.isEmpty || !email.contains('@')) {
                                          setModalState(() {
                                            modalError = 'Please enter a valid email format.';
                                          });
                                          return;
                                        }

                                        setModalState(() {
                                          isSending = true;
                                          modalError = null;
                                        });

                                        try {
                                          await SupabaseService.resetPasswordForEmail(email);
                                          if (!context.mounted) return;
                                          Navigator.of(context).pop();
                                          SweetAlert.showSuccess(
                                            context,
                                            'Password reset link sent! Please check your inbox.',
                                            title: 'Reset Email Sent',
                                          );
                                        } catch (e) {
                                          setModalState(() {
                                            isSending = false;
                                            String errStr = e.toString();
                                            errStr = errStr.replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
                                            modalError = errStr;
                                          });
                                        }
                                      },
                                icon: isSending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Send Reset Link', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF031B33),
              Color(0xFF0A3052),
              Color(0xFF021224),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Subtle Radial Decorative Blue Circles
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 520,
                height: 520,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: 180,
              child: Container(
                width: 650,
                height: 650,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0369A1).withValues(alpha: 0.10),
                ),
              ),
            ),

            // Main Content Row
            Row(
              children: [
                // Left Column - Branding (Hidden on mobile)
                if (MediaQuery.of(context).size.width >= 900)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AnimatedWaterDropLogo(),
                          const SizedBox(height: 28),
                          const Text(
                            'AquaSync\nAdmin Control Center',
                            style: TextStyle(
                              fontSize: 42,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aqua Pure Water Station',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFBAE6FD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Central master control center for station operations. Monitor realtime orders, assign drivers, manage master product catalog, and track reusable gallon containers.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF93C5FD),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildFeatureChip(Icons.cloud_outlined, 'Realtime Sync'),
                              _buildFeatureChip(Icons.security_rounded, 'Secure Auth'),
                              _buildFeatureChip(Icons.analytics_outlined, 'Live Analytics'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Right Column - Frosted Blue Glass Login Card
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x28074163),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x3838BDF8), width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 32,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(36),
                              child: _buildLoginForm(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x260284C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4038BDF8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7DD3FC)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE0F2FE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.of(context).size.width < 900) ...[
            const _AnimatedWaterDropLogo(),
            const SizedBox(height: 24),
          ],

          const Text(
            'Admin Login',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your master credentials to access the AquaSync Admin Control Center.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF93C5FD),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x38EF4444),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66EF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFCA5A5), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'EMAIL ADDRESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFF7DD3FC),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'admin@aquasync.com',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF7DD3FC)),
              filled: true,
              fillColor: const Color(0x380A3052),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x3838BDF8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x3838BDF8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Email is required';
              if (!val.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),

          const Text(
            'PASSWORD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFF7DD3FC),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF7DD3FC)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF7DD3FC),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0x380A3052),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x3838BDF8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x3838BDF8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Password is required';
              return null;
            },
            onFieldSubmitted: (_) => _performLogin(),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF0284C7),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF7DD3FC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember session',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF93C5FD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showForgotPasswordModal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _performLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: const Color(0x400284C7),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'LOG IN TO CONTROL CENTER',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 28),

          const Center(
            child: Text(
              'Authorized Admin Access Only',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWaterDropLogo extends StatefulWidget {
  const _AnimatedWaterDropLogo();

  @override
  State<_AnimatedWaterDropLogo> createState() => _AnimatedWaterDropLogoState();
}

class _AnimatedWaterDropLogoState extends State<_AnimatedWaterDropLogo> with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rippleController, _floatController]),
        builder: (context, child) {
          final rippleVal = _rippleController.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Water Ripple 2
              Transform.scale(
                scale: 1.0 + (0.55 * ((rippleVal + 0.5) % 1.0)),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(
                        alpha: (1.0 - ((rippleVal + 0.5) % 1.0)) * 0.45,
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Outer Water Ripple 1
              Transform.scale(
                scale: 1.0 + (0.55 * rippleVal),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(
                        alpha: (1.0 - rippleVal) * 0.55,
                      ),
                      width: 2.0,
                    ),
                  ),
                ),
              ),

              // Main Floating Water Logo Card
              Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF0284C7),
                    size: 34,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
