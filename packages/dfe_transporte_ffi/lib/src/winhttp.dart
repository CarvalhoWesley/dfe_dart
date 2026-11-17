// Transporte WinHTTP + SChannel via FFI (Windows).
//
// SChannel aceita renegociação TLS iniciada pelo servidor, que é como as
// SEFAZ (IIS) pedem o certificado do cliente.
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dfe_core/dfe_core.dart';
import 'package:ffi/ffi.dart';

class TransporteWinHttp implements TransporteSoap {
  TransporteWinHttp(this.config);

  final ConfiguracaoTransporte config;

  @override
  Future<RespostaHttp> post(
    Uri url, {
    required Map<String, String> cabecalhos,
    required Uint8List corpo,
    required Duration timeout,
  }) async {
    final pedido = _Pedido(
      url: url.toString(),
      cabecalhos: cabecalhos,
      corpo: corpo,
      timeoutMs: timeout.inMilliseconds,
      pfx: config.certificado.pfx,
      senha: config.certificado.senha,
      validarServidor: config.validarCertificadoServidor,
    );
    // WinHTTP síncrono é bloqueante: roda em outro isolate para não travar a UI.
    final r = await Isolate.run(() => _executar(pedido));
    return switch (r) {
      (int status, String corpo, null) => RespostaHttp(status, corpo),
      (_, _, (String msg, int cod)) => throw TransporteException(msg, codigo: cod),
    };
  }

  @override
  void fechar() {}
}

class _Pedido {
  _Pedido({
    required this.url,
    required this.cabecalhos,
    required this.corpo,
    required this.timeoutMs,
    required this.pfx,
    required this.senha,
    required this.validarServidor,
  });
  final String url;
  final Map<String, String> cabecalhos;
  final Uint8List corpo;
  final int timeoutMs;
  final Uint8List pfx;
  final String senha;
  final bool validarServidor;
}

// ---------------------------------------------------------------------------
// Bindings

