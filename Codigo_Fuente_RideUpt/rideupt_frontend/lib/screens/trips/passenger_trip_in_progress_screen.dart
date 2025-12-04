import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/screens/ratings/rate_trip_screen.dart';
import 'package:rideupt_app/utils/map_markers.dart' show createGreenMarker, createRedMarker, getLargeMarkerAnchor;
import 'package:rideupt_app/utils/directions_service.dart';

class PassengerTripInProgressScreen extends StatefulWidget {
  final Trip trip;
  const PassengerTripInProgressScreen({super.key, required this.trip});

  @override
  State<PassengerTripInProgressScreen> createState() => _PassengerTripInProgressScreenState();
}

class _PassengerTripInProgressScreenState extends State<PassengerTripInProgressScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _timer;
  Timer? _checkTripStatusTimer;
  int _elapsedMinutes = 0;
  int _estimatedArrivalMinutes = 0;
  BitmapDescriptor? _greenMarker;
  BitmapDescriptor? _redMarker;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar estilo del mapa cuando las dependencias cambian (incluyendo el tema)
    _loadMapStyle();
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
      _calculateEstimatedArrival();
      _startTimer();
      _startTripStatusChecker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkTripStatusTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (isDark) {
      // Estilo oscuro para el mapa
      _mapStyle = '''
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
          "featureType": "poi",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#1d2c4d"}]
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
          "featureType": "road",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#1d2c4d"}]
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
          "featureType": "road.highway",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#023e58"}]
        },
        {
          "featureType": "transit",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#98a5be"}]
        },
        {
          "featureType": "transit",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#1d2c4d"}]
        },
        {
          "featureType": "transit.line",
          "elementType": "geometry.fill",
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
    }
  }
  
  void _startTripStatusChecker() {
    // Verificar cada 10 segundos si el viaje se completó (aumentado para reducir carga)
    _checkTripStatusTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      
      try {
        final tripProvider = Provider.of<TripProvider>(context, listen: false);
        final updatedTrip = await tripProvider.fetchTripById(widget.trip.id);
        
        if (mounted && updatedTrip != null && updatedTrip.isCompleted) {
          // Cancelar el timer antes de navegar
          _checkTripStatusTimer?.cancel();
          
          // El viaje se completó, redirigir a calificar
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RateTripScreen(trip: updatedTrip),
            ),
          );
        }
      } catch (e) {
        // Error al verificar, continuar normalmente
      }
    });
  }

  Future<void> _setupMap() async {
    final trip = widget.trip;
    
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
        if (mounted) {
          _fitBounds();
        }
      });
    }
  }

  void _fitBounds() {
    if (_mapController == null) return;
    final trip = widget.trip;
    
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

  void _calculateEstimatedArrival() {
    if (!mounted) return;
    
    final trip = widget.trip;
    
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

    double distanceKm = earthRadius * c;
    
    // Estimar tiempo: asumiendo velocidad promedio en ciudad de 30 km/h
    if (mounted) {
      setState(() {
        _estimatedArrivalMinutes = (distanceKm / 30 * 60).ceil();
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedMinutes++;
        });
      }
    });
  }

  int get _remainingMinutes {
    return math.max(0, _estimatedArrivalMinutes - _elapsedMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final confirmedPassengers = trip.passengers.where((p) => p.status == 'confirmed').toList();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Verificar que el viaje esté realmente en proceso y no expirado
    if (!trip.isInProgress || trip.isExpired) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Viaje No Disponible'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                trip.isExpired ? Icons.timer_off : Icons.cancel,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                trip.isExpired ? 'Este viaje ha expirado' : 'Este viaje no está disponible',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No puedes acceder a un viaje que ya ha terminado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Volver al Inicio'),
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
    
    return PopScope(
      canPop: false, // Bloquear retroceso durante el viaje
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Mostrar mensaje si intentan retroceder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No puedes salir del viaje hasta que finalice'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Recorrido en Curso',
            style: TextStyle(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          automaticallyImplyLeading: false, // No permitir volver atrás
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeAreaWrapper(
          top: false, // El AppBar maneja el safe area superior
          bottom: true, // Necesitamos safe area inferior
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Mapa
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, // 40% de la pantalla
                  child: GoogleMap(
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
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    // Optimizaciones de rendimiento
                    compassEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),

                // Información del viaje
                ResponsivePadding(
                  mobile: const EdgeInsets.all(16),
                  tablet: const EdgeInsets.all(24),
                  desktop: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                  // Estado del viaje
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Viajando con ${trip.driver.firstName}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${trip.origin.name} → ${trip.destination.name}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiempo transcurrido y estimado
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeCard(
                          'Tiempo Transcurrido',
                          '$_elapsedMinutes min',
                          Icons.access_time,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeCard(
                          'Llegada Estimada',
                          '$_remainingMinutes min',
                          Icons.flag,
                          Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Información del conductor
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Conductor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  trip.driver.firstName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${trip.driver.firstName} ${trip.driver.lastName}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      trip.driver.university,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Otros pasajeros
                  if (confirmedPassengers.length > 1) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Viajando con (${confirmedPassengers.length - 1})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...confirmedPassengers
                                .where((p) => p.user.id != currentUserId)
                                .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    child: Text(
                                      p.user.firstName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${p.user.firstName} ${p.user.lastName}'),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Mensaje de estado
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El conductor te notificará cuando lleguen al destino',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Espacio adicional al final para evitar que quede oculto
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
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
            ),
          ],
        ),
      ),
    );
  }
}
