// lib/screens/ratings/rate_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/trip.dart';
import '../../models/user.dart';
import '../../services/rating_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../home/main_layout_screen.dart';

class RateTripScreen extends StatefulWidget {
  final Trip trip;
  const RateTripScreen({super.key, required this.trip});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  final Map<String, int> _ratings = {};
  final Map<String, String> _comments = {};
  bool _isSubmitting = false;
  bool _isLoadingRatings = true;
  final Set<String> _alreadyRatedUsers = {};

  @override
  void initState() {
    super.initState();
    _initializeRatings();
  }

  Future<void> _initializeRatings() async {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return;

    final isDriver = currentUser.role == 'driver';

    // Verificar qué usuarios ya fueron calificados
    if (isDriver) {
      // Conductor: verificar cada pasajero confirmado
      for (final passenger in widget.trip.passengers) {
        if (passenger.status == 'confirmed') {
          final result = await RatingService.canRateUser(
            ratedId: passenger.user.id,
            tripId: widget.trip.id,
            ratingType: 'passenger',
            context: context,
          );
          
          if (result['success'] == true && result['alreadyRated'] == true) {
            _alreadyRatedUsers.add(passenger.user.id);
          } else {
            _ratings[passenger.user.id] = 0;
          }
        }
      }
    } else {
      // Pasajero: verificar si ya calificó al conductor
      if (widget.trip.driver.id != currentUser.id) {
        final result = await RatingService.canRateUser(
          ratedId: widget.trip.driver.id,
          tripId: widget.trip.id,
          ratingType: 'driver',
          context: context,
        );
        
        if (result['success'] == true && result['alreadyRated'] == true) {
          _alreadyRatedUsers.add(widget.trip.driver.id);
        } else {
          _ratings[widget.trip.driver.id] = 0;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingRatings = false;
      });
      
      // Si no hay usuarios para calificar, cerrar después de un momento
      if (_usersToRate.isEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateBack();
          }
        });
      }
    }
  }

  List<User> get _usersToRate {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return [];

    final users = <User>[];
    final isDriver = currentUser.role == 'driver';

    if (isDriver) {
      // Conductor: calificar a TODOS los pasajeros confirmados que NO hayan sido calificados
      for (final passenger in widget.trip.passengers) {
        if (passenger.status == 'confirmed' && !_alreadyRatedUsers.contains(passenger.user.id)) {
          users.add(passenger.user);
        }
      }
    } else {
      // Pasajero: calificar al conductor si NO ha sido calificado
      if (widget.trip.driver.id != currentUser.id && !_alreadyRatedUsers.contains(widget.trip.driver.id)) {
        users.add(widget.trip.driver);
      }
    }

    return users;
  }

  void _navigateBack() {
    if (!mounted) return;
    
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser == null) return;

    // Usar pushAndRemoveUntil para limpiar completamente el stack de navegación
    // y evitar bucles al regresar a MainLayoutScreen
    // Esto asegura que no haya pantallas anteriores que puedan causar problemas
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainLayoutScreen(),
      ),
      (route) => false, // Eliminar todas las rutas anteriores
    );
  }

  bool get _canSubmit {
    return _ratings.values.every((rating) => rating > 0) && !_isSubmitting;
  }

  Future<void> _submitRatings() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
      if (currentUser == null) return;

      bool allSuccess = true;

      for (final user in _usersToRate) {
        final rating = _ratings[user.id]!;
        final comment = _comments[user.id];

        final result = await RatingService.createRating(
          ratedId: user.id,
          tripId: widget.trip.id,
          rating: rating,
          comment: comment,
          ratingType: user.isDriver ? 'driver' : 'passenger',
          context: context, // Pasar el contexto para obtener el token
        );

        if (!result['success']) {
          allSuccess = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al calificar a ${user.firstName}: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      if (allSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Calificaciones enviadas exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Guardar los IDs de usuarios que acabamos de calificar
        final justRatedUserIds = _usersToRate.map((u) => u.id).toList();
        
        // Actualizar la lista de usuarios ya calificados
        for (final userId in justRatedUserIds) {
          _alreadyRatedUsers.add(userId);
          // Limpiar las calificaciones y comentarios enviados
          _ratings.remove(userId);
          _comments.remove(userId);
        }
        
        // Actualizar el estado para recalcular _usersToRate
        if (mounted) {
          setState(() {
            // El estado se actualiza para recalcular _usersToRate
          });
        }
        
        // Esperar un momento para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          // Verificar si aún hay usuarios para calificar
          final remainingUsers = _usersToRate;
          
          if (remainingUsers.isEmpty) {
            // No hay más usuarios para calificar, marcar el viaje como procesado
            final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
            if (currentUser != null) {
              final prefs = await SharedPreferences.getInstance();
              final tripKey = 'rated_trip_${widget.trip.id}_${currentUser.id}';
              await prefs.setBool(tripKey, true);
            }
            
            // Actualizar los viajes y navegar de vuelta
            // Esto asegura que MainLayoutScreen tenga información actualizada
            final tripProvider = Provider.of<TripProvider>(context, listen: false);
            await tripProvider.fetchMyTrips(force: true);
            
            // Esperar un momento adicional para que el servidor procese las calificaciones
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              _navigateBack();
            }
          }
          // Si aún hay usuarios, la UI ya se actualizó con el setState anterior
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRatings) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calificar Viaje'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final usersToRate = _usersToRate;

    if (usersToRate.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calificar Viaje'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
              SizedBox(height: 16),
              Text(
                'No hay usuarios para calificar',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Ya has calificado a todos los participantes',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Calificar Viaje',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 8),
            child: FilledButton.icon(
              onPressed: _canSubmit ? _submitRatings : null,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isSubmitting ? 'Enviando...' : 'Enviar',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _canSubmit 
                    ? colorScheme.secondary 
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: _canSubmit 
                    ? colorScheme.onSecondary 
                    : colorScheme.onSurfaceVariant,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 10 : 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del viaje - Estilo mejorado
          Container(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: colorScheme.onPrimary,
                        size: isTablet ? 24 : 20,
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Viaje completado',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            '${widget.trip.origin.name} → ${widget.trip.destination.name}',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: colorScheme.primary,
                        size: isTablet ? 20 : 18,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        'Califica a ${usersToRate.length} participante${usersToRate.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de usuarios para calificar
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: usersToRate.length,
              itemBuilder: (context, index) {
                final user = usersToRate[index];
                final rating = _ratings[user.id] ?? 0;

                return Card(
                  margin: EdgeInsets.only(
                    bottom: isTablet ? 20 : 16,
                    left: isTablet ? 8 : 4,
                    right: isTablet ? 8 : 4,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del usuario - Mejorado
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: isTablet ? 28 : 24,
                                backgroundImage: user.profilePhoto != 'default_avatar.png' && user.profilePhoto.isNotEmpty
                                    ? NetworkImage(user.profilePhoto)
                                    : null,
                                backgroundColor: colorScheme.primaryContainer,
                                child: user.profilePhoto == 'default_avatar.png' || user.profilePhoto.isEmpty
                                    ? Text(
                                        user.initials,
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 4 : 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 10 : 8,
                                      vertical: isTablet ? 4 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isDriver 
                                          ? colorScheme.primaryContainer 
                                          : colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user.isDriver ? 'Conductor' : 'Pasajero',
                                      style: TextStyle(
                                        color: user.isDriver 
                                            ? colorScheme.onPrimaryContainer 
                                            : colorScheme.onSecondaryContainer,
                                        fontSize: isTablet ? 13 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (user.hasRatings) ...[
                                    SizedBox(height: isTablet ? 8 : 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 8 : 6,
                                            vertical: isTablet ? 4 : 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                user.averageRating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: isTablet ? 14 : 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber.shade700,
                                                ),
                                              ),
                                              SizedBox(width: isTablet ? 6 : 4),
                                              ...List.generate(5, (index) {
                                                return Icon(
                                                  index < user.averageRating.floor() 
                                                    ? Icons.star 
                                                    : index < user.averageRating 
                                                      ? Icons.star_half 
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: isTablet ? 16 : 14,
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 24 : 20),
                        // Calificación con estrellas - Mejorado
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _ratings[user.id] = index + 1;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 4),
                                      padding: EdgeInsets.all(isTablet ? 4 : 2),
                                      child: Icon(
                                        index < rating ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: isTablet ? 48 : 44,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              if (rating > 0) ...[
                                SizedBox(height: isTablet ? 12 : 10),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 20 : 16,
                                    vertical: isTablet ? 8 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRatingColor(rating).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getRatingColor(rating).withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _getRatingText(rating),
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getRatingColor(rating),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: isTablet ? 24 : 20),
                        // Campo de comentario - Mejorado
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Comentario (opcional)',
                            hintText: 'Escribe tu experiencia con ${user.firstName}...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 14 : 12,
                            ),
                            counterStyle: TextStyle(
                              fontSize: isTablet ? 12 : 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          maxLines: 3,
                          maxLength: 500,
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 14,
                          ),
                          onChanged: (value) {
                            _comments[user.id] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
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
        return 'Selecciona una calificación';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}


