class UserUpdateRequest {
  final String? nombre;
  final String? email;
  final String? rol;
  final bool? isVerified;
  final bool? isActive;
  final bool? isSuspended;
  final String? phone;
  final String? apellido;

  UserUpdateRequest({
    this.nombre,
    this.email,
    this.rol,
    this.isVerified,
    this.isActive,
    this.isSuspended,
    this.phone,
    this.apellido,
  });

  // Alias para mantener compatibilidad si se recibe 'name'
  String? get name => nombre;

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) =>
      UserUpdateRequest(
        nombre: (json['nombre'] ?? json['name']) as String?,
        email: json['email'] as String?,
        rol: json['rol'] as String?,
        isVerified: json['is_verified'] as bool?,
        isActive: json['is_active'] as bool?,
        isSuspended: json['is_suspended'] as bool?,
        phone: json['phone'] as String?,
        apellido: json['apellido'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (email != null) 'email': email,
        if (rol != null) 'rol': rol,
        if (isVerified != null) 'is_verified': isVerified,
        if (isActive != null) 'is_active': isActive,
        if (isSuspended != null) 'is_suspended': isSuspended,
        if (phone != null) 'phone': phone,
        if (apellido != null) 'apellido': apellido,
      };
}
