// lib/screens/admin/tabs/rankings_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../api/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/web_ranking_card.dart';
import '../../../utils/image_utils.dart';

class RankingsTab extends StatefulWidget {
  const RankingsTab({super.key});

  @override
  State<RankingsTab> createState() => _RankingsTabState();
}

class _RankingsTabState extends State<RankingsTab> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _rankings = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterType = 'all'; // 'all', 'drivers', 'passengers'

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
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

      String endpoint = 'admin/rankings?limit=50';
      if (_filterType != 'all') {
        endpoint += '&type=$_filterType';
      }

      final response = await _apiService.get(endpoint, token);
      
      setState(() {
        _rankings = List<Map<String, dynamic>>.from(response['rankings'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 20, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 20, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 20, color: Colors.grey);
        }
      }),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700; // Oro
    if (rank == 2) return Colors.grey.shade400; // Plata
    if (rank == 3) return Colors.brown.shade400; // Bronce
    return Colors.grey.shade300;
  }

  IconData _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events; // Oro
    if (rank == 2) return Icons.emoji_events; // Plata
    if (rank == 3) return Icons.emoji_events; // Bronce
    return Icons.leaderboard;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = AppTheme.isDesktop(context);
    final isTablet = AppTheme.isTablet(context);
    final screenPadding = AppTheme.getScreenPadding(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filtros mejorados con mejor responsividad
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
          child: isDesktop || isTablet
              ? Row(
                  children: [
                    Text(
                      'Filtrar por tipo:',
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
                            value: 'drivers',
                            label: Text('Conductores'),
                            icon: Icon(Icons.drive_eta, size: 18),
                          ),
                          ButtonSegment(
                            value: 'passengers',
                            label: Text('Pasajeros'),
                            icon: Icon(Icons.person, size: 18),
                          ),
                        ],
                        selected: {_filterType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _filterType = newSelection.first;
                          });
                          _loadRankings();
                        },
                      ),
                    ),
                  ],
                )
              : SegmentedButton<String>(
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
                      value: 'drivers',
                      label: Text('Conductores'),
                      icon: Icon(Icons.drive_eta, size: 18),
                    ),
                    ButtonSegment(
                      value: 'passengers',
                      label: Text('Pasajeros'),
                      icon: Icon(Icons.person, size: 18),
                    ),
                  ],
                  selected: {_filterType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _filterType = newSelection.first;
                    });
                    _loadRankings();
                  },
                ),
        ),

        // Lista de rankings
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
                        'Cargando rankings...',
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
                              'Error al cargar rankings',
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
                              onPressed: _loadRankings,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _rankings.isEmpty
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
                                    Icons.leaderboard_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingLG),
                                Text(
                                  'No hay rankings',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingSM),
                                Text(
                                  'Aún no hay usuarios con calificaciones',
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
                          onRefresh: _loadRankings,
                          color: colorScheme.primary,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
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
                                      childAspectRatio: isDesktop ? 4.5 : 3.0,
                                    ),
                                    itemCount: _rankings.length,
                                    itemBuilder: (context, index) {
                                      final rank = _rankings[index]['rank'] ?? (index + 1);
                                      return WebRankingCard(
                                        user: _rankings[index],
                                        rank: rank,
                                        index: index,
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
                                    childAspectRatio: isDesktop ? 2.0 : 1.5,
                                  ),
                                  itemCount: _rankings.length,
                                  itemBuilder: (context, index) {
                                    return _buildRankingCard(context, _rankings[index], index, theme, colorScheme);
                                  },
                                );
                              }
                              return ListView.builder(
                                padding: EdgeInsets.all(screenPadding.horizontal),
                                itemCount: _rankings.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                                    child: _buildRankingCard(context, _rankings[index], index, theme, colorScheme),
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

  Widget _buildRankingCard(BuildContext context, Map<String, dynamic> user, int index, ThemeData theme, ColorScheme colorScheme) {
    final rank = user['rank'] ?? (index + 1);
    final avgRating = (user['averageRating'] ?? 0.0).toDouble();
    final totalRatings = user['totalRatings'] ?? 0;
    final role = user['role'] ?? 'passenger';
    final isTopThree = rank <= 3;
    
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: isTopThree
            ? BorderSide(
                color: _getRankColor(rank),
                width: 2.5,
              )
            : BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.12),
                width: 1,
              ),
      ),
      child: Container(
        decoration: isTopThree
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getRankColor(rank).withValues(alpha: 0.1),
                    _getRankColor(rank).withValues(alpha: 0.05),
                  ],
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          child: Row(
            children: [
              // Posición/Rank con trofeo mejorado
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? _getRankColor(rank)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  boxShadow: isTopThree
                      ? [
                          BoxShadow(
                            color: _getRankColor(rank).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isTopThree
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRankIcon(rank),
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#$rank',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '#$rank',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: role == 'driver'
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
                          color: role == 'driver'
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingMD),
              // Información
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
                              color: isTopThree ? _getRankColor(rank) : null,
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
                    const SizedBox(height: AppTheme.spacingSM),
                    Row(
                      children: [
                        _buildStarRating(avgRating),
                        const SizedBox(width: AppTheme.spacingSM),
                        Text(
                          '${avgRating.toStringAsFixed(1)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          '($totalRatings ${totalRatings == 1 ? 'calificación' : 'calificaciones'})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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




