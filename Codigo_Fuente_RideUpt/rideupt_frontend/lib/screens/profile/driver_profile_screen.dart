import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideupt_app/providers/auth_provider.dart';
import 'package:rideupt_app/widgets/auth_form_field.dart';
import 'package:rideupt_app/screens/home/main_navigation_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _seatsController = TextEditingController(text: '4'); // Por defecto 4 asientos

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final vehicleData = {
      'make': _makeController.text.trim(),
      'model': _modelController.text.trim(),
      'year': int.parse(_yearController.text.trim()),
      'color': _colorController.text.trim(),
      'licensePlate': _licensePlateController.text.trim(),
      'seats': int.parse(_seatsController.text.trim()),
    };

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateDriverProfile(vehicleData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil de conductor completado. Tu solicitud está pendiente de aprobación del administrador.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      
      // Navegar a la pantalla principal y limpiar el stack de navegación
      // Esto asegura que el usuario vea la pantalla de conductor
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildResubmitButton(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reenviar Solicitud'),
                    content: const Text(
                      '¿Estás seguro de que deseas reenviar tu solicitud? Asegúrate de haber corregido todos los documentos antes de reenviar.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Reenviar'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  final success = await authProvider.resubmitDriverApplication();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitud reenviada exitosamente. Está pendiente de revisión.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  } else if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
        icon: authProvider.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(authProvider.isLoading ? 'Reenviando...' : 'Reenviar Solicitud'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.red[400]!),
          foregroundColor: Colors.red[700],
        ),
      ),
    );
  }

  Widget _buildApprovalStatusBanner(user) {
    final approvalStatus = user.driverApprovalStatus;
    final rejectionReason = user.driverRejectionReason;

    if (approvalStatus == 'approved') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Aprobado!',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu solicitud ha sido aprobada. Ya puedes crear viajes como conductor.',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (approvalStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[700], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solicitud Rechazada',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Razón del rechazo:',
                          style: TextStyle(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rejectionReason,
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Puedes corregir tus documentos y volver a enviar tu solicitud para revisión.',
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    } else if (approvalStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.pending, color: Colors.orange[700], size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendiente de Aprobación',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tus documentos están siendo revisados por un administrador. Te notificaremos cuando se complete la revisión.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Si el usuario ya es conductor, mostrar mensaje informativo
    final isAlreadyDriver = user?.role == 'driver' && user?.vehicle != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner informativo
              if (!isAlreadyDriver)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '¡Último paso!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa los datos de tu vehículo para finalizar tu registro como conductor',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Puedes actualizar los datos de tu vehículo aquí',
                          style: TextStyle(color: Colors.green[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                isAlreadyDriver ? 'Actualizar datos del vehículo' : 'Completa los datos de tu vehículo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Banner de estado de aprobación
              if (isAlreadyDriver && user?.driverApprovalStatus != null) ...[
                _buildApprovalStatusBanner(user!),
                const SizedBox(height: 16),
                // Botón para reenviar solicitud si fue rechazada
                if (user.driverApprovalStatus == 'rejected')
                  _buildResubmitButton(context, authProvider),
                const SizedBox(height: 8),
              ],
              
              const SizedBox(height: 24),
              AuthFormField(controller: _makeController, labelText: 'Marca (ej. Toyota)'),
              const SizedBox(height: 16),
              AuthFormField(controller: _modelController, labelText: 'Modelo (ej. Yaris)'),
              const SizedBox(height: 16),
              AuthFormField(
                controller: _yearController,
                labelText: 'Año',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || int.tryParse(val) == null || val.length != 4) return 'Año inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthFormField(controller: _colorController, labelText: 'Color'),
              const SizedBox(height: 16),
              AuthFormField(controller: _licensePlateController, labelText: 'Placa'),
              const SizedBox(height: 16),
              AuthFormField(
                controller: _seatsController,
                labelText: 'Número de asientos disponibles',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Campo requerido';
                  final seats = int.tryParse(val);
                  if (seats == null || seats < 1 || seats > 20) {
                    return 'Debe ser entre 1 y 20 asientos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(isAlreadyDriver ? Icons.save : Icons.check_circle),
                      label: Text(
                        isAlreadyDriver 
                          ? 'ACTUALIZAR DATOS DEL VEHÍCULO'
                          : 'GUARDAR Y CONVERTIRME EN CONDUCTOR',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isAlreadyDriver 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}