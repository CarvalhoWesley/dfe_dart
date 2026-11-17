import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../asn1/der.dart';

class Pkcs12Exception implements Exception {
  Pkcs12Exception(this.message);
  final String message;
  @override
  String toString() => 'Pkcs12Exception: $message';
}

/// Conteúdo extraído de um arquivo PKCS#12 (.pfx / .p12).
class Pkcs12Conteudo {
  Pkcs12Conteudo(this.chavesPkcs8, this.certificados);

  /// Chaves privadas em PKCS#8 (PrivateKeyInfo, DER, já decifradas).
  final List<Uint8List> chavesPkcs8;

  /// Certificados X.509 (DER).
  final List<Uint8List> certificados;
}

// OIDs
const _oidData = '1.2.840.113549.1.7.1';
const _oidEncryptedData = '1.2.840.113549.1.7.6';
const _oidKeyBag = '1.2.840.113549.1.12.10.1.1';
const _oidShroudedKeyBag = '1.2.840.113549.1.12.10.1.2';
const _oidCertBag = '1.2.840.113549.1.12.10.1.3';
const _oidX509Cert = '1.2.840.113549.1.9.22.1';
const _oidPbes2 = '1.2.840.113549.1.5.13';
const _oidPbkdf2 = '1.2.840.113549.1.5.12';
const _oidPbeSha3Des = '1.2.840.113549.1.12.1.3';
const _oidPbeSha2Des = '1.2.840.113549.1.12.1.4';
const _oidPbeShaRc2_128 = '1.2.840.113549.1.12.1.5';
const _oidPbeShaRc2_40 = '1.2.840.113549.1.12.1.6';
const _oidSha1 = '1.3.14.3.2.26';
const _oidSha256 = '2.16.840.1.101.3.4.2.1';
const _oidHmacSha1 = '1.2.840.113549.2.7';
const _oidHmacSha256 = '1.2.840.113549.2.9';
const _oidAes128Cbc = '2.16.840.1.101.3.4.1.2';
const _oidAes192Cbc = '2.16.840.1.101.3.4.1.22';
const _oidAes256Cbc = '2.16.840.1.101.3.4.1.42';
const _oidDesEde3Cbc = '1.2.840.113549.3.7';

/// Lê um PKCS#12 com a senha informada.
Pkcs12Conteudo lerPkcs12(Uint8List pfx, String senha) {
  final Asn1Node raiz;
  try {
    raiz = Asn1Reader.parse(pfx);
  } on FormatException catch (e) {
    throw Pkcs12Exception('Arquivo não é um PKCS#12 válido (${e.message})');
  }
  final authSafe = raiz[1];
  if (authSafe[0].oid != _oidData) {
    throw Pkcs12Exception('PKCS#12 com authSafe assinado não é suportado');
  }
  final authSafeBytes = authSafe[1][0].octets;

  if (raiz.children.length > 2) {
    _verificarMac(raiz[2], authSafeBytes, senha);
  }

  final chaves = <Uint8List>[];
  final certs = <Uint8List>[];

  for (final ci in Asn1Reader.parse(authSafeBytes).children) {
    final tipo = ci[0].oid;
    Uint8List safeContents;
    if (tipo == _oidData) {
      safeContents = ci[1][0].octets;
    } else if (tipo == _oidEncryptedData) {
      final encInfo = ci[1][0][1];
      safeContents = _decifrar(encInfo[1], encInfo[2].octets, senha);
    } else {
      continue; // envelopedData etc. não suportados
    }
    for (final bag in Asn1Reader.parse(safeContents).children) {
      final bagId = bag[0].oid;
      final valor = bag[1][0];
      switch (bagId) {
        case _oidKeyBag:
          chaves.add(valor.encoded);
        case _oidShroudedKeyBag:
          chaves.add(_decifrar(valor[0], valor[1].octets, senha));
        case _oidCertBag:
          if (valor[0].oid == _oidX509Cert) certs.add(valor[1][0].octets);
      }
    }
  }

  if (chaves.isEmpty) {
    throw Pkcs12Exception('Nenhuma chave privada encontrada no certificado');
  }
  if (certs.isEmpty) {
    throw Pkcs12Exception('Nenhum certificado encontrado no arquivo');
  }
  return Pkcs12Conteudo(chaves, certs);
}

void _verificarMac(Asn1Node macData, Uint8List authSafe, String senha) {
  final digestInfo = macData[0];
  final algOid = digestInfo[0][0].oid;
  final esperado = digestInfo[1].octets;
  final salt = macData[1].octets;
  final iter = macData.children.length > 2 ? macData[2].intValue : 1;

  final Digest Function() fabrica;
  switch (algOid) {
    case _oidSha1:
      fabrica = SHA1Digest.new;
    case _oidSha256:
      fabrica = SHA256Digest.new;
    default:
      return; // algoritmo de MAC desconhecido: segue sem verificar
  }
  final tamanho = fabrica().digestSize;
  final chave = pkcs12Kdf(fabrica, _senhaBmp(senha), salt, iter, 3, tamanho);
  final hmac = HMac(fabrica(), 64)..init(KeyParameter(chave));
  final calculado = hmac.process(authSafe);
  if (!_iguais(calculado, esperado)) {
    throw Pkcs12Exception('Senha do certificado incorreta');
  }
}

