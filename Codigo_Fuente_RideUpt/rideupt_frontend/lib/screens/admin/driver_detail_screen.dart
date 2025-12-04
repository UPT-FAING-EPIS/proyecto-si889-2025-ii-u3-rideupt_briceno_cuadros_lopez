// lib/screens/admin/driver_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../api/api_service.dart';
import '../../utils/image_utils.dart';

class DriverDetailScreen extends StatefulWidget {
  final String driverId;

  const DriverDetailScreen({super.key, required this.driverId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _driver;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDriverDetails();
  }

  Future<void> _loadDriverDetails() async {
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

      final response = await _apiService.get('admin/drivers/${widget.driverId}', token);
      
      setState(() {
        _driver = response['driver'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _approveDriver() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      await _apiService.put('admin/drivers/${widget.driverId}/approve', token, {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conductor aprobado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar conductor: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rejectDriver(String reason) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      await _apiService.put('admin/drivers/${widget.driverId}/reject', token, {
        'reason': reason,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conductor rechazado exitosamente'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar conductor: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Conductor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de rechazar a ${_driver?['firstName']} ${_driver?['lastName']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razón del rechazo',
                hintText: 'Ej: Documentos incompletos o no válidos',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectDriver(reasonController.text.isNotEmpty 
                ? reasonController.text 
                : 'Documentos no cumplen con los requisitos');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _getImageUrl(String? url) {
    return ImageUtils.buildImageUrl(url);
  }

  void _showImageZoom(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Conductor'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverDetails,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar detalles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDriverDetails,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _driver == null
                  ? const Center(child: Text('No se encontraron datos'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información personal
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 24),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Información Personal',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Nombre', '${_driver!['firstName']} ${_driver!['lastName']}'),
                                  _buildInfoRow('Email', _driver!['email'] ?? ''),
                                  _buildInfoRow('Teléfono', _driver!['phone'] ?? 'Pendiente'),
                                  _buildInfoRow('Universidad', _driver!['university'] ?? ''),
                                  _buildInfoRow('Código de Estudiante', _driver!['studentId'] ?? ''),
                                  if (_driver!['age'] != null)
                                    _buildInfoRow('Edad', _driver!['age'].toString()),
                                  if (_driver!['gender'] != null && _driver!['gender'] != 'prefiero_no_decir')
                                    _buildInfoRow('Género', _driver!['gender']),
                                ],
                              ),
                            ),
                          ),

                          // Información del vehículo
                          if (_driver!['vehicle'] != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_car, size: 24),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Información del Vehículo',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Marca', _driver!['vehicle']['make'] ?? ''),
                                    _buildInfoRow('Modelo', _driver!['vehicle']['model'] ?? ''),
                                    _buildInfoRow('Año', _driver!['vehicle']['year']?.toString() ?? ''),
                                    _buildInfoRow('Color', _driver!['vehicle']['color'] ?? ''),
                                    _buildInfoRow('Placa', _driver!['vehicle']['licensePlate'] ?? ''),
                                    _buildInfoRow('Asientos Totales', _driver!['vehicle']['totalSeats']?.toString() ?? ''),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Documentos
                          if (_driver!['driverDocuments'] != null && 
                              (_driver!['driverDocuments'] as List).isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.description, size: 24),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Documentos',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Toca una imagen para ampliarla',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...((_driver!['driverDocuments'] as List).map((doc) {
                                      final imageUrl = _getImageUrl(doc['urlImagen']);
                                      final docType = doc['tipoDocumento'] ?? '';
                                      final requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
                                      final isRequired = requiredDocs.contains(docType);
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  docType,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (isRequired) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade100,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Requerido',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blue.shade900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (doc['subidoEn'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Subido: ${_formatDate(doc['subidoEn'])}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            if (imageUrl.isNotEmpty)
                                              Center(
                                                child: GestureDetector(
                                                  onTap: () => _showImageZoom(imageUrl, docType),
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                      maxWidth: 600, // Ancho máximo para pantallas grandes
                                                      maxHeight: 400, // Altura máxima
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: colorScheme.outline,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final screenWidth = MediaQuery.of(context).size.width;
                                                          final isSmallScreen = screenWidth < 600;
                                                          final double imageWidth = isSmallScreen 
                                                              ? screenWidth - 48.0 // Ancho completo menos padding en móvil
                                                              : 600.0; // Ancho fijo en pantallas grandes
                                                          final double imageHeight = isSmallScreen ? 250.0 : 400.0;
                                                          
                                                          return CachedNetworkImage(
                                                            imageUrl: imageUrl,
                                                            width: imageWidth,
                                                            height: imageHeight,
                                                            fit: BoxFit.contain, // Cambiado a contain para ver la imagen completa
                                                            placeholder: (context, url) => Container(
                                                              width: imageWidth,
                                                              height: imageHeight,
                                                              color: colorScheme.surfaceContainerHighest,
                                                              child: Center(
                                                                child: CircularProgressIndicator(
                                                                  color: colorScheme.primary,
                                                                ),
                                                              ),
                                                            ),
                                                            errorWidget: (context, url, error) => Container(
                                                              width: imageWidth,
                                                              height: imageHeight,
                                                              color: colorScheme.surfaceContainerHighest,
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(
                                                                    Icons.broken_image,
                                                                    size: 48,
                                                                    color: colorScheme.onSurfaceVariant,
                                                                  ),
                                                                  const SizedBox(height: 8),
                                                                  Text(
                                                                    'Error al cargar imagen',
                                                                    style: TextStyle(
                                                                      color: colorScheme.onSurfaceVariant,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    })),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Estado de aprobación
                          const SizedBox(height: 16),
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info, size: 24),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Estado de Aprobación',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildStatusInfo(),
                                ],
                              ),
                            ),
                          ),

                          // Botones de acción
                          if (_driver!['driverApprovalStatus'] == 'pending') ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _showRejectDialog,
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Rechazar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _approveDriver,
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Aprobar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final status = _driver!['driverApprovalStatus'] ?? 'pending';
    final documents = _driver!['driverDocuments'] as List? ?? [];
    final requiredDocs = ['Foto del Vehículo', 'Tarjeta de Propiedad', 'Carnet Universitario'];
    final hasAllDocs = requiredDocs.every((docType) => 
      documents.any((doc) => doc['tipoDocumento'] == docType)
    );

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aprobado';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazado';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pendiente';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Estado: $statusText',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        if (status == 'pending') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasAllDocs ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasAllDocs ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasAllDocs ? Icons.check_circle : Icons.warning,
                  color: hasAllDocs ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasAllDocs
                        ? 'Todos los documentos requeridos están presentes. Listo para aprobar.'
                        : 'Faltan documentos requeridos. No se puede aprobar hasta que se completen.',
                    style: TextStyle(
                      color: hasAllDocs ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (status == 'rejected' && _driver!['driverRejectionReason'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Razón de Rechazo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _driver!['driverRejectionReason'],
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
}
