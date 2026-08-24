import 'package:gendut_garage/models/app_role.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
  });

  final String userId;
  final String email;
  final String fullName;
  final AppRole role;
  final bool isActive;
  final bool mustChangePassword;

  UserProfile copyWith({
    String? userId,
    String? email,
    String? fullName,
    AppRole? role,
    bool? isActive,
    bool? mustChangePassword,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
    };
  }

  static UserProfile fromJson(Map<String, Object?> json) {
    final roleStr = (json['role'] as String?) ?? 'pelanggan';
    return UserProfile(
      userId: (json['user_id'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      role: AppRoleX.tryParse(roleStr) ?? AppRole.pelanggan,
      isActive: (json['is_active'] as bool?) ?? true,
      mustChangePassword: (json['must_change_password'] as bool?) ?? false,
    );
  }
}

