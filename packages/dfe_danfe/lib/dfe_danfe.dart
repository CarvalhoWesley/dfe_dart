/// DANFE NFC-e a partir do `procNFe`: layout único com saídas em texto, PDF e
/// bytes ESC/POS. O envio para a impressora é responsabilidade do app.
///
/// A imagem (PNG) é gerada no pacote `dfe_flutter`, rasterizando o PDF.
library;

import 'dart:typed_data';

import 'src/dados_danfe.dart';
import 'src/layout.dart';
import 'src/saida_escpos.dart';
import 'src/saida_pdf.dart';
import 'src/saida_texto.dart';

export 'src/dados_danfe.dart';
export 'src/layout.dart'
    show Alinhamento, ElementoDanfe, LinhaDanfe, SeparadorDanfe, QrCodeDanfe, OpcoesDanfe;
export 'src/saida_escpos.dart' show OpcoesEscPos, PaginaCodigo, ModoQrCode, Corte;
export 'src/saida_pdf.dart' show OpcoesPdf;

/// DANFE NFC-e.
///
/// ```dart
/// final danfe = DanfeNfce.deXml(procNFeXml);
/// final texto = danfe.texto();
/// final pdf = await danfe.pdf();
/// final escpos = danfe.escPos(const OpcoesEscPos(modoQrCode: ModoQrCode.imagem));
/// ```
class DanfeNfce {
  DanfeNfce(this.dados, {this.opcoes = OpcoesDanfe.papel80mm});

  /// Aceita o `nfeProc` autorizado ou o `<NFe>` assinado (contingência offline).
  factory DanfeNfce.deXml(String xml, {OpcoesDanfe opcoes = OpcoesDanfe.papel80mm}) =>
      DanfeNfce(DadosDanfeNfce.deXml(xml), opcoes: opcoes);

  final DadosDanfeNfce dados;
  final OpcoesDanfe opcoes;

  /// Layout independente de formato (para renderizações próprias do app).
  List<ElementoDanfe> get layout => montarLayoutNfce(dados, opcoes);

  /// Conteúdo do QR Code, para o app desenhar com recurso próprio.
  String get qrCode => dados.qrCode;

  /// Texto puro em [OpcoesDanfe.colunas] colunas.
  String texto({bool incluirQrCode = true}) =>
      renderizarTexto(layout, opcoes.colunas, incluirQrCode: incluirQrCode);

  /// Bytes ESC/POS prontos para enviar à impressora térmica.
  Uint8List escPos([OpcoesEscPos escPos = const OpcoesEscPos()]) {
    final l = escPos.paginaCodigo == PaginaCodigo.semAcento
        ? montarLayoutNfce(dados, OpcoesDanfe(
            colunas: opcoes.colunas,
            itemEmDuasLinhas: opcoes.itemEmDuasLinhas,
            removerAcentos: true))
        : layout;
    return renderizarEscPos(l, opcoes.colunas, escPos);
  }

  /// PDF em bobina (altura ajustada ao conteúdo).
  Future<Uint8List> pdf([OpcoesPdf pdf = const OpcoesPdf()]) =>
      renderizarPdf(layout, opcoes.colunas, pdf);
}
