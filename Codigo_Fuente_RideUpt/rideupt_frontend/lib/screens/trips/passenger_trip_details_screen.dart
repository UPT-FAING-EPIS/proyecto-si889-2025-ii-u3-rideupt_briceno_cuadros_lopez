import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/models/user.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/widgets/error_dialog.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/screens/trips/passenger_trip_in_progress_screen.dart';
import 'package:rideupt_app/screens/ratings/ratings_screen.dart';
import 'package:rideupt_app/screens/ratings/rate_trip_screen.dart';
import 'package:rideupt_app/services/rating_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rideupt_app/utils/map_markers.dart' show createGreenMarker, createRedMarker, getLargeMarkerAnchor;
import 'package:rideupt_app/utils/directions_service.dart';
import 'package:rideupt_app/screens/chat/chat_screen.dart';
import 'package:rideupt_app/services/socket_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class PassengerTripDetailsScreen extends StatefulWidget {
  final Trip trip;
  const PassengerTripDetailsScreen({super.key, required this.trip});

  @override
  State<PassengerTripDetailsScreen> createState() => _PassengerTripDetailsScreenState();
}

class _PassengerTripDetailsScreenState extends State<PassengerTripDetailsScreen> {
  Trip? _fullTrip;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double? _distanceKm;
  int? _estimatedMinutes;
  bool _isAtPickupLocation = false;
  bool _isCheckingLocation = false;
  double? _distanceToPickup;
  String? _mapStyle;
  BitmapDescriptor? _greenMarker;
  BitmapDescriptor? _redMarker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
      _loadMapStyle();
      _loadMarkers();
      _setupSocketListeners();
    });
  }
  
  @override
  void dispose() {
    // Limpiar listeners de socket
    final socket = SocketService().socket;
    socket?.off('tripUpdated');
    socket?.off('tripStarted');
    super.dispose();
  }
  
  void _setupSocketListeners() {
    final socket = SocketService().socket;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    if (socket == null || currentUserId == null) return;
    
    // Unirse a la sala del viaje
    SocketService().joinTripRoom(widget.trip.id);
    
    // Escuchar cuando el conductor inicia el viaje
    socket.on('tripStarted', (data) async {
      if (!mounted) return;
      
      try {
        // Actualizar el viaje
        await tripProvider.fetchMyTrips(force: true);
        final updatedTrip = await tripProvider.fetchTripById(widget.trip.id);
        
        if (mounted && updatedTrip != null && updatedTrip.isInProgress) {
          // Buscar el estado del pasajero actual
          final myPassenger = updatedTrip.passengers.firstWhere(
            (p) => p.user.id == currentUserId,
            orElse: () => TripPassenger(
              user: authProvider.user!,
              status: 'none',
              bookedAt: DateTime.now(),
            ),
          );
          
          // Solo mostrar diálogo si el pasajero está confirmado y NO ha confirmado que está en el vehículo
          if (myPassenger.status == 'confirmed' && !myPassenger.inVehicle) {
            _showConfirmInVehicleDialog(updatedTrip, tripProvider);
          }
        }
      } catch (e) {
        debugPrint('Error al procesar inicio de viaje: $e');
      }
    });
    
    // Escuchar actualizaciones del viaje
    socket.on('tripUpdated', (data) async {
      if (!mounted) return;
      
      try {
        // Actualizar el viaje inmediatamente
        await tripProvider.fetchMyTrips(force: true);
        final updatedTrip = await tripProvider.fetchTripById(widget.trip.id);
        
        if (mounted && updatedTrip != null) {
          setState(() {
            _fullTrip = updatedTrip;
          });
          
          // Si el viaje inició y el pasajero está confirmado Y ya confirmó que está en el vehículo, navegar
          if (updatedTrip.isInProgress) {
            final myPassenger = updatedTrip.passengers.firstWhere(
              (p) => p.user.id == currentUserId,
              orElse: () => TripPassenger(
                user: authProvider.user!,
                status: 'none',
                bookedAt: DateTime.now(),
              ),
            );
            
            // Solo redirigir si está confirmado Y ya confirmó que está en el vehículo
            if (myPassenger.status == 'confirmed' && myPassenger.inVehicle) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => PassengerTripInProgressScreen(trip: updatedTrip),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error al procesar actualización de viaje: $e');
      }
    });
  }

  void _showConfirmInVehicleDialog(Trip trip, TripProvider tripProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.directions_car, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Viaje Iniciado!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El conductor ha iniciado el viaje.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Ya estás en el vehículo?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('AÚN NO'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Confirmar que está en el vehículo
              final success = await tripProvider.confirmInVehicle(trip.id);
              
              if (mounted) {
                if (success) {
                  // Actualizar el viaje y redirigir
                  final updatedTrip = await tripProvider.fetchTripById(trip.id);
                  if (updatedTrip != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PassengerTripInProgressScreen(trip: updatedTrip),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${tripProvider.errorMessage}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('SÍ, ESTOY EN EL VEHÍCULO'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMarkers() async {
    final green = await createGreenMarker();
    final red = await createRedMarker();
    if (mounted) {
      setState(() {
        _greenMarker = green;
        _redMarker = red;
        _setupMap();
      });
    }
  }
  
  Future<void> _loadMapStyle() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (isDark) {
      // Estilo oscuro para el mapa
      final style = '''
      [
        {
          "elementType": "geometry",
          "stylers": [{"color": "#1d2c4d"}]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#8ec3b9"}]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#1a3646"}]
        },
        {
          "featureType": "administrative.country",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#4b6878"}]
        },
        {
          "featureType": "administrative.land_parcel",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#64779e"}]
        },
        {
          "featureType": "administrative.province",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#4b6878"}]
        },
        {
          "featureType": "landscape.man_made",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#334e87"}]
        },
        {
          "featureType": "landscape.natural",
          "elementType": "geometry",
          "stylers": [{"color": "#023e58"}]
        },
        {
          "featureType": "poi",
          "elementType": "geometry",
          "stylers": [{"color": "#283d6a"}]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#6f9ba5"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry.fill",
          "stylers": [{"color": "#023e58"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#3C7680"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [{"color": "#304a7d"}]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#98a5be"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [{"color": "#2c6675"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#255763"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#b0d5ce"}]
        },
        {
          "featureType": "transit",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#98a5be"}]
        },
        {
          "featureType": "transit.line",
          "elementType": "geometry",
          "stylers": [{"color": "#283d6a"}]
        },
        {
          "featureType": "transit.station",
          "elementType": "geometry",
          "stylers": [{"color": "#3a4762"}]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [{"color": "#0e1626"}]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#4e6d70"}]
        }
      ]
      ''';
      if (mounted) {
        setState(() {
          _mapStyle = style;
        });
      }
    }
  }

  Future<void> _loadDetails() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final t = await tripProvider.fetchTripById(widget.trip.id);
    if (!mounted) return;
    setState(() {
      _fullTrip = t ?? widget.trip;
      _setupMap();
      _calculateDistanceAndTime();
      _checkPickupLocation();
    });
  }
  
  Future<void> _checkPickupLocation() async {
    final trip = _fullTrip ?? widget.trip;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    // Solo verificar si el pasajero está confirmado
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
    
    if (myPassengerStatus != 'confirmed') return;
    
    try {
      setState(() => _isCheckingLocation = true);
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        trip.origin.coordinates.latitude,
        trip.origin.coordinates.longitude,
      );
      
      // Considerar que está en el punto si está a menos de 100 metros
      final isAtLocation = distance < 100;
      final distanceKm = distance / 1000;
      
      if (mounted) {
        setState(() {
          _isAtPickupLocation = isAtLocation;
          _distanceToPickup = distanceKm;
          _isCheckingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingLocation = false);
      }
    }
  }

  Future<void> _setupMap() async {
    final trip = _fullTrip ?? widget.trip;
    
    _markers = {};
    
    if (_greenMarker != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: trip.origin.coordinates,
          icon: _greenMarker!,
          anchor: getLargeMarkerAnchor(),
          draggable: false,
          infoWindow: InfoWindow(
            title: 'Origen',
            snippet: trip.origin.name,
          ),
        ),
      );
    }
    
    if (_redMarker != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: trip.destination.coordinates,
          icon: _redMarker!,
          anchor: getLargeMarkerAnchor(),
          draggable: false,
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: trip.destination.name,
          ),
        ),
      );
    }

    // Obtener ruta real usando Google Directions API
    final routePoints = await getRoute(
      trip.origin.coordinates,
      trip.destination.coordinates,
    );

    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints ?? [trip.origin.coordinates, trip.destination.coordinates],
            color: const Color(0xFF64B5F6), // Azul claro
            width: 6,
            patterns: routePoints != null ? [] : [PatternItem.dash(30), PatternItem.gap(10)],
            geodesic: true,
          ),
        };
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        _fitBounds();
      });
    }
  }

  void _fitBounds() {
    if (_mapController == null) return;
    final trip = _fullTrip ?? widget.trip;
    
    double south = math.min(trip.origin.coordinates.latitude, trip.destination.coordinates.latitude);
    double north = math.max(trip.origin.coordinates.latitude, trip.destination.coordinates.latitude);
    double west = math.min(trip.origin.coordinates.longitude, trip.destination.coordinates.longitude);
    double east = math.max(trip.origin.coordinates.longitude, trip.destination.coordinates.longitude);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  void _calculateDistanceAndTime() {
    final trip = _fullTrip ?? widget.trip;
    
    // Calcular distancia con Haversine
    const double earthRadius = 6371;
    double lat1 = trip.origin.coordinates.latitude * math.pi / 180;
    double lat2 = trip.destination.coordinates.latitude * math.pi / 180;
    double deltaLat = (trip.destination.coordinates.latitude - trip.origin.coordinates.latitude) * math.pi / 180;
    double deltaLng = (trip.destination.coordinates.longitude - trip.origin.coordinates.longitude) * math.pi / 180;

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    _distanceKm = earthRadius * c;
    
    // Estimar tiempo: asumiendo velocidad promedio en ciudad de 30 km/h
    _estimatedMinutes = (_distanceKm! / 30 * 60).ceil();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final trip = _fullTrip ?? widget.trip;
    final confirmedPassengers = trip.passengers.where((p) => p.status == 'confirmed').toList();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    // Verificar el estado del usuario actual en este viaje
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

    // Si el viaje está en curso y el usuario está confirmado, redirigir a la pantalla de recorrido
    if (trip.isInProgress && myPassengerStatus == 'confirmed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PassengerTripInProgressScreen(trip: trip),
          ),
        );
      });
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Detalles del Viaje',
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
          if (_canChat(trip))
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Chat del viaje',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(trip: trip),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeAreaWrapper(
        top: false, // El AppBar maneja el safe area superior
        bottom: true, // Necesitamos safe area inferior para los botones
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
          // Mapa con ruta - Estilo INDRIVE (más grande y prominente)
          Container(
            height: size.height * 0.4, // 40% de la pantalla
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
            ),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: trip.origin.coordinates,
                    zoom: 14,
                  ),
                  style: _mapStyle,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Delay para evitar errores de FrameEvents
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted && _mapController != null) {
                        _fitBounds();
                      }
                    });
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  // Optimizaciones de rendimiento
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  liteModeEnabled: false,
                ),
                
                // Información de ruta flotante estilo INDRIVE
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.route,
                            color: colorScheme.primary,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recorrido',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 14 : 12,
                                ),
                              ),
                              if (_distanceKm != null && _estimatedMinutes != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${_distanceKm!.toStringAsFixed(1)} km • ~$_estimatedMinutes min',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: isTablet ? 12 : 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info del viaje
          ResponsivePadding(
            mobile: const EdgeInsets.all(16.0),
            tablet: const EdgeInsets.all(24.0),
            desktop: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Countdown
                if (trip.expiresAt != null)
                  Card(
                    color: _getCountdownColor(trip),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.white, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.timeRemainingText,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Tiempo para que expire',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Información de ruta
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Trayecto',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildRouteInfo(Icons.trip_origin, 'Origen', trip.origin.name, Colors.green),
                        const SizedBox(height: 12),
                        _buildRouteInfo(Icons.place, 'Destino', trip.destination.name, Colors.red),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                Icons.straighten,
                                'Distancia',
                                _distanceKm != null ? '${_distanceKm!.toStringAsFixed(2)} km' : 'Calculando...',
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatBox(
                                Icons.access_time,
                                'Tiempo est.',
                                _estimatedMinutes != null ? '$_estimatedMinutes min' : 'Calculando...',
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Información del conductor
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conductor',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo,
                            radius: 28,
                            child: Text(
                              trip.driver.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${trip.driver.firstName} ${trip.driver.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trip.driver.university),
                              if (trip.driver.hasRatings) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      trip.driver.averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ...List.generate(5, (index) {
                                      return Icon(
                                        index < trip.driver.averageRating.floor() 
                                          ? Icons.star 
                                          : index < trip.driver.averageRating 
                                            ? Icons.star_half 
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 14,
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: trip.driver.hasRatings
                              ? IconButton(
                                  icon: const Icon(Icons.star, size: 20),
                                  onPressed: () => _onViewDriverRatings(context, trip.driver),
                                  tooltip: 'Ver calificaciones del conductor',
                                )
                              : null,
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBox(
                                Icons.attach_money,
                                'Precio',
                                'S/. ${trip.pricePerSeat.toStringAsFixed(2)}',
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatBox(
                                Icons.event_seat,
                                'Asientos',
                                '${trip.availableSeats - trip.seatsBooked} disponibles',
                                trip.seatsBooked >= trip.availableSeats ? Colors.red : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pasajeros confirmados
                if (confirmedPassengers.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Viajarás con (${confirmedPassengers.length})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          ...confirmedPassengers.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    p.user.firstName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.user.firstName} ${p.user.lastName}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        p.user.university,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.verified, color: Colors.green, size: 20),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón de acción según estado
                _buildActionButton(trip, myPassengerStatus, theme, colorScheme, isTablet),
                
                // Espacio adicional al final para evitar que quede oculto
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoItem(IconData icon, String value, String label, Color color, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 2 : 1),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Trip trip, String myStatus, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Consumer<TripProvider>(
      builder: (ctx, tripProvider, _) {
        final seatsAvailable = trip.availableSeats - trip.seatsBooked;
        final canJoin = seatsAvailable > 0 && !trip.isExpired;
        
        // Si el pasajero está confirmado
        if (myStatus == 'confirmed') {
          // Si el viaje ya inició, no puede cancelar
          if (trip.status == 'in-progress') {
            return Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Estás en este viaje!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'El viaje ha iniciado. ¡Disfruta el viaje!',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Si el viaje está completado, mostrar botón para calificar
          if (trip.isCompleted) {
            return Column(
              children: [
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Viaje completado!',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Califica tu experiencia con el conductor',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _onRateTrip(context, trip),
                    icon: const Icon(Icons.star),
                    label: const Text('CALIFICAR VIAJE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          }
          
          // Si el viaje no ha iniciado, puede cancelar
          return Column(
            children: [
              // Estado de confirmación - Estilo INDRIVE
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondaryContainer,
                      colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: colorScheme.onSecondary,
                        size: isTablet ? 32 : 28,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Estás confirmado!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 20 : 18,
                            ),
                          ),
                          SizedBox(height: isTablet ? 4 : 2),
                          Text(
                            'El conductor te recogerá en el punto de encuentro',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              
              // Punto de encuentro con confirmación de ubicación - Estilo INDRIVE
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAtPickupLocation 
                        ? colorScheme.secondary 
                        : colorScheme.outline.withValues(alpha: 0.2),
                    width: _isAtPickupLocation ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: colorScheme.primary,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Punto de Encuentro',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                              SizedBox(height: isTablet ? 4 : 2),
                              Text(
                                trip.origin.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: isTablet ? 14 : 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_distanceToPickup != null) ...[
                                SizedBox(height: isTablet ? 6 : 4),
                                Row(
                                  children: [
                                    Icon(
                                      _isAtPickupLocation 
                                          ? Icons.check_circle 
                                          : Icons.location_searching,
                                      color: _isAtPickupLocation 
                                          ? colorScheme.secondary 
                                          : colorScheme.onSurfaceVariant,
                                      size: isTablet ? 16 : 14,
                                    ),
                                    SizedBox(width: isTablet ? 6 : 4),
                                    Text(
                                      _isAtPickupLocation
                                          ? 'Estás en el punto de encuentro'
                                          : 'A ${_distanceToPickup!.toStringAsFixed(2)} km del punto',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _isAtPickupLocation 
                                            ? colorScheme.secondary 
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: _isAtPickupLocation 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                        fontSize: isTablet ? 13 : 11,
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
                    SizedBox(height: isTablet ? 16 : 12),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCheckingLocation 
                                ? null 
                                : () => _checkPickupLocation(),
                            icon: _isCheckingLocation
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.my_location,
                                    size: isTablet ? 20 : 18,
                                  ),
                            label: Text(
                              _isCheckingLocation 
                                  ? 'Verificando...' 
                                  : 'Verificar Ubicación',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 14 : 12,
                                horizontal: isTablet ? 16 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openInGoogleMaps(trip.origin.coordinates, trip.origin.name),
                            icon: Icon(
                              Icons.directions,
                              size: isTablet ? 20 : 18,
                            ),
                            label: Text(
                              'Navegar',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 14 : 12,
                                horizontal: isTablet ? 16 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              
              // Información del recorrido - Estilo INDRIVE
              if (_distanceKm != null && _estimatedMinutes != null)
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.straighten,
                        '${_distanceKm!.toStringAsFixed(1)} km',
                        'Distancia',
                        colorScheme.primary,
                        isTablet,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      _buildInfoItem(
                        Icons.access_time,
                        '~$_estimatedMinutes min',
                        'Tiempo estimado',
                        colorScheme.tertiary,
                        isTablet,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      _buildInfoItem(
                        Icons.attach_money,
                        'S/. ${trip.pricePerSeat.toStringAsFixed(0)}',
                        'Precio',
                        colorScheme.secondary,
                        isTablet,
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: isTablet ? 20 : 16),
              
              // Botón cancelar participación
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: tripProvider.isLoading
                    ? null
                    : () => _onLeaveTrip(trip.id),
                  icon: tripProvider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.error,
                        ),
                      )
                    : Icon(
                        Icons.exit_to_app,
                        size: isTablet ? 20 : 18,
                      ),
                  label: Text(
                    tripProvider.isLoading
                      ? 'Cancelando...'
                      : 'CANCELAR MI PARTICIPACIÓN',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16 : 14,
                      horizontal: isTablet ? 20 : 16,
                    ),
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                      color: colorScheme.error,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        // Si el pasajero está pendiente
        if (myStatus == 'pending') {
          return Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitud Pendiente',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Espera a que el conductor revise tu solicitud',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Si el pasajero fue rechazado, permitir solicitar de nuevo
        if (myStatus == 'rejected') {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: !tripProvider.isLoading
                ? () async {
                    final success = await tripProvider.bookTrip(trip.id);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Solicitud enviada nuevamente!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      await _loadDetails();
                    } else {
                      showErrorDialog(context, 'Error', tripProvider.errorMessage);
                    }
                  }
                : null,
              icon: tripProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
              label: Text(
                tripProvider.isLoading
                  ? 'Enviando...'
                  : 'VOLVER A SOLICITAR',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
        
        // Si no está en el viaje, mostrar botón para solicitar
        return FutureBuilder<Trip?>(
          future: tripProvider.getUnratedCompletedTrip(),
          builder: (context, unratedSnapshot) {
            if (unratedSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: double.infinity,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            final unratedTrip = unratedSnapshot.data;
            final hasUnratedTrip = unratedTrip != null;
            
            if (hasUnratedTrip && canJoin) {
              // Verificar si realmente no ha calificado al conductor
              return FutureBuilder<Map<String, dynamic>>(
                future: RatingService.canRateUser(
                  ratedId: unratedTrip.driver.id,
                  tripId: unratedTrip.id,
                  ratingType: 'driver',
                  context: context,
                ),
                builder: (context, ratingSnapshot) {
                  if (ratingSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: double.infinity,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final canRate = ratingSnapshot.data?['canRate'] ?? false;
                  final alreadyRated = ratingSnapshot.data?['alreadyRated'] ?? false;
                  
                  if (!alreadyRated && !canRate) {
                    // No ha calificado, bloquear la reserva
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Calificación Pendiente'),
                              content: const Text(
                                'Debes calificar al conductor de tu viaje anterior antes de poder solicitar un nuevo viaje.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('CANCELAR'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RateTripScreen(trip: unratedTrip),
                                      ),
                                    );
                                  },
                                  child: const Text('CALIFICAR AHORA'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.star),
                        label: const Text('DEBES CALIFICAR PRIMERO'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  
                  // Ya calificó o puede calificar, permitir reserva
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canJoin && !tripProvider.isLoading
                        ? () async {
                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await tripProvider.bookTrip(trip.id);
                            if (!mounted) return;
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('¡Solicitud enviada! Espera la aprobación del conductor.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              await _loadDetails();
                            } else {
                              if (!mounted) return;
                              final errorCtx = context;
                              // ignore: use_build_context_synchronously
                              showErrorDialog(errorCtx, 'Error', tripProvider.errorMessage);
                            }
                          }
                        : null,
                      icon: tripProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.hail),
                      label: Text(
                        tripProvider.isLoading
                          ? 'Enviando...'
                          : !canJoin
                            ? (seatsAvailable <= 0 ? 'SIN ASIENTOS' : 'VIAJE EXPIRADO')
                            : 'SOLICITAR UNIRME AL VIAJE',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: canJoin ? Colors.indigo : Colors.grey,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            }
            
            // No hay viajes sin calificar, permitir reserva normal
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canJoin && !tripProvider.isLoading
                  ? () async {
                      if (!mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await tripProvider.bookTrip(trip.id);
                      if (!mounted) return;
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('¡Solicitud enviada! Espera la aprobación del conductor.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _loadDetails();
                      } else {
                        if (!mounted) return;
                        final errorCtx = context;
                        // ignore: use_build_context_synchronously
                        showErrorDialog(errorCtx, 'Error', tripProvider.errorMessage);
                      }
                    }
                  : null,
                icon: tripProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.hail),
                label: Text(
                  tripProvider.isLoading
                    ? 'Enviando...'
                    : !canJoin
                      ? (seatsAvailable <= 0 ? 'SIN ASIENTOS' : 'VIAJE EXPIRADO')
                      : 'SOLICITAR UNIRME AL VIAJE',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: canJoin ? Colors.indigo : Colors.grey,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onLeaveTrip(String tripId) async {
    // Confirmar antes de cancelar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Participación'),
        content: const Text('¿Estás seguro de que quieres salir de este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SÍ, SALIR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await tripProvider.leaveTrip(tripId);
    if (!mounted) return;
    
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Has salido del viaje exitosamente'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop(); // Regresar al menú
    } else {
      showErrorDialog(context, 'Error', tripProvider.errorMessage);
    }
  }

  Color _getCountdownColor(Trip trip) {
    final minutes = trip.minutesRemaining;
    if (minutes <= 0) return Colors.red.shade700;
    if (minutes <= 3) return Colors.red.shade600;
    if (minutes <= 6) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  Future<void> _openInGoogleMaps(LatLng coordinates, String locationName) async {
    try {
      // Crear URL para Google Maps con navegación
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${coordinates.latitude},${coordinates.longitude}&travelmode=driving';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback: abrir Google Maps con la ubicación
        final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=${coordinates.latitude},${coordinates.longitude}';
        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
        } else {
          // Mostrar mensaje de error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir Google Maps. Instala la aplicación.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRateTrip(BuildContext context, Trip trip) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RateTripScreen(trip: trip),
      ),
    );
  }

  Future<void> _onViewDriverRatings(BuildContext context, User driver) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RatingsScreen(user: driver),
      ),
    );
  }

  // Verificar si el usuario puede chatear (solo conductor o pasajeros confirmados)
  bool _canChat(Trip trip) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    if (currentUserId == null) return false;

    // El conductor siempre puede chatear
    if (trip.driver.id == currentUserId) {
      // Solo si el viaje está activo (no completado, cancelado o expirado)
      return !trip.isCompleted && !trip.isCancelled && !trip.isExpired;
    }

    // Verificar si es pasajero confirmado
    final isConfirmedPassenger = trip.passengers.any(
      (p) => p.user.id == currentUserId && p.status == 'confirmed',
    );

    if (isConfirmedPassenger) {
      // Solo si el viaje está activo
      return !trip.isCompleted && !trip.isCancelled && !trip.isExpired;
    }

    return false;
  }
}




