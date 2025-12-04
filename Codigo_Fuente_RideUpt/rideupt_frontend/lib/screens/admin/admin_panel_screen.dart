// lib/screens/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'tabs/drivers_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/rankings_tab.dart';
import 'tabs/stats_tab.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _selectedIndex) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = AppTheme.isDesktop(context);
    final isTablet = AppTheme.isTablet(context);

    // Layout responsivo: Desktop usa NavigationRail, Mobile/Tablet usa AppBar con Tabs
    if (isDesktop) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Row(
            children: [
              // Navigation Rail para Desktop - Material Design 3
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Header del sidebar
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingSM),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panel Administrativo',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'RideUPT',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Navigation items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
                        children: [
                          _buildNavItem(
                            context: context,
                            icon: Icons.drive_eta_outlined,
                            selectedIcon: Icons.drive_eta_rounded,
                            label: 'Conductores',
                            index: 0,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.people_outline,
                            selectedIcon: Icons.people_rounded,
                            label: 'Usuarios',
                            index: 1,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.emoji_events_outlined,
                            selectedIcon: Icons.emoji_events_rounded,
                            label: 'Rankings',
                            index: 2,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          _buildNavItem(
                            context: context,
                            icon: Icons.analytics_outlined,
                            selectedIcon: Icons.analytics_rounded,
                            label: 'Estadísticas',
                            index: 3,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                    // Footer con acciones
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('Actualizar'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          OutlinedButton.icon(
                            onPressed: () async {
                              if (!mounted) return;
                              final navigator = Navigator.of(context);
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await authProvider.logout();
                              if (mounted) {
                                navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
                              }
                            },
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido principal
              Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.03),
                      colorScheme.surface,
                    ],
                    stops: const [0.0, 0.2],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header para Desktop - Material Design 3
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXXL,
                        vertical: AppTheme.spacingXL,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTabTitle(_selectedIndex),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                Text(
                                  _getTabSubtitle(_selectedIndex),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualizar',
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          IconButton.filledTonal(
                            onPressed: () async {
                              if (!mounted) return;
                              final navigator = Navigator.of(context);
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await authProvider.logout();
                              if (mounted) {
                                navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
                              }
                            },
                            icon: const Icon(Icons.logout_rounded),
                            tooltip: 'Cerrar sesión',
                          ),
                        ],
                      ),
                    ),
                    // Contenido de la pestaña
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            DriversTab(),
                            UsersTab(),
                            RankingsTab(),
                            StatsTab(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
      );
    }

    // Layout para Mobile/Tablet con AppBar y Tabs
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.03),
                colorScheme.surface,
              ],
              stops: const [0.0, 0.2],
            ),
          ),
        child: Column(
          children: [
            // AppBar mejorado con diseño profesional
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Header principal
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? AppTheme.spacingLG : AppTheme.spacingMD,
                        vertical: AppTheme.spacingMD,
                      ),
                      child: Row(
                        children: [
                          // Logo y título - Material Design 3
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingSM),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panel Administrativo',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'RideUPT',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botones de acción
                          IconButton.filledTonal(
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: () {
                              setState(() {});
                            },
                            tooltip: 'Actualizar',
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.logout_rounded),
                            onPressed: () async {
                              if (!mounted) return;
                              final navigator = Navigator.of(context);
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await authProvider.logout();
                              if (mounted) {
                                navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
                              }
                            },
                            tooltip: 'Cerrar sesión',
                          ),
                        ],
                      ),
                    ),
                    // TabBar mejorado con Material Design 3
                    Container(
                      color: colorScheme.surface,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? AppTheme.spacingLG : AppTheme.spacingMD,
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: !isTablet,
                        indicatorColor: colorScheme.primary,
                        indicatorWeight: 3,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 14 : 13,
                          letterSpacing: 0.1,
                        ),
                        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: isTablet ? 14 : 13,
                          letterSpacing: 0.1,
                        ),
                        tabs: [
                          Tab(
                            height: 52,
                            icon: const Icon(Icons.drive_eta_outlined, size: 22),
                            iconMargin: const EdgeInsets.only(bottom: 4),
                            text: 'Conductores',
                          ),
                          Tab(
                            height: 52,
                            icon: const Icon(Icons.people_outline, size: 22),
                            iconMargin: const EdgeInsets.only(bottom: 4),
                            text: 'Usuarios',
                          ),
                          Tab(
                            height: 52,
                            icon: const Icon(Icons.emoji_events_outlined, size: 22),
                            iconMargin: const EdgeInsets.only(bottom: 4),
                            text: 'Rankings',
                          ),
                          Tab(
                            height: 52,
                            icon: const Icon(Icons.analytics_outlined, size: 22),
                            iconMargin: const EdgeInsets.only(bottom: 4),
                            text: 'Estadísticas',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Contenido de las pestañas
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    DriversTab(),
                    UsersTab(),
                    RankingsTab(),
                    StatsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Conductores';
      case 1:
        return 'Usuarios';
      case 2:
        return 'Rankings';
      case 3:
        return 'Estadísticas';
      default:
        return 'Panel Administrativo';
    }
  }

  String _getTabSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Gestiona las solicitudes y aprobaciones de conductores';
      case 1:
        return 'Administra usuarios, conductores y pasajeros';
      case 2:
        return 'Visualiza los rankings y calificaciones';
      case 3:
        return 'Consulta estadísticas y métricas del sistema';
      default:
        return 'Panel de administración de RideUPT';
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSM,
        vertical: AppTheme.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
              _tabController.animateTo(index);
            });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
