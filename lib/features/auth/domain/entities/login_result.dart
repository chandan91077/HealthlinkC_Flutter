import 'auth_user.dart';

class LoginResult {
  final String token;
  final String role;
  final AuthUser user;

  const LoginResult({
    required this.token,
    required this.role,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final role = (json['role']?.toString() ?? '').trim().toLowerCase();
    final token = json['token']?.toString() ?? '';
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    if (token.isEmpty || (role != 'doctor' && role != 'patient')) {
      throw const FormatException('Invalid login response payload');
    }

    return LoginResult(
      token: token,
      role: role,
      user: AuthUser.fromJson(userMap, role),
    );
  }
}
