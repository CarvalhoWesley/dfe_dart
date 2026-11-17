import 'package:xml/xml.dart';

import '../enums.dart';
import '../status/cons_stat_serv.dart' show nsNfe;

String _semDeclaracao(String xml) =>
    xml.replaceFirst(RegExp(r'^\s*<\?xml[^>]*\?>\s*'), '');

/// `enviNFe` 4.00 com um ou mais `<NFe>` assinados.
String montarEnviNfe(List<String> nfes, {required int idLote, bool sincrono = true}) {
  final b = StringBuffer('<enviNFe xmlns="$nsNfe" versao="4.00">')
    ..write('<idLote>$idLote</idLote>')
    ..write('<indSinc>${sincrono ? 1 : 0}</indSinc>');
  for (final n in nfes) {
    b.write(_semDeclaracao(n));
  }
  b.write('</enviNFe>');
  return b.toString();
}

/// `consReciNFe` 4.00.
String montarConsReciNfe(String recibo, Ambiente ambiente) =>
    '<consReciNFe xmlns="$nsNfe" versao="4.00">'
    '<tpAmb>${ambiente.codigo}</tpAmb><nRec>$recibo</nRec></consReciNFe>';

/// Protocolo de autorização (`protNFe`).
class ProtNfe {
  ProtNfe._(this.xml, this.chave, this.cStat, this.xMotivo, this.nProt, this.dhRecbto);

  factory ProtNfe.deElemento(XmlElement prot) {
    final inf = prot.getElement('infProt')!;
    String? t(String n) => inf.getElement(n)?.innerText;
    return ProtNfe._(
      prot.toXmlString(),
      t('chNFe') ?? '',
      int.parse(t('cStat')!),
      t('xMotivo') ?? '',
      t('nProt'),
      t('dhRecbto'),
    );
  }

  final String xml;
  final String chave;
  final int cStat;
  final String xMotivo;
  final String? nProt;
  final String? dhRecbto;

  /// 100 = autorizado; 150 = autorizado fora de prazo.
  bool get autorizado => cStat == 100 || cStat == 150;

  /// 110, 301, 302, 303 = uso denegado.
  bool get denegado => const {110, 301, 302, 303}.contains(cStat);
}

/// Retorno de `retEnviNFe` ou `retConsReciNFe`.
class RetornoLote {
  RetornoLote._(this.cStat, this.xMotivo, this.recibo, this.tMed, this.protocolos);

  factory RetornoLote.fromXml(String xml) {
    final raiz = XmlDocument.parse(xml).rootElement;
    String? t(String n) => raiz.getElement(n)?.innerText;
    return RetornoLote._(
      int.parse(t('cStat')!),
      t('xMotivo') ?? '',
      raiz.getElement('infRec')?.getElement('nRec')?.innerText ?? t('nRec'),
      int.tryParse(raiz.getElement('infRec')?.getElement('tMed')?.innerText ?? '') ??
          int.tryParse(t('tMed') ?? ''),
      raiz.findElements('protNFe').map(ProtNfe.deElemento).toList(),
    );
  }

  final int cStat;
  final String xMotivo;
  final String? recibo;
  final int? tMed;
  final List<ProtNfe> protocolos;

  /// 103 = lote recebido (assíncrono); 105 = em processamento.
  bool get pendente => cStat == 103 || cStat == 105;
}

/// Monta o `nfeProc` (NF-e + protocolo) — o XML que deve ser guardado.
String montarNfeProc(String nfeAssinada, ProtNfe prot) {
  final nfe = XmlDocument.parse(_semDeclaracao(nfeAssinada)).rootElement.copy();
  final protEl = XmlDocument.parse(prot.xml).rootElement.copy();
  final doc = XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?>'
      '<nfeProc xmlns="$nsNfe" versao="4.00"></nfeProc>');
  doc.rootElement.children
    ..add(nfe)
    ..add(protEl);
  return doc.toXmlString();
}
