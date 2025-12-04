// lib/screens/home/header_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HeaderScreen extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const HeaderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      automaticallyImplyLeading: false, // Evitar leading automático que puede duplicar el título
      actions: [
        // Logo del usuario
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: _buildUserAvatar(user),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(user) {
    final hasGooglePhoto = user != null && 
                          user.profilePhoto.isNotEmpty && 
                          user.profilePhoto != 'default_avatar.png' &&
                          Uri.tryParse(user.profilePhoto)?.hasAbsolutePath == true;
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      backgroundImage: hasGooglePhoto
          ? NetworkImage(user.profilePhoto)
          : null,
      child: !hasGooglePhoto
          ? Text(
              _getUserInitial(user),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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



