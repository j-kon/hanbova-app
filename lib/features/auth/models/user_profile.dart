class UserProfile {
  final String id;
  final String username;
  final String handle;
  final String email;
  final String firstName;
  final String lastName;
  final String displayName;
  final String? phone;
  final bool emailVerified;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.handle,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.phone,
    required this.emailVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      handle: json['handle'] as String? ?? '@${json['username']}',
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['username'] as String,
      phone: json['phone'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'handle': handle,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'phone': phone,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
