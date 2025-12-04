// lib/widgets/admin/web_ranking_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';

class WebRankingCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final int rank;
  final int index;

  const WebRankingCard({
    super.key,
    required this.user,
    required this.rank,
    required this.index,
  });

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

  bool _hasProfilePhoto(String? profilePhoto) {
    return profilePhoto != null &&
           profilePhoto.isNotEmpty &&
           profilePhoto != 'default_avatar.png' &&
           Uri.tryParse(profilePhoto)?.hasAbsolutePath == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avgRating = (user['averageRating'] ?? 0.0).toDouble();
    final totalRatings = user['totalRatings'] ?? 0;
    final role = user['role'] ?? 'passenger';
    final isTopThree = rank <= 3;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: isTopThree
            ? BorderSide(
                color: _getRankColor(rank),
                width: 2,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM + 4,
          ),
          child: Row(
            children: [
              // Posición/Rank más pequeño
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? _getRankColor(rank)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  boxShadow: isTopThree
                      ? [
                          BoxShadow(
                            color: _getRankColor(rank).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isTopThree
                      ? Icon(
                          _getRankIcon(rank),
                          color: Colors.white,
                          size: 20,
                        )
                      : Text(
                          '#$rank',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              // Avatar más pequeño
              CircleAvatar(
                radius: 20,
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
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingSM),
              // Información compacta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:                         Text(
                          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isTopThree ? _getRankColor(rank) : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSM,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: role == 'driver'
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Text(
                          role == 'driver' ? 'Conductor' : 'Pasajero',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: role == 'driver'
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < avgRating.floor()
                              ? Icons.star
                              : index < avgRating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          size: 13,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: AppTheme.spacingXS),
                      Text(
                        '${avgRating.toStringAsFixed(1)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '($totalRatings ${totalRatings == 1 ? 'calificación' : 'calificaciones'})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
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
}

