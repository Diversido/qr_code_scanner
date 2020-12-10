class QrCameraFacing {
  const QrCameraFacing._(this.name);

  factory QrCameraFacing.fromName(String name) {
    if (name == back.name) {
      return back;
    }
    if (name == front.name) {
      return front;
    }
    throw ArgumentError.value(name);
  }

  final String name;

  static const QrCameraFacing back = QrCameraFacing._('back');
  static const QrCameraFacing front = QrCameraFacing._('front');
}

