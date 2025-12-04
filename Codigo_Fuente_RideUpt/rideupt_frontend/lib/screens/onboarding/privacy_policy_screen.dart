import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad - RideUpt',
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
              '1. Información que Recopilamos',
              'Recopilamos la siguiente información:\n\n'
              '• Información personal: nombre, email, teléfono, universidad\n'
              '• Información del vehículo (solo conductores): marca, modelo, placa\n'
              '• Ubicación: para mostrar viajes cercanos y crear rutas\n'
              '• Datos de uso: cómo interactúas con la aplicación\n'
              '• Información de viajes: origen, destino, horarios',
            ),
            
            _buildSection(
              context,
              '2. Cómo Usamos tu Información',
              'Utilizamos tu información para:\n\n'
              '• Proporcionar y mejorar nuestros servicios\n'
              '• Conectarte con otros estudiantes para viajes compartidos\n'
              '• Mostrar viajes relevantes basados en tu ubicación\n'
              '• Enviar notificaciones sobre viajes y actualizaciones\n'
              '• Mantener la seguridad de la plataforma\n'
              '• Cumplir con obligaciones legales',
            ),
            
            _buildSection(
              context,
              '3. Compartir Información',
              'Compartimos tu información solo en las siguientes circunstancias:\n\n'
              '• Con otros usuarios de la aplicación (información básica de perfil)\n'
              '• Con proveedores de servicios que nos ayudan a operar la aplicación\n'
              '• Cuando sea requerido por ley o para proteger nuestros derechos\n'
              '• En caso de emergencia para garantizar la seguridad',
            ),
            
            _buildSection(
              context,
              '4. Seguridad de los Datos',
              'Implementamos medidas de seguridad para proteger tu información:\n\n'
              '• Encriptación de datos sensibles\n'
              '• Acceso restringido a la información personal\n'
              '• Monitoreo regular de seguridad\n'
              '• Actualizaciones de seguridad regulares',
            ),
            
            _buildSection(
              context,
              '5. Tus Derechos',
              'Tienes derecho a:\n\n'
              '• Acceder a tu información personal\n'
              '• Corregir información inexacta\n'
              '• Solicitar la eliminación de tu cuenta\n'
              '• Retirar el consentimiento en cualquier momento\n'
              '• Recibir una copia de tus datos',
            ),
            
            _buildSection(
              context,
              '6. Cookies y Tecnologías Similares',
              'Utilizamos cookies y tecnologías similares para:\n\n'
              '• Recordar tus preferencias\n'
              '• Analizar el uso de la aplicación\n'
              '• Mejorar la experiencia del usuario\n'
              '• Personalizar el contenido',
            ),
            
            _buildSection(
              context,
              '7. Retención de Datos',
              'Conservamos tu información personal solo durante el tiempo necesario para:\n\n'
              '• Proporcionar nuestros servicios\n'
              '• Cumplir con obligaciones legales\n'
              '• Resolver disputas\n'
              '• Hacer cumplir nuestros acuerdos',
            ),
            
            _buildSection(
              context,
              '8. Menores de Edad',
              'Nuestra aplicación está dirigida a estudiantes universitarios. No recopilamos intencionalmente información de menores de 18 años.',
            ),
            
            _buildSection(
              context,
              '9. Cambios en esta Política',
              'Podemos actualizar esta política de privacidad ocasionalmente. Te notificaremos sobre cambios significativos a través de la aplicación.',
            ),
            
            _buildSection(
              context,
              '10. Contacto',
              'Para preguntas sobre esta política de privacidad:\n\n'
              'Email: privacidad@rideupt.com\n'
              'Teléfono: +51 999 999 999\n'
              'Dirección: Universidad Privada de Tacna, Tacna, Perú',
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

