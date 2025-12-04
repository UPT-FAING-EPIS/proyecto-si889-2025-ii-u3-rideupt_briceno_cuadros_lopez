import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideupt_app/models/user.dart';

class LocationPoint {
  final String name;
  final LatLng coordinates;

  LocationPoint({required this.name, required this.coordinates});

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      name: json['name'] ?? 'Ubicación sin nombre',
      coordinates: LatLng(json['coordinates'][1], json['coordinates'][0]), // lat, lng
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'Point',
      'coordinates': [coordinates.longitude, coordinates.latitude],
    };
  }
}

class Trip {
  final String id;
  final User driver;
  final LocationPoint origin;
  final LocationPoint destination;
  final DateTime departureTime;
  final DateTime? expiresAt; // Tiempo de expiración del viaje
  final int availableSeats;
  final int seatsBooked;
  final double pricePerSeat;
  final String? description;
  final String status;
  final List<TripPassenger> passengers;

  Trip({
    required this.id,
    required this.driver,
    required this.origin,
    required this.destination,
    required this.departureTime,
    this.expiresAt,
    required this.availableSeats,
    required this.seatsBooked,
    required this.pricePerSeat,
    this.description,
    required this.status,
    this.passengers = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'],
      driver: User.fromJson(json['driver']),
      origin: LocationPoint.fromJson(json['origin']),
      destination: LocationPoint.fromJson(json['destination']),
      departureTime: DateTime.parse(json['departureTime']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      availableSeats: json['availableSeats'],
      seatsBooked: json['seatsBooked'],
      pricePerSeat: (json['pricePerSeat'] as num).toDouble(),
      description: json['description'],
      status: json['status'],
      passengers: (json['passengers'] as List<dynamic>?)
              ?.map((p) => TripPassenger.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  // Método helper para verificar si el viaje ha expirado por tiempo
  bool get hasTimeExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Método helper para obtener el tiempo restante en minutos
  int get minutesRemaining {
    if (expiresAt == null) return 0;
    final difference = expiresAt!.difference(DateTime.now());
    return difference.inMinutes;
  }

  // Método helper para obtener el texto del tiempo restante
  String get timeRemainingText {
    if (expiresAt == null) return '';
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 'Expirado';
    
    final difference = expiresAt!.difference(now);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes min restante${minutes != 1 ? 's' : ''}';
    } else {
      return '$seconds seg restante${seconds != 1 ? 's' : ''}';
    }
  }

  // Método helper para verificar si el viaje está en curso
  bool get isInProgress => status == 'en-proceso' || status == 'in-progress';

  // Método helper para verificar si el viaje está completado
  bool get isCompleted => status == 'completado' || status == 'completed';

  // Método helper para verificar si el viaje está activo (esperando pasajeros)
  bool get isActive => status == 'esperando' || status == 'active';

  // Método helper para verificar si el viaje está completo (lleno)
  bool get isFull => status == 'completo' || status == 'full';

  // Método helper para verificar si el viaje está expirado (por estado o por tiempo)
  bool get isExpired => status == 'expirado' || status == 'expired' || hasTimeExpired;

  // Método helper para verificar si el viaje acepta solicitudes
  bool get acceptsRequests => status == 'esperando' || status == 'active' || status == 'completo' || status == 'full';

  // Método helper para verificar si el viaje está cancelado
  bool get isCancelled => status == 'cancelado' || status == 'cancelled';

  // Método helper para obtener el tiempo de espera restante (solo si está activo)
  String get waitingTimeText {
    if (!isActive || expiresAt == null) return '';
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 'Tiempo agotado';
    
    final difference = expiresAt!.difference(now);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes min para llenar el vehículo';
    } else {
      return '$seconds seg para llenar el vehículo';
    }
  }
}

class TripPassenger {
  final User user;
  final String status; // pending | confirmed | rejected | cancelled
  final DateTime bookedAt;
  final bool inVehicle; // Indica si el pasajero ya está en el vehículo

  TripPassenger({
    required this.user, 
    required this.status, 
    required this.bookedAt,
    this.inVehicle = false,
  });

  factory TripPassenger.fromJson(Map<String, dynamic> json) {
    return TripPassenger(
      user: User.fromJson(json['user'] is Map<String, dynamic>
          ? json['user']
          : {'_id': json['user'], 'firstName': 'Usuario', 'lastName': '', 'email': '', 'role': 'passenger', 'phone': '', 'university': ''}),
      status: json['status'] ?? 'pending',
      bookedAt: DateTime.tryParse(json['bookedAt'] ?? '') ?? DateTime.now(),
      inVehicle: json['inVehicle'] ?? false,
    );
  }
}