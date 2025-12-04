// lib/screens/home/home_screen.dart (ACTUALIZADO)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/screens/trips/passenger_trip_details_screen.dart';
import 'package:rideupt_app/screens/trips/passenger_trip_in_progress_screen.dart';
import 'package:rideupt_app/services/socket_service.dart';
import 'package:rideupt_app/widgets/trip_card.dart';
import 'package:rideupt_app/widgets/skeleton_trip_list.dart';
import 'package:rideupt_app/widgets/gps_searching_lottie.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTrips();
        _setupTripStatusListener();
      }
    });
    
    // Auto-refresh cada 10 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadTrips();
      }
    });
  }

  void _setupTripStatusListener() {
    final socket = SocketService().socket;
    if (socket == null) return;
    
    // Escuchar actualizaciones del viaje para redirigir si el conductor inicia el viaje
    socket.on('tripUpdated', (data) async {
      if (!mounted) return;
      
      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.user?.id;
        
        if (currentUserId == null) return;
        
        // Actualizar los viajes
        await tripProvider.fetchMyTrips(force: true);
        
        // Buscar viaje en proceso donde el pasajero esté confirmado Y ya confirmó que está en el vehículo
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
            
            // Solo redirigir si está confirmado Y ya confirmó que está en el vehículo
            if (myPassenger.status == 'confirmed' && myPassenger.inVehicle) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PassengerTripInProgressScreen(trip: trip),
                  ),
                );
              }
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Error al procesar actualización de viaje en home: $e');
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Limpiar listener de socket
    final socket = SocketService().socket;
    socket?.off('tripUpdated');
    super.dispose();
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    
    try {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      await tripProvider.fetchAvailableTrips();
    } catch (e) {
      debugPrint('Error loading trips: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeAreaWrapper(
        top: false, // El HeaderScreen en MainLayoutScreen maneja el safe area superior
        bottom: false, // El bottom navigation maneja el safe area inferior
        child: Consumer<TripProvider>(
          builder: (context, tripProvider, child) {
            if (tripProvider.isLoading) {
              return const SkeletonTripList();
            }
            
            if (tripProvider.errorMessage.isNotEmpty && tripProvider.availableTrips.isEmpty) {
              return SingleChildScrollView(
                child: _buildErrorState(tripProvider.errorMessage, theme, colorScheme, isTablet),
              );
            }
            
            if (tripProvider.availableTrips.isEmpty) {
              return _buildEmptyState(theme, colorScheme, isTablet);
            }
            
            return _buildTripList(tripProvider, theme, colorScheme, isTablet);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? AppTheme.spacingXXL : AppTheme.spacingXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isTablet ? 80 : 64,
                color: colorScheme.error,
              ),
            ),
            SizedBox(height: isTablet ? AppTheme.spacingXL : AppTheme.spacingLG),
            Text(
              'Error al cargar viajes',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLG + AppTheme.spacingXS),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: isTablet ? AppTheme.spacingXL : AppTheme.spacingLG),
            FilledButton.icon(
              onPressed: _loadTrips,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
                  vertical: isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return NoTripsAvailableLottie(
      onRefresh: _loadTrips,
    );
  }

  Widget _buildTripList(TripProvider tripProvider, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Contador de viajes
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? AppTheme.spacingLG : AppTheme.spacingMD,
              vertical: isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS,
            ),
            color: colorScheme.surface,
            child: Text(
              '${tripProvider.availableTrips.length} viaje${tripProvider.availableTrips.length != 1 ? 's' : ''} disponible${tripProvider.availableTrips.length != 1 ? 's' : ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Lista de viajes
          ...tripProvider.availableTrips.asMap().entries.map((entry) {
            final i = entry.key;
            final trip = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (i * 100)),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(
                bottom: isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS,
                top: i == 0 ? (isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS) : 0,
                left: isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS,
                right: isTablet ? AppTheme.spacingMD : AppTheme.spacingSM + AppTheme.spacingXS,
              ),
              child: TripCard(
                trip: trip,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PassengerTripDetailsScreen(trip: trip),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}