import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'layout.dart';
import 'saida_texto.dart';

/// Opções do PDF (bobina com altura ajustada ao conteúdo).
class OpcoesPdf {
  const OpcoesPdf({this.larguraMm = 80, this.margemMm = 3, this.ladoQrMm = 35});

  final double larguraMm;
  final double margemMm;
  final double ladoQrMm;
}

/// Gera o PDF do layout em fonte monoespaçada (mesma diagramação do texto e do ESC/POS).
Future<Uint8List> renderizarPdf(List<ElementoDanfe> layout, int colunas, OpcoesPdf o) async {
  final regular = pw.Font.courier();
  final negrito = pw.Font.courierBold();

  // Courier: largura do caractere = 0,6 × tamanho da fonte.
  final larguraUtil = (o.larguraMm - 2 * o.margemMm) * PdfPageFormat.mm;
  final tamanho = larguraUtil / (colunas * 0.6);

  pw.Widget linha(String s, {bool b = false, bool expandido = false}) => pw.Text(
        s,
        style: pw.TextStyle(
          font: b ? negrito : regular,
          fontSize: expandido ? tamanho * 2 : tamanho,
          lineSpacing: 0,
        ),
      );

  final filhos = <pw.Widget>[];
  for (final e in layout) {
    switch (e) {
      case LinhaDanfe():
        final largura = e.expandido ? colunas ~/ 2 : colunas;
        filhos.add(linha(alinhar(e.texto, largura, e.alinhamento),
            b: e.negrito, expandido: e.expandido));
      case SeparadorDanfe():
        filhos.add(linha('-' * colunas));
      case QrCodeDanfe():
        filhos.add(pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: e.conteudo,
              width: o.ladoQrMm * PdfPageFormat.mm,
              height: o.ladoQrMm * PdfPageFormat.mm,
            ),
          ),
        ));
    }
  }

  final doc = pw.Document(title: 'DANFE NFC-e', creator: 'dfe_dart');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(o.larguraMm * PdfPageFormat.mm, double.infinity,
        marginAll: o.margemMm * PdfPageFormat.mm),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: filhos),
  ));
  return doc.save();
}
