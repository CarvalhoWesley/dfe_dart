import 'dart:typed_data';

/// Nó ASN.1 (BER/DER) mínimo, suficiente para PKCS#12, PKCS#8 e X.509.
class Asn1Node {
  Asn1Node(this.tag, this.content, this.encoded, [this._children]);

  /// Byte de tag completo (classe + construído + número), só tags curtas.
  final int tag;

  /// Conteúdo (para tipos construídos com tamanho indefinido, é a concatenação
  /// dos filhos já reencodados; use [children]).
  final Uint8List content;

  /// TLV original completo.
  final Uint8List encoded;

  List<Asn1Node>? _children;

  bool get isConstructed => tag & 0x20 != 0;
  int get tagClass => tag & 0xC0;
  int get tagNumber => tag & 0x1F;
  bool get isContextSpecific => tagClass == 0x80;

  List<Asn1Node> get children =>
      _children ??= isConstructed ? Asn1Reader(content).readAll() : const [];

  Asn1Node operator [](int i) => children[i];

  /// OCTET STRING (primitivo ou construído/BER).
  Uint8List get octets {
    if (!isConstructed) return content;
    final b = BytesBuilder(copy: false);
    for (final c in children) {
      b.add(c.octets);
    }
    return b.toBytes();
  }

  BigInt get integer {
    var r = BigInt.zero;
    for (final b in content) {
      r = (r << 8) | BigInt.from(b);
    }
    if (content.isNotEmpty && content[0] & 0x80 != 0) {
      r -= BigInt.one << (content.length * 8);
    }
    return r;
  }

  int get intValue => integer.toInt();

  String get oid {
    final c = content;
    if (c.isEmpty) return '';
    final parts = <int>[c[0] ~/ 40, c[0] % 40];
    var v = 0;
    for (var i = 1; i < c.length; i++) {
      v = (v << 7) | (c[i] & 0x7F);
      if (c[i] & 0x80 == 0) {
        parts.add(v);
        v = 0;
      }
    }
    return parts.join('.');
  }
}

class Asn1Reader {
  Asn1Reader(this._data);

  final Uint8List _data;
  int _pos = 0;

  bool get hasMore => _pos < _data.length;

  List<Asn1Node> readAll() {
    final r = <Asn1Node>[];
    while (hasMore) {
      final n = read();
      if (n == null) break; // marcador de fim (00 00)
      r.add(n);
    }
    return r;
  }

  static Asn1Node parse(Uint8List data) => Asn1Reader(data).read()!;

  /// Lê um TLV. Retorna null ao encontrar end-of-contents (00 00).
  Asn1Node? read() {
    final start = _pos;
    final tag = _byte();
    if ((tag & 0x1F) == 0x1F) {
      throw const FormatException('ASN.1: tags longas não suportadas');
    }
    var len = _byte();
    if (tag == 0 && len == 0) return null;

    if (len == 0x80) {
      // Tamanho indefinido (BER): lê filhos até 00 00.
      final children = <Asn1Node>[];
      while (true) {
        final c = read();
        if (c == null) break;
        children.add(c);
      }
      final b = BytesBuilder(copy: false);
      for (final c in children) {
        b.add(c.encoded);
      }
      return Asn1Node(tag, b.toBytes(),
          Uint8List.sublistView(_data, start, _pos), children);
    }

    if (len & 0x80 != 0) {
      final n = len & 0x7F;
      len = 0;
      for (var i = 0; i < n; i++) {
        len = (len << 8) | _byte();
      }
    }
    if (_pos + len > _data.length) {
      throw const FormatException('ASN.1: tamanho além do fim dos dados');
    }
    final content = Uint8List.sublistView(_data, _pos, _pos + len);
    _pos += len;
    return Asn1Node(tag, content, Uint8List.sublistView(_data, start, _pos));
  }

  int _byte() {
    if (_pos >= _data.length) {
      throw const FormatException('ASN.1: fim inesperado dos dados');
    }
    return _data[_pos++];
  }
}
