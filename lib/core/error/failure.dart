class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class StorageFailure extends AppFailure {
  const StorageFailure([
    super.message = 'Unable to access charging data. Please try again.',
  ]);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}
