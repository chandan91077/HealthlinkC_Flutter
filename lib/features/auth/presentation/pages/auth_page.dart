import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/shared/widgets/app_button.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class AuthPage extends StatefulWidget {
  final bool initialIsLogin;
  final String? initialRole;
  final bool? embeddedInShell;

  const AuthPage({
    super.key,
    this.initialIsLogin = true,
    this.initialRole,
    this.embeddedInShell = false,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool isLogin;
  String selectedRole = 'Patient';
  bool _isSubmitting = false;
  bool _hideLoginPassword = true;
  bool _hideSignUpPassword = true;
  bool _hideConfirmPassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    isLogin = widget.initialIsLogin;
    if (widget.initialRole != null) {
      final normalized = widget.initialRole!.trim().toLowerCase();
      if (normalized == 'doctor') {
        selectedRole = 'Doctor';
      } else if (normalized == 'patient') {
        selectedRole = 'Patient';
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 980;
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.embeddedInShell == true) {
      return Container(
        color: colorScheme.surface,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, isDesktop ? 46 : 24, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _buildFormPanel(context, showBackToHome: false),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const MediConnectHeader(),
      drawer: const MediConnectDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, isDesktop ? 46 : 24, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildFormPanel(context, showBackToHome: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel(
    BuildContext context, {
    required bool showBackToHome,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBackToHome) ...[
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: Icon(Icons.arrow_back,
                  size: 16, color: colorScheme.onSurfaceVariant),
              label: Text('Back to home',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 10),
          ],
          if (!showBackToHome)
            Text(
              'MediConnect',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            )
          else
            Text(
              isLogin ? 'Sign In' : 'Create Account',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
          const SizedBox(height: 22),
          _buildToggle(),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: isLogin ? _buildLoginForm() : _buildSignUpForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLogin = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isLogin
                      ? colorScheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isLogin ? FontWeight.bold : FontWeight.normal,
                    color: isLogin
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isLogin = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isLogin
                      ? colorScheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: !isLogin ? FontWeight.bold : FontWeight.normal,
                    color: !isLogin
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Sign in to continue your care journey.',
            style: TextStyle(color: colorScheme.onSurface)),
        const SizedBox(height: 24),
        _buildTextField(
          'Email',
          'you@example.com',
          prefixIcon: Icons.mail_outline,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Password',
          '••••••••',
          obscureText: _hideLoginPassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _hideLoginPassword ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              setState(() => _hideLoginPassword = !_hideLoginPassword);
            },
          ),
          controller: _passwordController,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isSubmitting ? null : _handleForgotPassword,
            child: const Text('Forgot Password?'),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isSubmitting
                ? null
                : () => context.push(AppRoutes.resetPassword),
            child: const Text('Already have token? Reset now'),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Login',
            onPressed: _handleLogin,
            isLoading: authProvider.isLoading,
          ),
        ),
        const SizedBox(height: 16),
        _buildGoogleDivider(),
        const SizedBox(height: 16),
        _buildGoogleButton(role: 'patient'),
      ],
    );
  }

  Widget _buildSignUpForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create Account',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Join as patient or doctor in just a few steps.',
            style: TextStyle(color: colorScheme.onSurface)),
        const SizedBox(height: 24),
        _buildTextField(
          'Full Name',
          'John Doe',
          prefixIcon: Icons.person_outline,
          controller: _fullNameController,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Email',
          'you@example.com',
          prefixIcon: Icons.mail_outline,
          controller: _emailController,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Phone Number',
          '9682000334',
          prefixIcon: Icons.phone_outlined,
          controller: _phoneController,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Password',
          '••••••••',
          obscureText: _hideSignUpPassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _hideSignUpPassword ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              setState(() => _hideSignUpPassword = !_hideSignUpPassword);
            },
          ),
          controller: _passwordController,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          'Confirm Password',
          '••••••••',
          obscureText: _hideConfirmPassword,
          prefixIcon: Icons.lock_reset_outlined,
          suffixIcon: IconButton(
            icon: Icon(
              _hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () {
              setState(() => _hideConfirmPassword = !_hideConfirmPassword);
            },
          ),
          controller: _confirmPasswordController,
        ),
        const SizedBox(height: 18),
        Text('Join as',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildRoleCard('Patient', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(
                child:
                    _buildRoleCard('Doctor', Icons.medical_services_outlined)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Create Account',
            onPressed: _handleRegister,
            isLoading: _isSubmitting,
          ),
        ),
        const SizedBox(height: 16),
        _buildGoogleDivider(),
        const SizedBox(height: 16),
        _buildGoogleButton(role: selectedRole.toLowerCase()),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextEditingController? controller,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: colorScheme.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color: colorScheme.onSurfaceVariant, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.3),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleDivider() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outline)),
      ],
    );
  }

  Widget _buildGoogleButton({required String role}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : () => _handleGoogleSignIn(role: role),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(color: colorScheme.outline),
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.16)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : colorScheme.outline,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24),
            const SizedBox(height: 8),
            Text(
              role,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn({required String role}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.signInWithGoogle(role: role);

      if (!mounted) return;

      if (!success) {
        final msg = authProvider.errorMessage ?? 'Google Sign-In failed.';
        if (msg != 'Google Sign-In was cancelled.') {
          _showMessage(msg);
        }
        return;
      }

      final resolvedRole = authProvider.role;
      if (resolvedRole == 'patient') {
        context.go(AppRoutes.patientDashboard);
        return;
      }
      if (resolvedRole == 'doctor') {
        final userId = authProvider.user?.id?.trim() ?? '';
        if (userId.isNotEmpty) {
          final isNewProfile = await _createPendingDoctorProfile(userId);
          if (isNewProfile) {
            _showMessage(
                'Doctor account created. Waiting for admin verification.');
          }
        }
        if (!mounted) return;
        context.go(AppRoutes.doctorDashboard);
        return;
      }
      _showMessage('Unknown role returned by server.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      emailOrPhone: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success) {
      _showMessage(authProvider.errorMessage ?? 'Login failed.');
      return;
    }

    if (!mounted) {
      return;
    }

    final role = authProvider.role;
    if (role == 'patient') {
      context.go(AppRoutes.patientDashboard);
      return;
    }

    if (role == 'doctor') {
      final userId = authProvider.user?.id?.trim() ?? '';
      if (userId.isNotEmpty) {
        await _createPendingDoctorProfile(userId);
      }
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.doctorDashboard);
      return;
    }

    _showMessage('Unknown role returned by server.');
  }

  Future<void> _handleRegister() async {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill all required fields.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Password and confirm password do not match.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = sl<ApiClient>();
      final selectedRoleValue = selectedRole.toLowerCase();
      final response = await api.post(
        '/api/auth/register',
        data: {
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': selectedRoleValue,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token']?.toString() ?? '';
      final userId = data['_id']?.toString() ?? '';

      if (token.isEmpty) {
        _showMessage('Signup failed: token not received.');
        return;
      }

      await _secureStorage.write(key: 'auth_token', value: token);
      await _secureStorage.write(key: 'user_role', value: selectedRoleValue);

      if (selectedRoleValue == 'doctor' && userId.isNotEmpty) {
        await _createPendingDoctorProfile(userId);
      }

      final authProvider = sl<AuthProvider>();
      final loginSuccess = await authProvider.login(
        emailOrPhone: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!loginSuccess) {
        if (!mounted) {
          return;
        }
        _showMessage(
            authProvider.errorMessage ?? 'Account created. Please login.');
        context.go(AppRoutes.login);
        return;
      }

      if (!mounted) {
        return;
      }

      if (authProvider.role == 'doctor') {
        _showMessage('Doctor account created. Waiting for admin verification.');
        context.go(AppRoutes.doctorDashboard);
      } else if (authProvider.role == 'patient') {
        _showMessage('Account created successfully.');
        context.go(AppRoutes.patientDashboard);
      } else {
        context.go(AppRoutes.home);
      }
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final serverMessage = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString() ?? '')
          : '';
      _showMessage(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Signup failed. Try another email or check backend.',
      );
    } catch (_) {
      _showMessage('Signup failed. Try another email or check backend.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final enteredEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Forgot Password'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(emailController.text.trim()),
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (!mounted || enteredEmail == null) {
      return;
    }

    final email = enteredEmail.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await sl<ApiClient>().post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );

      if (!mounted) {
        return;
      }

      final data = response.data;
      final serverMessage = data is Map<String, dynamic>
          ? data['message']?.toString().trim() ?? ''
          : '';

      _showMessage(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'If the email exists, a reset link has been sent.',
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final responseData = error.response?.data;
      final message = responseData is Map<String, dynamic>
          ? (responseData['message']?.toString().trim() ?? '')
          : '';
      _showMessage(
        message.isNotEmpty
            ? message
            : 'Unable to process forgot password right now.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to process forgot password right now.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _createPendingDoctorProfile(String userId) async {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      return false;
    }

    final api = sl<ApiClient>();
    try {
      await api.get('/api/doctors/user/$normalizedId');
      return false;
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        return false;
      }
    } catch (_) {
      return false;
    }

    try {
      await api.post(
        '/api/doctors',
        data: {
          'user_id': normalizedId,
          'specialization': 'General Medicine',
          'experience_years': 0,
          'consultation_fee': 0,
          'emergency_fee': 0,
          'bio': '',
          'state': '',
          'location': '',
          'is_verified': false,
          'verification_status': 'pending',
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
