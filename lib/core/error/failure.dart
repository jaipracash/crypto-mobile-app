import 'package:equatable/equatable.dart';

enum FailureType { noInternet, timeout, rateLimited, notFound, server, unknown }

class Failure extends Equatable implements Exception {
  const Failure(this.type, this.message);

  final FailureType type;
  final String message;

  @override
  List<Object?> get props => [type, message];

  @override
  String toString() => message;
}
