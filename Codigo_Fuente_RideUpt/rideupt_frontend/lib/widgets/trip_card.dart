import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideupt_app/models/trip.dart';
import 'package:rideupt_app/theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap; // Callback para la acción de tap

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    // Determinar color del badge de expiración
    Color expirationColor = colorScheme.tertiary;
    if (trip.expiresAt != null) {
      final minutesLeft = trip.minutesRemaining;
      if (minutesLeft <= 0) {
        expirationColor = colorScheme.error;
      } else if (minutesLeft <= 2) {
        expirationColor = colorScheme.error;
      } else if (minutesLeft <= 4) {
        expirationColor = colorScheme.tertiary;
      } else {
        expirationColor = colorScheme.secondary;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          padding: EdgeInsets.all(isTablet ? AppTheme.spacingLG : AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con precio y estado
              Row(
                children: [
                  // Precio destacado estilo INDRIVE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: AppTheme.spacingSM,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'S/. ',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          trip.pricePerSeat.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Badge de estado
                  _buildStatusChip(context, isTablet),
                ],
              ),
              SizedBox(height: isTablet ? AppTheme.spacingLG + AppTheme.spacingXS : AppTheme.spacingLG - AppTheme.spacingXS),
              // Ruta con línea conectora
              _buildLocationRow(context, Icons.circle, trip.origin.name, colorScheme.tertiary, true),
              const SizedBox(height: AppTheme.spacingSM),
              // Línea conectora
              Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingSM + AppTheme.spacingXS - 1),
                child: Container(
                  height: AppTheme.spacingLG - AppTheme.spacingXS,
                  width: 2,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              _buildLocationRow(context, Icons.location_on, trip.destination.name, colorScheme.primary, false),
              const SizedBox(height: AppTheme.spacingMD),
              // Información del conductor y fecha
              Row(
                children: [
                  // Avatar del conductor
                  CircleAvatar(
                    radius: isTablet ? 20 : 18,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      trip.driver.firstName[0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? AppTheme.spacingSM + AppTheme.spacingXS : AppTheme.spacingSM + AppTheme.spacingXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driver.firstName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingXS / 2),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(trip.departureTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Asientos disponibles
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM + AppTheme.spacingXS,
                      vertical: AppTheme.spacingSM - AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: isTablet ? 18 : 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: AppTheme.spacingXS),
                        Text(
                          '${trip.availableSeats - trip.seatsBooked}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Tiempo restante si está activo
              if (trip.isActive && trip.expiresAt != null) ...[
                SizedBox(height: isTablet ? AppTheme.spacingSM + AppTheme.spacingXS : AppTheme.spacingSM + AppTheme.spacingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM + AppTheme.spacingXS,
                    vertical: AppTheme.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: expirationColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(
                      color: expirationColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: isTablet ? 18 : 16,
                        color: expirationColor,
                      ),
                      SizedBox(width: isTablet ? AppTheme.spacingSM - AppTheme.spacingXS : AppTheme.spacingSM - AppTheme.spacingXS),
                      Text(
                        trip.timeRemainingText,
                        style: TextStyle(
                          color: expirationColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (trip.isInProgress) {
      statusText = 'En Proceso';
      statusColor = colorScheme.primary;
      statusIcon = Icons.directions_car;
    } else if (trip.isCompleted) {
      statusText = 'Completado';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (trip.isFull) {
      statusText = 'Completo';
      statusColor = Colors.grey.shade600;
      statusIcon = Icons.event_seat;
    } else if (trip.isCancelled) {
      statusText = 'Cancelado';
      statusColor = Colors.grey.shade600;
      statusIcon = Icons.cancel;
    } else if (trip.isExpired) {
      statusText = 'Expirado';
      statusColor = colorScheme.error;
      statusIcon = Icons.timer_off;
    } else {
      statusText = 'Disponible';
      statusColor = colorScheme.tertiary;
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM + AppTheme.spacingXS,
        vertical: AppTheme.spacingSM - AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: isTablet ? 16 : 14, color: statusColor),
          SizedBox(width: AppTheme.spacingXS),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, IconData icon, String text, Color color, bool isOrigin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: isOrigin ? 16 : 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}