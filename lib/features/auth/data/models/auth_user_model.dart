import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.hasPin,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: _stringValue(json['id'] ?? json['_id'], 'id'),
      name: _stringValue(json['name'], 'name'),
      email: _stringValue(json['email'], 'email'),
      role: _stringValue(json['role'], 'role'),
      hasPin: json['has_pin'] == true,
    );
  }

  static String _stringValue(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Data profil tidak memiliki $field yang valid.');
  }
}
