// lib/screens/driver/become_driver_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/driver_document_service.dart';
import '../../models/driver_document.dart';
import '../../widgets/document_upload_widget.dart';
import '../../widgets/modern_loading.dart';

class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen> {
  final DriverDocumentService _documentService = DriverDocumentService();
  final Map<String, File?> _selectedImages = {};
  final Map<String, DriverDocument?> _uploadedDocuments = {};
  DriverDocumentsStatus? _status;
  bool _isLoading = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingStatus = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No estás autenticado')),
          );
        }
        return;
      }

      // Cargar documentos existentes
      final documents = await _documentService.getDocuments(token);
      for (var doc in documents) {
        _uploadedDocuments[doc.tipoDocumento] = doc;
      }

      // Cargar estado
      _status = await _documentService.getDocumentsStatus(token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar documentos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _uploadDocument(String tipoDocumento, File imageFile) async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('No estás autenticado');
      }

      // Subir documento
      final document = await _documentService.uploadDocument(
        token,
        imageFile,
        tipoDocumento,
      );

      setState(() {
        _uploadedDocuments[tipoDocumento] = document;
        _selectedImages[tipoDocumento] = null; // Limpiar selección local
      });

      // Recargar estado
      _status = await _documentService.getDocumentsStatus(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento subido exitosamente. Esperando aprobación del administrador.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: $e'),
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


  Future<void> _deleteDocument(String tipoDocumento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Estás seguro de eliminar $tipoDocumento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('No estás autenticado');
      }

      await _documentService.deleteDocument(token, tipoDocumento);

      setState(() {
        _uploadedDocuments.remove(tipoDocumento);
        _selectedImages.remove(tipoDocumento);
      });

      // Recargar estado
      _status = await _documentService.getDocumentsStatus(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
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

  Widget _buildApprovalStatusBanner() {
    final approvalStatus = _status?.approvalStatus;
    final rejectionReason = _status?.rejectionReason;

    if (approvalStatus == 'approved') {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
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
        margin: const EdgeInsets.only(bottom: 24),
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
              const SizedBox(height: 8),
              Text(
                'Razón: $rejectionReason',
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Puedes corregir tus documentos y volver a enviarlos para revisión.',
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else if (approvalStatus == 'pending') {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
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

  Widget _buildDocumentCard(String tipoDocumento, bool isRequired) {
    final doc = _uploadedDocuments[tipoDocumento];
    final status = _status?.documentosRequeridos[tipoDocumento] ??
                   _status?.documentosOpcionales[tipoDocumento];

    // Determinar el estado: subido o no subido
    String? documentStatus;
    if (status?.subido == true || doc != null) {
      documentStatus = 'subido';
    } else {
      documentStatus = null;
    }

    return DocumentUploadWidget(
      tipoDocumento: tipoDocumento,
      imageUrl: doc?.urlImagen,
      documentStatus: documentStatus,
      isRequired: isRequired,
      approvalStatus: _status?.approvalStatus,
      rejectionReason: _status?.rejectionReason,
      onImageSelected: (file) {
        setState(() {
          _selectedImages[tipoDocumento] = file;
        });
        _uploadDocument(tipoDocumento, file);
      },
      onDelete: doc != null ? () => _deleteDocument(tipoDocumento) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Conviértete en Conductor'),
        ),
        body: const Center(child: ModernLoading()),
      );
    }

    final canBecomeDriver = _status?.puedeConvertirseEnConductor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conviértete en Conductor'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner informativo mejorado
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.verified_user,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Conviértete en Conductor',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sube los siguientes documentos para verificar tu identidad y vehículo. Un administrador revisará tus documentos y te notificará cuando sean aprobados.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Revisión por panel administrativo',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Banner de estado de aprobación
                if (_status?.approvalStatus != null)
                  _buildApprovalStatusBanner(),

                // Documentos requeridos
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Documentos Requeridos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Todos estos documentos son obligatorios para ser conductor',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDocumentCard('Foto del Vehículo', true),
                _buildDocumentCard('Tarjeta de Propiedad', true),
                _buildDocumentCard('Carnet Universitario', true),

                const SizedBox(height: 32),

                // Documentos opcionales
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Documentos Opcionales',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Estos documentos ayudan a mejorar tu perfil',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDocumentCard('Selfie del Conductor', false),

                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),

          // Botón flotante para completar proceso
          if (canBecomeDriver)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () {
                    // Navegar a la pantalla de datos del vehículo
                    Navigator.pushNamed(context, '/driver-profile');
                  },
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'Continuar con Datos del Vehículo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          // Indicador de progreso
          if (!canBecomeDriver && _status != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completa todos los documentos requeridos para continuar',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

