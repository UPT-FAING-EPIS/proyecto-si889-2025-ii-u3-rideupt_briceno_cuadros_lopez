// lib/providers/trip_provider.dart (ACTUALIZADO)
import 'package:flutter/material.dart';
import 'package:rideupt_app/api/api_service.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/providers/auth_provider.dart';

class TripProvider with ChangeNotifier {
  final AuthProvider? _authProvider;
  final ApiService _apiService = ApiService();

  TripProvider(this._authProvider);

  List<Trip> _availableTrips = [];
  List<Trip> _myTrips = []; // Lista para "Mis Viajes"
  bool _isLoading = false;
  bool _isInitialLoad = true; // Para distinguir carga inicial de actualizaciones
  String _errorMessage = '';
  
  // Caché para historial filtrado (optimización de rendimiento)
  List<Trip>? _cachedHistoryTrips;
  String? _cachedHistoryUserId;
  bool? _cachedHistoryIsDriver;
  DateTime? _cachedHistoryTimestamp;
  static const Duration _historyCacheDuration = Duration(minutes: 1);

  List<Trip> get availableTrips => _availableTrips;
  List<Trip> get myTrips => _myTrips;
  // Viajes activos: incluye viajes en proceso, activos (esperando) y completos (llenos)
  List<Trip> get activeMyTrips => _myTrips.where((trip) {
    final status = trip.status;
    // Incluir viajes en proceso
    if (status == 'en-proceso') return !trip.isCancelled;
    // Incluir viajes esperando (si no han expirado por tiempo)
    if (status == 'esperando') {
      if (trip.expiresAt != null) {
        return !trip.isCancelled && DateTime.now().isBefore(trip.expiresAt!);
      }
      return !trip.isCancelled;
    }
    // Incluir viajes completos (llenos)
    if (status == 'completo') return !trip.isCancelled;
    return false;
  }).toList();
  
  // Viajes completados: solo los que tienen estado 'completado' o 'completed'
  // NO verificar isExpired porque los completados pueden tener expiresAt pasado
  List<Trip> get completedMyTrips => _myTrips.where((trip) => 
    trip.isCompleted && !trip.isCancelled
  ).toList();
  
  /// Obtiene el historial de viajes filtrado y cacheado (optimizado)
  /// [userId] - ID del usuario actual
  /// [isDriver] - Si el usuario es conductor
  /// [limit] - Límite de viajes a retornar (default: 10)
  List<Trip> getHistoryTrips(String? userId, bool isDriver, {int limit = 10}) {
    // Verificar si el caché es válido
    final now = DateTime.now();
    final isCacheValid = _cachedHistoryTrips != null &&
        _cachedHistoryUserId == userId &&
        _cachedHistoryIsDriver == isDriver &&
        _cachedHistoryTimestamp != null &&
        now.difference(_cachedHistoryTimestamp!) < _historyCacheDuration;
    
    if (isCacheValid) {
      return _cachedHistoryTrips!.take(limit).toList();
    }
    
    // Filtrar y cachear
    final historyTrips = _myTrips.where((trip) {
      // Verificar que el viaje esté completado
      final isCompleted = trip.isCompleted;
      
      // Verificar que NO esté cancelado, en proceso, o con estado 'expirado'
      final isNotCancelled = !trip.isCancelled;
      final isNotInProgress = !trip.isInProgress;
      final isNotExpiredStatus = trip.status != 'expirado' && trip.status != 'expired';
      
      // Verificar que el usuario participó en el viaje
      bool userParticipated = false;
      if (userId != null) {
        if (isDriver) {
          userParticipated = trip.driver.id == userId;
        } else {
          userParticipated = trip.passengers.any(
            (p) => p.user.id == userId && p.status == 'confirmed'
          );
        }
      }
      
      return isCompleted && isNotCancelled && isNotInProgress && isNotExpiredStatus && userParticipated;
    }).toList()
      ..sort((a, b) {
        // Ordenar por fecha de creación (más recientes primero)
        return b.departureTime.compareTo(a.departureTime);
      });
    
    // Actualizar caché
    _cachedHistoryTrips = historyTrips;
    _cachedHistoryUserId = userId;
    _cachedHistoryIsDriver = isDriver;
    _cachedHistoryTimestamp = now;
    
    return historyTrips.take(limit).toList();
  }
  
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;
  String get errorMessage => _errorMessage;

