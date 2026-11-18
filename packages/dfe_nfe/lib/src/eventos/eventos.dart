import 'package:dfe_core/dfe_core.dart';
import 'package:xml/xml.dart';

import '../autorizacao/autorizacao.dart';
import '../enums.dart';
import '../status/cons_stat_serv.dart' show nsNfe;
import '../util/formatacao.dart';

String _semDeclaracao(String xml) => xml.replaceFirst(RegExp(r'^\s*<\?xml[^>]*\?>\s*'), '');
String _t(String tag, String valor) => '<$tag>${escaparXml(valor)}</$tag>';

void _validarJustificativa(String j) {
  if (j.trim().length < 15 || j.length > 255) {
    throw ArgumentError('Justificativa deve ter de 15 a 255 caracteres');
  }
}

// ---------------------------------------------------------------------------
// Consulta de protocolo

/// `consSitNFe` 4.00.
String montarConsSitNfe(String chave, Ambiente ambiente) =>
    '<consSitNFe xmlns="$nsNfe" versao="4.00">'
    '${_t('tpAmb', '${ambiente.codigo}')}${_t('xServ', 'CONSULTAR')}${_t('chNFe', chave)}'
    '</consSitNFe>';

/// Retorno de `retConsSitNFe`.
class RetConsSitNfe {
  RetConsSitNfe._(this.cStat, this.xMotivo, this.chave, this.protocolo, this.eventos);

  factory RetConsSitNfe.fromXml(String xml) {
    final raiz = XmlDocument.parse(xml).rootElement;
    final prot = raiz.getElement('protNFe');
    return RetConsSitNfe._(
      int.parse(raiz.getElement('cStat')!.innerText),
      raiz.getElement('xMotivo')?.innerText ?? '',
      raiz.getElement('chNFe')?.innerText ?? '',
      prot == null ? null : ProtNfe.deElemento(prot),
      raiz.findElements('procEventoNFe').map((e) => e.toXmlString()).toList(),
    );
  }

  /// 100 autorizada, 101 cancelada, 110/301/302 denegada, 217 não consta.
  final int cStat;
  final String xMotivo;
  final String chave;
  final ProtNfe? protocolo;

  /// `procEventoNFe` vinculados (cancelamento, CC-e...).
  final List<String> eventos;

  bool get autorizada => cStat == 100 || cStat == 150;
  bool get cancelada => cStat == 101 || cStat == 151 || cStat == 155;
  bool get naoConsta => cStat == 217;
}

// ---------------------------------------------------------------------------
// Eventos (cancelamento e carta de correção)

/// Evento da NF-e (cancelamento 110111, CC-e 110110), já assinado.
class EventoNfe {
  EventoNfe._(this.xml, this.id, this.chave, this.tipo, this.sequencia);
  final String xml;
  final String id;
  final String chave;
  final String tipo;
  final int sequencia;
}

/// Monta e assina o `<evento>` de cancelamento.
EventoNfe montarEventoCancelamento({
  required String chave,
  required String protocolo,
  required String justificativa,
  required String cnpj,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  int sequencia = 1,
  DateTime? dataEvento,
}) {
  _validarJustificativa(justificativa);
  return _montarEvento(
    tipo: '110111',
    detalhe: '${_t('descEvento', 'Cancelamento')}${_t('nProt', protocolo)}${_t('xJust', justificativa)}',
    chave: chave,
    cnpj: cnpj,
    ambiente: ambiente,
    certificado: certificado,
    sequencia: sequencia,
    dataEvento: dataEvento,
  );
}

/// Texto legal obrigatório da CC-e (versão sem acentos, aceita por todas as UFs;
/// a SEFAZ-MT exige esta forma).
const condicaoUsoCartaCorrecao =
    'A Carta de Correcao e disciplinada pelo paragrafo 1o-A do art. 7o do Convenio S/N, de 15 de '
    'dezembro de 1970 e pode ser utilizada para regularizacao de erro ocorrido na emissao de documento '
    'fiscal, desde que o erro nao esteja relacionado com: I - as variaveis que determinam o valor do '
    'imposto tais como: base de calculo, aliquota, diferenca de preco, quantidade, valor da operacao ou '
    'da prestacao; II - a correcao de dados cadastrais que implique mudanca do remetente ou do '
    'destinatario; III - a data de emissao ou de saida.';

