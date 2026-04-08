int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? _toIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final String roleDisplayName;
  final String? department;
  final bool isActive;
  final String? dateJoined;
  final UserProfile? profile;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    required this.roleDisplayName,
    this.department,
    required this.isActive,
    this.dateJoined,
    this.profile,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'sales_rep',
      roleDisplayName: json['role_display_name'] ?? json['role'] ?? '',
      department: json['department'],
      isActive: json['is_active'] ?? true,
      dateJoined: json['date_joined'],
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'role': role,
    'department': department,
    'is_active': isActive,
  };

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isManager => role == 'sales_manager' || isAdmin;
}

class UserProfile {
  final int? id;
  final String? bio;
  final String? avatar;
  final String? timezone;
  final String? language;

  UserProfile({this.id, this.bio, this.avatar, this.timezone, this.language});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _toIntNullable(json['id']),
      bio: json['bio'],
      avatar: json['avatar'],
      timezone: json['timezone'],
      language: json['language'],
    );
  }
}
