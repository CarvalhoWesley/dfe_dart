import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../asn1/der.dart';
import 'pkcs12.dart';

const _oidRsa = '1.2.840.113549.1.1.1';
const _oidCn = '2.5.4.3';

/// Certificado digital A1 (equivalente ao X509Certificate2 usado no Zeus).
class CertificadoDigital {
  CertificadoDigital._({
    required this.certificadoDer,
    required this.cadeiaDer,
    required this.chavePkcs8,
    required this.chavePrivada,
    required this.chavePublica,
    required this.titular,
    required this.nomeComum,
    required this.validoDe,
    required this.validoAte,
    required this.pfx,
    required this.senha,
  });

  /// Conteúdo original do .pfx, repassado às pilhas TLS nativas.
  final Uint8List pfx;

  /// Senha do .pfx, repassada às pilhas TLS nativas.
  final String senha;

  /// Carrega um certificado A1 a partir do conteúdo de um .pfx/.p12.
  factory CertificadoDigital.dePfx(Uint8List pfx, String senha) {
    final conteudo = lerPkcs12(pfx, senha);

    // Associa a chave ao certificado pelo módulo RSA.
    for (final chaveDer in conteudo.chavesPkcs8) {
      final priv = _lerChavePrivada(chaveDer);
      for (final certDer in conteudo.certificados) {
        final info = _lerX509(certDer);
        if (info.publica.modulus == priv.modulus) {
          final cadeia =
              conteudo.certificados.where((c) => !identical(c, certDer)).toList();
          return CertificadoDigital._(
            certificadoDer: certDer,
            cadeiaDer: cadeia,
            chavePkcs8: chaveDer,
            chavePrivada: priv,
            chavePublica: info.publica,
            titular: info.titular,
            nomeComum: info.nomeComum,
            validoDe: info.validoDe,
            validoAte: info.validoAte,
            pfx: pfx,
            senha: senha,
          );
        }
      }
    }
    throw Pkcs12Exception(
        'Nenhum certificado do arquivo corresponde à chave privada');
  }

  /// Certificado do titular (DER).
  final Uint8List certificadoDer;

  /// Demais certificados da cadeia presentes no arquivo (DER).
  final List<Uint8List> cadeiaDer;

  /// Chave privada em PKCS#8 (DER).
  final Uint8List chavePkcs8;

  final RSAPrivateKey chavePrivada;
  final RSAPublicKey chavePublica;

  /// Subject completo, ex.: `CN=EMPRESA LTDA:12345678000199, OU=..., O=ICP-Brasil, C=BR`.
  final String titular;

  /// CN do titular.
  final String nomeComum;

  final DateTime validoDe;
  final DateTime validoAte;

  /// CNPJ (e-CNPJ) ou CPF (e-CPF) extraído do CN no padrão ICP-Brasil `NOME:DOCUMENTO`.
  String? get documento {
    final m = RegExp(r':(\d{11}|\d{14})$').firstMatch(nomeComum);
    return m?.group(1);
  }

  bool get vencido => DateTime.now().toUtc().isAfter(validoAte);

  String get certificadoBase64 => base64.encode(certificadoDer);

  /// Certificado + cadeia em PEM (para `SecurityContext.useCertificateChainBytes`).
  Uint8List get cadeiaPem => Uint8List.fromList(utf8.encode([
        _pem('CERTIFICATE', certificadoDer),
        for (final c in cadeiaDer) _pem('CERTIFICATE', c),
      ].join()));

  /// Chave privada em PEM PKCS#8 (para `SecurityContext.usePrivateKeyBytes`).
  Uint8List get chavePem =>
      Uint8List.fromList(utf8.encode(_pem('PRIVATE KEY', chavePkcs8)));

  static String _pem(String tipo, Uint8List der) {
    final b64 = base64.encode(der);
    final linhas = StringBuffer('-----BEGIN $tipo-----\n');
    for (var i = 0; i < b64.length; i += 64) {
      linhas.writeln(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    linhas.writeln('-----END $tipo-----');
    return linhas.toString();
  }
}

/// Extrai a chave pública RSA de um certificado X.509 (DER).
RSAPublicKey chavePublicaDoCertificado(Uint8List der) => _lerX509(der).publica;

RSAPrivateKey _lerChavePrivada(Uint8List pkcs8) {
  final pki = Asn1Reader.parse(pkcs8);
  final alg = pki[1][0].oid;
  if (alg != _oidRsa) {
    throw Pkcs12Exception('Somente chaves RSA são suportadas (OID $alg)');
  }
  final rsa = Asn1Reader.parse(pki[2].octets);
  return RSAPrivateKey(
    rsa[1].integer, // n
    rsa[3].integer, // d
    rsa[4].integer, // p
    rsa[5].integer, // q
  );
}

class _X509Info {
  _X509Info(this.publica, this.titular, this.nomeComum, this.validoDe, this.validoAte);
  final RSAPublicKey publica;
  final String titular;
  final String nomeComum;
  final DateTime validoDe;
  final DateTime validoAte;
}

/// Extrai o necessário de um certificado X.509 (DER).
_X509Info _lerX509(Uint8List der) {
  final tbs = Asn1Reader.parse(der)[0];
  var i = 0;
  if (tbs[0].isContextSpecific) i++; // [0] version
  i++; // serialNumber
  i++; // signature
  i++; // issuer
  final validade = tbs[i++];
  final subject = tbs[i++];
  final spki = tbs[i++];

  final bitString = spki[1].content;
  final rsa = Asn1Reader.parse(Uint8List.sublistView(bitString, 1));
  final publica = RSAPublicKey(rsa[0].integer, rsa[1].integer);

  final partes = <String>[];
  var cn = '';
  for (final rdn in subject.children) {
    for (final atv in rdn.children) {
      final oid = atv[0].oid;
      final valor = utf8.decode(atv[1].content, allowMalformed: true);
      partes.add('${_nomeAtributo(oid)}=$valor');
      if (oid == _oidCn) cn = valor;
    }
  }

  return _X509Info(
    publica,
    partes.reversed.join(', '),
    cn,
    _lerTempo(validade[0]),
    _lerTempo(validade[1]),
  );
}

String _nomeAtributo(String oid) => switch (oid) {
      '2.5.4.3' => 'CN',
      '2.5.4.6' => 'C',
      '2.5.4.7' => 'L',
      '2.5.4.8' => 'S',
      '2.5.4.10' => 'O',
      '2.5.4.11' => 'OU',
      _ => 'OID.$oid',
    };

DateTime _lerTempo(Asn1Node n) {
  var s = ascii.decode(n.content).replaceAll('Z', '');
  if (n.tag == 0x17) {
    // UTCTime YYMMDDHHMMSS
    final yy = int.parse(s.substring(0, 2));
    s = '${yy >= 50 ? 19 : 20}$s';
  }
  return DateTime.utc(
    int.parse(s.substring(0, 4)),
    int.parse(s.substring(4, 6)),
    int.parse(s.substring(6, 8)),
    int.parse(s.substring(8, 10)),
    int.parse(s.substring(10, 12)),
    s.length >= 14 ? int.parse(s.substring(12, 14)) : 0,
  );
}
