import 'dart:typed_data';

/// CRC32 checksum calculator.
class Crc32 {
  /// CRC32 lookup table (public for streaming calculations).
  static final List<int> table = _generateTable();

  static List<int> _generateTable() {
    final t = List<int>.filled(256, 0);
    for (var i = 0; i < 256; i++) {
      var crc = i;
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
      t[i] = crc;
    }
    return t;
  }

  /// Calculates CRC32 for the given bytes.
  static int calculate(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = (crc >> 8) ^ table[(crc ^ byte) & 0xFF];
    }
    return crc ^ 0xFFFFFFFF;
  }

  /// Calculates CRC32 incrementally (for streaming).
  static int update(int crc, Uint8List bytes) {
    var result = crc ^ 0xFFFFFFFF;
    for (final byte in bytes) {
      result = (result >> 8) ^ table[(result ^ byte) & 0xFF];
    }
    return result ^ 0xFFFFFFFF;
  }

  /// Returns CRC32 as unsigned 32-bit integer.
  static int toUnsigned(int crc) => crc & 0xFFFFFFFF;
}
