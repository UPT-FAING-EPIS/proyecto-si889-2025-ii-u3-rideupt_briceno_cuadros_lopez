// lib/screens/admin/tabs/stats_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/api_service.dart';
import '../../../theme/app_theme.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
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

      final response = await _apiService.get('admin/stats', token);
      
      setState(() {
        _stats = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDesktop,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 120,
        ),
        padding: EdgeInsets.all(isDesktop ? AppTheme.spacingLG : AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Icon(icon, color: color, size: isDesktop ? 28 : 24),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isDesktop ? 40 : 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = AppTheme.isDesktop(context);
    final isTablet = AppTheme.isTablet(context);
    final screenPadding = AppTheme.getScreenPadding(context);
    final maxWidth = AppTheme.getMaxContentWidth(context);

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: colorScheme.primary,
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
                    'Cargando estadísticas...',
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
                          'Error al cargar estadísticas',
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
                          onPressed: _loadStats,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _stats == null
                  ? Center(
                      child: Padding(
                        padding: screenPadding,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            Text(
                              'No hay datos disponibles',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenPadding.horizontal,
                            vertical: AppTheme.spacingLG,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              // Usuarios
                              Text(
                                'Usuarios',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              SizedBox(
                                width: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: AppTheme.spacingMD,
                                      mainAxisSpacing: AppTheme.spacingMD,
                                      childAspectRatio: isDesktop ? 1.8 : (isTablet ? 1.6 : 1.4),
                                      children: [
                                        _buildStatCard(
                                          title: 'Total Usuarios',
                                          value: '${_stats!['users']?['total'] ?? 0}',
                                          icon: Icons.people,
                                          color: colorScheme.primary,
                                          theme: theme,
                                          colorScheme: colorScheme,
                                          isDesktop: isDesktop,
                                        ),
                                        _buildStatCard(
                                          title: 'Conductores',
                                          value: '${_stats!['users']?['drivers'] ?? 0}',
                                          icon: Icons.drive_eta,
                                          color: Colors.orange,
                                          theme: theme,
                                          colorScheme: colorScheme,
                                          isDesktop: isDesktop,
                                        ),
                                        _buildStatCard(
                                          title: 'Pasajeros',
                                          value: '${_stats!['users']?['passengers'] ?? 0}',
                                          icon: Icons.person,
                                          color: Colors.green,
                                          theme: theme,
                                          colorScheme: colorScheme,
                                          isDesktop: isDesktop,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXXL),
                              // Conductores
                              Text(
                                'Estado de Conductores',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              SizedBox(
                                width: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: AppTheme.spacingMD,
                                      mainAxisSpacing: AppTheme.spacingMD,
                                      childAspectRatio: isDesktop ? 1.8 : (isTablet ? 1.6 : 1.4),
                                    children: [
                                      _buildStatCard(
                                        title: 'Pendientes',
                                        value: '${_stats!['drivers']?['pending'] ?? 0}',
                                        icon: Icons.pending,
                                        color: Colors.orange,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                      _buildStatCard(
                                        title: 'Aprobados',
                                        value: '${_stats!['drivers']?['approved'] ?? 0}',
                                        icon: Icons.check_circle,
                                        color: Colors.green,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                      _buildStatCard(
                                        title: 'Rechazados',
                                        value: '${_stats!['drivers']?['rejected'] ?? 0}',
                                        icon: Icons.cancel,
                                        color: Colors.red,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                    ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXXL),
                              // Viajes
                              Text(
                                'Viajes',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              SizedBox(
                                width: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount = isDesktop ? 2 : 1;
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: AppTheme.spacingMD,
                                      mainAxisSpacing: AppTheme.spacingMD,
                                      childAspectRatio: isDesktop ? 2.0 : 1.4,
                                    children: [
                                      _buildStatCard(
                                        title: 'Total Viajes',
                                        value: '${_stats!['trips']?['total'] ?? 0}',
                                        icon: Icons.directions_car,
                                        color: Colors.purple,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                      _buildStatCard(
                                        title: 'Completados',
                                        value: '${_stats!['trips']?['completed'] ?? 0}',
                                        icon: Icons.check_circle_outline,
                                        color: Colors.teal,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                    ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXXL),
                              // Calificaciones
                              Text(
                                'Calificaciones',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              SizedBox(
                                width: double.infinity,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount = isDesktop ? 2 : 1;
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: AppTheme.spacingMD,
                                      mainAxisSpacing: AppTheme.spacingMD,
                                      childAspectRatio: isDesktop ? 2.0 : 1.4,
                                    children: [
                                      _buildStatCard(
                                        title: 'Total Calificaciones',
                                        value: '${_stats!['ratings']?['total'] ?? 0}',
                                        icon: Icons.star,
                                        color: Colors.amber,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                      _buildStatCard(
                                        title: 'Promedio General',
                                        value: '${(_stats!['ratings']?['average'] ?? 0.0).toStringAsFixed(1)}',
                                        icon: Icons.star_rate,
                                        color: Colors.amber.shade700,
                                        subtitle: 'De 5.0 estrellas',
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        isDesktop: isDesktop,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}







