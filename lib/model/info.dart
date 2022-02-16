class Info {
  late bool status;
  late String message;

  Info({required this.status, required this.message});

  @override
  String toString() {
    return 'Info{status: $status, message: $message}';
  }
}
