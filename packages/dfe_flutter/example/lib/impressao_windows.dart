// Envio de bytes ESC/POS em modo RAW pelo spooler do Windows (winspool.drv).
//
// Isto é responsabilidade do APP, não da biblioteca: o PDV pode trocar por
// socket TCP (impressora de rede), serial, SDK do fabricante etc.
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

final _winspool = DynamicLibrary.open('winspool.drv');

final class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

final _openPrinter = _winspool.lookupFunction<
    Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer),
    int Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer)>('OpenPrinterW');
final _closePrinter =
    _winspool.lookupFunction<Int32 Function(IntPtr), int Function(int)>('ClosePrinter');
final _startDoc = _winspool.lookupFunction<Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>),
    int Function(int, int, Pointer<_DocInfo1>)>('StartDocPrinterW');
final _endDoc =
    _winspool.lookupFunction<Int32 Function(IntPtr), int Function(int)>('EndDocPrinter');
final _startPage =
    _winspool.lookupFunction<Int32 Function(IntPtr), int Function(int)>('StartPagePrinter');
final _endPage =
    _winspool.lookupFunction<Int32 Function(IntPtr), int Function(int)>('EndPagePrinter');
final _writePrinter = _winspool.lookupFunction<
    Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>),
    int Function(int, Pointer<Uint8>, int, Pointer<Uint32>)>('WritePrinter');

/// Envia [dados] (ESC/POS) para a impressora [nome] instalada no Windows.
void imprimirRawWindows(String nome, Uint8List dados, {String documento = 'DANFE NFC-e'}) {
  final a = Arena();
  try {
    final h = a<IntPtr>();
    if (_openPrinter(nome.toNativeUtf16(allocator: a), h, nullptr) == 0) {
      throw StateError('Impressora "$nome" não encontrada');
    }
    try {
      final info = a<_DocInfo1>();
      info.ref
        ..pDocName = documento.toNativeUtf16(allocator: a)
        ..pOutputFile = nullptr
        ..pDatatype = 'RAW'.toNativeUtf16(allocator: a);
      if (_startDoc(h.value, 1, info) == 0) throw StateError('Falha ao iniciar o documento');
      try {
        _startPage(h.value);
        final buf = a<Uint8>(dados.length)..asTypedList(dados.length).setAll(0, dados);
        final escritos = a<Uint32>();
        if (_writePrinter(h.value, buf, dados.length, escritos) == 0 ||
            escritos.value != dados.length) {
          throw StateError('Falha ao enviar os dados para a impressora');
        }
        _endPage(h.value);
      } finally {
        _endDoc(h.value);
      }
    } finally {
      _closePrinter(h.value);
    }
  } finally {
    a.releaseAll();
  }
}
