class UpdateCheckInfo {
  const UpdateCheckInfo({
    required this.isUpdateAvailable,
    required this.isImmediateUpdateAllowed,
    this.availableVersionCode,
  });

  final bool isUpdateAvailable;
  final bool isImmediateUpdateAllowed;
  final int? availableVersionCode;
}