final _crypt32 = DynamicLibrary.open('crypt32.dll');
final _winhttp = DynamicLibrary.open('winhttp.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

final class _CryptDataBlob extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

final _getLastError = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetLastError', isLeaf: true);

final _pfxImportCertStore = _crypt32.lookupFunction<
    Pointer Function(Pointer<_CryptDataBlob>, Pointer<Utf16>, Uint32),
    Pointer Function(Pointer<_CryptDataBlob>, Pointer<Utf16>, int)>(
  'PFXImportCertStore',
  isLeaf: true,
);

final _certEnum = _crypt32.lookupFunction<Pointer Function(Pointer, Pointer),
    Pointer Function(Pointer, Pointer)>('CertEnumCertificatesInStore', isLeaf: true);

final _certDuplicate = _crypt32.lookupFunction<Pointer Function(Pointer),
    Pointer Function(Pointer)>('CertDuplicateCertificateContext', isLeaf: true);

final _certFree = _crypt32.lookupFunction<Int32 Function(Pointer), int Function(Pointer)>(
    'CertFreeCertificateContext', isLeaf: true);

final _certCloseStore = _crypt32.lookupFunction<Int32 Function(Pointer, Uint32),
    int Function(Pointer, int)>('CertCloseStore', isLeaf: true);

final _acquirePrivateKey = _crypt32.lookupFunction<
    Int32 Function(Pointer, Uint32, Pointer, Pointer<IntPtr>, Pointer<Uint32>, Pointer<Int32>),
    int Function(Pointer, int, Pointer, Pointer<IntPtr>, Pointer<Uint32>, Pointer<Int32>)>(
  'CryptAcquireCertificatePrivateKey',
  isLeaf: true,
);

final _open = _winhttp.lookupFunction<
    Pointer Function(Pointer<Utf16>, Uint32, Pointer<Utf16>, Pointer<Utf16>, Uint32),
    Pointer Function(Pointer<Utf16>, int, Pointer<Utf16>, Pointer<Utf16>, int)>(
  'WinHttpOpen',
  isLeaf: true,
);

final _connect = _winhttp.lookupFunction<
    Pointer Function(Pointer, Pointer<Utf16>, Uint16, Uint32),
    Pointer Function(Pointer, Pointer<Utf16>, int, int)>('WinHttpConnect', isLeaf: true);

final _openRequest = _winhttp.lookupFunction<
    Pointer Function(Pointer, Pointer<Utf16>, Pointer<Utf16>, Pointer<Utf16>,
        Pointer<Utf16>, Pointer<Pointer<Utf16>>, Uint32),
    Pointer Function(Pointer, Pointer<Utf16>, Pointer<Utf16>, Pointer<Utf16>,
        Pointer<Utf16>, Pointer<Pointer<Utf16>>, int)>('WinHttpOpenRequest', isLeaf: true);

final _setOption = _winhttp.lookupFunction<
    Int32 Function(Pointer, Uint32, Pointer, Uint32),
    int Function(Pointer, int, Pointer, int)>('WinHttpSetOption', isLeaf: true);

final _setTimeouts = _winhttp.lookupFunction<
    Int32 Function(Pointer, Int32, Int32, Int32, Int32),
    int Function(Pointer, int, int, int, int)>('WinHttpSetTimeouts', isLeaf: true);

final _sendRequest = _winhttp.lookupFunction<
    Int32 Function(Pointer, Pointer<Utf16>, Uint32, Pointer, Uint32, Uint32, IntPtr),
    int Function(Pointer, Pointer<Utf16>, int, Pointer, int, int, int)>(
  'WinHttpSendRequest',
  isLeaf: true,
);

final _receiveResponse = _winhttp.lookupFunction<Int32 Function(Pointer, Pointer),
    int Function(Pointer, Pointer)>('WinHttpReceiveResponse', isLeaf: true);

final _queryHeaders = _winhttp.lookupFunction<
    Int32 Function(Pointer, Uint32, Pointer<Utf16>, Pointer, Pointer<Uint32>, Pointer<Uint32>),
    int Function(Pointer, int, Pointer<Utf16>, Pointer, Pointer<Uint32>, Pointer<Uint32>)>(
  'WinHttpQueryHeaders',
  isLeaf: true,
);

final _queryDataAvailable = _winhttp.lookupFunction<
    Int32 Function(Pointer, Pointer<Uint32>),
    int Function(Pointer, Pointer<Uint32>)>('WinHttpQueryDataAvailable', isLeaf: true);

final _readData = _winhttp.lookupFunction<
    Int32 Function(Pointer, Pointer<Uint8>, Uint32, Pointer<Uint32>),
    int Function(Pointer, Pointer<Uint8>, int, Pointer<Uint32>)>('WinHttpReadData', isLeaf: true);

final _closeHandle = _winhttp.lookupFunction<Int32 Function(Pointer), int Function(Pointer)>(
    'WinHttpCloseHandle', isLeaf: true);

// Constantes
const _pkcs12NoPersistKey = 0x00008000;
const _cryptAcquireCacheFlag = 0x1;
const _cryptAcquireSilentFlag = 0x40;
const _cryptAcquireAllowNcrypt = 0x00010000;
const _accessTypeAutomaticProxy = 4;
const _accessTypeDefaultProxy = 0;
const _flagSecure = 0x00800000;
const _optionClientCertContext = 47;
const _optionSecurityFlags = 31;
const _optionSecureProtocols = 84;
const _protocolTls12 = 0x00000800;
const _protocolTls13 = 0x00002000;
const _ignoreCertErrors = 0x00000100 | 0x00000200 | 0x00001000 | 0x00002000;
const _queryStatusCode = 19 | 0x20000000; // STATUS_CODE | FLAG_NUMBER
const _errorClientAuthCertNeeded = 12044;

// Mensagens dos erros WinHTTP mais comuns.
String _descreverErro(int codigo) => switch (codigo) {
      0 => 'falha de conexão ou de TLS (o Windows não informou o código; '
          'verifique se o certificado é aceito pelo servidor)',
      12002 => 'tempo esgotado',
      12007 => 'nome do servidor não resolvido',
      12029 => 'não foi possível conectar',
      12030 => 'conexão encerrada pelo servidor',
      12044 => 'servidor exige certificado do cliente',
      12175 => 'falha de segurança no TLS (cadeia do servidor ou certificado do cliente recusado)',
      0x80092002 => 'arquivo .pfx inválido',
      0x80070056 => 'senha do certificado incorreta',
      _ => 'erro $codigo',
    };

// ---------------------------------------------------------------------------
// Execução (dentro do isolate)

typedef _Resultado = (int, String, (String, int)?);

_Resultado _falha(String etapa, [int? codigo]) {
  final c = codigo ?? _getLastError();
  return (0, '', ('WinHTTP: $etapa: ${_descreverErro(c)}', c));
}

_Resultado _executar(_Pedido p) {
  final uri = Uri.parse(p.url);
  final arena = Arena();
  Pointer store = nullptr;
  Pointer certCtx = nullptr;
  Pointer sessao = nullptr;
  Pointer conexao = nullptr;
  Pointer req = nullptr;
  try {
    // 1. Importa o PFX em um store temporário, sem persistir a chave em disco.
    final blob = arena<_CryptDataBlob>();
    final dados = arena<Uint8>(p.pfx.length)..asTypedList(p.pfx.length).setAll(0, p.pfx);
    blob.ref
      ..cbData = p.pfx.length
      ..pbData = dados;
    store = _pfxImportCertStore(blob, p.senha.toNativeUtf16(allocator: arena), _pkcs12NoPersistKey);
    if (store == nullptr) return _falha('importação do certificado');

    // 2. Escolhe o certificado que possui chave privada.
    final hKey = arena<IntPtr>();
    final keySpec = arena<Uint32>();
    final liberar = arena<Int32>();
    for (var c = _certEnum(store, nullptr); c != nullptr; c = _certEnum(store, c)) {
      final ok = _acquirePrivateKey(
          c,
          _cryptAcquireCacheFlag | _cryptAcquireSilentFlag | _cryptAcquireAllowNcrypt,
          nullptr,
          hKey,
          keySpec,
          liberar);
      if (ok != 0) {
        certCtx = _certDuplicate(c);
        _certFree(c);
        break;
      }
    }
    if (certCtx == nullptr) {
      return (0, '', ('WinHTTP: nenhum certificado com chave privada no .pfx', 0));
    }

    // 3. Sessão, conexão e requisição.
    final agente = 'dfe_dart/0.1'.toNativeUtf16(allocator: arena);
    sessao = _open(agente, _accessTypeAutomaticProxy, nullptr, nullptr, 0);
    if (sessao == nullptr) {
      sessao = _open(agente, _accessTypeDefaultProxy, nullptr, nullptr, 0);
    }
    if (sessao == nullptr) return _falha('abertura da sessão');

    final protocolos = arena<Uint32>()..value = _protocolTls12 | _protocolTls13;
    if (_setOption(sessao, _optionSecureProtocols, protocolos, 4) == 0) {
      protocolos.value = _protocolTls12; // Windows sem TLS 1.3
      _setOption(sessao, _optionSecureProtocols, protocolos, 4);
    }
    _setTimeouts(sessao, p.timeoutMs, p.timeoutMs, p.timeoutMs, p.timeoutMs);

    conexao = _connect(sessao, uri.host.toNativeUtf16(allocator: arena),
        uri.hasPort ? uri.port : 443, 0);
    if (conexao == nullptr) return _falha('conexão');

    final caminho = (uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path);
    req = _openRequest(
      conexao,
      'POST'.toNativeUtf16(allocator: arena),
      (caminho.isEmpty ? '/' : caminho).toNativeUtf16(allocator: arena),
      nullptr,
      nullptr,
      nullptr,
      _flagSecure,
    );
    if (req == nullptr) return _falha('abertura da requisição');

    if (_setOption(req, _optionClientCertContext, certCtx, sizeOf<IntPtr>() * 5) == 0) {
      return _falha('configuração do certificado do cliente');
    }
    if (!p.validarServidor) {
      final flags = arena<Uint32>()..value = _ignoreCertErrors;
      _setOption(req, _optionSecurityFlags, flags, 4);
    }

    final cab = p.cabecalhos.entries.map((e) => '${e.key}: ${e.value}').join('\r\n');
    final cabNativo = cab.toNativeUtf16(allocator: arena);
    final corpo = arena<Uint8>(p.corpo.length)..asTypedList(p.corpo.length).setAll(0, p.corpo);

    // 4. Envia. Se o servidor pedir o certificado (renegociação), reenvia.
    var enviado = false;
    for (var tentativa = 0; tentativa < 2 && !enviado; tentativa++) {
      final okEnvio = _sendRequest(req, cabNativo, 0xFFFFFFFF, corpo,
          p.corpo.length, p.corpo.length, 0);
      if (okEnvio == 0) {
        final e = _getLastError();
        if (e == _errorClientAuthCertNeeded && tentativa == 0) {
          _setOption(req, _optionClientCertContext, certCtx, sizeOf<IntPtr>() * 5);
          continue;
        }
        return _falha('envio', e);
      }
      if (_receiveResponse(req, nullptr) == 0) {
        final e = _getLastError();
        if (e == _errorClientAuthCertNeeded && tentativa == 0) {
          _setOption(req, _optionClientCertContext, certCtx, sizeOf<IntPtr>() * 5);
          continue;
        }
        return _falha('recebimento', e);
      }
      enviado = true;
    }
    if (!enviado) return _falha('envio', _errorClientAuthCertNeeded);

    // 5. Status e corpo.
    final status = arena<Uint32>();
    final tam = arena<Uint32>()..value = 4;
    _queryHeaders(req, _queryStatusCode, nullptr, status, tam, nullptr);

    final saida = BytesBuilder(copy: false);
    final disp = arena<Uint32>();
    final lidos = arena<Uint32>();
    while (true) {
      if (_queryDataAvailable(req, disp) == 0) return _falha('leitura');
      if (disp.value == 0) break;
      final buf = calloc<Uint8>(disp.value);
      try {
        if (_readData(req, buf, disp.value, lidos) == 0) return _falha('leitura');
        saida.add(Uint8List.fromList(buf.asTypedList(lidos.value)));
      } finally {
        calloc.free(buf);
      }
    }
    return (status.value, utf8.decode(saida.toBytes(), allowMalformed: true), null);
  } finally {
    if (req != nullptr) _closeHandle(req);
    if (conexao != nullptr) _closeHandle(conexao);
    if (sessao != nullptr) _closeHandle(sessao);
    if (certCtx != nullptr) _certFree(certCtx);
    if (store != nullptr) _certCloseStore(store, 0);
    arena.releaseAll();
  }
}
