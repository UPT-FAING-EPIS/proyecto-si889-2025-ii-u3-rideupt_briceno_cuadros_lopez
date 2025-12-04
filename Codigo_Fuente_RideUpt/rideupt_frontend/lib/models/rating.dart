// lib/models/rating.dart

class Rating {
  final String id;
  final String raterId;
  final String ratedId;
  final String tripId;
  final int rating;
  final String? comment;
  final String ratingType; // 'driver' o 'passenger'
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.raterId,
    required this.ratedId,
    required this.tripId,
    required this.rating,
    this.comment,
    required this.ratingType,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['_id'] ?? json['id'] ?? '',
      raterId: json['rater']?['_id'] ?? json['raterId'] ?? '',
      ratedId: json['rated']?['_id'] ?? json['ratedId'] ?? '',
      tripId: json['trip']?['_id'] ?? json['tripId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      ratingType: json['ratingType'] ?? '',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raterId': raterId,
      'ratedId': ratedId,
      'tripId': tripId,
      'rating': rating,
      'comment': comment,
      'ratingType': ratingType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Obtiene el texto de la calificación
  String get ratingText {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return 'Sin calificar';
    }
  }

  /// Verifica si tiene comentario
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Obtiene el tipo de calificación en español
  String get ratingTypeText {
    switch (ratingType) {
      case 'driver':
        return 'Conductor';
      case 'passenger':
        return 'Pasajero';
      default:
        return 'Usuario';
    }
  }
}