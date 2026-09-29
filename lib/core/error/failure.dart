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

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Server error.', this.statusCode]);
}

final class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Unexpected data from server.']);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not read or write local data.']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