/// Monta e assina a Carta de Correção Eletrônica (tpEvento 110110).
///
/// Somente NF-e (modelo 55). Cada nova CC-e da mesma nota usa a próxima
/// [sequencia] (1 a 20) e substitui integralmente a anterior.
EventoNfe montarEventoCartaCorrecao({
  required String chave,
  required String correcao,
  required String cnpj,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  int sequencia = 1,
  DateTime? dataEvento,
}) {
  if (chave.substring(20, 22) != '55') {
    throw ArgumentError('Carta de Correção é permitida somente para NF-e (modelo 55)');
  }
  final texto = correcao.trim();
  if (texto.length < 15 || texto.length > 1000) {
    throw ArgumentError('Correção deve ter de 15 a 1000 caracteres');
  }
  if (sequencia < 1 || sequencia > 20) {
    throw ArgumentError('Sequência da CC-e deve ser de 1 a 20');
  }
  return _montarEvento(
    tipo: '110110',
    detalhe: '${_t('descEvento', 'Carta de Correcao')}${_t('xCorrecao', texto)}'
        '${_t('xCondUso', condicaoUsoCartaCorrecao)}',
    chave: chave,
    cnpj: cnpj,
    ambiente: ambiente,
    certificado: certificado,
    sequencia: sequencia,
    dataEvento: dataEvento,
  );
}

EventoNfe _montarEvento({
  required String tipo,
  required String detalhe,
  required String chave,
  required String cnpj,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  required int sequencia,
  DateTime? dataEvento,
}) {
  final id = 'ID$tipo$chave${sequencia.toString().padLeft(2, '0')}';
  final cOrgao = chave.substring(0, 2);
  final xml = '<evento xmlns="$nsNfe" versao="1.00"><infEvento Id="$id">'
      '${_t('cOrgao', cOrgao)}${_t('tpAmb', '${ambiente.codigo}')}${_t('CNPJ', cnpj)}'
      '${_t('chNFe', chave)}${_t('dhEvento', formatarDataHora(dataEvento ?? DateTime.now()))}'
      '${_t('tpEvento', tipo)}${_t('nSeqEvento', '$sequencia')}${_t('verEvento', '1.00')}'
      '<detEvento versao="1.00">$detalhe</detEvento>'
      '</infEvento></evento>';
  return EventoNfe._(assinarXml(xml, id, certificado), id, chave, tipo, sequencia);
}

/// `envEvento` 1.00 com um ou mais eventos assinados.
String montarEnvEvento(List<EventoNfe> eventos, {required int idLote}) {
  final b = StringBuffer('<envEvento xmlns="$nsNfe" versao="1.00">${_t('idLote', '$idLote')}');
  for (final e in eventos) {
    b.write(_semDeclaracao(e.xml));
  }
  b.write('</envEvento>');
  return b.toString();
}

/// `retEvento` de um evento processado.
class RetEvento {
  RetEvento._(this.xml, this.cStat, this.xMotivo, this.chave, this.nProt, this.dataRegistro);

  factory RetEvento.deElemento(XmlElement e) {
    final inf = e.getElement('infEvento')!;
    String? t(String n) => inf.getElement(n)?.innerText;
    return RetEvento._(e.toXmlString(), int.parse(t('cStat')!), t('xMotivo') ?? '', t('chNFe') ?? '',
        t('nProt'), DateTime.tryParse(t('dhRegEvento') ?? ''));
  }

  final String xml;
  final int cStat;
  final String xMotivo;
  final String chave;
  final String? nProt;

  /// Data/hora de registro do evento na SEFAZ (dhRegEvento).
  final DateTime? dataRegistro;

  /// 135 registrado e vinculado; 155 cancelamento fora de prazo homologado.
  bool get registrado => cStat == 135 || cStat == 136 || cStat == 155;
}

/// Retorno de `retEnvEvento`.
class RetEnvEvento {
  RetEnvEvento._(this.cStat, this.xMotivo, this.eventos);

