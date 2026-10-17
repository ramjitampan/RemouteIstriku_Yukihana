class ConnectionValidator {
  const ConnectionValidator._();

  static String? ipv4(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'IP laptop wajib diisi.';
    final parts = input.split('.');
    if (parts.length != 4) return 'Masukkan alamat IPv4, contoh 192.168.1.20.';
    for (final part in parts) {
      if (part.isEmpty || !RegExp(r'^\d{1,3}$').hasMatch(part)) {
        return 'Setiap bagian IP harus berupa angka 0 sampai 255.';
      }
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) {
        return 'Setiap bagian IP harus berupa angka 0 sampai 255.';
      }
    }
    return null;
  }

  static String? port(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Port wajib diisi.';
    if (!RegExp(r'^\d+$').hasMatch(input)) return 'Port harus berupa angka.';
    final number = int.tryParse(input);
    if (number == null || number < 1 || number > 65535) {
      return 'Port harus berada di antara 1 dan 65535.';
    }
    return null;
  }
}
