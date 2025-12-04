import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/screens/trips/location_picker_screen.dart';
import 'package:rideupt_app/widgets/auth_form_field.dart';
import 'package:rideupt_app/widgets/error_dialog.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  LocationPoint? _origin;
  LocationPoint? _destination;
  final DateTime _departureTime = DateTime.now(); // Hora actual automática
  final _seatsController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoadingLocation = true;
  double? _suggestedPrice;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _checkDriverApproval();
    _getCurrentLocation();
    _loadDriverSeats();
  }

  /// Verificar que el conductor esté aprobado antes de permitir crear viajes
  void _checkDriverApproval() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final approvalStatus = user?.driverApprovalStatus;
      
      if (approvalStatus != 'approved') {
        Navigator.of(context).pop();
        String message;
        if (approvalStatus == 'pending') {
          message = 'Tu solicitud está siendo revisada. Este proceso toma un promedio de 24 a 48 horas. Te notificaremos cuando sea aprobada.';
        } else if (approvalStatus == 'rejected') {
          message = 'Tu solicitud fue rechazada. Por favor, corrige tus documentos desde tu perfil y vuelve a enviarlos para revisión.';
        } else {
          message = 'Debes completar tu perfil de conductor y ser aprobado por un administrador antes de poder crear viajes.';
        }
        
        showErrorDialog(context, 'No puedes crear viajes aún', message);
      }
    });
  }

  /// Cargar el número de asientos del perfil del conductor
  void _loadDriverSeats() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.vehicle != null) {
      _seatsController.text = user!.vehicle!.totalSeats.toString();
    } else {
      _seatsController.text = '4'; // Valor por defecto
    }
  }

  /// Obtener ubicación actual del conductor como origen
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          showErrorDialog(context, 'Ubicación deshabilitada', 
            'Por favor, habilita los servicios de ubicación.');
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            showErrorDialog(context, 'Permiso denegado', 
              'Necesitamos acceso a tu ubicación para crear el viaje.');
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showErrorDialog(context, 'Permiso denegado permanentemente', 
            'Por favor, habilita el permiso de ubicación en la configuración.');
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Obtener posición actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtener nombre de la ubicación usando geocoding inverso
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = 'Mi ubicación actual';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName = '${place.street ?? ''}, ${place.locality ?? 'Lima'}'.trim();
        if (locationName.startsWith(',')) {
          locationName = locationName.substring(1).trim();
        }
      }

      setState(() {
        _origin = LocationPoint(
          name: locationName,
          coordinates: LatLng(position.latitude, position.longitude),
        );
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Error', 'No se pudo obtener tu ubicación: $e');
      }
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Seleccionar destino
  Future<void> _selectDestination() async {
    if (_origin == null) {
      showErrorDialog(context, 'Origen no disponible', 
        'Esperando tu ubicación actual...');
      return;
    }

    final selectedLocation = await Navigator.of(context).push<LocationPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          origin: _origin, // Pasar origen al selector
          isSelectingDestination: true, // Indicar que estamos seleccionando destino
        ),
      ),
    );
    if (selectedLocation != null) {
      setState(() {
        _destination = selectedLocation;
      });
      _calculateDistanceAndPrice();
    }
  }

  /// Calcular distancia entre origen y destino usando fórmula de Haversine
  double _calculateDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371; // Radio de la Tierra en km

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

  /// Calcular distancia y sugerir precio
  void _calculateDistanceAndPrice() {
    if (_origin == null || _destination == null) return;

    double distance = _calculateDistance(
      _origin!.coordinates,
      _destination!.coordinates,
    );

    setState(() {
      _distanceKm = distance;
      // Sugerencia de precio basada en distancia
      // Fórmula: 1 sol base + 0.30 soles por km adicional
      // Mínimo: 1 sol, Máximo: 3 soles
      double calculatedPrice = 1.0 + (distance * 0.30);
      _suggestedPrice = calculatedPrice.clamp(1.0, 3.0);
      _priceController.text = _suggestedPrice!.toStringAsFixed(2);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showErrorDialog(context, 'Formulario Incompleto', 
        'Por favor, completa todos los campos correctamente.');
      return;
    }

    if (_origin == null) {
      showErrorDialog(context, 'Origen no disponible', 
        'Esperando tu ubicación actual...');
      return;
    }

    if (_destination == null) {
      showErrorDialog(context, 'Destino no seleccionado', 
        'Por favor, selecciona un destino en el mapa.');
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price < 1.0 || price > 3.0) {
      showErrorDialog(context, 'Precio inválido', 
        'El precio debe estar entre S/. 1.00 y S/. 3.00');
      return;
    }

    final seats = int.tryParse(_seatsController.text);
    if (seats == null || seats < 1 || seats > 20) {
      showErrorDialog(context, 'Asientos inválidos', 
        'El número de asientos debe estar entre 1 y 20');
      return;
    }

    final tripData = {
      'origin': _origin!.toJson(),
      'destination': _destination!.toJson(),
      'departureTime': _departureTime.toIso8601String(),
      'availableSeats': seats,
      'pricePerSeat': price,
    };

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final success = await tripProvider.createTrip(tripData);

    if (success && mounted) {
      Navigator.of(context).pop();
      showSuccessSnackBar(context, '¡Viaje publicado con éxito! Vigente por 10 minutos.');
    } else if (!success && mounted) {
      String errorMsg = tripProvider.errorMessage;
      
      // Mensaje específico si ya tiene un viaje activo
      if (errorMsg.contains('Ya tienes un viaje activo')) {
        errorMsg = '⚠️ Ya tienes un viaje activo\n\n'
                   'Debes esperar a que expire (10 min) o completarlo '
                   'antes de crear otro viaje.';
      }
      
      showErrorDialog(context, 'No se puede crear el viaje', errorMsg);
    }
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Publicar Nuevo Viaje',
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
      body: SafeAreaWrapper(
        top: false, // El AppBar maneja el safe area superior
        bottom: true, // Necesitamos safe area inferior para los botones
        child: _isLoadingLocation
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Obteniendo tu ubicación actual...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG : AppTheme.spacingMD),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Info Card
                    Card(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                            Expanded(
                              child: Text(
                                'Tu viaje estará disponible por 10 minutos desde ahora',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    
                    // Info Card sobre asientos del vehículo
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.user;
                        final vehicleSeats = user?.vehicle?.totalSeats ?? 4;
                        return Card(
                          color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                                Expanded(
                                  child: Text(
                                    'Tu vehículo tiene $vehicleSeats asientos disponibles',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Selección de Ubicación
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingSM),
                        child: Column(
                          children: [
                            // Origen (automático, no editable)
                            ListTile(
                              leading: Icon(
                                Icons.my_location,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              title: Text(
                                _origin?.name ?? 'Obteniendo ubicación...',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: const Text('Tu ubicación actual (origen)'),
                              trailing: _origin != null 
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.secondary,
                                  )
                                : SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                            ),
                            const Divider(),
                            // Destino (seleccionable)
                            ListTile(
                              leading: Icon(
                                Icons.place,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                _destination?.name ?? 'Toca para seleccionar destino',
                                style: TextStyle(
                                  fontWeight: _destination != null 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                                  color: _destination != null 
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              subtitle: _distanceKm != null
                                  ? Text(
                                      'Distancia: ${_distanceKm!.toStringAsFixed(2)} km',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : const Text('Selecciona el destino del viaje'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _selectDestination,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha y Hora (automática)
                    Card(
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(
                          Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          DateFormat('dd/MM/yyyy hh:mm a').format(_departureTime),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text('Hora de salida (ahora)'),
                        trailing: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Asientos disponibles
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.user;
                        final maxSeats = user?.vehicle?.totalSeats ?? 4;
                        return AuthFormField(
                          controller: _seatsController,
                          labelText: 'Asientos Disponibles (máximo $maxSeats)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el número de asientos';
                            }
                            final seats = int.tryParse(value);
                            if (seats == null || seats < 1 || seats > maxSeats) {
                              return 'Debe ser entre 1 y $maxSeats asientos';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Precio con sugerencia
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthFormField(
                          controller: _priceController,
                          labelText: 'Precio por Asiento (S/. 1.00 - 3.00)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el precio por asiento';
                            }
                            final price = double.tryParse(value);
                            if (price == null) {
                              return 'Ingresa un precio válido';
                            }
                            if (price < 1.0 || price > 3.0) {
                              return 'El precio debe estar entre S/. 1.00 y S/. 3.00';
                            }
                            return null;
                          },
                        ),
                        if (_suggestedPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Precio sugerido: S/. ${_suggestedPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(basado en ${_distanceKm!.toStringAsFixed(1)} km)',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón de publicar
                    Consumer<TripProvider>(
                      builder: (ctx, provider, _) => provider.isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.publish),
                              label: Text(
                                'PUBLICAR VIAJE',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? AppTheme.spacingMD + AppTheme.spacingXS : AppTheme.spacingMD,
                                  horizontal: isTablet ? AppTheme.spacingLG : AppTheme.spacingLG - AppTheme.spacingXS,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                ),
                              ),
                            ),
                    ),
                    
                    // Espacio adicional al final para evitar que quede oculto
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