  factory RetEnvEvento.fromXml(String xml) {
    final raiz = XmlDocument.parse(xml).rootElement;
    return RetEnvEvento._(
      int.parse(raiz.getElement('cStat')!.innerText),
      raiz.getElement('xMotivo')?.innerText ?? '',
      raiz.findElements('retEvento').map(RetEvento.deElemento).toList(),
    );
  }

  /// 128 = lote de evento processado.
  final int cStat;
  final String xMotivo;
  final List<RetEvento> eventos;
}

/// `procEventoNFe` (evento + retorno) — o XML do evento que deve ser guardado.
String montarProcEventoNfe(EventoNfe evento, RetEvento ret) => _proc(
    '<procEventoNFe xmlns="$nsNfe" versao="1.00"></procEventoNFe>', evento.xml, ret.xml);

// ---------------------------------------------------------------------------
// Inutilização

/// Pedido de inutilização (`inutNFe`), já assinado.
class InutilizacaoNfe {
  InutilizacaoNfe._(this.xml, this.id);
  final String xml;
  final String id;
}

InutilizacaoNfe montarInutilizacao({
  required Uf uf,
  required Ambiente ambiente,
  required String cnpj,
  required ModeloDocumento modelo,
  required int serie,
  required int numeroInicial,
  required int numeroFinal,
  required String justificativa,
  required CertificadoDigital certificado,
  int? ano,
}) {
  _validarJustificativa(justificativa);
  if (numeroFinal < numeroInicial) {
    throw ArgumentError('Número final menor que o inicial');
  }
  final aa = ((ano ?? DateTime.now().year) % 100).toString().padLeft(2, '0');
  final id = 'ID${uf.codigo}$aa$cnpj${modelo.codigo}${serie.toString().padLeft(3, '0')}'
      '${numeroInicial.toString().padLeft(9, '0')}${numeroFinal.toString().padLeft(9, '0')}';
  final xml = '<inutNFe xmlns="$nsNfe" versao="4.00"><infInut Id="$id">'
      '${_t('tpAmb', '${ambiente.codigo}')}${_t('xServ', 'INUTILIZAR')}${_t('cUF', '${uf.codigo}')}'
      '${_t('ano', aa)}${_t('CNPJ', cnpj)}${_t('mod', '${modelo.codigo}')}${_t('serie', '$serie')}'
      '${_t('nNFIni', '$numeroInicial')}${_t('nNFFin', '$numeroFinal')}${_t('xJust', justificativa)}'
      '</infInut></inutNFe>';
  return InutilizacaoNfe._(assinarXml(xml, id, certificado), id);
}

/// Retorno de `retInutNFe`.
class RetInutNfe {
  RetInutNfe._(this.xml, this.cStat, this.xMotivo, this.nProt);

  factory RetInutNfe.fromXml(String xml) {
    final raiz = XmlDocument.parse(xml).rootElement;
    final inf = raiz.getElement('infInut')!;
    return RetInutNfe._(
      raiz.toXmlString(),
      int.parse(inf.getElement('cStat')!.innerText),
      inf.getElement('xMotivo')?.innerText ?? '',
      inf.getElement('nProt')?.innerText,
    );
  }

  final String xml;
  final int cStat;
  final String xMotivo;
  final String? nProt;

  /// 102 = inutilização homologada.
  bool get homologada => cStat == 102;

  /// 998 = a SEFAZ desativou o serviço de inutilização (visto na SEFAZ-SP, homologação, nov/2026).
  bool get servicoDesativado => cStat == 998;
}

/// `ProcInutNFe` (pedido + retorno).
String montarProcInutNfe(InutilizacaoNfe inut, RetInutNfe ret) =>
    _proc('<ProcInutNFe xmlns="$nsNfe" versao="4.00"></ProcInutNFe>', inut.xml, ret.xml);

String _proc(String raizXml, String pedido, String retorno) {
  final doc = XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?>$raizXml');
  doc.rootElement.children
    ..add(XmlDocument.parse(_semDeclaracao(pedido)).rootElement.copy())
    ..add(XmlDocument.parse(_semDeclaracao(retorno)).rootElement.copy());
  return doc.toXmlString();
}
