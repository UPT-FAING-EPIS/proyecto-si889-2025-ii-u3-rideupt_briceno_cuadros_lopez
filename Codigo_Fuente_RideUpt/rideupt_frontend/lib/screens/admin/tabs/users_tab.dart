// lib/screens/admin/tabs/users_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/web_user_card.dart';
import '../../../utils/image_utils.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterRole = 'all'; // 'all', 'driver', 'passenger'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadUsers();
  }

  Future<void> _loadUsers() async {
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

      String endpoint = 'admin/users';
      final params = <String>[];
      if (_filterRole != 'all') {
        params.add('role=$_filterRole');
      }
      if (_searchQuery.isNotEmpty) {
        params.add('search=$_searchQuery');
      }
      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiService.get(endpoint, token);
      
      setState(() {
        _users = List<Map<String, dynamic>>.from(response['users'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenPadding = AppTheme.getScreenPadding(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra de búsqueda y filtros mejorados
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
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: kIsWeb ? 13 : null,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, email o código de estudiante...',
                  hintStyle: TextStyle(
                    fontSize: kIsWeb ? 13 : null,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                    vertical: kIsWeb ? AppTheme.spacingSM : AppTheme.spacingMD,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                          },
                          tooltip: 'Limpiar búsqueda',
                        )
                      : null,
                ),
              ),
              SizedBox(height: kIsWeb ? AppTheme.spacingSM : AppTheme.spacingMD),
              Row(
                children: [
                  Text(
                    'Filtrar por rol:',
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
                          value: 'all',
                          label: Text('Todos'),
                          icon: Icon(Icons.people, size: 18),
                        ),
                        ButtonSegment(
                          value: 'driver',
                          label: Text('Conductores'),
                          icon: Icon(Icons.drive_eta, size: 18),
                        ),
                        ButtonSegment(
                          value: 'passenger',
                          label: Text('Pasajeros'),
                          icon: Icon(Icons.person, size: 18),
                        ),
                      ],
                      selected: {_filterRole},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _filterRole = newSelection.first;
                        });
                        _loadUsers();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de usuarios
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
                        'Cargando usuarios...',
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
                              'Error al cargar usuarios',
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
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _users.isEmpty
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
                                    Icons.people_outline,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingLG),
                                Text(
                                  'No hay usuarios',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingSM),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No se encontraron usuarios con la búsqueda "$_searchQuery"'
                                      : 'No se encontraron usuarios',
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
                          onRefresh: _loadUsers,
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
                                      childAspectRatio: isDesktop ? 5.0 : 3.5,
                                    ),
                                    itemCount: _users.length,
                                    itemBuilder: (context, index) {
                                      return WebUserCard(
                                        user: _users[index],
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
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserCard(context, _users[index], theme, colorScheme);
                                  },
                                );
                              }
                              
                              // Lista para Mobile
                              return ListView.builder(
                                padding: EdgeInsets.all(screenPadding.horizontal),
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                                    child: _buildUserCard(context, _users[index], theme, colorScheme),
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

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user, ThemeData theme, ColorScheme colorScheme) {
    final role = user['role'] ?? 'passenger';
    final isAdmin = user['isAdmin'] == true;
    final avgRating = user['averageRating'] ?? 0.0;
    final totalRatings = user['totalRatings'] ?? 0;
    
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Puedes agregar navegación a detalles del usuario aquí
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isAdmin
                      ? Colors.purple.shade100
                      : role == 'driver'
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer,
                  backgroundImage: _hasProfilePhoto(user['profilePhoto'])
                      ? CachedNetworkImageProvider(
                          ImageUtils.getImageUrl(user['profilePhoto']) ?? '',
                        )
                      : null,
                  child: !_hasProfilePhoto(user['profilePhoto'])
                      ? Text(
                          '${user['firstName']?[0] ?? ''}${user['lastName']?[0] ?? ''}'.toUpperCase(),
                          style: TextStyle(
                            color: isAdmin
                                ? Colors.purple.shade900
                                : role == 'driver'
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                if (isAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMD,
                          vertical: AppTheme.spacingXS + 2,
                        ),
                        decoration: BoxDecoration(
                          color: role == 'driver'
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: Text(
                          role == 'driver' ? 'Conductor' : 'Pasajero',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: role == 'driver'
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    user['email'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user['studentId'] != null) ...[
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Código: ${user['studentId']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (avgRating > 0) ...[
                    const SizedBox(height: AppTheme.spacingSM),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < avgRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: AppTheme.spacingSM),
                        Text(
                          '${avgRating.toStringAsFixed(1)} ($totalRatings)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  bool _hasProfilePhoto(String? profilePhoto) {
    return profilePhoto != null &&
           profilePhoto.isNotEmpty &&
           profilePhoto != 'default_avatar.png' &&
           Uri.tryParse(profilePhoto)?.hasAbsolutePath == true;
  }
}




