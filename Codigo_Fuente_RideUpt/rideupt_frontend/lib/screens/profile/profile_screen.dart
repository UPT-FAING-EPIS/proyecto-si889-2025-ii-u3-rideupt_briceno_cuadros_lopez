import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/providers/trip_provider.dart';
import 'package:rideupt_app/screens/profile/edit_profile_screen.dart';
import 'package:rideupt_app/screens/driver/become_driver_screen.dart';
import 'package:rideupt_app/screens/admin/admin_panel_screen.dart';
import 'package:rideupt_app/services/dashboard_service.dart';
import 'package:rideupt_app/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  String? _previousRole; // Para detectar cambios de rol

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _previousRole = authProvider.user?.role;
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Escuchar cambios en el AuthProvider para detectar cambios de rol
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRole = authProvider.user?.role;
    
    // Si el rol cambió, recargar datos
    if (_previousRole != currentRole && currentRole != null) {
      _previousRole = currentRole;
      _loadDashboardData();
      
      // También recargar viajes según el nuevo rol
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      if (currentRole == 'driver') {
        tripProvider.fetchMyTrips(force: true);
      } else {
        tripProvider.fetchAvailableTrips();
        tripProvider.fetchMyTrips(force: true);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      setState(() => _isLoadingStats = false);
      return;
    }

    try {
      final stats = await DashboardService.getDashboardStats(authProvider.token!);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          // Header del perfil
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: isTablet ? 32 : 24,
                bottom: isTablet ? 32 : 24,
                left: isTablet ? 24 : 16,
                right: isTablet ? 24 : 16,
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.onPrimary.withValues(alpha: 0.3),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: isTablet ? 50 : 45,
                      backgroundColor: colorScheme.onPrimary,
                      backgroundImage: (user.profilePhoto.isNotEmpty && 
                                       user.profilePhoto != 'default_avatar.png' &&
                                       Uri.tryParse(user.profilePhoto)?.hasAbsolutePath == true)
                          ? NetworkImage(user.profilePhoto)
                          : null,
                      child: (user.profilePhoto.isEmpty || 
                             user.profilePhoto == 'default_avatar.png' ||
                             Uri.tryParse(user.profilePhoto)?.hasAbsolutePath != true)
                          ? Text(
                              '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase(),
                              style: TextStyle(
                                fontSize: isTablet ? 36 : 32,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Nombre completo
                  Text(
                    '${user.firstName} ${user.lastName}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      fontSize: isTablet ? 24 : 20,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Badge del rol
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.onPrimary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.role == 'driver' ? Icons.directions_car : Icons.person,
                          size: 18,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.role == 'driver' ? 'CONDUCTOR' : 'PASAJERO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorScheme.onPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido del perfil
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          
                  // Dashboard/Estadísticas
                  _buildDashboardSection(context, user),
                  
                  SizedBox(height: isTablet ? 24 : 20),
                  
                  // Calificaciones
                  _buildRatingsCard(context, user, theme, colorScheme, isTablet),
                  
                  SizedBox(height: isTablet ? 24 : 20),
                  
                  // Información personal
                  _buildPersonalInfoSection(context, user, theme, colorScheme, isTablet),
                  
                  if (user.role == 'driver' && user.vehicle != null) ...[
                    SizedBox(height: isTablet ? 24 : 20),
                    _buildVehicleInfoSection(context, user, theme, colorScheme, isTablet),
                  ],
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Botón de editar perfil
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('EDITAR PERFIL'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                        horizontal: isTablet ? 24 : 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Panel administrativo (solo para admins)
                  if (user.role == 'admin') ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('PANEL ADMINISTRATIVO'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminPanelScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 14,
                          horizontal: isTablet ? 24 : 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Botones de modo conductor/pasajero
                  _buildModeButtons(context, user),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // Botón de cerrar sesión
                  TextButton.icon(
                    icon: Icon(Icons.logout, color: colorScheme.error),
                    label: Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cerrar Sesión'),
                          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('CANCELAR'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.error,
                              ),
                              child: const Text('CERRAR SESIÓN'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await authProvider.logout();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                        horizontal: isTablet ? 24 : 20,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construye la tarjeta de calificaciones
  Widget _buildRatingsCard(BuildContext context, user, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG + AppTheme.spacingXS : AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                Expanded(
                  child: Text(
                    'Calificaciones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 20 : 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Row(
              children: [
                Text(
                  user.averageRating.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: isTablet ? 32 : 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                ...List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      index < user.averageRating.floor()
                          ? Icons.star
                          : index < user.averageRating
                              ? Icons.star_half
                              : Icons.star_border,
                      color: Colors.amber,
                      size: isTablet ? 24 : 20,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${user.totalRatings} ${user.totalRatings == 1 ? 'calificación' : 'calificaciones'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye la sección de información personal
  Widget _buildPersonalInfoSection(BuildContext context, user, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG + AppTheme.spacingXS : AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.spacingSM + AppTheme.spacingXS),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colorScheme.primary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                Expanded(
                  child: Text(
                    'Información Personal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 20 : 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            _buildInfoRow(context, Icons.phone, 'Teléfono', user.phone.isEmpty ? 'No registrado' : user.phone, colorScheme),
            const Divider(height: AppTheme.spacingLG),
            _buildInfoRow(context, Icons.school, 'Universidad', user.university.isEmpty ? 'No registrado' : user.university, colorScheme),
            const Divider(height: AppTheme.spacingLG),
            _buildInfoRow(context, Icons.badge, 'Código', user.studentId.isEmpty ? 'No registrado' : user.studentId, colorScheme),
          ],
        ),
      ),
    );
  }
  
  /// Construye una fila de información
  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String subtitle, ColorScheme colorScheme) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isSmallScreen = size.width < 360;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : (AppTheme.spacingSM + AppTheme.spacingXS)),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.spacingSM + AppTheme.spacingXS),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: isSmallScreen ? 18 : (isTablet ? 22 : 20),
          ),
        ),
        SizedBox(width: isSmallScreen ? AppTheme.spacingSM : AppTheme.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : (isTablet ? 13 : 12),
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : (isTablet ? 17 : 16),
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Construye la sección de información del vehículo
  Widget _buildVehicleInfoSection(BuildContext context, user, ThemeData theme, ColorScheme colorScheme, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG + AppTheme.spacingXS : AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.spacingSM + AppTheme.spacingXS),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: colorScheme.secondary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                Expanded(
                  child: Text(
                    'Información del Vehículo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 20 : 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            _buildInfoRow(context, Icons.directions_car, 'Vehículo', '${user.vehicle!.make} ${user.vehicle!.model} (${user.vehicle!.year})', colorScheme),
            const Divider(height: AppTheme.spacingLG),
            _buildInfoRow(context, Icons.palette, 'Color', user.vehicle!.color, colorScheme),
            const Divider(height: AppTheme.spacingLG),
            _buildInfoRow(context, Icons.pin, 'Placa', user.vehicle!.licensePlate, colorScheme),
          ],
        ),
      ),
    );
  }

  /// Construye los botones de modo conductor/pasajero
  Widget _buildModeButtons(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = user.role == 'driver';
    final hasVehicle = user.vehicle != null;
    
    // Si es pasajero y NO tiene vehículo: mostrar botón para convertirse en conductor
    if (!isDriver && !hasVehicle) {
      return FilledButton.icon(
        icon: const Icon(Icons.directions_car),
        label: const Text('CONVERTIRSE EN CONDUCTOR'),
        onPressed: () {
          // Navegar primero a la pantalla de documentos (BecomeDriverScreen)
          // Esta pantalla manejará el flujo completo: documentos → datos del vehículo → aprobación del admin
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BecomeDriverScreen()),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 14,
            horizontal: isTablet ? 24 : 20,
          ),
        ),
      );
    }
    
    // Si es conductor O pasajero con vehículo: mostrar botones de modo
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG + AppTheme.spacingXS : AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.spacingSM + AppTheme.spacingXS),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: colorScheme.primary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSM + AppTheme.spacingXS),
                Expanded(
                  child: Text(
                    'Modo de Usuario',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 20 : 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            // Botón del modo actual (deshabilitado)
            FilledButton.icon(
              icon: Icon(isDriver ? Icons.directions_car : Icons.person),
              label: Text(isDriver ? 'MODO CONDUCTOR' : 'MODO PASAJERO'),
              onPressed: null, // Deshabilitado porque ya está en ese modo
              style: FilledButton.styleFrom(
                backgroundColor: isDriver ? colorScheme.secondary : colorScheme.primary,
                foregroundColor: colorScheme.onSecondary,
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? AppTheme.spacingMD : AppTheme.spacingMD - AppTheme.spacingXS,
                  horizontal: isTablet ? AppTheme.spacingLG : AppTheme.spacingLG - AppTheme.spacingXS,
                ),
                disabledBackgroundColor: isDriver ? colorScheme.secondary : colorScheme.primary,
                disabledForegroundColor: colorScheme.onSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM + AppTheme.spacingXS),
            // Botón para cambiar al otro modo
            OutlinedButton.icon(
              icon: Icon(isDriver ? Icons.person : Icons.directions_car),
              label: Text(isDriver ? 'CAMBIAR A MODO PASAJERO' : 'CAMBIAR A MODO CONDUCTOR'),
              onPressed: () async {
                final newMode = isDriver ? 'passenger' : 'driver';
                final modeName = isDriver ? 'pasajero' : 'conductor';
                
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Cambiar a Modo $modeName'),
                    content: Text(
                      isDriver
                        ? '¿Estás seguro que deseas cambiar a modo pasajero? Podrás volver a ser conductor en cualquier momento.'
                        : '¿Estás seguro que deseas cambiar a modo conductor? Podrás cambiar a modo pasajero en cualquier momento.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('CANCELAR'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('CAMBIAR'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  // Mostrar indicador de carga
                  if (!context.mounted) return;
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  final tripProvider = Provider.of<TripProvider>(context, listen: false);
                  final success = await authProvider.switchUserMode(newMode);
                  
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // Cerrar indicador de carga
                  
                  if (success && context.mounted) {
                    // Limpiar y recargar viajes según el nuevo rol
                    tripProvider.clearTrips();
                    
                    if (newMode == 'driver') {
                      await tripProvider.fetchMyTrips(force: true);
                    } else {
                      await tripProvider.fetchAvailableTrips();
                      await tripProvider.fetchMyTrips(force: true);
                    }
                    
                    // Recargar estadísticas del dashboard
                    await _loadDashboardData();
                    
                    // Actualizar el rol anterior para evitar recargas innecesarias
                    _previousRole = newMode;
                    
                    // Forzar actualización del perfil para obtener calificaciones actualizadas
                    await authProvider.refreshUserProfile();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Modo cambiado a $modeName'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Forzar reconstrucción del widget
                      setState(() {});
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage.isNotEmpty 
                            ? authProvider.errorMessage 
                            : 'Error al cambiar modo'
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? AppTheme.spacingMD : AppTheme.spacingMD - AppTheme.spacingXS,
                  horizontal: isTablet ? AppTheme.spacingLG : AppTheme.spacingLG - AppTheme.spacingXS,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDriver = user.role == 'driver';
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final stats = _stats?['stats'];

    if (_isLoadingStats) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tarjetas de estadísticas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDriver ? 'Viajes Creados' : 'Viajes Reservados',
                stats != null ? '${stats[isDriver ? 'totalTrips' : 'totalBookings'] ?? 0}' : '0',
                Icons.directions_car_rounded,
                colorScheme.primary,
                isTablet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                isDriver ? 'Calificación' : 'Viajes Activos',
                isDriver 
                  ? (stats != null ? '${stats['averageRating']?.toStringAsFixed(1) ?? '0.0'} ⭐' : '0.0 ⭐')
                  : (stats != null ? '${stats['activeBookings'] ?? 0}' : '0'),
                isDriver ? Icons.star_rounded : Icons.book_online_rounded,
                isDriver ? Colors.orange : colorScheme.tertiary,
                isTablet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDriver ? 'Ganancias' : 'Ahorro',
                isDriver 
                  ? (stats != null ? 'S/. ${stats['totalEarnings']?.toStringAsFixed(2) ?? '0.00'}' : 'S/. 0.00')
                  : (stats != null ? 'S/. ${stats['savings']?.toStringAsFixed(2) ?? '0.00'}' : 'S/. 0.00'),
                Icons.savings_rounded,
                colorScheme.tertiary,
                isTablet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Puntos',
                stats != null ? '${stats['points'] ?? 0}' : '0',
                Icons.local_fire_department_rounded,
                colorScheme.secondary,
                isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG + AppTheme.spacingXS : AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSM + AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.spacingSM + AppTheme.spacingXS),
                ),
                child: Icon(icon, color: color, size: isTablet ? 24 : 20),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? AppTheme.spacingSM + AppTheme.spacingXS : AppTheme.spacingSM),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}