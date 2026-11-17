import 'dart:convert';
import 'dart:typed_data';

import 'package:qr/qr.dart';

import 'layout.dart';

/// Página de código usada para os acentos.
enum PaginaCodigo {
  /// CP860 (português) — `ESC t 3`.
  cp860(3),

  /// CP850 (multilíngue) — `ESC t 2`.
  cp850(2),

  /// Remove os acentos (funciona em qualquer impressora).
  semAcento(0);

  const PaginaCodigo(this.comando);
  final int comando;
}

/// Como o QR Code é enviado à impressora.
enum ModoQrCode {
  /// Comando nativo `GS ( k` (Epson, Elgin, Bematech e a maioria das atuais).
  nativo,

  /// Imagem raster `GS v 0` (para impressoras sem o comando nativo).
  imagem,
}

enum Corte { total, parcial, nenhum }

/// Opções da geração ESC/POS. O envio dos bytes à impressora é do app.
class OpcoesEscPos {
  const OpcoesEscPos({
    this.paginaCodigo = PaginaCodigo.cp860,
    this.modoQrCode = ModoQrCode.nativo,
    this.tamanhoModuloQr = 4,
    this.corte = Corte.parcial,
    this.linhasAntesDoCorte = 3,
    this.abrirGaveta = false,
  });

  final PaginaCodigo paginaCodigo;
  final ModoQrCode modoQrCode;

  /// Tamanho do módulo do QR Code (1–16; 4 a 6 costuma ficar bom em 80 mm).
  final int tamanhoModuloQr;
  final Corte corte;
  final int linhasAntesDoCorte;
  final bool abrirGaveta;
}

const _esc = 0x1B;
const _gs = 0x1D;
const _lf = 0x0A;

/// Gera os bytes ESC/POS do layout.
Uint8List renderizarEscPos(List<ElementoDanfe> layout, int colunas, OpcoesEscPos o) {
  final b = BytesBuilder();
  b.add([_esc, 0x40]); // ESC @ — inicializa
  if (o.paginaCodigo != PaginaCodigo.semAcento) {
    b.add([_esc, 0x74, o.paginaCodigo.comando]); // ESC t n
  }

  var alinhamentoAtual = -1;
  void alinhar(Alinhamento a) {
    final n = switch (a) {
      Alinhamento.esquerda => 0,
      Alinhamento.centro => 1,
      Alinhamento.direita => 2,
    };
    if (n != alinhamentoAtual) {
      b.add([_esc, 0x61, n]); // ESC a n
      alinhamentoAtual = n;
    }
  }

  for (final e in layout) {
    switch (e) {
      case LinhaDanfe():
        alinhar(e.alinhamento);
        if (e.negrito) b.add([_esc, 0x45, 1]); // ESC E 1
        if (e.expandido) b.add([_gs, 0x21, 0x11]); // GS ! — largura e altura duplas
        b.add(codificar(e.texto, o.paginaCodigo));
        if (e.expandido) b.add([_gs, 0x21, 0x00]);
        if (e.negrito) b.add([_esc, 0x45, 0]);
        b.addByte(_lf);
      case SeparadorDanfe():
        alinhar(Alinhamento.esquerda);
        b.add(ascii.encode('-' * colunas));
        b.addByte(_lf);
      case QrCodeDanfe():
        alinhar(Alinhamento.centro);
        b.add(o.modoQrCode == ModoQrCode.nativo
            ? _qrNativo(e.conteudo, o.tamanhoModuloQr)
            : _qrImagem(e.conteudo, o.tamanhoModuloQr));
        b.addByte(_lf);
    }
  }

  alinhar(Alinhamento.esquerda);
  for (var i = 0; i < o.linhasAntesDoCorte; i++) {
    b.addByte(_lf);
  }
  switch (o.corte) {
    case Corte.total:
      b.add([_gs, 0x56, 0x00]); // GS V 0
    case Corte.parcial:
      b.add([_gs, 0x56, 0x01]); // GS V 1
    case Corte.nenhum:
      break;
  }
  if (o.abrirGaveta) b.add([_esc, 0x70, 0x00, 0x19, 0xFA]); // ESC p 0 25 250
  return b.toBytes();
}

List<int> _qrNativo(String dados, int modulo) {
  final d = utf8.encode(dados);
  final len = d.length + 3;
  return [
    _gs, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00, // modelo 2
    _gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, modulo.clamp(1, 16), // tamanho do módulo
    _gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31, // correção de erro M
    _gs, 0x28, 0x6B, len & 0xFF, len >> 8, 0x31, 0x50, 0x30, ...d, // armazena
    _gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30, // imprime
  ];
}

