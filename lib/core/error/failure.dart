sealed class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() {
    return message;
  }
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Connection timed out.']);
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Server error.', this.statusCode]);
}

final class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Unexpected data from server.']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
