/// Transporte TLS mútuo nativo via FFI.
///
/// - Windows: WinHTTP + SChannel (mesma pilha do .NET usado pelo Zeus).
/// - Linux: libcurl + OpenSSL (requer `libcurl.so.4` instalado).
library;

import 'dart:io';

import 'package:dfe_core/dfe_core.dart';

import 'src/curl.dart';
import 'src/winhttp.dart';

export 'src/curl.dart' show TransporteCurl;
export 'src/winhttp.dart' show TransporteWinHttp;

/// Cria o transporte FFI adequado à plataforma atual (Windows ou Linux).
TransporteSoap criarTransporteFfi(ConfiguracaoTransporte config) {
  if (Platform.isWindows) return TransporteWinHttp(config);
  if (Platform.isLinux) return TransporteCurl(config);
  throw UnsupportedError(
      'dfe_transporte_ffi suporta Windows e Linux. Use dfe_flutter '
      'em Android, iOS e macOS.');
}
