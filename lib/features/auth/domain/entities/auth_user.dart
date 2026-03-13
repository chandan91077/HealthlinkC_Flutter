class AuthNotificationPreferences {
  final bool email;
  final bool push;
  final bool videoCalls;
  final bool appointments;

  const AuthNotificationPreferences({
    required this.email,
    required this.push,
    required this.videoCalls,
    required this.appointments,
  });

  factory AuthNotificationPreferences.fromJson(Map<String, dynamic>? json) {
    return AuthNotificationPreferences(
      email: json?['email'] == true,
      push: json?['push'] == true,
      videoCalls: json?['video_calls'] == true,
      appointments: json?['appointments'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'push': push,
      'video_calls': videoCalls,
      'appointments': appointments,
    };
  }

  AuthNotificationPreferences copyWith({
    bool? email,
    bool? push,
    bool? videoCalls,
    bool? appointments,
  }) {
    return AuthNotificationPreferences(
      email: email ?? this.email,
      push: push ?? this.push,
      videoCalls: videoCalls ?? this.videoCalls,
      appointments: appointments ?? this.appointments,
    );
  }
}

class AuthUser {
  final String? id;
  final String? email;
  final String? name;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String locale;
  final DateTime? createdAt;
  final AuthNotificationPreferences notificationPreferences;

  const AuthUser({
    required this.role,
    this.id,
    this.email,
    this.name,
    this.phone,
    this.avatarUrl,
    required this.locale,
    required this.notificationPreferences,
    this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json, String role) {
    return AuthUser(
      role: role,
      id: (json['_id'] ?? json['id'])?.toString(),
      email: json['email']?.toString(),
      name: json['full_name']?.toString() ?? json['name']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      locale: json['locale']?.toString() ?? 'en',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      notificationPreferences: AuthNotificationPreferences.fromJson(
        json['notification_preferences'] as Map<String, dynamic>?,
      ),
    );
  }

  AuthUser copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? locale,
    DateTime? createdAt,
    AuthNotificationPreferences? notificationPreferences,
  }) {
    return AuthUser(
      role: role,
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }
}
