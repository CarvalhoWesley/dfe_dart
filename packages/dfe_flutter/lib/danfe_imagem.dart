/// Imagem (PNG) do DANFE NFC-e, rasterizando o mesmo PDF do `dfe_danfe`.
library;

import 'dart:typed_data';

import 'package:dfe_danfe/dfe_danfe.dart';
import 'package:printing/printing.dart';

export 'package:dfe_danfe/dfe_danfe.dart';

extension DanfeNfceImagem on DanfeNfce {
  /// PNG do DANFE.
  ///
  /// [dpi] 203 corresponde à resolução da maioria das impressoras térmicas
  /// (8 pontos/mm): em 80 mm a imagem sai com ~640 px de largura.
  Future<Uint8List> imagemPng({double dpi = 203, OpcoesPdf pdf = const OpcoesPdf()}) async {
    final bytes = await this.pdf(pdf);
    final pagina = await Printing.raster(bytes, dpi: dpi).first;
    return pagina.toPng();
  }
}

extension DanfeNfeImagem on DanfeNfe {
  /// Um PNG por folha do DANFE NF-e (A4). 150 dpi gera ~1240 × 1754 px por folha.
  Future<List<Uint8List>> imagensPng({double dpi = 150, OpcoesDanfeNfe opcoes = const OpcoesDanfeNfe()}) async {
    final bytes = await pdf(opcoes);
    return [await for (final p in Printing.raster(bytes, dpi: dpi)) await p.toPng()];
  }
}
