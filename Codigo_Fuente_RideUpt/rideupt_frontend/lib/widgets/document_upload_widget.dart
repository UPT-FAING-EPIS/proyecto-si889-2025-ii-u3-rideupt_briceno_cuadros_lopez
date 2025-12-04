// lib/widgets/document_upload_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_config.dart';

class DocumentUploadWidget extends StatefulWidget {
  final String tipoDocumento;
  final String? imageUrl;
  final String? documentStatus; // 'subido' o null
  final bool isRequired;
  final String? approvalStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final Function(File) onImageSelected;
  final VoidCallback? onDelete;

  const DocumentUploadWidget({
    super.key,
    required this.tipoDocumento,
    this.imageUrl,
    this.documentStatus,
    this.isRequired = true,
    this.approvalStatus,
    this.rejectionReason,
    required this.onImageSelected,
    this.onDelete,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isLoading = false;
        });
        // Llamar al callback para subir la imagen
        widget.onImageSelected(_selectedImage!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getApprovalStatusText() {
    switch (widget.approvalStatus) {
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'pending':
        return 'Pendiente de revisión';
      default:
        return 'Documento subido';
    }
  }

  Color _getApprovalStatusColor() {
    switch (widget.approvalStatus) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getApprovalStatusIcon() {
    switch (widget.approvalStatus) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.upload_file;
    }
  }

  Widget _buildImagePreview() {
    // Imagen seleccionada localmente (antes de subir)
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
            // Overlay de "Subiendo..."
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Subiendo...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
    
    // Imagen ya subida (desde servidor)
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      // Construir URL completa correctamente
      String fullUrl;
      if (widget.imageUrl!.startsWith('http://') || widget.imageUrl!.startsWith('https://')) {
        fullUrl = widget.imageUrl!;
      } else {
        final baseUrl = AppConfig.socketUrl;
        final cleanUrl = widget.imageUrl!.startsWith('/') ? widget.imageUrl! : '/${widget.imageUrl!}';
        fullUrl = baseUrl.endsWith('/') 
            ? '$baseUrl${cleanUrl.substring(1)}' 
            : '$baseUrl$cleanUrl';
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: fullUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Error al cargar imagen',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            // Badge de estado del documento
            if (widget.documentStatus == 'subido')
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Subido',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
    
    // Estado vacío - sin imagen
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isRequired ? Colors.red[300]! : Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: widget.isRequired ? Colors.red[400] : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Toca para subir imagen',
            style: TextStyle(
              color: widget.isRequired ? Colors.red[600] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.isRequired) ...[
            const SizedBox(height: 4),
            Text(
              '(Requerido)',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null || 
                     (widget.imageUrl != null && widget.imageUrl!.isNotEmpty);
    final isUploaded = widget.documentStatus == 'subido';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.tipoDocumento,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Requerido',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isLoading ? null : _showImageSourceDialog,
              child: _buildImagePreview(),
            ),
            if (hasImage && isUploaded) ...[
              const SizedBox(height: 12),
              // Barra de estado del documento
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getApprovalStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getApprovalStatusColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getApprovalStatusIcon(),
                      color: _getApprovalStatusColor(),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getApprovalStatusText(),
                            style: TextStyle(
                              color: _getApprovalStatusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.approvalStatus == 'rejected' && 
                              widget.rejectionReason != null &&
                              widget.rejectionReason!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Razón: ${widget.rejectionReason}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (widget.approvalStatus == 'pending') ...[
                            const SizedBox(height: 4),
                            Text(
                              'Esperando revisión del administrador',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón de eliminar
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: widget.onDelete,
                        tooltip: 'Eliminar documento',
                        iconSize: 24,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

