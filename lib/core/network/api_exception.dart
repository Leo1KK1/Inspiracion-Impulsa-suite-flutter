import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  final String message;
  final int? statusCode;
  final List<Object?> errors;

  factory ApiException.fromDio(DioException exception) {
    final response = exception.response;
    final payload = response?.data;
    if (payload is Map) {
      final message = payload['message'];
      final rawErrors = payload['errors'];
      return ApiException(
        message is String && message.trim().isNotEmpty
            ? message
            : _fallbackMessage(response?.statusCode),
        statusCode: response?.statusCode,
        errors: rawErrors is List ? rawErrors.cast<Object?>() : const [],
      );
    }
    return ApiException(
      _fallbackMessage(response?.statusCode),
      statusCode: response?.statusCode,
    );
  }

  static String _fallbackMessage(int? statusCode) => switch (statusCode) {
    401 => 'La sesión expiró. Inicia sesión nuevamente.',
    403 => 'No tienes permisos para realizar esta operación.',
    404 => 'No se encontró la información solicitada.',
    409 => 'La operación entra en conflicto con información existente.',
    422 => 'La información enviada no cumple las reglas del negocio.',
    _ => 'No fue posible comunicarse con el servidor.',
  };

  @override
  String toString() => message;
}
