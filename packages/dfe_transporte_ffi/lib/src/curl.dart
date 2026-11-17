// Transporte libcurl + OpenSSL via FFI (Linux).
//
// O OpenSSL aceita, como cliente, a renegociação segura iniciada pelo servidor.
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dfe_core/dfe_core.dart';
import 'package:ffi/ffi.dart';

class TransporteCurl implements TransporteSoap {
  TransporteCurl(this.config);

  final ConfiguracaoTransporte config;

  @override
  Future<RespostaHttp> post(
    Uri url, {
    required Map<String, String> cabecalhos,
    required Uint8List corpo,
    required Duration timeout,
  }) async {
    final args = (
      url.toString(),
      cabecalhos,
      corpo,
      timeout.inMilliseconds,
      config.certificado.pfx,
      config.certificado.senha,
      config.validarCertificadoServidor,
    );
    final r = await Isolate.run(() => _executar(args));
    return switch (r) {
      (int status, String corpo, null) => RespostaHttp(status, corpo),
      (_, _, (String msg, int cod)) => throw TransporteException(msg, codigo: cod),
    };
  }

  @override
  void fechar() {}
}

// ---------------------------------------------------------------------------
// Bindings

DynamicLibrary _abrirCurl() {
  for (final nome in ['libcurl.so.4', 'libcurl.so', 'libcurl-gnutls.so.4']) {
    try {
      return DynamicLibrary.open(nome);
    } on ArgumentError {
      continue;
    }
  }
  throw TransporteException('libcurl não encontrada (instale libcurl4)');
}

final _curl = _abrirCurl();

final _init = _curl.lookupFunction<Pointer Function(), Pointer Function()>('curl_easy_init');
final _cleanup = _curl.lookupFunction<Void Function(Pointer), void Function(Pointer)>('curl_easy_cleanup');
final _perform = _curl.lookupFunction<Int32 Function(Pointer), int Function(Pointer)>('curl_easy_perform');
final _strerror = _curl.lookupFunction<Pointer<Utf8> Function(Int32), Pointer<Utf8> Function(int)>('curl_easy_strerror');

final _setoptPtr = _curl.lookupFunction<
    Int32 Function(Pointer, Int32, VarArgs<(Pointer,)>),
    int Function(Pointer, int, Pointer)>('curl_easy_setopt');
final _setoptLong = _curl.lookupFunction<
    Int32 Function(Pointer, Int32, VarArgs<(Long,)>),
    int Function(Pointer, int, int)>('curl_easy_setopt');
final _setoptOff = _curl.lookupFunction<
    Int32 Function(Pointer, Int32, VarArgs<(Int64,)>),
    int Function(Pointer, int, int)>('curl_easy_setopt');
final _getinfoLong = _curl.lookupFunction<
    Int32 Function(Pointer, Int32, VarArgs<(Pointer<Long>,)>),
    int Function(Pointer, int, Pointer<Long>)>('curl_easy_getinfo');

final _slistAppend = _curl.lookupFunction<Pointer Function(Pointer, Pointer<Utf8>),
    Pointer Function(Pointer, Pointer<Utf8>)>('curl_slist_append');
final _slistFree = _curl.lookupFunction<Void Function(Pointer), void Function(Pointer)>('curl_slist_free_all');

final class _CurlBlob extends Struct {
  external Pointer<Uint8> data;
  @Size()
  external int len;
  @Uint32()
  external int flags;
}

const _optUrl = 10002;
const _optPost = 47;
const _optPostFields = 10015;
const _optPostFieldSizeLarge = 30120;
const _optHttpHeader = 10023;
const _optSslCertBlob = 40291;
const _optSslCertType = 10086;
const _optKeyPasswd = 10026;
const _optTimeoutMs = 155;
const _optConnectTimeoutMs = 156;
const _optSslVerifyPeer = 64;
const _optSslVerifyHost = 81;
const _optWriteFunction = 20011;
const _optNoSignal = 99;
const _infoResponseCode = 0x200002;

// Buffer da resposta (o callback roda de forma síncrona no próprio isolate).
BytesBuilder? _buffer;

int _escrever(Pointer<Uint8> ptr, int size, int nmemb, Pointer userdata) {
  final n = size * nmemb;
  _buffer?.add(Uint8List.fromList(ptr.asTypedList(n)));
  return n;
}

typedef _Args = (String, Map<String, String>, Uint8List, int, Uint8List, String, bool);
typedef _Resultado = (int, String, (String, int)?);

_Resultado _executar(_Args a) {
  final (url, cabecalhos, corpo, timeoutMs, pfx, senha, validar) = a;
  final arena = Arena();
  final h = _init();
  Pointer headers = nullptr;
  if (h == nullptr) return (0, '', ('libcurl: falha ao iniciar', 0));
  try {
    _buffer = BytesBuilder(copy: false);
    final callback = Pointer.fromFunction<
        Size Function(Pointer<Uint8>, Size, Size, Pointer)>(_escrever, 0);

    _setoptPtr(h, _optUrl, url.toNativeUtf8(allocator: arena));
    _setoptLong(h, _optNoSignal, 1);
    _setoptLong(h, _optPost, 1);
    final corpoNativo = arena<Uint8>(corpo.length)..asTypedList(corpo.length).setAll(0, corpo);
    _setoptOff(h, _optPostFieldSizeLarge, corpo.length);
    _setoptPtr(h, _optPostFields, corpoNativo);

    for (final e in cabecalhos.entries) {
      headers = _slistAppend(headers, '${e.key}: ${e.value}'.toNativeUtf8(allocator: arena));
    }
    headers = _slistAppend(headers, 'Expect:'.toNativeUtf8(allocator: arena));
    _setoptPtr(h, _optHttpHeader, headers);

    final blob = arena<_CurlBlob>();
    final pfxNativo = arena<Uint8>(pfx.length)..asTypedList(pfx.length).setAll(0, pfx);
    blob.ref
      ..data = pfxNativo
      ..len = pfx.length
      ..flags = 1; // CURL_BLOB_COPY
    _setoptPtr(h, _optSslCertBlob, blob);
    _setoptPtr(h, _optSslCertType, 'P12'.toNativeUtf8(allocator: arena));
    _setoptPtr(h, _optKeyPasswd, senha.toNativeUtf8(allocator: arena));

    _setoptLong(h, _optTimeoutMs, timeoutMs);
    _setoptLong(h, _optConnectTimeoutMs, timeoutMs);
    _setoptLong(h, _optSslVerifyPeer, validar ? 1 : 0);
    _setoptLong(h, _optSslVerifyHost, validar ? 2 : 0);
    _setoptPtr(h, _optWriteFunction, callback);

    final rc = _perform(h);
    if (rc != 0) {
      return (0, '', ('libcurl: ${_strerror(rc).toDartString()}', rc));
    }
    final status = arena<Long>();
    _getinfoLong(h, _infoResponseCode, status);
    return (status.value, utf8.decode(_buffer!.toBytes(), allowMalformed: true), null);
  } finally {
    _buffer = null;
    if (headers != nullptr) _slistFree(headers);
    _cleanup(h);
    arena.releaseAll();
  }
}
