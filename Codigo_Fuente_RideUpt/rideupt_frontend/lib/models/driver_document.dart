// lib/models/driver_document.dart

/// Modelo para documentos del conductor
class DriverDocument {
  final String tipoDocumento;
  final String? urlImagen;
  final DateTime subidoEn;

  DriverDocument({
    required this.tipoDocumento,
    this.urlImagen,
    required this.subidoEn,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      tipoDocumento: json['tipoDocumento'] ?? '',
      urlImagen: json['urlImagen'],
      subidoEn: json['subidoEn'] != null
          ? DateTime.parse(json['subidoEn'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipoDocumento': tipoDocumento,
      'urlImagen': urlImagen,
      'subidoEn': subidoEn.toIso8601String(),
    };
  }

  bool get isUploaded => urlImagen != null && urlImagen!.isNotEmpty;
}

/// Estado de documentos del conductor
class DriverDocumentsStatus {
  final Map<String, DocumentStatus> documentosRequeridos;
  final Map<String, DocumentStatus> documentosOpcionales;
  final bool todosSubidos;
  final bool puedeConvertirseEnConductor;
  final String? approvalStatus;
  final String? rejectionReason;

  DriverDocumentsStatus({
    required this.documentosRequeridos,
    required this.documentosOpcionales,
    required this.todosSubidos,
    required this.puedeConvertirseEnConductor,
    this.approvalStatus,
    this.rejectionReason,
  });

  factory DriverDocumentsStatus.fromJson(Map<String, dynamic> json) {
    final requeridos = <String, DocumentStatus>{};
    if (json['documentosRequeridos'] != null) {
      (json['documentosRequeridos'] as Map<String, dynamic>).forEach((key, value) {
        requeridos[key] = DocumentStatus.fromJson(value);
      });
    }

    final opcionales = <String, DocumentStatus>{};
    if (json['documentosOpcionales'] != null) {
      (json['documentosOpcionales'] as Map<String, dynamic>).forEach((key, value) {
        opcionales[key] = DocumentStatus.fromJson(value);
      });
    }

    return DriverDocumentsStatus(
      documentosRequeridos: requeridos,
      documentosOpcionales: opcionales,
      todosSubidos: json['todosSubidos'] ?? false,
      puedeConvertirseEnConductor: json['puedeConvertirseEnConductor'] ?? false,
      approvalStatus: json['approvalStatus'],
      rejectionReason: json['rejectionReason'],
    );
  }
}

/// Estado individual de un documento
class DocumentStatus {
  final bool subido;

  DocumentStatus({
    required this.subido,
  });

  factory DocumentStatus.fromJson(Map<String, dynamic> json) {
    return DocumentStatus(
      subido: json['subido'] ?? false,
    );
  }
}

