import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../certificado/certificado_digital.dart';

/// Resposta HTTP bruta devolvida por um [TransporteSoap].
class RespostaHttp {
  const RespostaHttp(this.status, this.corpo);
  final int status;
  final String corpo;
}

/// Falha de transporte (conexão, TLS, timeout). Os transportes lançam esta
/// exceção; o `SoapClient` a converte em `ComunicacaoException`.
class TransporteException implements Exception {
  TransporteException(this.message, {this.codigo});
  final String message;

  /// Código nativo do erro (ex.: código WinHTTP, CURLcode), se houver.
  final int? codigo;

  @override
  String toString() =>
      'TransporteException: $message${codigo != null ? ' (código $codigo)' : ''}';
}

/// Camada HTTP com TLS mútuo usada pelo `SoapClient`.
///
/// O `dart:io` não aceita renegociação TLS, que é como as SEFAZ pedem o
/// certificado do cliente. Use um transporte nativo (pacotes
/// `dfe_transporte_ffi` / `dfe_flutter`) para falar com a SEFAZ.
abstract interface class TransporteSoap {
  Future<RespostaHttp> post(
    Uri url, {
    required Map<String, String> cabecalhos,
    required Uint8List corpo,
    required Duration timeout,
  });

  void fechar();
}

/// Configuração comum aos transportes.
class ConfiguracaoTransporte {
  const ConfiguracaoTransporte({
    required this.certificado,
    this.validarCertificadoServidor = true,
  });

  final CertificadoDigital certificado;

  /// Equivale a `ValidarCertificadoDoServidor` do Zeus.
  final bool validarCertificadoServidor;
}

/// Transporte com `dart:io`. Só funciona com servidores que pedem o
/// certificado no handshake inicial (não é o caso das SEFAZ testadas).
class TransporteDartIo implements TransporteSoap {
  TransporteDartIo(this.config);

  final ConfiguracaoTransporte config;
  HttpClient? _http;

  HttpClient _cliente(Duration timeout) {
    final existente = _http;
    if (existente != null) return existente;
    final ctx = SecurityContext(withTrustedRoots: true)
      ..useCertificateChainBytes(config.certificado.cadeiaPem)
      ..usePrivateKeyBytes(config.certificado.chavePem);
    final c = HttpClient(context: ctx)..connectionTimeout = timeout;
    if (!config.validarCertificadoServidor) {
      c.badCertificateCallback = (_, __, ___) => true;
    }
    return _http = c;
  }

  @override
  Future<RespostaHttp> post(
    Uri url, {
    required Map<String, String> cabecalhos,
    required Uint8List corpo,
    required Duration timeout,
  }) async {
    try {
      final req = await _cliente(timeout).postUrl(url).timeout(timeout);
      cabecalhos.forEach(req.headers.set);
      req.add(corpo);
      final resp = await req.close().timeout(timeout);
      final texto = await resp.transform(utf8.decoder).join().timeout(timeout);
      return RespostaHttp(resp.statusCode, texto);
    } on TimeoutException {
      throw TransporteException('Tempo esgotado ao comunicar com $url');
    } on SocketException catch (e) {
      throw TransporteException('Falha de conexão com $url: ${e.message}');
    } on HandshakeException catch (e) {
      throw TransporteException('Falha no TLS com $url: ${e.message}');
    } on HttpException catch (e) {
      if (e.message.contains('NO_RENEGOTIATION')) {
        throw TransporteException(
            'O servidor $url pediu renegociação TLS para solicitar o certificado '
            'do cliente, e o BoringSSL do dart:io não permite renegociação. '
            'Use um transporte nativo.');
      }
      throw TransporteException('Erro HTTP com $url: ${e.message}');
    }
  }

  @override
  void fechar() {
    _http?.close(force: true);
    _http = null;
  }
}
