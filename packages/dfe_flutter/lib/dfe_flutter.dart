/// Transporte TLS mútuo para a SEFAZ com a pilha HTTP nativa de cada plataforma.
///
/// | Plataforma | Pilha |
/// |---|---|
/// | Android | HttpsURLConnection + JSSE (KeyStore PKCS12) |
/// | iOS / macOS | URLSession (identidade via SecPKCS12Import) |
/// | Windows | WinHTTP + SChannel (via `dfe_transporte_ffi`) |
/// | Linux | libcurl + OpenSSL (via `dfe_transporte_ffi`) |
///
/// Todas aceitam a renegociação TLS que as SEFAZ usam para pedir o
/// certificado do cliente — o que o `dart:io` não faz.
library;

import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_transporte_ffi/dfe_transporte_ffi.dart';
import 'package:flutter/services.dart';

/// Cria o transporte nativo da plataforma atual.
TransporteSoap criarTransporteNativo(ConfiguracaoTransporte config) {
  if (Platform.isWindows || Platform.isLinux) return criarTransporteFfi(config);
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return TransporteCanalNativo(config);
  }
  throw UnsupportedError('Plataforma sem transporte nativo: ${Platform.operatingSystem}');
}

/// Transporte via method channel (Android, iOS, macOS).
class TransporteCanalNativo implements TransporteSoap {
  TransporteCanalNativo(this.config);

  static const _canal = MethodChannel('br.com.dfedart/dfe_flutter');

  final ConfiguracaoTransporte config;

  @override
  Future<RespostaHttp> post(
    Uri url, {
    required Map<String, String> cabecalhos,
    required Uint8List corpo,
    required Duration timeout,
  }) async {
    try {
      final r = await _canal.invokeMapMethod<String, Object?>('post', {
        'url': url.toString(),
        'cabecalhos': cabecalhos,
        'corpo': corpo,
        'timeoutMs': timeout.inMilliseconds,
        'pfx': config.certificado.pfx,
        'senha': config.certificado.senha,
        'validarServidor': config.validarCertificadoServidor,
        // Android: chave e cadeia já extraídas (o KeyStore PKCS12 do Android
        // não lê todos os formatos de .pfx, ex.: MAC SHA-256 do OpenSSL 3).
        'chavePkcs8': config.certificado.chavePkcs8,
        'cadeiaDer': [config.certificado.certificadoDer, ...config.certificado.cadeiaDer],
      });
      return RespostaHttp(r!['status']! as int, r['corpo']! as String);
    } on PlatformException catch (e) {
      throw TransporteException(e.message ?? e.code,
          codigo: int.tryParse('${e.details ?? ''}'));
    }
  }

  @override
  void fechar() {}
}
