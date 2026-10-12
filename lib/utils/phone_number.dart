String? normalizeContactPhoneNumber(String value) {
  var phone = value.trim().replaceAll(RegExp(r'[\s()-]'), '');
  if (phone.startsWith('00')) phone = '+${phone.substring(2)}';
  if (RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) return phone;

  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (RegExp(r'^01[0125][0-9]{8}$').hasMatch(digits)) {
    return '+20${digits.substring(1)}';
  }
  return null;
}
