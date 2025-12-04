// lib/widgets/unified_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../theme/app_theme.dart';

class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const UnifiedAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 22 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: isTablet ? 64 : kToolbarHeight,
      actions: [
        // Logo del usuario
        Container(
          margin: EdgeInsets.only(right: isTablet ? AppTheme.spacingSM + AppTheme.spacingXS : AppTheme.spacingSM),
          child: _buildUserAvatar(user, isTablet),
        ),
        
        // Switch de modo SOLO para conductores
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isDriver = authProvider.user?.role == 'driver';
            final switchColorScheme = Theme.of(context).colorScheme;
            
            // Solo mostrar switch si es conductor
            if (!isDriver) {
              return const SizedBox.shrink();
            }
            
            return Container(
              margin: const EdgeInsets.only(right: AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Switch(
                value: isDriver,
                onChanged: (value) => _toggleRole(context, authProvider, value),
                activeColor: Colors.white,
                activeTrackColor: switchColorScheme.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              ),
            );
          },
        ),
      ],
    );
  }

  void _toggleRole(BuildContext context, AuthProvider authProvider, bool isDriver) {
    final newRole = isDriver ? 'driver' : 'passenger';
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    
    // Si está cambiando de conductor a pasajero, verificar viajes activos
    if (!isDriver && authProvider.user?.role == 'driver') {
      final hasActiveTrips = tripProvider.activeMyTrips.any(
        (trip) => (trip.isInProgress || trip.isActive || trip.isFull) && !trip.isExpired && !trip.isCancelled
      );
      
      if (hasActiveTrips) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No se puede cambiar de modo'),
            content: const Text(
              'Tienes viajes activos o en proceso. Debes completar o cancelar todos tus viajes antes de cambiar a modo pasajero.'
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        return;
      }
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar a ${isDriver ? 'Conductor' : 'Pasajero'}'),
        content: Text(
          isDriver 
            ? '¿Quieres cambiar a modo conductor? Podrás crear y gestionar viajes.'
            : '¿Quieres cambiar a modo pasajero? Podrás buscar y reservar viajes.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _changeUserRole(context, authProvider, tripProvider, newRole);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _changeUserRole(BuildContext context, AuthProvider authProvider, TripProvider tripProvider, String newRole) async {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Mostrar indicador de carga
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Usar el método correcto que valida en el backend
      final success = await authProvider.switchUserMode(newRole);
      
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar indicador de carga
      
      if (success) {
        // Limpiar el estado de viajes cuando se cambia de rol
        tripProvider.clearTrips();
        
        // Recargar viajes según el nuevo rol
        if (newRole == 'driver') {
          await tripProvider.fetchMyTrips(force: true);
        } else {
          await tripProvider.fetchAvailableTrips();
          await tripProvider.fetchMyTrips(force: true);
        }
        
        // El AuthProvider ya llama a notifyListeners() en switchUserMode,
        // lo que causará que todas las pantallas que escuchan se actualicen automáticamente
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cambiado a modo ${newRole == 'driver' ? 'Conductor' : 'Pasajero'}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          );
        }
      } else {
        // El error ya está manejado en authProvider
        final errorMessage = authProvider.errorMessage;
        if (context.mounted && errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar indicador de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar modo: ${e.toString()}'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      );
    }
  }

  Widget _buildUserAvatar(user, bool isTablet) {
    final hasGooglePhoto = user != null && 
                          user.profilePhoto.isNotEmpty && 
                          user.profilePhoto != 'default_avatar.png' &&
                          Uri.tryParse(user.profilePhoto)?.hasAbsolutePath == true;
    
    return CircleAvatar(
      radius: isTablet ? 20 : 18,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      backgroundImage: hasGooglePhoto
          ? NetworkImage(user.profilePhoto)
          : null,
      child: !hasGooglePhoto
          ? Text(
              _getUserInitial(user),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 18 : 16,
              ),
            )
          : null,
    );
  }

  String _getUserInitial(user) {
    if (user?.firstName?.isNotEmpty == true) {
      return user.firstName[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
