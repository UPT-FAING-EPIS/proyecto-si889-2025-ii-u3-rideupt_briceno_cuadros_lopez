import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/screens/trips/create_trip_screen.dart';
import 'package:rideupt_app/screens/trips/driver_trip_in_progress_screen.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/services/socket_service.dart';
import 'package:rideupt_app/widgets/modern_loading.dart';
import 'package:rideupt_app/widgets/gps_searching_lottie.dart';
import 'package:rideupt_app/widgets/error_dialog.dart';
import 'package:rideupt_app/widgets/safe_area_wrapper.dart';
import 'package:rideupt_app/widgets/passenger_search_radar.dart';
import 'package:rideupt_app/screens/ratings/rate_trip_screen.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/screens/chat/chat_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupSocketListeners();
    });
    
    // Actualizar cada 15 segundos (reducido para mejor performance)
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Widget _buildApprovalStatusView(String? approvalStatus, String? rejectionReason) {
    if (approvalStatus == 'pending') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.pending_actions,
              size: 80,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Verificación en Proceso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Tu solicitud para ser conductor está siendo revisada por nuestro equipo administrativo.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[900],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este proceso toma un promedio de 24 a 48 horas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Te notificaremos cuando tu solicitud sea aprobada y puedas comenzar a crear viajes.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (approvalStatus == 'rejected') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.cancel,
              size: 80,
              color: Colors.red[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Solicitud Rechazada',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                children: [
                  if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Razón del rechazo:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rejectionReason,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Tu solicitud fue rechazada. Puedes corregir tus documentos y volver a enviar tu solicitud para revisión.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[900],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Botón para reenviar solicitud
            _buildResubmitButton(context),
          ],
        ),
      );
    }
    
    return NoDriverTripsLottie(
      onCreateTrip: null,
    );
  }

  Widget _buildResubmitButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user?.driverApprovalStatus != 'rejected') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FilledButton.icon(
        onPressed: authProvider.isLoading
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reenviar Solicitud'),
                    content: const Text(
                      '¿Estás seguro de que deseas reenviar tu solicitud? Asegúrate de haber corregido todos los documentos antes de reenviar.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Reenviar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  final success = await authProvider.resubmitDriverApplication();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitud reenviada exitosamente. Está pendiente de revisión.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    // Recargar datos
                    _loadData();
                  } else if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
        icon: authProvider.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.refresh),
        label: Text(authProvider.isLoading ? 'Reenviando...' : 'Reenviar Solicitud'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socket = SocketService().socket;
    socket?.on('newBookingRequest', (_) {
      if (mounted) {
        // Log solo en modo debug
        // debugPrint('Socket: Nueva solicitud!');
        _loadData();
      }
    });
    socket?.on('tripUpdated', (_) {
      if (mounted) {
        // Log solo en modo debug
        // debugPrint('Socket: Viaje actualizado!');
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      // Forzar actualización sin throttle
      await tripProvider.fetchMyTrips(force: true);
    } catch (e) {
      // Log solo en modo debug
      // debugPrint('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Consumer<TripProvider>(
          builder: (context, tripProvider, child) {
            if (tripProvider.isLoading && tripProvider.myTrips.isEmpty) {
              return const ModernLoading(message: 'Cargando viajes...');
            }

            // Buscar viaje activo (esperando o completo/lleno)
            Trip? activeTrip;
            
            // Buscar en myTrips directamente - el backend devuelve viajes con estado en español
            for (var trip in tripProvider.myTrips) {
              final status = trip.status;
              
              // Solo procesar viajes en estado "esperando" o "completo"
              if (status == 'esperando') {
                // Para viajes "esperando", verificar que NO haya expirado por tiempo
                if (trip.expiresAt != null) {
                  final now = DateTime.now();
                  final expiresAt = trip.expiresAt!;
                  // Si expiresAt es futuro, el viaje está activo
                  if (now.isBefore(expiresAt)) {
                    activeTrip = trip;
                    break;
                  }
                } else {
                  // Si no tiene expiresAt, considerar activo
                  activeTrip = trip;
                  break;
                }
              } else if (status == 'completo') {
                // Viaje completo (lleno) - siempre mostrar
                activeTrip = trip;
                break;
              }
            }
            
            // Si no se encuentra, buscar también en activeMyTrips como respaldo
            if (activeTrip == null) {
              for (var trip in tripProvider.activeMyTrips) {
                final status = trip.status;
                if (status == 'esperando') {
                  if (trip.expiresAt != null) {
                    if (DateTime.now().isBefore(trip.expiresAt!)) {
                      activeTrip = trip;
                      break;
                    }
                  } else {
                    activeTrip = trip;
                    break;
                  }
                } else if (status == 'completo') {
                  activeTrip = trip;
                  break;
                }
              }
            }

            if (activeTrip == null) {
              // Verificar estado de aprobación
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final user = authProvider.user;
              final approvalStatus = user?.driverApprovalStatus;
              
              // Si está pendiente o rechazado, mostrar banner informativo
              if (approvalStatus == 'pending' || approvalStatus == 'rejected') {
                return _buildApprovalStatusView(approvalStatus, user?.driverRejectionReason);
              }
              
              return NoDriverTripsLottie(
                onCreateTrip: null, // El FloatingActionButton maneja la creación
              );
            }

            // activeTrip ya está verificado que no es null aquí
            final currentTrip = activeTrip;
            
            // No crear Scaffold con AppBar aquí, solo mostrar el contenido
            // El HeaderScreen del main_layout_screen ya maneja el encabezado principal
            return _buildActiveTripWithChat(currentTrip, tripProvider, theme, colorScheme, isTablet);
          },
        ),
      ),
      floatingActionButton: Consumer2<TripProvider, AuthProvider>(
        builder: (context, tripProvider, authProvider, child) {
          // Verificar estado de aprobación del conductor
          final user = authProvider.user;
          final isApproved = user?.driverApprovalStatus == 'approved';

          // Buscar si hay viaje activo (esperando o completo)
          final hasActive = tripProvider.myTrips.any((t) {
            final status = t.status;
            if (status == 'esperando') {
              if (t.expiresAt != null) {
                return DateTime.now().isBefore(t.expiresAt!);
              }
              return true;
            }
            return status == 'completo';
          });

          if (hasActive) return const SizedBox.shrink();

          // Si no está aprobado, no mostrar el botón de crear viaje
          if (!isApproved) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              );
              await _loadData();
            },
            label: const Text('Crear Viaje'),
            icon: const Icon(Icons.add_rounded),
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }


  Widget _buildActiveTripWithChat(Trip trip, TripProvider tripProvider, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Stack(
      children: [
        _buildActiveTrip(trip, tripProvider, theme, colorScheme, isTablet),
        // Botón de Chat flotante en la esquina superior derecha
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(trip: trip),
                ),
              );
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat del viaje',
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTrip(Trip trip, TripProvider tripProvider, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    final pending = trip.passengers.where((p) => p.status == 'pending').toList();
    final confirmed = trip.passengers.where((p) => p.status == 'confirmed').toList();
    final seatsLeft = trip.availableSeats - trip.seatsBooked;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: colorScheme.primary,
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        children: [
          // RADAR DE BÚSQUEDA DE PASAJEROS
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: Column(
                children: [
                  // Radar animado
                  const PassengerSearchRadar(size: 180),
                  SizedBox(height: isTablet ? 24 : 20),
                  // Texto de búsqueda
                  Text(
                    'Buscando pasajeros...',
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Text(
                    'Esperando solicitudes de viaje',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // CONTADOR REGRESIVO MEJORADO
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCountdownColor(trip),
                  _getCountdownColor(trip).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getCountdownColor(trip).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: isTablet ? 32 : 28,
                    color: Colors.white,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.timeRemainingText,
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Tiempo restante',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // INFO VIAJE MEJORADA
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inicio
                  Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.trip_origin_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inicio',
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                trip.origin.name,
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  // Línea conectora
                  Padding(
                    padding: EdgeInsets.only(left: isTablet ? 28 : 24),
                    child: Container(
                      width: 2,
                      height: isTablet ? 24 : 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.withValues(alpha: 0.5),
                            Colors.red.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  // Destino
                  Container(
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.place_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destino',
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 10,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                trip.destination.name,
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  // Precio y asientos
                  Row(
                    children: [
                      Expanded(
                        child: _buildChip('S/. ${trip.pricePerSeat.toStringAsFixed(2)}', Colors.green, isTablet),
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Expanded(
                        child: _buildChip('${trip.seatsBooked}/${trip.availableSeats}', Colors.blue, isTablet),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // SOLICITUDES PENDIENTES mejorado
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions_rounded, color: Colors.orange.shade700, size: isTablet ? 24 : 20),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'SOLICITUDES PENDIENTES (${pending.length})',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          if (pending.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 40 : 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: isTablet ? 64 : 48,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'Esperando solicitudes...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...pending.map((p) => Container(
              margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.user.firstName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.user.firstName} ${p.user.lastName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 18 : 16,
                                ),
                              ),
                              SizedBox(height: isTablet ? 4 : 2),
                              Text(
                                p.user.university,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () => _reject(p.user.id, p.user.firstName, tripProvider, trip.id),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('RECHAZAR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 2),
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: FilledButton.icon(
                              onPressed: seatsLeft > 0
                                ? () => _accept(p.user.id, p.user.firstName, tripProvider, trip.id)
                                : null,
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('ACEPTAR'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
          
          SizedBox(height: isTablet ? 32 : 24),

          // PASAJEROS CONFIRMADOS mejorado
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: isTablet ? 24 : 20),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'PASAJEROS CONFIRMADOS (${confirmed.length})',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          
          if (confirmed.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                child: Center(
                  child: Text(
                    'Aún no hay pasajeros confirmados',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ),
              ),
            )
          else
            ...confirmed.map((p) => Container(
              margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    p.user.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  '${p.user.firstName} ${p.user.lastName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                subtitle: Text(
                  p.user.university,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                ),
              ),
            )),
          
          SizedBox(height: isTablet ? 32 : 24),
          
          // BOTÓN DE CHAT (si hay pasajeros confirmados o el viaje está activo)
          if (confirmed.isNotEmpty || trip.isInProgress || trip.isActive || trip.isFull)
            Container(
              margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(trip: trip),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 24),
                label: Text(
                  'ABRIR CHAT',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
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
          
          SizedBox(height: isTablet ? 24 : 20),
          
          // BOTONES DE ACCIÓN: INICIAR O FINALIZAR VIAJE
          _buildActionButtons(trip, confirmed, tripProvider, theme, colorScheme, isTablet),
          
          SizedBox(height: isTablet ? 100 : 80),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(Trip trip, List<TripPassenger> confirmed, TripProvider tripProvider, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    // Si el viaje está en progreso, mostrar botón de finalizar
    if (trip.isInProgress && !trip.isExpired) {
      return SafeAreaWrapper(
        top: false,
        bottom: true,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _onCompleteTrip(trip.id, tripProvider),
            icon: const Icon(Icons.check_circle, size: 24),
            label: Text(
              'FINALIZAR VIAJE',
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
      );
    }
    
    // Si hay pasajeros confirmados y el viaje está activo, mostrar botón de iniciar
    final canStartTrip = confirmed.isNotEmpty && 
                        !trip.isInProgress && 
                        !trip.isCompleted && 
                        !trip.isCancelled && 
                        !trip.isExpired &&
                        (trip.isActive || trip.isFull);
    
    if (canStartTrip) {
      return SafeAreaWrapper(
        top: false,
        bottom: true,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _onStartTrip(trip.id, tripProvider),
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
            if (confirmed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${confirmed.length} pasajero${confirmed.length != 1 ? 's' : ''} confirmado${confirmed.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // Si hay pasajeros confirmados pero aún no se puede iniciar
    if (confirmed.isNotEmpty && !canStartTrip && !trip.isExpired) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.primary,
              size: isTablet ? 24 : 20,
            ),
            SizedBox(width: isTablet ? 12 : 8),
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
      );
    }
    
    return const SizedBox.shrink();
  }
  
  Future<void> _onStartTrip(String tripId, TripProvider tripProvider) async {
    // Confirmar antes de iniciar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar Viaje'),
        content: const Text('¿Estás seguro de que quieres iniciar el viaje? Una vez iniciado, no se pueden agregar más pasajeros.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text('INICIAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await tripProvider.startTrip(tripId);
    if (!mounted) return;
    
    if (ok) {
      await _loadData();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('¡Viaje iniciado! Los pasajeros han sido notificados.'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
      // Redirigir a la pantalla de viaje en curso
      final updatedTrip = await tripProvider.fetchTripById(tripId);
      if (mounted && updatedTrip != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverTripInProgressScreen(trip: updatedTrip),
          ),
        );
      }
    } else {
      showErrorDialog(context, 'Error al iniciar viaje', tripProvider.errorMessage);
    }
  }
  
  Future<void> _onCompleteTrip(String tripId, TripProvider tripProvider) async {
    // Confirmar antes de finalizar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Viaje'),
        content: const Text('¿Has llegado al destino indicado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('NO'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text('SÍ, LLEGUÉ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await tripProvider.completeTrip(tripId);
    if (!mounted) return;
    
    if (ok) {
      // Obtener el viaje actualizado para redirigir a calificar
      final updatedTrip = await tripProvider.fetchTripById(tripId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Viaje completado exitosamente!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        
        // Redirigir a la pantalla de calificaciones
        if (updatedTrip != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RateTripScreen(trip: updatedTrip),
            ),
          );
        }
        
        // Recargar datos para actualizar la vista
        await _loadData();
      }
    } else {
      showErrorDialog(context, 'Error al finalizar viaje', tripProvider.errorMessage);
    }
  }

  Widget _buildChip(String text, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 16 : 14,
        ),
      ),
    );
  }

  Color _getCountdownColor(Trip trip) {
    final min = trip.minutesRemaining;
    if (min <= 0) return Colors.red;
    if (min <= 3) return Colors.red.shade600;
    if (min <= 6) return Colors.orange;
    return Colors.green;
  }

  Future<void> _accept(String passengerId, String name, TripProvider provider, String tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceptar Pasajero'),
        content: Text('¿Confirmas que $name puede unirse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await provider.manageBooking(
      tripId: tripId,
      passengerId: passengerId,
      status: 'confirmed',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $name fue aceptado'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reject(String passengerId, String name, TripProvider provider, String tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Text('¿Seguro que quieres rechazar a $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('RECHAZAR'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await provider.manageBooking(
      tripId: tripId,
      passengerId: passengerId,
      status: 'rejected',
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Solicitud de $name rechazada'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
