class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.hasPin,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool hasPin;
}
