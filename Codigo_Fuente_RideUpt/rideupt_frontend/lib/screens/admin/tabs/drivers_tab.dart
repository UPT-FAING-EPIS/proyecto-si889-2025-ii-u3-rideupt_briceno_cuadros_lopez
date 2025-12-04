// lib/screens/admin/tabs/drivers_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/api_service.dart';
import '../../../theme/app_theme.dart';
import '../driver_detail_screen.dart';
import '../../../widgets/admin/web_driver_card.dart';

class DriversTab extends StatefulWidget {
  const DriversTab({super.key});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterStatus = 'pending'; // 'pending', 'approved', 'rejected', 'all'

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      String endpoint = 'admin/drivers';
      if (_filterStatus != 'all') {
        endpoint += '?status=$_filterStatus';
      }

      final response = await _apiService.get(endpoint, token);
      
      setState(() {
        _drivers = List<Map<String, dynamic>>.from(response['drivers'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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
    final isDesktop = AppTheme.isDesktop(context);
    final isTablet = AppTheme.isTablet(context);
    final screenPadding = AppTheme.getScreenPadding(context);

    return Column(
      children: [
        // Filtros mejorados con Material 3
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenPadding.horizontal,
            vertical: kIsWeb ? AppTheme.spacingSM + 4 : AppTheme.spacingMD,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (!isDesktop && !isTablet)
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'pending',
                        label: Text('Pendientes'),
                        icon: Icon(Icons.pending, size: 18),
                      ),
                      ButtonSegment(
                        value: 'approved',
                        label: Text('Aprobados'),
                        icon: Icon(Icons.check_circle, size: 18),
                      ),
                      ButtonSegment(
                        value: 'rejected',
                        label: Text('Rechazados'),
                        icon: Icon(Icons.cancel, size: 18),
                      ),
                      ButtonSegment(
                        value: 'all',
                        label: Text('Todos'),
                        icon: Icon(Icons.list, size: 18),
                      ),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filterStatus = newSelection.first;
                      });
                      _loadDrivers();
                    },
                  ),
                )
              else ...[
                Text(
                  'Filtrar por estado:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: kIsWeb ? 12 : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSM,
                        vertical: kIsWeb ? AppTheme.spacingXS : AppTheme.spacingSM,
                      ),
                      textStyle: TextStyle(
                        fontSize: kIsWeb ? 11 : null,
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 'pending',
                        label: Text('Pendientes'),
                        icon: Icon(Icons.pending, size: 18),
                      ),
                      ButtonSegment(
                        value: 'approved',
                        label: Text('Aprobados'),
                        icon: Icon(Icons.check_circle, size: 18),
                      ),
                      ButtonSegment(
                        value: 'rejected',
                        label: Text('Rechazados'),
                        icon: Icon(Icons.cancel, size: 18),
                      ),
                      ButtonSegment(
                        value: 'all',
                        label: Text('Todos'),
                        icon: Icon(Icons.list, size: 18),
                      ),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filterStatus = newSelection.first;
                      });
                      _loadDrivers();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // Lista de conductores
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        'Cargando conductores...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: screenPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLG),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 64,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            Text(
                              'Error al cargar conductores',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSM),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            FilledButton.icon(
                              onPressed: _loadDrivers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _drivers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: screenPadding,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.drive_eta_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingLG),
                                Text(
                                  'No hay conductores',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingSM),
                                Text(
                                  'No se encontraron conductores con el estado seleccionado',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDrivers,
                          color: colorScheme.primary,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = AppTheme.isDesktop(context);
                              final isTablet = AppTheme.isTablet(context);
                              
                              // Grid para Desktop/Tablet, Lista para Mobile
                              if (isDesktop || isTablet) {
                                // Usar widgets web compactos si es web
                                if (kIsWeb) {
                                  return GridView.builder(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenPadding.horizontal,
                                      vertical: AppTheme.spacingSM,
                                    ),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isDesktop ? 4 : 2,
                                      crossAxisSpacing: AppTheme.spacingSM,
                                      mainAxisSpacing: AppTheme.spacingSM,
                                      childAspectRatio: isDesktop ? 3.5 : 2.5,
                                    ),
                                    itemCount: _drivers.length,
                                    itemBuilder: (context, index) {
                                      return WebDriverCard(
                                        driver: _drivers[index],
                                      );
                                    },
                                  );
                                }
                                
                                return GridView.builder(
                                  padding: EdgeInsets.all(screenPadding.horizontal),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isDesktop ? 2 : 1,
                                    crossAxisSpacing: AppTheme.spacingMD,
                                    mainAxisSpacing: AppTheme.spacingMD,
                                    childAspectRatio: isDesktop ? 1.8 : 1.2,
                                  ),
                                  itemCount: _drivers.length,
                                  itemBuilder: (context, index) {
                                    return _buildDriverCard(context, _drivers[index], theme, colorScheme);
                                  },
                                );
                              }
                              
                              // Lista para Mobile
                              return ListView.builder(
                                padding: EdgeInsets.all(screenPadding.horizontal),
                                itemCount: _drivers.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                                    child: _buildDriverCard(context, _drivers[index], theme, colorScheme),
                                  );
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(BuildContext context, Map<String, dynamic> driver, ThemeData theme, ColorScheme colorScheme) {
    final status = driver['driverApprovalStatus'] ?? 'pending';
    final documents = driver['driverDocuments'] as List? ?? [];
    final requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
    final hasAllDocs = requiredDocs.every((docType) => 
      documents.any((doc) => doc['tipoDocumento'] == docType)
    );
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverDetailScreen(
                driverId: driver['_id'],
              ),
            ),
          ).then((_) => _loadDrivers());
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      '${driver['firstName']?[0] ?? ''}${driver['lastName']?[0] ?? ''}'.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          driver['email'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: AppTheme.spacingXS,
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
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          _getStatusText(status),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (driver['vehicle'] != null) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Text(
                          '${driver['vehicle']['make']} ${driver['vehicle']['model']} - ${driver['vehicle']['licensePlate']}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingSM),
              Row(
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTheme.spacingXS),
                  Text(
                    'Documentos: ${documents.length}/3',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  if (hasAllDocs)
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    )
                  else
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                ],
              ),
              if (status == 'pending') ...[
                const SizedBox(height: AppTheme.spacingSM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
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
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: Text(
                          hasAllDocs 
                            ? 'Listo para revisar y aprobar'
                            : 'Faltan documentos requeridos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade900,
                          ),
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