Uint8List _decifrar(Asn1Node algId, Uint8List dados, String senha) {
  final oid = algId[0].oid;
  try {
    switch (oid) {
      case _oidPbes2:
        return _decifrarPbes2(algId[1], dados, senha);
      case _oidPbeSha3Des:
        return _decifrarPkcs12Pbe(algId[1], dados, senha, 24, 8,
            () => DESedeEngine());
      case _oidPbeSha2Des:
        return _decifrarPkcs12Pbe(algId[1], dados, senha, 16, 8,
            () => DESedeEngine());
      case _oidPbeShaRc2_128:
        return _decifrarPkcs12Pbe(algId[1], dados, senha, 16, 8,
            () => RC2Engine());
      case _oidPbeShaRc2_40:
        return _decifrarPkcs12Pbe(algId[1], dados, senha, 5, 8,
            () => RC2Engine());
    }
  } on ArgumentError {
    throw Pkcs12Exception('Senha do certificado incorreta');
  } on StateError {
    throw Pkcs12Exception('Senha do certificado incorreta');
  }
  throw Pkcs12Exception('Algoritmo de cifra não suportado: $oid');
}

Uint8List _decifrarPkcs12Pbe(Asn1Node params, Uint8List dados, String senha,
    int tamChave, int tamIv, BlockCipher Function() engine) {
  final salt = params[0].octets;
  final iter = params[1].intValue;
  final pwd = _senhaBmp(senha);
  final chave = pkcs12Kdf(SHA1Digest.new, pwd, salt, iter, 1, tamChave);
  final iv = pkcs12Kdf(SHA1Digest.new, pwd, salt, iter, 2, tamIv);
  return _cbc(engine(), chave, iv, dados);
}

Uint8List _decifrarPbes2(Asn1Node params, Uint8List dados, String senha) {
  final kdf = params[0];
  final esquema = params[1];
  if (kdf[0].oid != _oidPbkdf2) {
    throw Pkcs12Exception('KDF não suportada: ${kdf[0].oid}');
  }
  final kp = kdf[1];
  final salt = kp[0].octets;
  final iter = kp[1].intValue;
  Digest Function() prf = SHA1Digest.new;
  for (final c in kp.children.skip(2)) {
    if (c.tag == 0x30) {
      final p = c[0].oid;
      if (p == _oidHmacSha256) {
        prf = SHA256Digest.new;
      } else if (p != _oidHmacSha1) {
        throw Pkcs12Exception('PRF não suportada: $p');
      }
    }
  }

  final cifraOid = esquema[0].oid;
  final iv = esquema[1].octets;
  final (int tamChave, BlockCipher Function() engine) = switch (cifraOid) {
    _oidAes128Cbc => (16, AESEngine.new),
    _oidAes192Cbc => (24, AESEngine.new),
    _oidAes256Cbc => (32, AESEngine.new),
    _oidDesEde3Cbc => (24, DESedeEngine.new),
    _ => throw Pkcs12Exception('Cifra não suportada: $cifraOid'),
  };

  final gerador = PBKDF2KeyDerivator(HMac(prf(), 64))
    ..init(Pbkdf2Parameters(salt, iter, tamChave));
  final chave = gerador.process(Uint8List.fromList(utf8.encode(senha)));
  return _cbc(engine(), chave, iv, dados);
}

Uint8List _cbc(BlockCipher engine, Uint8List chave, Uint8List iv, Uint8List dados) {
  final cifra = PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(engine))
    ..init(
      false,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters?>(
          ParametersWithIV(KeyParameter(chave), iv), null),
    );
  return cifra.process(dados);
}

/// Senha em BMPString (UTF-16BE) terminada com 00 00, como exige o PKCS#12.
Uint8List _senhaBmp(String senha) {
  final r = Uint8List(senha.length * 2 + 2);
  for (var i = 0; i < senha.length; i++) {
    final c = senha.codeUnitAt(i);
    r[i * 2] = c >> 8;
    r[i * 2 + 1] = c & 0xFF;
  }
  return r;
}

/// KDF do PKCS#12 (RFC 7292, apêndice B.2).
Uint8List pkcs12Kdf(Digest Function() fabrica, Uint8List senha, Uint8List salt,
    int iteracoes, int id, int n) {
  final d0 = fabrica();
  final u = d0.digestSize;
  const v = 64;

  Uint8List repetir(Uint8List src) {
    if (src.isEmpty) return Uint8List(0);
    final len = v * ((src.length + v - 1) ~/ v);
    final r = Uint8List(len);
    for (var i = 0; i < len; i++) {
      r[i] = src[i % src.length];
    }
    return r;
  }

  final dBytes = Uint8List(v)..fillRange(0, v, id);
  final s = repetir(salt);
  final p = repetir(senha);
  final i = Uint8List(s.length + p.length)
    ..setRange(0, s.length, s)
    ..setRange(s.length, s.length + p.length, p);

  final c = (n + u - 1) ~/ u;
  final saida = Uint8List(c * u);
  for (var k = 0; k < c; k++) {
    var a = Uint8List(u);
    final dg = fabrica()
      ..update(dBytes, 0, v)
      ..update(i, 0, i.length);
    dg.doFinal(a, 0);
    for (var it = 1; it < iteracoes; it++) {
      final dg2 = fabrica()..update(a, 0, u);
      final out = Uint8List(u);
      dg2.doFinal(out, 0);
      a = out;
    }
    saida.setRange(k * u, k * u + u, a);
    if (k == c - 1) break;

    final b = Uint8List(v);
    for (var j = 0; j < v; j++) {
      b[j] = a[j % u];
    }
    for (var j = 0; j < i.length; j += v) {
      var carry = 1;
      for (var x = v - 1; x >= 0; x--) {
        final soma = i[j + x] + b[x] + carry;
        i[j + x] = soma & 0xFF;
        carry = soma >> 8;
      }
    }
  }
  return Uint8List.sublistView(saida, 0, n);
}

bool _iguais(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var r = 0;
  for (var i = 0; i < a.length; i++) {
    r |= a[i] ^ b[i];
  }
  return r == 0;
}
