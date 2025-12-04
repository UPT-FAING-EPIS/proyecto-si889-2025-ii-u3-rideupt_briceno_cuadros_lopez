// lib/screens/trips/trip_details_screen.dart (NUEVO)
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/models/user.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/widgets/error_dialog.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/screens/trips/driver_trip_in_progress_screen.dart';
import 'package:rideupt_app/screens/ratings/ratings_screen.dart';
import 'package:rideupt_app/screens/ratings/rate_trip_screen.dart';
import 'package:rideupt_app/services/rating_service.dart';
import 'package:rideupt_app/utils/map_markers.dart' show createGreenMarker, createRedMarker, getLargeMarkerAnchor;
import 'package:rideupt_app/utils/directions_service.dart';
import 'package:rideupt_app/screens/chat/chat_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Trip? _fullTrip;
  String? _mapStyle;
  BitmapDescriptor? _greenMarker;
  BitmapDescriptor? _redMarker;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final green = await createGreenMarker();
    final red = await createRedMarker();
    if (mounted) {
      setState(() {
        _greenMarker = green;
        _redMarker = red;
      });
    }
  }

  Future<void> _loadDetails() async {
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final t = await tripProvider.fetchTripById(widget.trip.id);
    if (!mounted) return;
    setState(() {
      _fullTrip = t ?? widget.trip;
    });
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final trip = _fullTrip ?? widget.trip;
    try {
      final routePoints = await getRoute(
        trip.origin.coordinates,
        trip.destination.coordinates,
      );

      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points:
                  routePoints ??
                  [trip.origin.coordinates, trip.destination.coordinates],
              color: const Color(0xFF64B5F6), // Azul claro
              width: 6,
              patterns:
                  routePoints != null
                      ? []
                      : [PatternItem.dash(30), PatternItem.gap(10)],
              geodesic: true,
            ),
          };
        });
      }
    } catch (e) {
      // Si falla la ruta, mostrar línea recta
      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [trip.origin.coordinates, trip.destination.coordinates],
              color: const Color(0xFF64B5F6),
              width: 6,
              patterns: [PatternItem.dash(30), PatternItem.gap(10)],
              geodesic: true,
            ),
          };
        });
      }
    }
  }

  Future<void> _loadMapStyle(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final effectiveTrip = _fullTrip ?? widget.trip;
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.id;
    final isDriver = currentUserId == effectiveTrip.driver.id;

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
          if (_canChat(effectiveTrip))
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Chat del viaje',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(trip: effectiveTrip),
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
            SizedBox(
              height: 260,
              child: Card(
                margin: const EdgeInsets.all(12),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: effectiveTrip.origin.coordinates,
                    zoom: 14,
                  ),
                  style: _mapStyle,
                  onMapCreated: (_) async {
                    await _loadMapStyle(context);
                    setState(() {}); // Actualizar para aplicar el estilo
                  },
                  markers: {
                    if (_greenMarker != null)
                      Marker(
                        markerId: const MarkerId('origin'),
                        position: effectiveTrip.origin.coordinates,
                        icon: _greenMarker!,
                        anchor: getLargeMarkerAnchor(),
                        draggable: false,
                        infoWindow: InfoWindow(
                          title: 'Origen',
                          snippet: effectiveTrip.origin.name,
                        ),
                      ),
                    if (_redMarker != null)
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: effectiveTrip.destination.coordinates,
                        icon: _redMarker!,
                        anchor: getLargeMarkerAnchor(),
                        draggable: false,
                        infoWindow: InfoWindow(
                          title: 'Destino',
                          snippet: effectiveTrip.destination.name,
                        ),
                      ),
                  },
                  polylines: _polylines,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  // Optimizaciones de rendimiento
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            ResponsivePadding(
              mobile: const EdgeInsets.all(16.0),
              tablet: const EdgeInsets.all(24.0),
              desktop: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDetailRow(
                    context,
                    'Conductor:',
                    effectiveTrip.driver.firstName,
                  ),
                  _buildDetailRow(
                    context,
                    'Salida:',
                    DateFormat(
                      'dd MMM, hh:mm a',
                    ).format(effectiveTrip.departureTime),
                  ),
                  _buildDetailRow(
                    context,
                    'Asientos:',
                    '${effectiveTrip.seatsBooked}/${effectiveTrip.availableSeats} ocupados',
                  ),
                  _buildDetailRow(
                    context,
                    'Precio:',
                    'S/. ${effectiveTrip.pricePerSeat.toStringAsFixed(2)} por asiento',
                  ),
                  const SizedBox(height: 16),
                  if (isDriver)
                    _buildPassengersSection(context, effectiveTrip)
                  else
                    _buildJoinButton(context, effectiveTrip),

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

  Widget _buildDetailRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildPassengersSection(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    final pending =
        trip.passengers.where((p) => p.status == 'pending').toList();
    final confirmed =
        trip.passengers.where((p) => p.status == 'confirmed').toList();

    // El conductor puede iniciar el viaje si:
    // 1. Hay al menos un pasajero confirmado
    // 2. El viaje no está en progreso, completado, cancelado o expirado
    // 3. El viaje está en estado "esperando" (active) o "completo" (full)
    final canStartTrip =
        confirmed.isNotEmpty &&
        !trip.isInProgress &&
        !trip.isCompleted &&
        !trip.isCancelled &&
        !trip.isExpired &&
        (trip.isActive || trip.isFull);

    // El conductor puede cancelar si:
    // 1. El viaje no está en progreso, completado, cancelado o expirado
    // 2. NO hay pasajeros que ya están en el vehículo
    // 3. El viaje está en un estado cancelable (esperando, completo)
    // IMPORTANTE: El conductor puede cancelar incluso si hay pasajeros confirmados,
    // siempre que NO estén en el vehículo (se pedirá motivo de cancelación)
    final passengersInVehicle = confirmed.where((p) => p.inVehicle).toList();
    final canCancelTrip =
        passengersInVehicle.isEmpty &&
        !trip.isInProgress &&
        !trip.isCompleted &&
        !trip.isCancelled &&
        !trip.isExpired &&
        (trip.isActive || trip.isFull);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Estado del viaje
        Card(
          color: _getTripStatusColor(trip),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
            child: Row(
              children: [
                Icon(
                  _getTripStatusIcon(trip),
                  color: Colors.white,
                  size: isTablet ? 32 : 28,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTripStatusText(trip),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTripStatusDescription(trip, confirmed.length),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                      // Mostrar contador de 10 minutos solo si está activo
                      if (trip.isActive && trip.waitingTimeText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trip.waitingTimeText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      // Mostrar número de pasajeros confirmados
                      if (confirmed.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${confirmed.length} pasajero${confirmed.length != 1 ? 's' : ''} confirmado${confirmed.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isTablet ? 13 : 11,
                                fontWeight: FontWeight.w500,
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
          ),
        ),
        const SizedBox(height: 16),

        // Botones de acción
        if (!trip.isInProgress &&
            !trip.isCompleted &&
            !trip.isCancelled &&
            !trip.isExpired) ...[
          // Si hay pasajeros confirmados, mostrar botón de iniciar prominentemente
          if (canStartTrip) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _onStartTrip(context, trip.id),
                icon: const Icon(Icons.play_arrow, size: 24),
                label: Text(
                  'INICIAR VIAJE',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 18 : 16,
                    horizontal: isTablet ? 24 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón de cancelar (siempre disponible cuando se puede cancelar)
          // Si hay pasajeros confirmados, se pedirá motivo de cancelación
          if (canCancelTrip) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _onCancelTrip(context, trip.id),
                icon: const Icon(Icons.cancel),
                label: Text(
                  'CANCELAR VIAJE',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error, width: 2),
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 14,
                    horizontal: isTablet ? 24 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Mensaje informativo si hay pasajeros confirmados pero no se puede iniciar
          if (confirmed.isNotEmpty && !canStartTrip && !trip.isExpired) ...[
            Card(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esperando más pasajeros o que el viaje esté completo para iniciar',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),
        ],

        // Botón para calificar cuando el viaje esté completado
        if (trip.isCompleted) ...[
          ElevatedButton.icon(
            onPressed: () => _onRateTrip(context, trip),
            icon: const Icon(Icons.star),
            label: const Text('CALIFICAR VIAJE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          'Solicitudes Pendientes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (pending.isEmpty) const Text('No hay solicitudes pendientes.'),
        ...pending.map(
          (p) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${p.user.firstName} ${p.user.lastName}'),
              subtitle: Text(p.user.university),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed:
                        () =>
                            _onManage(context, trip.id, p.user.id, 'rejected'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed:
                        () =>
                            _onManage(context, trip.id, p.user.id, 'confirmed'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pasajeros Confirmados (${confirmed.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (confirmed.isEmpty) const Text('Aún no hay pasajeros confirmados.'),
        ...confirmed.map(
          (p) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.verified, color: Colors.white),
              ),
              title: Text('${p.user.firstName} ${p.user.lastName}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.user.university),
                  if (p.user.hasRatings) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.user.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 2),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < p.user.averageRating.floor()
                                ? Icons.star
                                : index < p.user.averageRating
                                ? Icons.star_half
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 12,
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.user.hasRatings)
                    IconButton(
                      icon: const Icon(Icons.star, size: 16),
                      onPressed: () => _onViewRatings(context, p.user),
                      tooltip: 'Ver calificaciones',
                    ),
                  if (p.user.phone.isNotEmpty)
                    Text(p.user.phone, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTripStatusText(Trip trip) {
    // Verificar primero si está completado usando el getter
    if (trip.isCompleted) {
      return 'VIAJE COMPLETADO';
    }

    // Verificar otros estados
    if (trip.isInProgress) {
      return 'VIAJE EN CURSO';
    }

    if (trip.isCancelled) {
      return 'VIAJE CANCELADO';
    }

    if (trip.isExpired && !trip.isCompleted) {
      return 'VIAJE EXPIRADO';
    }

    if (trip.isFull) {
      return 'VIAJE LLENO';
    }

    if (trip.isActive) {
      return 'VIAJE ACTIVO';
    }

    // Si no coincide con ningún estado conocido, usar el status directamente
    switch (trip.status) {
      case 'active':
      case 'esperando':
        return 'VIAJE ACTIVO';
      case 'full':
      case 'completo':
        return 'VIAJE LLENO';
      case 'in-progress':
      case 'en-proceso':
        return 'VIAJE EN CURSO';
      case 'completed':
      case 'completado':
        return 'VIAJE COMPLETADO';
      case 'cancelled':
      case 'cancelado':
        return 'VIAJE CANCELADO';
      case 'expired':
      case 'expirado':
        return 'VIAJE EXPIRADO';
      default:
        return 'VIAJE COMPLETADO'; // Por defecto, asumir completado si no se reconoce
    }
  }

  String _getTripStatusDescription(Trip trip, int confirmedCount) {
    // Verificar primero si está completado
    if (trip.isCompleted) {
      return 'El viaje ha finalizado';
    }

    if (trip.isInProgress) {
      return 'El viaje ha iniciado';
    }

    if (trip.isCancelled) {
      return 'El viaje fue cancelado';
    }

    if (trip.isExpired && !trip.isCompleted) {
      return 'El tiempo de espera expiró';
    }

    if (trip.isFull) {
      return 'Todos los asientos están ocupados';
    }

    if (trip.isActive) {
      return confirmedCount > 0
          ? 'Esperando más pasajeros o listo para iniciar'
          : 'Esperando pasajeros';
    }

    return '';
  }

  IconData _getTripStatusIcon(Trip trip) {
    if (trip.isCompleted) {
      return Icons.check_circle;
    }

    if (trip.isInProgress) {
      return Icons.directions_car;
    }

    if (trip.isCancelled) {
      return Icons.cancel;
    }

    if (trip.isExpired && !trip.isCompleted) {
      return Icons.timer_off;
    }

    if (trip.isFull) {
      return Icons.event_seat;
    }

    if (trip.isActive) {
      return Icons.access_time;
    }

    return Icons.check_circle; // Por defecto, icono de completado
  }

  Color _getTripStatusColor(Trip trip) {
    if (trip.isCompleted) {
      return Colors.green; // Verde para completado
    }

    if (trip.isInProgress) {
      return Colors.green;
    }

    if (trip.isCancelled) {
      return Colors.red;
    }

    if (trip.isExpired && !trip.isCompleted) {
      return Colors.red.shade900;
    }

    if (trip.isFull) {
      return Colors.orange;
    }

    if (trip.isActive) {
      return Colors.blue;
    }

    return Colors.green; // Por defecto, verde para completado
  }

  Widget _buildJoinButton(BuildContext context, Trip trip) {
    return Consumer<TripProvider>(
      builder:
          (ctx, tripProvider, _) =>
              tripProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<Trip?>(
                    future: tripProvider.getUnratedCompletedTrip(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final unratedTrip = snapshot.data;
                      final hasUnratedTrip = unratedTrip != null;

                      if (hasUnratedTrip) {
                        // Verificar si realmente no ha calificado al conductor
                        return FutureBuilder<Map<String, dynamic>>(
                          future: RatingService.canRateUser(
                            ratedId: unratedTrip.driver.id,
                            tripId: unratedTrip.id,
                            ratingType: 'driver',
                            context: context,
                          ),
                          builder: (context, ratingSnapshot) {
                            if (ratingSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final canRate =
                                ratingSnapshot.data?['canRate'] ?? false;
                            final alreadyRated =
                                ratingSnapshot.data?['alreadyRated'] ?? false;

                            if (!alreadyRated && !canRate) {
                              // No ha calificado, bloquear la reserva
                              return ElevatedButton.icon(
                                icon: const Icon(Icons.star),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text(
                                            'Calificación Pendiente',
                                          ),
                                          content: const Text(
                                            'Debes calificar al conductor de tu viaje anterior antes de poder solicitar un nuevo viaje.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(ctx).pop(),
                                              child: const Text('CANCELAR'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                                if (mounted) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) => RateTripScreen(
                                                            trip: unratedTrip,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                'CALIFICAR AHORA',
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                label: const Text('DEBES CALIFICAR PRIMERO'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                ),
                              );
                            }

                            // Ya calificó o puede calificar, permitir reserva
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.hail),
                              onPressed: () async {
                                if (!mounted) return;
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                final tripProvider = Provider.of<TripProvider>(
                                  context,
                                  listen: false,
                                );
                                final success = await tripProvider.bookTrip(
                                  trip.id,
                                );
                                if (!mounted) return;
                                if (success) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '¡Solicitud enviada! Espera la aprobación.',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  navigator.pop();
                                } else {
                                  if (!mounted) return;
                                  final errorCtx = context;
                                  showErrorDialog(
                                    // ignore: use_build_context_synchronously
                                    errorCtx,
                                    'Error en la Solicitud',
                                    tripProvider.errorMessage,
                                  );
                                }
                              },
                              label: const Text('SOLICITAR UNIRME'),
                            );
                          },
                        );
                      }

                      // No hay viajes sin calificar, permitir reserva
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.hail),
                        onPressed: () async {
                          if (!mounted) return;
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final tripProvider = Provider.of<TripProvider>(
                            context,
                            listen: false,
                          );
                          final success = await tripProvider.bookTrip(trip.id);
                          if (!mounted) return;
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '¡Solicitud enviada! Espera la aprobación.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            navigator.pop();
                          } else {
                            if (!mounted) return;
                            final errorCtx = context;
                            showErrorDialog(
                              // ignore: use_build_context_synchronously
                              errorCtx,
                              'Error en la Solicitud',
                              tripProvider.errorMessage,
                            );
                          }
                        },
                        label: const Text('SOLICITAR UNIRME'),
                      );
                    },
                  ),
    );
  }

  Future<void> _onManage(
    BuildContext context,
    String tripId,
    String passengerId,
    String status,
  ) async {
    if (!mounted) return;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await tripProvider.manageBooking(
      tripId: tripId,
      passengerId: passengerId,
      status: status,
    );
    if (!mounted) return;
    if (ok) {
      await _loadDetails();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed'
                ? 'Solicitud aceptada'
                : 'Solicitud rechazada',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      final errorCtx = context;
      showErrorDialog(
        // ignore: use_build_context_synchronously
        errorCtx,
        'No se pudo actualizar',
        tripProvider.errorMessage,
      );
    }
  }

  Future<void> _onStartTrip(BuildContext context, String tripId) async {
    if (!mounted) return;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ctx = context;
    // Confirmar antes de iniciar
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Iniciar Viaje'),
            content: const Text(
              '¿Estás seguro de que quieres iniciar el viaje? Una vez iniciado, no se pueden agregar más pasajeros.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('INICIAR'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    final ok = await tripProvider.startTrip(tripId);
    if (!mounted) return;

    if (ok) {
      await _loadDetails();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '¡Viaje iniciado! Los pasajeros han sido notificados.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Redirigir a la pantalla de viaje en curso
      navigator.pushReplacement(
        MaterialPageRoute(
          builder:
              (_) =>
                  DriverTripInProgressScreen(trip: _fullTrip ?? widget.trip),
        ),
      );
    } else {
      if (!mounted) return;
      final errorCtx = context;
      showErrorDialog(
        // ignore: use_build_context_synchronously
        errorCtx,
        'Error al iniciar viaje',
        tripProvider.errorMessage,
      );
    }
  }

  Future<void> _onCancelTrip(BuildContext context, String tripId) async {
    if (!mounted) return;
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    // Obtener el viaje actualizado para verificar pasajeros
    final trip = await tripProvider.fetchTripById(tripId);
    if (!mounted) return;
    if (trip == null) {
      final errorCtx = context;
      showErrorDialog(
        // ignore: use_build_context_synchronously
        errorCtx,
        'Error',
        'No se pudo obtener la información del viaje',
      );
      return;
    }

    final confirmedPassengers =
        trip.passengers.where((p) => p.status == 'confirmed').toList();
    final passengersInVehicle =
        confirmedPassengers.where((p) => p.inVehicle).toList();

    // Si hay pasajeros que ya están en el vehículo, no se puede cancelar
    if (!mounted) return;
    if (passengersInVehicle.isNotEmpty) {
      final errorCtx = context;
      showErrorDialog(
        // ignore: use_build_context_synchronously
        errorCtx,
        'No se puede cancelar',
        'No puedes cancelar el viaje porque hay pasajeros que ya están en el vehículo.',
      );
      return;
    }

    // Si hay pasajeros confirmados pero NO están en el vehículo, pedir motivo
    String? cancellationReason;
    if (confirmedPassengers.isNotEmpty) {
      if (!mounted) return;
      final dialogCtx = context;
      final reasonResult = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: dialogCtx,
        builder: (dialogCtx) {
          final reasonController = TextEditingController();
          return AlertDialog(
            title: const Text('Cancelar Viaje'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hay ${confirmedPassengers.length} pasajero${confirmedPassengers.length != 1 ? 's' : ''} confirmado${confirmedPassengers.length != 1 ? 's' : ''}. Por favor, proporciona un motivo de cancelación:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de cancelación',
                    hintText:
                        'Ej: Emergencia personal, problemas con el vehículo...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(null),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.of(dialogCtx).pop(reasonController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('CONFIRMAR'),
              ),
            ],
          );
        },
      );

      if (reasonResult == null) return; // Usuario canceló
      cancellationReason = reasonResult;
    } else {
      // Si no hay pasajeros confirmados, solo confirmar
      if (!mounted) return;
      final dialogCtx = context;
      final confirmed = await showDialog<bool>(
        // ignore: use_build_context_synchronously
        context: dialogCtx,
        builder:
            (dialogCtx) => AlertDialog(
              title: const Text('Cancelar Viaje'),
              content: const Text(
                '¿Estás seguro de que quieres cancelar el viaje? Esta acción no se puede deshacer.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('NO'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('SÍ, CANCELAR'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;
    }

    // Cancelar el viaje
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    // ignore: use_build_context_synchronously
    final navigator = Navigator.of(context);
    final ok = await tripProvider.cancelTrip(
      tripId,
      cancellationReason: cancellationReason,
    );
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Viaje cancelado exitosamente'),
          backgroundColor: Colors.orange,
        ),
      );
      navigator.pop(); // Regresar a la lista de viajes
    } else {
      if (!mounted) return;
      final errorCtx = context;
      showErrorDialog(
        // ignore: use_build_context_synchronously
        errorCtx,
        'Error al cancelar viaje',
        tripProvider.errorMessage,
      );
    }
  }

  Future<void> _onRateTrip(BuildContext context, Trip trip) async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RateTripScreen(trip: trip)));
  }

  Future<void> _onViewRatings(BuildContext context, User user) async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RatingsScreen(user: user)));
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
