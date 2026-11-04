import 'package:equatable/equatable.dart';

class AppException extends Equatable implements Exception {
  const AppException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [code, message, statusCode];

  @override
  String toString() => '$code: $message';
}
