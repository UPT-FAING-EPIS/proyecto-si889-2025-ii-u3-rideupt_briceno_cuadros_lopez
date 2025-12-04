// lib/screens/home/main_layout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/driver_home_screen.dart';
import '../../screens/trips/my_trips_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/trips/driver_trip_in_progress_screen.dart';
import '../../screens/trips/passenger_trip_in_progress_screen.dart';
import '../../screens/ratings/rate_trip_screen.dart';
import '../../models/trip.dart';
import '../../widgets/safe_area_wrapper.dart';
import '../../services/socket_service.dart';
import '../../services/rating_service.dart';
import 'header_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final Set<String> _processedCompletedTrips = {}; // Rastrear viajes completados ya procesados
  String? _previousRole; // Para detectar cambios de rol
  bool _isCheckingRatings = false; // Prevenir múltiples verificaciones simultáneas
  DateTime? _lastRatingCheck; // Timestamp de la última verificación de calificaciones

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Verificar viajes en proceso después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _previousRole = authProvider.user?.role;
      await _checkForTripInProgress();
      _setupSocketListeners();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuchar cambios en el AuthProvider para detectar cambios de rol
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRole = authProvider.user?.role;
    
    // Si el rol cambió, forzar actualización de la interfaz
    if (_previousRole != currentRole && currentRole != null) {
      _previousRole = currentRole;
      
      // Recargar viajes según el nuevo rol
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      tripProvider.clearTrips();
      
      if (currentRole == 'driver') {
        tripProvider.fetchMyTrips(force: true);
      } else {
        tripProvider.fetchAvailableTrips();
        tripProvider.fetchMyTrips(force: true);
      }
      
      // Forzar reconstrucción del widget para actualizar las pantallas
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  void _setupSocketListeners() {
    final socket = SocketService().socket;
    if (socket == null) return;
    
    // Escuchar actualizaciones del viaje
    socket.on('tripUpdated', (data) async {
      if (!mounted) return;
      
      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        // Actualizar inmediatamente sin throttle
        await tripProvider.fetchMyTrips(force: true);
        
        // Verificar si hay viajes activos que requieren navegación
        // Solo verificar calificaciones si han pasado al menos 30 segundos desde la última verificación
        if (mounted) {
          await _checkForTripInProgress(skipRatingCheck: true);
        }
      } catch (e) {
        // Error silencioso
        debugPrint('Error en tripUpdated listener: $e');
      }
    });
  }
  
  Future<void> _checkForTripInProgress({bool skipRatingCheck = false}) async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = authProvider.user?.role == 'driver';
    final currentUserId = authProvider.user?.id;
    
    if (currentUserId == null) return;
    
    // Buscar viaje en proceso
    Trip? tripInProgress;
    
    if (isDriver) {
      // Para conductores: buscar viaje en proceso
      try {
        tripInProgress = tripProvider.activeMyTrips.firstWhere(
          (trip) => trip.isInProgress && !trip.isExpired && !trip.isCancelled,
        );
      } catch (e) {
        try {
          tripInProgress = tripProvider.myTrips.firstWhere(
            (trip) => trip.isInProgress && !trip.isExpired && !trip.isCancelled,
          );
        } catch (e) {
          tripInProgress = null;
        }
      }
      
      if (tripInProgress != null && tripInProgress.id.isNotEmpty && tripInProgress.isInProgress) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverTripInProgressScreen(trip: tripInProgress!),
          ),
        );
        return;
      }
    } else {
      // Para pasajeros: buscar viaje en proceso donde esté confirmado Y ya confirmó que está en el vehículo
      for (final trip in tripProvider.myTrips) {
        if (trip.isInProgress && !trip.isExpired && !trip.isCancelled) {
          final myPassenger = trip.passengers.firstWhere(
            (p) => p.user.id == currentUserId,
            orElse: () => TripPassenger(
              user: authProvider.user!,
              status: 'none',
              bookedAt: DateTime.now(),
            ),
          );
          
          // Solo considerar viaje en progreso si está confirmado Y ya confirmó que está en el vehículo
          if (myPassenger.status == 'confirmed' && myPassenger.inVehicle) {
            tripInProgress = trip;
            break;
          }
        }
      }
      
      if (tripInProgress != null && tripInProgress.id.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PassengerTripInProgressScreen(trip: tripInProgress!),
          ),
        );
        return;
      }
    }
    
    // Verificar si hay viajes completados recientes que necesitan calificación
    // Solo si no estamos ya verificando y no se debe omitir la verificación
    // Y solo si han pasado al menos 30 segundos desde la última verificación (para evitar bucles)
    if (!skipRatingCheck && !_isCheckingRatings) {
      final now = DateTime.now();
      if (_lastRatingCheck == null || now.difference(_lastRatingCheck!).inSeconds >= 30) {
        _lastRatingCheck = now;
        await _checkForPendingRatings(tripProvider, currentUserId, isDriver);
      }
    }
  }

  /// Verifica si hay viajes completados que necesitan calificación
  Future<void> _checkForPendingRatings(TripProvider tripProvider, String? currentUserId, bool isDriver) async {
    if (currentUserId == null || _isCheckingRatings) return;
    
    setState(() {
      _isCheckingRatings = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Verificar viajes completados recientes (últimas 48 horas)
      for (final trip in tripProvider.myTrips) {
        if (trip.isCompleted && !trip.isExpired && !trip.isCancelled) {
          // Verificar que el viaje se completó recientemente
          final hoursSinceDeparture = now.difference(trip.departureTime).inHours;
          if (hoursSinceDeparture > 48) continue;
          
          // Verificar si el usuario participó en el viaje
          bool userParticipated = false;
          if (isDriver) {
            userParticipated = trip.driver.id == currentUserId;
          } else {
            userParticipated = trip.passengers.any(
              (p) => p.user.id == currentUserId && p.status == 'confirmed'
            );
          }
          
          if (!userParticipated) continue;
          
          // Verificar si ya procesamos este viaje (usando SharedPreferences)
          final tripKey = 'rated_trip_${trip.id}_$currentUserId';
          final alreadyProcessed = prefs.getBool(tripKey) ?? false;
          
          if (alreadyProcessed) continue;
          
          // Verificar si realmente hay usuarios pendientes de calificar
          final hasUsersToRate = await _checkIfHasUsersToRate(trip, currentUserId, isDriver);
          
          if (hasUsersToRate) {
            // Marcar como procesado ANTES de navegar para evitar bucles
            await prefs.setBool(tripKey, true);
            _processedCompletedTrips.add('${trip.id}_$currentUserId');
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RateTripScreen(trip: trip),
                ),
              );
            }
            return;
          } else {
            // No hay usuarios pendientes, marcar como procesado INMEDIATAMENTE
            // para evitar que se verifique nuevamente
            await prefs.setBool(tripKey, true);
            _processedCompletedTrips.add('${trip.id}_$currentUserId');
          }
        }
      }
    } catch (e) {
      debugPrint('Error al verificar calificaciones pendientes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRatings = false;
        });
      }
    }
  }

  /// Verifica si hay usuarios pendientes de calificar en un viaje completado
  Future<bool> _checkIfHasUsersToRate(Trip trip, String currentUserId, bool isDriver) async {
    try {
      if (isDriver) {
        // Conductor: verificar cada pasajero confirmado
        for (final passenger in trip.passengers) {
          if (passenger.status == 'confirmed') {
            final result = await RatingService.canRateUser(
              ratedId: passenger.user.id,
              tripId: trip.id,
              ratingType: 'passenger',
              context: context,
            );
            
            // Si puede calificar (no lo ha calificado), entonces hay usuarios pendientes
            if (result['success'] == true && result['canRate'] == true) {
              return true;
            }
          }
        }
      } else {
        // Pasajero: verificar si puede calificar al conductor
        if (trip.driver.id != currentUserId) {
          final result = await RatingService.canRateUser(
            ratedId: trip.driver.id,
            tripId: trip.id,
            ratingType: 'driver',
            context: context,
          );
          
          // Si puede calificar (no lo ha calificado), entonces hay usuarios pendientes
          if (result['success'] == true && result['canRate'] == true) {
            return true;
          }
        }
      }
      
      // No hay usuarios pendientes de calificar
      return false;
    } catch (e) {
      // En caso de error, asumir que no hay usuarios pendientes para evitar bucles
      debugPrint('Error al verificar usuarios pendientes de calificar: $e');
      // En caso de error, retornar false para evitar bucles infinitos
      return false;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    // Limpiar listeners de socket
    final socket = SocketService().socket;
    socket?.off('tripUpdated');
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Verificar si hay un viaje en proceso antes de permitir navegación
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = authProvider.user?.role == 'driver';
    final currentUserId = authProvider.user?.id;
    
    if (currentUserId != null) {
      // Verificar si hay un viaje en proceso
      bool hasTripInProgress = false;
      
      if (isDriver) {
        hasTripInProgress = tripProvider.activeMyTrips.any(
          (trip) => trip.isInProgress && !trip.isExpired && !trip.isCancelled
        );
      } else {
        hasTripInProgress = tripProvider.myTrips.any((trip) {
          if (trip.isInProgress && !trip.isExpired && !trip.isCancelled) {
            return trip.passengers.any(
              (p) => p.user.id == currentUserId && p.status == 'confirmed'
            );
          }
          return false;
        });
      }
      
      if (hasTripInProgress) {
        // Bloquear navegación si hay un viaje en proceso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No puedes navegar mientras tienes un viaje en curso'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _scaleController.reset();
      _scaleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Provider.of<AuthProvider>(context).user;
    final isDriver = user?.role == 'driver';
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    // Verificar si hay un viaje en proceso (conductor o pasajero)
    final tripProvider = Provider.of<TripProvider>(context);
    final currentUserId = user?.id;
    
    bool hasTripInProgress = false;
    if (currentUserId != null) {
      if (isDriver) {
        hasTripInProgress = tripProvider.activeMyTrips.any(
          (trip) => trip.isInProgress && !trip.isExpired && !trip.isCancelled
        );
      } else {
        hasTripInProgress = tripProvider.myTrips.any((trip) {
          if (trip.isInProgress && !trip.isExpired && !trip.isCancelled) {
            return trip.passengers.any(
              (p) => p.user.id == currentUserId && p.status == 'confirmed'
            );
          }
          return false;
        });
      }
    }
    
    // También verificar viajes activos (esperando/completo) para conductores
    final hasActiveTrip = isDriver && tripProvider.activeMyTrips.any(
      (trip) => (trip.isActive || trip.isFull) && !trip.isExpired
    );

    // Pantallas con perfil incluido - Estilo INDRIVE
    final List<Widget> widgetOptions = isDriver
        ? [
            const DriverHomeScreen(),  // Mi Viaje (conductores) - Página principal
            const MyTripsScreen(),    // Historial de viajes
            const ProfileScreen(),    // Perfil con dashboard
          ]
        : [
            const HomeScreen(),       // Buscar Viaje (pasajeros) - Página principal
            const MyTripsScreen(),    // Historial de reservas
            const ProfileScreen(),    // Perfil con dashboard
          ];

    // Títulos de las pantallas
    final List<String> screenTitles = isDriver
        ? ['Mi Viaje', 'Historial', 'Perfil']
        : ['Viajes Disponibles', 'Historial', 'Perfil'];

    // Items de navegación - Estilo INDRIVE moderno (3 tabs)
    final List<BottomNavigationBarItem> navItems = isDriver
        ? [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  size: isTablet ? 28 : 24,
                ),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: colorScheme.primary,
                  size: isTablet ? 28 : 24,
                ),
              ),
              label: 'Mi Viaje',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.history_rounded,
                size: isTablet ? 28 : 24,
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: colorScheme.primary,
                  size: isTablet ? 28 : 24,
                ),
              ),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_rounded,
                size: isTablet ? 28 : 24,
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                  size: isTablet ? 28 : 24,
                ),
              ),
              label: 'Perfil',
            ),
          ]
        : [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.search_rounded,
                size: isTablet ? 28 : 24,
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: isTablet ? 28 : 24,
                ),
              ),
              label: 'Viajes',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.history_rounded,
                size: isTablet ? 28 : 24,
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: colorScheme.primary,
                  size: isTablet ? 28 : 24,
                ),
              ),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_rounded,
                size: isTablet ? 28 : 24,
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                  size: isTablet ? 28 : 24,
                ),
              ),
              label: 'Perfil',
            ),
          ];

    return Scaffold(
      // Mostrar HeaderScreen para todas las pantallas (incluyendo índice 0)
      appBar: HeaderScreen(title: screenTitles[_selectedIndex]),
      body: SafeAreaWrapper(
        top: false, // El HeaderScreen maneja el safe area superior
        bottom: false, // El bottom se maneja en el bottomNavigationBar
          child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: IndexedStack(
              index: _selectedIndex,
              children: widgetOptions,
            ),
          ),
        ),
      ),
      // Ocultar navbar si hay un viaje en proceso o activo
      bottomNavigationBar: (hasTripInProgress || hasActiveTrip) ? null : BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isTablet ? 13 : 11,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: isTablet ? 13 : 11,
          letterSpacing: 0.3,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
