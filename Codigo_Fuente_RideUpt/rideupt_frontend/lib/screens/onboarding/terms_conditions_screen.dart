import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones de Uso - RideUpt',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              '1. Aceptación de los Términos',
              'Al usar la aplicación RideUpt, aceptas estos términos y condiciones. Si no estás de acuerdo, no uses la aplicación.',
            ),
            
            _buildSection(
              context,
              '2. Descripción del Servicio',
              'RideUpt es una plataforma que conecta estudiantes universitarios para compartir viajes. No somos un servicio de transporte público ni una empresa de taxis.',
            ),
            
            _buildSection(
              context,
              '3. Uso de la Aplicación',
              '• Debes ser estudiante universitario para usar la aplicación\n'
              '• Solo puedes crear viajes si eres conductor con vehículo propio\n'
              '• No puedes usar la aplicación para actividades comerciales\n'
              '• Debes mantener actualizada tu información personal',
            ),
            
            _buildSection(
              context,
              '4. Responsabilidades del Usuario',
              '• Verificar la identidad de otros usuarios\n'
              '• Cumplir con las leyes de tránsito\n'
              '• Mantener un comportamiento respetuoso\n'
              '• Reportar cualquier comportamiento inapropiado',
            ),
            
            _buildSection(
              context,
              '5. Privacidad y Datos',
              'Recopilamos y procesamos tus datos personales de acuerdo con nuestra Política de Privacidad. Esto incluye:\n'
              '• Información de perfil (nombre, universidad, etc.)\n'
              '• Ubicación para mostrar viajes cercanos\n'
              '• Datos de uso de la aplicación',
            ),
            
            _buildSection(
              context,
              '6. Limitación de Responsabilidad',
              'RideUpt no se hace responsable por:\n'
              '• Accidentes o incidentes durante los viajes\n'
              '• Pérdida de objetos personales\n'
              '• Comportamiento de otros usuarios\n'
              '• Interrupciones del servicio',
            ),
            
            _buildSection(
              context,
              '7. Modificaciones',
              'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios serán notificados a través de la aplicación.',
            ),
            
            _buildSection(
              context,
              '8. Contacto',
              'Para consultas sobre estos términos, contacta a:\n'
              'Email: soporte@rideupt.com\n'
              'Teléfono: +51 999 999 999',
            ),
            
            const SizedBox(height: 32),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

