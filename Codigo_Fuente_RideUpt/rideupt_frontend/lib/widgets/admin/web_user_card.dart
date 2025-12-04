// lib/widgets/admin/web_user_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';

class WebUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;

  const WebUserCard({
    super.key,
    required this.user,
    this.onTap,
  });

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
    final role = user['role'] ?? 'passenger';
    final isAdmin = user['isAdmin'] == true;
    final avgRating = user['averageRating'] ?? 0.0;
    final totalRatings = user['totalRatings'] ?? 0;

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
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM + 4,
          ),
          child: Row(
            children: [
              // Avatar más pequeño para web
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
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
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  if (isAdmin)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppTheme.spacingSM + 4),
              // Información compacta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                        child: Text(
                          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
                  const SizedBox(height: 3),
                  Text(
                    user['email'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user['studentId'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Código: ${user['studentId']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (avgRating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < avgRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 13,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          '${avgRating.toStringAsFixed(1)} ($totalRatings)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
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
}