List<int> _qrImagem(String dados, int modulo) {
  final qr = QrImage(QrCode.fromData(data: dados, errorCorrectLevel: QrErrorCorrectLevel.M));
  final m = modulo.clamp(1, 16);
  const margem = 2; // módulos de zona de silêncio
  final lado = (qr.moduleCount + margem * 2) * m;
  final larguraBytes = (lado + 7) ~/ 8;
  final img = Uint8List(larguraBytes * lado);
  for (var y = 0; y < lado; y++) {
    final my = y ~/ m - margem;
    for (var x = 0; x < lado; x++) {
      final mx = x ~/ m - margem;
      final escuro =
          mx >= 0 && my >= 0 && mx < qr.moduleCount && my < qr.moduleCount && qr.isDark(my, mx);
      if (escuro) img[y * larguraBytes + x ~/ 8] |= 0x80 >> (x % 8);
    }
  }
  return [
    _gs, 0x76, 0x30, 0x00, // GS v 0, modo normal
    larguraBytes & 0xFF, larguraBytes >> 8, lado & 0xFF, lado >> 8,
    ...img,
  ];
}

// --- Codificação --------------------------------------------------------------

const _cp860 = {
  'Ç': 0x80, 'ü': 0x81, 'é': 0x82, 'â': 0x83, 'ã': 0x84, 'à': 0x85, 'Á': 0x86, 'ç': 0x87,
  'ê': 0x88, 'Ê': 0x89, 'è': 0x8A, 'Í': 0x8B, 'Ô': 0x8C, 'ì': 0x8D, 'Ã': 0x8E, 'Â': 0x8F,
  'É': 0x90, 'À': 0x91, 'È': 0x92, 'ô': 0x93, 'õ': 0x94, 'ò': 0x95, 'Ú': 0x96, 'ù': 0x97,
  'Ì': 0x98, 'Õ': 0x99, 'Ü': 0x9A, 'Ù': 0x9D, 'Ó': 0x9F, 'á': 0xA0, 'í': 0xA1, 'ó': 0xA2,
  'ú': 0xA3, 'ñ': 0xA4, 'Ñ': 0xA5, 'ª': 0xA6, 'º': 0xA7, 'Ò': 0xA9,
};

const _cp850 = {
  'Ç': 0x80, 'ü': 0x81, 'é': 0x82, 'â': 0x83, 'ä': 0x84, 'à': 0x85, 'ç': 0x87, 'ê': 0x88,
  'ë': 0x89, 'è': 0x8A, 'ï': 0x8B, 'î': 0x8C, 'ì': 0x8D, 'Ä': 0x8E, 'É': 0x90, 'ô': 0x93,
  'ö': 0x94, 'ò': 0x95, 'û': 0x96, 'ù': 0x97, 'Ö': 0x99, 'Ü': 0x9A, 'á': 0xA0, 'í': 0xA1,
  'ó': 0xA2, 'ú': 0xA3, 'ñ': 0xA4, 'Ñ': 0xA5, 'ª': 0xA6, 'º': 0xA7, 'Á': 0xB5, 'Â': 0xB6,
  'À': 0xB7, 'ã': 0xC6, 'Ã': 0xC7, 'Ê': 0xD2, 'Ë': 0xD3, 'È': 0xD4, 'Í': 0xD6, 'Î': 0xD7,
  'Ï': 0xD8, 'Ì': 0xDE, 'Ó': 0xE0, 'Ô': 0xE2, 'Ò': 0xE3, 'õ': 0xE4, 'Õ': 0xE5, 'Ú': 0xE9,
  'Û': 0xEA, 'Ù': 0xEB,
};

/// Converte o texto para a página de código; caracteres sem equivalente
/// perdem o acento (ou viram `?`).
List<int> codificar(String s, PaginaCodigo p) {
  final tabela = switch (p) {
    PaginaCodigo.cp860 => _cp860,
    PaginaCodigo.cp850 => _cp850,
    PaginaCodigo.semAcento => const <String, int>{},
  };
  final r = <int>[];
  for (final c in s.split('')) {
    final u = c.codeUnitAt(0);
    if (u < 0x80) {
      r.add(u);
    } else if (tabela[c] != null) {
      r.add(tabela[c]!);
    } else {
      final semAcento = removerAcentos(c);
      final u2 = semAcento.codeUnitAt(0);
      r.add(u2 < 0x80 ? u2 : 0x3F);
    }
  }
  return r;
}
