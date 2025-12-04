import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:rideupt_app/utils/map_markers.dart' show createGreenMarker, createRedMarker, createYellowMarker, getLargeMarkerAnchor, getSmallMarkerAnchor;
import 'package:rideupt_app/utils/directions_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final LocationPoint? origin;
  final bool isSelectingDestination;

  const LocationPickerScreen({
    super.key,
    this.origin,
    this.isSelectingDestination = false,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _pickedLocation;
  String? _pickedLocationName;
  LatLng _initialPosition = const LatLng(-12.046374, -77.042793);
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _destinations = []; // Lista de destinos (máximo 3)
  final List<String> _destinationNames = []; // Nombres de los destinos intermedios
  BitmapDescriptor? _greenMarker;
  BitmapDescriptor? _redMarker;
  BitmapDescriptor? _yellowMarker; // Marcador para waypoints
  double? _distanceKm;
  String? _currentCity; // Ciudad actual del usuario
  bool _isSelectingDestination = false; // Modo para agregar nuevo destino
  
  // Búsqueda
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkers();
    _getCurrentCity();
    _initializeMap();
  }

  /// Obtiene la ciudad actual del usuario
  Future<void> _getCurrentCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          _currentCity = place.locality ?? place.administrativeArea ?? 'Lima';
        });
      }
    } catch (e) {
      // Si falla, usar Lima por defecto
      if (mounted) {
        setState(() {
          _currentCity = 'Lima';
        });
      }
    }
  }

  Future<void> _loadMarkers() async {
    final green = await createGreenMarker();
    final red = await createRedMarker();
    final yellow = await createYellowMarker();
    if (mounted) {
      setState(() {
        _greenMarker = green;
        _redMarker = red;
        _yellowMarker = yellow;
      });
    }
  }

  Future<void> _loadMapStyle() async {
    // Estilo personalizado del mapa (tema oscuro moderno)
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
  }

  Future<void> _initializeMap() async {
    if (widget.origin != null) {
      setState(() {
        _initialPosition = widget.origin!.coordinates;
        _addOriginMarker();
      });
    } else {
      await _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_initialPosition),
        );
      }
    } catch (e) {
      // Error silencioso
    }
  }

  void _addOriginMarker() {
    if (widget.origin == null || _greenMarker == null) return;
    
    _markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.origin!.coordinates,
        icon: _greenMarker!,
        anchor: getLargeMarkerAnchor(),
        draggable: false,
        infoWindow: InfoWindow(
          title: 'Origen',
          snippet: widget.origin!.name,
        ),
      ),
    );
  }

  // Búsqueda de lugares con Google Places API (limitada a la ciudad actual)
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      // Usar Places API Autocomplete limitado a la ciudad actual
      final apiKey = 'AIzaSyAqn3zQNpXL9VgtWpjVBInVJWj9KN6LEvk';
      
      // Construir componente de restricción por ciudad
      String components = 'country:pe';
      if (_currentCity != null) {
        // Limitar a la ciudad actual
        components += '|locality:$_currentCity';
      }
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&key=$apiKey'
        '&components=$components'
        '&language=es'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(data['predictions']);
          });
        } else {
          setState(() {
            _searchResults = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  // Obtener detalles del lugar seleccionado
  Future<void> _selectPlaceFromSearch(Map<String, dynamic> prediction) async {
    try {
      final apiKey = 'AIzaSyAqn3zQNpXL9VgtWpjVBInVJWj9KN6LEvk';
      final placeId = prediction['place_id'];
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$apiKey'
        '&language=es'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final location = result['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final position = LatLng(lat, lng);
          
          _selectLocation(position, result['formatted_address'] ?? prediction['description']);
          
          // Cerrar búsqueda
          _searchController.clear();
          _searchFocusNode.unfocus();
          setState(() {
            _searchResults = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectLocation(LatLng position, [String? name]) async {
    if (!mounted) return;
    
    // Si ya hay 3 destinos, no permitir más
    if (_destinations.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 destinos permitidos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Si ya hay un destino, convertirlo en waypoint
      if (_pickedLocation != null) {
        _destinations.add(_pickedLocation!);
        _destinationNames.add(_pickedLocationName ?? 'Destino ${_destinations.length}');
      }
      
      // El nuevo punto es el destino final
      _pickedLocation = position;
      _pickedLocationName = name;
      _isSelectingDestination = false; // Desactivar modo selección
      
      _updateMarkers();
    });

    // Si hay origen, dibujar ruta y calcular distancia
    if (widget.origin != null) {
      await _drawRoute();
      _calculateDistance();
    }
  }

  /// Actualiza los marcadores en el mapa
  void _updateMarkers() {
    // Limpiar marcadores de destinos
    _markers.removeWhere((marker) => 
      marker.markerId.value.startsWith('destination') || 
      marker.markerId.value.startsWith('waypoint')
    );
    
    // Agregar marcadores de destinos intermedios (waypoints)
    for (int i = 0; i < _destinations.length; i++) {
      if (_yellowMarker != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('waypoint_${i + 1}'),
            position: _destinations[i],
            icon: _yellowMarker!,
            anchor: getSmallMarkerAnchor(),
            draggable: false,
            infoWindow: InfoWindow(
              title: 'Destino ${i + 1}',
              snippet: i < _destinationNames.length ? _destinationNames[i] : 'Punto intermedio',
            ),
          ),
        );
      }
    }
    
    // Agregar marcador del destino final
    // IMPORTANTE: No es arrastrable hasta que se confirme
    if (_pickedLocation != null && _redMarker != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('destination_${_destinations.length + 1}'),
          position: _pickedLocation!,
          icon: _redMarker!,
          anchor: getLargeMarkerAnchor(),
          draggable: false, // No permitir arrastrar hasta confirmar
          infoWindow: InfoWindow(
            title: 'Destino Final',
            snippet: _pickedLocationName ?? 'Ubicación seleccionada',
          ),
        ),
      );
    }
  }

  /// Activa el modo para agregar un nuevo destino
  void _enableDestinationSelection() {
    if (_destinations.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 3 destinos permitidos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSelectingDestination = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toca en el mapa para agregar un destino'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  Future<void> _drawRoute() async {
    if (widget.origin == null || _pickedLocation == null) return;

    _polylines.clear();
    
    // Construir lista de puntos: origen -> destinos intermedios -> destino final
    List<LatLng> allPoints = [widget.origin!.coordinates];
    allPoints.addAll(_destinations);
    allPoints.add(_pickedLocation!);
    
    // Obtener ruta real usando Google Directions API
    // Si hay múltiples destinos, construir la ruta paso a paso
    List<LatLng>? finalRoutePoints;
    
    if (allPoints.length == 2) {
      // Solo origen y destino
      finalRoutePoints = await getRoute(
        allPoints[0],
        allPoints[1],
      );
    } else {
      // Múltiples destinos: construir ruta segmentada
      finalRoutePoints = [];
      for (int i = 0; i < allPoints.length - 1; i++) {
        final segment = await getRoute(
          allPoints[i],
          allPoints[i + 1],
        );
        if (segment != null) {
          if (i > 0) {
            // Evitar duplicar el punto de conexión
            finalRoutePoints.addAll(segment.skip(1));
          } else {
            finalRoutePoints.addAll(segment);
          }
        } else {
          // Fallback: línea recta
          if (i > 0) {
            finalRoutePoints.add(allPoints[i + 1]);
          } else {
            finalRoutePoints.addAll([allPoints[i], allPoints[i + 1]]);
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {
        // Si hay ruta real, usarla; si no, usar línea recta como fallback
        final points = finalRoutePoints ?? allPoints;
        
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF64B5F6), // Azul claro
            width: 6,
            patterns: finalRoutePoints != null ? [] : [PatternItem.dash(30), PatternItem.gap(10)],
            geodesic: true,
          ),
        );
      });

      _fitBounds();
    }
  }

  void _fitBounds() {
    if (widget.origin == null || _pickedLocation == null || _mapController == null) return;

    List<LatLng> allPoints = [widget.origin!.coordinates];
    allPoints.addAll(_destinations);
    allPoints.add(_pickedLocation!);

    double south = allPoints.map((p) => p.latitude).reduce(math.min);
    double north = allPoints.map((p) => p.latitude).reduce(math.max);
    double west = allPoints.map((p) => p.longitude).reduce(math.min);
    double east = allPoints.map((p) => p.longitude).reduce(math.max);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  double _calculateDistanceInKm(LatLng origin, LatLng destination) {
    const double earthRadius = 6371;

    double lat1 = origin.latitude * math.pi / 180;
    double lat2 = destination.latitude * math.pi / 180;
    double deltaLat = (destination.latitude - origin.latitude) * math.pi / 180;
    double deltaLng = (destination.longitude - origin.longitude) * math.pi / 180;

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  void _calculateDistance() {
    if (widget.origin == null || _pickedLocation == null) return;

    double totalDistance = 0.0;
    
    // Construir lista completa de puntos
    List<LatLng> allPoints = [widget.origin!.coordinates];
    allPoints.addAll(_destinations);
    allPoints.add(_pickedLocation!);
    
    // Calcular distancia total sumando segmentos
    for (int i = 0; i < allPoints.length - 1; i++) {
      totalDistance += _calculateDistanceInKm(allPoints[i], allPoints[i + 1]);
    }

    setState(() {
      _distanceKm = totalDistance;
    });
  }
  
  void _confirmSelection() async {
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecciona un destino'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );
      
      String locationName = 'Ubicación seleccionada';
      if(placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName = '${place.street ?? 'Calle'}, ${place.locality ?? 'Lima'}';
      }

      final locationPoint = LocationPoint(name: locationName, coordinates: _pickedLocation!);
      
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(locationPoint);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener la dirección: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.isSelectingDestination ? 'Selecciona el Destino' : 'Selecciona una Ubicación',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            style: _mapStyle,
            onMapCreated: (controller) {
              _mapController = controller;
              if (widget.origin != null && _pickedLocation != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _mapController != null) {
                    _fitBounds();
                  }
                });
              }
            },
            onTap: (LatLng position) {
              // Solo permitir seleccionar si está en modo selección de destino
              if (_isSelectingDestination) {
                _selectLocation(position);
              } else if (_pickedLocation == null) {
                // Si no hay destino, permitir seleccionar el primero
                _selectLocation(position);
              }
              // Si ya hay destino y no está en modo selección, no hacer nada
            },
            onCameraMove: (CameraPosition position) {
              // No hacer nada durante el movimiento de la cámara
              // Los marcadores deben mantenerse en su posición fija
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: false,
          ),
          
          // Barra de búsqueda
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar dirección o lugar...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _searchPlaces,
                  onTap: () {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),

          // Resultados de búsqueda
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.place, color: Colors.blue),
                        title: Text(
                          result['description'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: result['structured_formatting'] != null
                            ? Text(
                                result['structured_formatting']['secondary_text'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        onTap: () => _selectPlaceFromSearch(result),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Card de información
          if (widget.origin != null)
            Positioned(
              top: _searchResults.isNotEmpty ? 380 : 80,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Origen: ${widget.origin!.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_distanceKm != null) ...[
                          const Divider(height: 16),
                          Row(
                            children: [
                              Icon(Icons.straighten, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Distancia: ${_distanceKm!.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_destinations.isNotEmpty) ...[
                          const Divider(height: 16),
                          Text(
                            'Destinos intermedios: ${_destinations.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                        if (_destinations.length < 3 && _pickedLocation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Puedes agregar ${3 - _destinations.length} destino(s) más',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Botón para agregar destino adicional
          if (widget.origin != null && _pickedLocation != null && _destinations.length < 3)
            Positioned(
              top: _searchResults.isNotEmpty ? 380 : 80,
              right: 16,
              child: IgnorePointer(
                ignoring: false,
                child: FloatingActionButton.small(
                  onPressed: _enableDestinationSelection,
                  backgroundColor: Colors.orange,
                  tooltip: 'Agregar destino adicional',
                  child: const Icon(Icons.add_location_alt, color: Colors.white),
                ),
              ),
            ),

          // Botón de confirmación
          if (_pickedLocation != null)
            Positioned(
              bottom: bottomPadding + 16,
              left: 16,
              right: 16,
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _confirmSelection,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: colorScheme.onSecondary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _distanceKm != null
                                    ? 'Confirmar Destino\n${_distanceKm!.toStringAsFixed(2)} km'
                                    : 'Confirmar Ubicación',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Instrucción cuando no hay destino
          if (_pickedLocation == null)
            Positioned(
              bottom: bottomPadding + 16,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isSelectingDestination
                              ? 'Toca en el mapa para seleccionar tu destino'
                              : 'Toca en el mapa para seleccionar una ubicación',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
