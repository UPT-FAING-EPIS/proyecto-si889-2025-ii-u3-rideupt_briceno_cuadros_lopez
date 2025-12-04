// lib/screens/trips/my_trips_screen.dart (NUEVO)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/screens/trips/trip_details_screen.dart';
import 'package:rideupt_app/screens/trips/passenger_trip_details_screen.dart';
import 'package:rideupt_app/screens/trips/driver_trip_in_progress_screen.dart';
import 'package:rideupt_app/screens/trips/passenger_trip_in_progress_screen.dart';
import 'package:rideupt_app/screens/ratings/rate_trip_screen.dart';
import 'package:rideupt_app/widgets/trip_card.dart';
import 'package:rideupt_app/widgets/skeleton_trip_list.dart';
import 'package:rideupt_app/widgets/history_empty_lottie.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/services/socket_service.dart';
import 'dart:async';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  Timer? _refreshTimer;
  String? _previousRole; // Para detectar cambios de rol
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _previousRole = authProvider.user?.role;
        
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        // Pre-cargar datos inmediatamente
        tripProvider.fetchMyTrips();
        _setupSocketListeners();
        // Actualizar cada 10 segundos para mantener sincronizado
        _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          if (mounted) {
            tripProvider.fetchMyTrips(force: true);
            _checkForActiveTrip();
          }
        });
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuchar cambios en el AuthProvider para detectar cambios de rol
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRole = authProvider.user?.role;
    
    // Si el rol cambió, recargar viajes
    if (_previousRole != currentRole && currentRole != null) {
      _previousRole = currentRole;
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      tripProvider.clearTrips();
      
      if (currentRole == 'driver') {
        tripProvider.fetchMyTrips(force: true);
      } else {
        tripProvider.fetchAvailableTrips();
        tripProvider.fetchMyTrips(force: true);
      }
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Limpiar listeners de socket
    final socket = SocketService().socket;
    socket?.off('tripUpdated');
    super.dispose();
  }
  
  void _setupSocketListeners() {
    final socket = SocketService().socket;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    
    if (socket == null) return;
    
    // Escuchar actualizaciones del viaje
    socket.on('tripUpdated', (data) async {
      if (!mounted) return;
      
      try {
        // Actualizar inmediatamente sin throttle
        await tripProvider.fetchMyTrips(force: true);
        
        // Verificar si hay viajes activos que requieren navegación
        if (mounted) {
          _checkForActiveTrip();
        }
      } catch (e) {
        // Error silencioso, la actualización periódica lo corregirá
      }
    });
  }

  void _checkForActiveTrip() {
    if (!mounted) return;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = authProvider.user?.role == 'driver';
    final currentUserId = authProvider.user?.id;

    // Primero verificar si hay viajes completados recientes que necesitan calificación
    for (final trip in tripProvider.myTrips) {
      if (trip.isCompleted && !trip.isExpired && !trip.isCancelled) {
        // Verificar si el usuario participó en el viaje
        bool userParticipated = false;
        if (isDriver) {
          userParticipated = trip.driver.id == currentUserId;
        } else {
          userParticipated = trip.passengers.any(
            (p) => p.user.id == currentUserId && p.status == 'confirmed'
          );
        }
        
        // Si el usuario participó, redirigir a calificar
        if (userParticipated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RateTripScreen(trip: trip),
            ),
          );
          return;
        }
      }
    }

    // Buscar viaje REALMENTE en curso (solo en-proceso, NO esperando)
    for (final trip in tripProvider.activeMyTrips) {
      if (trip.isInProgress && !trip.isExpired) {
        if (isDriver) {
          // Conductor: ir a pantalla de viaje en curso
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DriverTripInProgressScreen(trip: trip),
            ),
          );
        } else {
          // Pasajero: verificar si está confirmado en el viaje
          final myPassengerStatus = trip.passengers
              .firstWhere(
                (p) => p.user.id == currentUserId,
                orElse: () => TripPassenger(
                  user: authProvider.user!,
                  status: 'none',
                  bookedAt: DateTime.now(),
                ),
              )
              .status;
          
          if (myPassengerStatus == 'confirmed') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PassengerTripInProgressScreen(trip: trip),
              ),
            );
          }
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = authProvider.user?.role == 'driver';
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeAreaWrapper(
        child: Consumer<TripProvider>(
          builder: (context, tripProvider, child) {
            // Obtener el ID del usuario actual
            final currentUserId = authProvider.user?.id;
            
            // Separar viajes en curso de historial
            // Viajes en proceso: solo los que están realmente en curso (en-proceso)
            final tripsInProgress = tripProvider.myTrips
                .where((trip) => trip.isInProgress && !trip.isExpired && !trip.isCancelled)
                .toList();
            
            // Historial: usar el método optimizado con caché del provider
            // Esto retorna datos inmediatamente si hay caché, incluso durante la carga
            final limitedHistoryTrips = tripProvider.getHistoryTrips(currentUserId, isDriver, limit: 10);
            
            // Mostrar skeleton solo en la carga inicial y si no hay datos en caché
            if (tripProvider.isInitialLoad && tripProvider.isLoading && tripProvider.myTrips.isEmpty) {
              return const SkeletonTripList();
            }
            
            // Verificar si hay un viaje en curso después de cargar
            if (!tripProvider.isLoading && tripsInProgress.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _checkForActiveTrip();
              });
            }
            
            // Si no hay historial y no hay viajes en curso, mostrar vacío
            if (limitedHistoryTrips.isEmpty && tripsInProgress.isEmpty) {
              return HistoryEmptyLottie(
                isDriver: isDriver,
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                await tripProvider.fetchMyTrips(force: true);
              },
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: CustomScrollView(
                slivers: [
                  // Contenido
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección de viajes en curso (si existen)
                        if (tripsInProgress.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        size: 16,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Viaje en Curso',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...tripsInProgress.map((trip) => Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: 6,
                            ),
                            child: TripCard(
                              trip: trip,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => isDriver
                                      ? TripDetailsScreen(trip: trip)
                                      : PassengerTripDetailsScreen(trip: trip),
                                  ),
                                ).then((_) {
                                  tripProvider.fetchMyTrips(force: true);
                                });
                              },
                            ),
                          )),
                          Divider(
                            height: 32,
                            thickness: 1,
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ],
                        
                        // Sección de historial
                        Padding(
                          padding: EdgeInsets.all(isTablet ? 20 : 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Historial (Últimos ${limitedHistoryTrips.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Lista de historial
                        if (limitedHistoryTrips.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(isTablet ? 48 : 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aún no tienes viajes en tu historial',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...limitedHistoryTrips.map((trip) => Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: 6,
                            ),
                            child: TripCard(
                              trip: trip,
                              onTap: () {
                                // Para viajes del historial, solo mostrar información
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => isDriver
                                      ? TripDetailsScreen(trip: trip)
                                      : PassengerTripDetailsScreen(trip: trip),
                                  ),
                                );
                              },
                            ),
                          )),
                        
                        // Espacio adicional al final para evitar que quede oculto
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}