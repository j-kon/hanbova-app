import 'dart:io';

/// Static configuration validation, not a DNS or redirect/egress firewall.
bool isHostedHttpsUrl(String value) {
  try {
    if (value != value.trim() || RegExp(r'[\s\\]').hasMatch(value)) {
      return false;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.port < 1 ||
        uri.port > 65535) {
      return false;
    }
    final host = uri.host
        .toLowerCase()
        .replaceAll(RegExp(r'^\[|\]$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    final address = InternetAddress.tryParse(host);
    if (address != null) {
      final bytes = address.rawAddress;
      if (bytes.length == 4) {
        if (host
            .split('.')
            .any((part) => part.length > 1 && part.startsWith('0'))) {
          return false;
        }
        return _publicV4(bytes);
      }
      if (bytes.take(10).every((b) => b == 0) &&
          bytes[10] == 255 &&
          bytes[11] == 255) {
        return _publicV4(bytes.sublist(12));
      }
      // Only global-unicast IPv6; excludes loopback, ULA, link-local and multicast.
      return (bytes[0] & 0xe0) == 0x20;
    }
    if (!host.contains('.') ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal')) {
      return false;
    }
    final labels = host.split('.');
    if (RegExp(r'^\d+$').hasMatch(labels.last)) return false;
    return host.length <= 253 &&
        labels.every((label) =>
            label.length <= 63 &&
            RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$').hasMatch(label));
  } on FormatException {
    return false;
  }
}

bool _publicV4(List<int> b) => !(b[0] == 0 ||
    b[0] == 10 ||
    b[0] == 127 ||
    (b[0] == 100 && b[1] >= 64 && b[1] <= 127) ||
    (b[0] == 169 && b[1] == 254) ||
    (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
    (b[0] == 192 && b[1] == 168) ||
    (b[0] == 198 && (b[1] == 18 || b[1] == 19)) ||
    b[0] >= 224);
