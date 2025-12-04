// lib/services/driver_document_service.dart
import 'dart:io';
import '../api/api_service.dart';
import '../models/driver_document.dart';

class DriverDocumentService {
  final ApiService _apiService = ApiService();

  /// Subir un documento del conductor
  Future<DriverDocument> uploadDocument(
    String token,
    File imageFile,
    String tipoDocumento,
  ) async {
    try {
      final response = await _apiService.postMultipart(
        'driver-documents/upload',
        token,
        imageFile,
        {'tipoDocumento': tipoDocumento},
      );

      if (response != null && response['documento'] != null) {
        return DriverDocument.fromJson(response['documento']);
      }
      throw Exception('Respuesta inválida del servidor');
    } catch (e) {
      throw Exception('Error al subir documento: ${e.toString()}');
    }
  }

  /// Obtener todos los documentos del conductor
  Future<List<DriverDocument>> getDocuments(String token) async {
    try {
      final response = await _apiService.get('driver-documents', token);
      
      if (response != null && response['documentos'] != null) {
        return (response['documentos'] as List)
            .map((doc) => DriverDocument.fromJson(doc))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error al obtener documentos: ${e.toString()}');
    }
  }

  /// Obtener estado de documentos del conductor
  Future<DriverDocumentsStatus> getDocumentsStatus(String token) async {
    try {
      final response = await _apiService.get('driver-documents/status', token);
      return DriverDocumentsStatus.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener estado de documentos: ${e.toString()}');
    }
  }

  /// Eliminar un documento
  Future<void> deleteDocument(String token, String tipoDocumento) async {
    try {
      await _apiService.delete('driver-documents/$tipoDocumento', token);
    } catch (e) {
      throw Exception('Error al eliminar documento: ${e.toString()}');
    }
  }

}