  String? get _token => _authProvider?.token;

  Future<void> fetchAvailableTrips() async {
    if (_token == null || _isDisposed) return;
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await _apiService.get('trips', _token!);
      if (_isDisposed) return;
      
      if (response is List) {
        _availableTrips = response
            .map((data) => Trip.fromJson(data as Map<String, dynamic>))
            .toList();
        _errorMessage = '';
        notifyListeners();
      } else {
        _errorMessage = 'Error al obtener viajes: respuesta inválida';
        _availableTrips = [];
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = _extractErrorMessage(e);
        _availableTrips = [];
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
        notifyListeners();
      }
    }
  }
  
  /// Extrae el mensaje de error de forma consistente
  String _extractErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('HttpException: ')) {
      return errorString.replaceAll('HttpException: ', '');
    }
    if (errorString.contains('SocketException: ')) {
      return 'Error de conexión. Verifica tu conexión a Internet.';
    }
    if (errorString.contains('TimeoutException')) {
      return 'Tiempo de espera agotado. Intenta de nuevo.';
    }
    if (errorString.contains('FormatException')) {
      return 'Error al procesar la respuesta del servidor.';
    }
    return errorString.replaceAll('Exception: ', '');
  }

  // --- ¡NUEVA FUNCIÓN! ---
  DateTime? _lastFetchMyTrips;
  static const Duration _fetchMyTripsThrottle = Duration(seconds: 2); // Reducido de 5 a 2 segundos
  
  Future<void> fetchMyTrips({bool force = false}) async {
    if (_token == null || _isDisposed) return;
    
    // Throttle: evitar llamadas muy frecuentes (solo si no es forzado)
    if (!force && _lastFetchMyTrips != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchMyTrips!);
      if (timeSinceLastFetch < _fetchMyTripsThrottle) {
        return; // Saltar esta llamada si fue muy reciente
      }
    }
    
    // Si es forzado, actualizar inmediatamente sin throttle
    if (force) {
      _lastFetchMyTrips = null; // Resetear para permitir actualización inmediata
    } else {
      _lastFetchMyTrips = DateTime.now();
    }
    
    // Solo mostrar loading en la primera carga o si es forzado
    if (_isInitialLoad || force) {
      _setLoading(true);
    }
    
    final isDriver = _authProvider?.user?.role == 'driver';
    final endpoint = isDriver ? 'trips/my-driver-trips' : 'trips/my-passenger-trips';
    
    try {
      final response = await _apiService.get(endpoint, _token!);
      
      // Verificar si fue disposed durante la llamada
      if (_isDisposed) return;
      
      // Verificar que la respuesta sea una lista
      if (response is! List) {
        // Log solo en modo debug
        // debugPrint('ERROR: Respuesta no es una lista, es: ${response.runtimeType}');
        if (!_isDisposed) {
          _myTrips = [];
          _errorMessage = 'Error al obtener viajes';
          _isInitialLoad = false;
          _setLoading(false);
          notifyListeners();
        }
        return;
      }
      
      if (!_isDisposed) {
        final List<dynamic> tripData = response;
        _myTrips = tripData.map((data) => Trip.fromJson(data as Map<String, dynamic>)).toList();
        
        // Invalidar caché de historial cuando se actualizan los viajes
        _invalidateHistoryCache();
        
        // Log solo en modo debug y solo el conteo
        // debugPrint('✅ fetchMyTrips: ${_myTrips.length} viajes');
        
        _errorMessage = '';
        _isInitialLoad = false;
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      if (_isDisposed) return;
      
      _errorMessage = _extractErrorMessage(e);
      if (!_isDisposed) {
        _myTrips = [];
        _isInitialLoad = false;
        _setLoading(false);
        notifyListeners();
      }
    }
  }

  // Verificar si hay viajes completados sin calificar (para pasajeros)
  Future<Trip?> getUnratedCompletedTrip() async {
    if (_authProvider?.user?.role != 'passenger') return null;
    
    final currentUserId = _authProvider?.user?.id;
    if (currentUserId == null) return null;
    
    // Buscar viajes completados donde el usuario es pasajero confirmado
    for (final trip in completedMyTrips) {
      final isPassenger = trip.passengers.any(
        (p) => p.user.id == currentUserId && p.status == 'confirmed'
      );
      
      if (isPassenger) {
        // Verificar si ya calificó al conductor
        // Esto se verificará en el frontend usando RatingService
        return trip;
      }
    }
    
    return null;
  }

  // --- ¡NUEVA FUNCIÓN! ---
  Future<bool> bookTrip(String tripId) async {
    if (_token == null || _isDisposed) return false;
    _setLoading(true);
    try {
      await _apiService.post('trips/$tripId/book', _token!, {});
      if (_isDisposed) return false;
      // Después de reservar, actualizamos la lista de "mis viajes"
      await fetchMyTrips(force: true);
      if (!_isDisposed) {
        _setLoading(false);
      }
      return !_isDisposed;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = _extractErrorMessage(e);
        _setLoading(false);
        notifyListeners();
      }
      return false;
    }
  }

  // Obtener detalles de un viaje por ID (incluye pasajeros)
  Future<Trip?> fetchTripById(String tripId) async {
    if (_token == null) return null;
    try {
      final data = await _apiService.get('trips/$tripId', _token!);
      return Trip.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      return null;
    }
  }

  // Conductor acepta/rechaza solicitud
  Future<bool> manageBooking({required String tripId, required String passengerId, required String status}) async {
    if (_token == null) return false;
    _setLoading(true);
    try {
      await _apiService.put('trips/$tripId/bookings/$passengerId', _token!, {'status': status});
      await fetchMyTrips(force: true);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTrip(Map<String, dynamic> tripData) async {
    if (_token == null) return false;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      final createdTripData = await _apiService.post('trips', _token!, tripData);
      final newTrip = Trip.fromJson(createdTripData);

      // Actualizar myTrips inmediatamente agregando el nuevo viaje
      _myTrips.insert(0, newTrip);
      notifyListeners();
      
      // Luego actualizar desde el servidor
      await fetchMyTrips(force: true);
      await fetchAvailableTrips();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // --- NUEVAS FUNCIONES PARA GESTIÓN DE VIAJES ---
  
  // Iniciar viaje (conductor)
  Future<bool> startTrip(String tripId) async {
    if (_token == null) return false;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      await _apiService.put('trips/$tripId/start', _token!, {});
      
      // Actualizar lista de mis viajes inmediatamente sin throttle
      _lastFetchMyTrips = null; // Resetear throttle
      await fetchMyTrips(force: true);
      
      // Notificar inmediatamente para que la UI se actualice
      notifyListeners();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Cancelar viaje (conductor)
  Future<bool> cancelTrip(String tripId, {String? cancellationReason}) async {
    if (_token == null) return false;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      // El backend espera PUT, no DELETE
      final Map<String, dynamic> body = cancellationReason != null && cancellationReason.isNotEmpty
          ? {'cancellationReason': cancellationReason}
          : <String, dynamic>{};
      
      await _apiService.put('trips/$tripId/cancel', _token!, body);
      
      // Actualizar lista de mis viajes y viajes disponibles
      await fetchMyTrips(force: true);
      await fetchAvailableTrips();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Salir del viaje (pasajero)
  Future<bool> leaveTrip(String tripId) async {
    if (_token == null) return false;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      await _apiService.delete('trips/$tripId/leave', _token!);
      
      // Actualizar lista de mis viajes
      await fetchMyTrips(force: true);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Finalizar viaje (conductor)
  Future<bool> completeTrip(String tripId) async {
    if (_token == null) return false;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      await _apiService.put('trips/$tripId/complete', _token!, {});
      
      // Actualizar lista de mis viajes
      await fetchMyTrips(force: true);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Confirmar que el pasajero está en el vehículo
  Future<bool> confirmInVehicle(String tripId) async {
    if (_token == null) return false;
    _setLoading(true);
    _errorMessage = '';
    
    try {
      await _apiService.put('trips/$tripId/confirm-in-vehicle', _token!, {});
      
      // Actualizar lista de mis viajes
      await fetchMyTrips(force: true);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Limpia todos los viajes del estado (útil cuando se cambia de rol)
  void clearTrips() {
    _availableTrips = [];
    _myTrips = [];
    _lastFetchMyTrips = null;
    _errorMessage = '';
    _isInitialLoad = true;
    _invalidateHistoryCache();
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  /// Invalida el caché del historial
  void _invalidateHistoryCache() {
    _cachedHistoryTrips = null;
    _cachedHistoryUserId = null;
    _cachedHistoryIsDriver = null;
    _cachedHistoryTimestamp = null;
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}