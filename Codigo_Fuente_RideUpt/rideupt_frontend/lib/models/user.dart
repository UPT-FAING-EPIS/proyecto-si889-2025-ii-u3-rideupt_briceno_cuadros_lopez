// lib/models/user.dart
import 'driver_document.dart';

class Vehicle {
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final int totalSeats; // NUEVO: Total de asientos del vehículo

  Vehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.totalSeats,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      color: json['color'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      totalSeats: json['totalSeats'] ?? 4, // Por defecto 4 asientos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'totalSeats': totalSeats,
    };
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isAdmin; // Campo para verificar si es administrador
  final String phone;
  final String university;
  final String studentId; // NUEVO: Código de estudiante
  final String profilePhoto; // NUEVO: URL de foto de perfil
  final int? age; // NUEVO: Edad (opcional)
  final String? gender; // NUEVO: Sexo (opcional)
  final String? bio; // NUEVO: Biografía (opcional)
  final Vehicle? vehicle;
  final List<DriverDocument> driverDocuments; // Documentos del conductor
  final double averageRating; // NUEVO: Promedio de calificaciones
  final int totalRatings; // NUEVO: Total de calificaciones
  final String? driverApprovalStatus; // Estado de aprobación: 'pending', 'approved', 'rejected'
  final String? driverRejectionReason; // Razón de rechazo (si aplica)

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.isAdmin = false,
    required this.phone,
    required this.university,
    required this.studentId,
    this.profilePhoto = 'default_avatar.png',
    this.age,
    this.gender,
    this.bio,
    this.vehicle,
    this.driverDocuments = const [],
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.driverApprovalStatus,
    this.driverRejectionReason,
  });

  /// Obtiene el nombre completo del usuario
  String get fullName => '$firstName $lastName';

  /// Obtiene las iniciales del usuario
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  /// Verifica si es conductor
  bool get isDriver => role == 'driver';

  /// Verifica si es pasajero
  bool get isPassenger => role == 'passenger';

  /// Verifica si es administrador (usa el campo isAdmin directamente)

  /// Verifica si el conductor está aprobado
  bool get isDriverApproved => driverApprovalStatus == 'approved';

  /// Verifica si el conductor está pendiente de aprobación
  bool get isDriverPending => driverApprovalStatus == 'pending';

  /// Verifica si el conductor fue rechazado
  bool get isDriverRejected => driverApprovalStatus == 'rejected';

  /// Verifica si el perfil está completo
  bool get isProfileComplete {
    return phone != 'Pendiente' && 
           phone.isNotEmpty && 
           age != null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? 'Usuario',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'passenger',
      isAdmin: json['isAdmin'] ?? false,
      phone: json['phone'] ?? 'Pendiente',
      university: json['university'] ?? 'UPT',
      studentId: json['studentId'] ?? _extractStudentIdFromEmail(json['email'] ?? ''),
      profilePhoto: json['profilePhoto'] ?? 'default_avatar.png',
      age: json['age'],
      gender: json['gender'],
      bio: json['bio'],
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
      driverDocuments: json['driverDocuments'] != null
          ? (json['driverDocuments'] as List)
              .map((doc) => DriverDocument.fromJson(doc))
              .toList()
          : [],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
      driverApprovalStatus: json['driverApprovalStatus'],
      driverRejectionReason: json['driverRejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'isAdmin': isAdmin,
      'phone': phone,
      'university': university,
      'studentId': studentId,
      'profilePhoto': profilePhoto,
      'age': age,
      'gender': gender,
      'bio': bio,
      'vehicle': vehicle?.toJson(),
      'driverDocuments': driverDocuments.map((doc) => doc.toJson()).toList(),
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'driverApprovalStatus': driverApprovalStatus,
      'driverRejectionReason': driverRejectionReason,
    };
  }

  /// Extrae el código de estudiante del email
  /// Ejemplo: jb2017059611@virtual.upt.pe -> 2017059611
  static String _extractStudentIdFromEmail(String email) {
    if (email.isEmpty) return 'N/A';
    
    // Patrón: letras + números + @
    // Ejemplo: jb2017059611@virtual.upt.pe
    final regex = RegExp(r'[a-z]+(\d+)@', caseSensitive: false);
    final match = regex.firstMatch(email);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? 'N/A';
    }
    
    return 'N/A';
  }

  /// Copia el usuario con campos actualizados
  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? phone,
    String? university,
    String? studentId,
    String? profilePhoto,
    int? age,
    String? gender,
    String? bio,
    Vehicle? vehicle,
    List<DriverDocument>? driverDocuments,
    double? averageRating,
    int? totalRatings,
    String? driverApprovalStatus,
    String? driverRejectionReason,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isAdmin: isAdmin, // isAdmin no puede ser null, pero mantenemos la sintaxis para consistencia
      phone: phone ?? this.phone,
      university: university ?? this.university,
      studentId: studentId ?? this.studentId,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      vehicle: vehicle ?? this.vehicle,
      driverDocuments: driverDocuments ?? this.driverDocuments,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      driverApprovalStatus: driverApprovalStatus ?? this.driverApprovalStatus,
      driverRejectionReason: driverRejectionReason ?? this.driverRejectionReason,
    );
  }

  /// Obtiene el texto del promedio de calificaciones
  String get averageRatingText {
    if (totalRatings == 0) return 'Sin calificaciones';
    return '${averageRating.toStringAsFixed(1)} ($totalRatings calificación${totalRatings != 1 ? 'es' : ''})';
  }

  /// Verifica si tiene calificaciones
  bool get hasRatings => totalRatings > 0;
}
