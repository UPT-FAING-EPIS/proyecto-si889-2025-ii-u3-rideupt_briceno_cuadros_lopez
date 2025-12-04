// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedGender = 'prefiero_no_decir';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone == 'Pendiente' ? '' : user.phone;
      if (user.age != null) {
        _ageController.text = user.age.toString();
      }
      _selectedGender = user.gender ?? 'prefiero_no_decir';
      if (user.bio != null && user.bio!.isNotEmpty) {
        _bioController.text = user.bio!;
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final updatedData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': _ageController.text.trim().isEmpty ? null : int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'bio': _bioController.text.trim(),
      };

      final apiService = ApiService();
      await apiService.put('users/profile', authProvider.token!, updatedData);

      // Recargar perfil del usuario para obtener los datos actualizados
      await authProvider.refreshUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar/Foto de perfil
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                if (user == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                final profilePhoto = user.profilePhoto;
                final hasGooglePhoto = profilePhoto.isNotEmpty && 
                                     profilePhoto != 'default_avatar.png' &&
                                     Uri.tryParse(profilePhoto)?.hasAbsolutePath == true;
                
                return Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: hasGooglePhoto
                            ? NetworkImage(profilePhoto)
                            : null,
                        child: !hasGooglePhoto
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      // Solo mostrar botón de cambiar foto si NO hay foto de Google
                      if (!hasGooglePhoto)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('La foto de perfil se obtiene desde tu cuenta de Google')),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Nombre
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Apellido
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El apellido es obligatorio';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Teléfono
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Número de Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+51 999 999 999',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El teléfono es obligatorio';
                }
                if (value.length < 9) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Edad
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Edad',
                prefixIcon: Icon(Icons.cake_outlined),
                hintText: 'Ej: 20',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Ingresa una edad válida';
                  }
                  if (age < 16 || age > 100) {
                    return 'Debes tener entre 16 y 100 años';
                  }
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Género
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Sexo',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
                DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
                DropdownMenuItem(value: 'prefiero_no_decir', child: Text('Prefiero no decir')),
              ],
              onChanged: (value) {
                setState(() => _selectedGender = value!);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Biografía
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Sobre mí (opcional)',
                prefixIcon: Icon(Icons.info_outline),
                hintText: 'Cuéntanos un poco sobre ti...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 500,
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Máximo 500 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Botón Guardar
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'GUARDAR CAMBIOS'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Información adicional
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu información es privada y solo se comparte con conductores/pasajeros cuando confirmes un viaje',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
}




