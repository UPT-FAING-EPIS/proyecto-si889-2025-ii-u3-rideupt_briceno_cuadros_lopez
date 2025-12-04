// lib/widgets/admin/web_driver_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../screens/admin/driver_detail_screen.dart';

class WebDriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;

  const WebDriverCard({
    super.key,
    required this.driver,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'pending':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = driver['driverApprovalStatus'] ?? 'pending';
    final documents = driver['driverDocuments'] as List? ?? [];
    final requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
    final hasAllDocs = requiredDocs.every((docType) => 
      documents.any((doc) => doc['tipoDocumento'] == docType)
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverDetailScreen(
                driverId: driver['_id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM + 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Avatar más pequeño
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      '${driver['firstName']?[0] ?? ''}${driver['lastName']?[0] ?? ''}'.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          driver['email'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Badge de estado más pequeño
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 12,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(status),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (driver['vehicle'] != null) ...[
                const SizedBox(height: AppTheme.spacingSM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Expanded(
                        child: Text(
                          '${driver['vehicle']['make']} ${driver['vehicle']['model']} - ${driver['vehicle']['licensePlate']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Documentos: ${documents.length}/3',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXS),
                  if (hasAllDocs)
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.green,
                    )
                  else
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: Colors.orange,
                    ),
                ],
              ),
              if (status == 'pending') ...[
                const SizedBox(height: AppTheme.spacingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Expanded(
                        child: Text(
                          hasAllDocs 
                            ? 'Listo para revisar y aprobar'
                            : 'Faltan documentos requeridos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
}

