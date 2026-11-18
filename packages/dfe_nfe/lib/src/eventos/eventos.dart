import 'package:dfe_core/dfe_core.dart';
import 'package:xml/xml.dart';

import '../autorizacao/autorizacao.dart';
import '../enums.dart';
import '../status/cons_stat_serv.dart' show nsNfe;
import '../tributacao/classes.g.dart';
import '../tributacao/grupo.dart';
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
  String? cOrgao,
  String? cpf,
}) {
  final id = 'ID$tipo$chave${sequencia.toString().padLeft(2, '0')}';
  final autor = cpf != null ? _t('CPF', cpf) : _t('CNPJ', cnpj);
  final xml = '<evento xmlns="$nsNfe" versao="1.00"><infEvento Id="$id">'
      '${_t('cOrgao', cOrgao ?? chave.substring(0, 2))}${_t('tpAmb', '${ambiente.codigo}')}$autor'
      '${_t('chNFe', chave)}${_t('dhEvento', formatarDataHora(dataEvento ?? DateTime.now()))}'
      '${_t('tpEvento', tipo)}${_t('nSeqEvento', '$sequencia')}${_t('verEvento', '1.00')}'
      '<detEvento versao="1.00">$detalhe</detEvento>'
      '</infEvento></evento>';
  return EventoNfe._(assinarXml(xml, id, certificado), id, chave, tipo, sequencia);
}

/// Destinatário do EPEC (grupo `dest` do detEvento, classe `dest` do Zeus).
typedef DestinatarioEpec = EventoDest;

/// Detalhe do evento (`detEvento`), gerado da classe `detEvento` do Zeus:
/// cobre todos os eventos (CC-e, cancelamento, EPEC, manifestação, ator
/// interessado, entrega/insucesso, conciliação e eventos da reforma).
/// Os valores são informados pelo app; o atributo `versao` é preenchido por
/// [montarEvento].
typedef DetalheEvento = EventoDetEvento;

/// Monta e assina um evento genérico com o [detalhe] informado pelo app.
///
/// [cOrgao] padrão = UF da chave; use `91` para eventos do Ambiente Nacional.
/// Informe [cpf] no lugar de [cnpj] quando o autor for pessoa física.
EventoNfe montarEvento({
  required String tipo,
  required DetalheEvento detalhe,
  required String chave,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  String cnpj = '',
  String? cpf,
  String? cOrgao,
  int sequencia = 1,
  DateTime? dataEvento,
}) =>
    _montarEvento(
      tipo: tipo,
      detalhe: _conteudoDetalhe(detalhe),
      chave: chave,
      cnpj: cnpj,
      cpf: cpf,
      cOrgao: cOrgao,
      ambiente: ambiente,
      certificado: certificado,
      sequencia: sequencia,
      dataEvento: dataEvento,
    );

/// Cancelamento por substituição da NFC-e (110112): cancela [chave]
/// informando a NFC-e substituta [chaveSubstituta].
EventoNfe montarEventoCancelamentoSubstituicao({
  required String chave,
  required String protocolo,
  required String justificativa,
  required String chaveSubstituta,
  required String cnpj,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  String versaoAplicativo = 'dfe_dart 0.1',
  int sequencia = 1,
  DateTime? dataEvento,
}) =>
    montarEvento(
      tipo: '110112',
      detalhe: DetalheEvento(
        descEvento: 'Cancelamento por substituicao',
        cOrgaoAutor: chave.substring(0, 2),
        tpAutor: '1',
        verAplic: versaoAplicativo,
        nProt: protocolo,
        xJust: justificativa,
        chNFeRef: chaveSubstituta,
      ),
      chave: chave,
      cnpj: cnpj,
      ambiente: ambiente,
      certificado: certificado,
      sequencia: sequencia,
      dataEvento: dataEvento,
    );

/// EPEC (110140) — evento prévio da NF-e emitida em contingência EPEC
/// (tpEmis 4). Enviado ao Ambiente Nacional (cOrgao 91).
EventoNfe montarEventoEpec({
  required String chave,
  required String cnpj,
  required String inscricaoEstadual,
  required DateTime dataEmissao,
  required DestinatarioEpec destinatario,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  int tipoOperacao = 1,
  String versaoAplicativo = 'dfe_dart 0.1',
  DateTime? dataEvento,
}) =>
    montarEvento(
      tipo: '110140',
      detalhe: DetalheEvento(
        descEvento: 'EPEC',
        cOrgaoAutor: chave.substring(0, 2),
        tpAutor: '1',
        verAplic: versaoAplicativo,
        dhEmi: dataEmissao,
        tpNF: '$tipoOperacao',
        ie: inscricaoEstadual,
        dest: destinatario,
      ),
      chave: chave,
      cnpj: cnpj,
      cOrgao: '91',
      ambiente: ambiente,
      certificado: certificado,
      dataEvento: dataEvento,
    );

/// Tipos da manifestação do destinatário.
enum Manifestacao {
  confirmacao('210200', 'Confirmacao da Operacao'),
  ciencia('210210', 'Ciencia da Operacao'),
  desconhecimento('210220', 'Desconhecimento da Operacao'),

  /// Exige justificativa.
  naoRealizada('210240', 'Operacao nao Realizada');

  const Manifestacao(this.tipo, this.descricao);
  final String tipo;
  final String descricao;
}

/// Manifestação do destinatário (210200/210210/210220/210240), enviada ao
/// Ambiente Nacional (cOrgao 91) pelo destinatário da NF-e.
EventoNfe montarEventoManifestacao({
  required String chave,
  required Manifestacao manifestacao,
  required Ambiente ambiente,
  required CertificadoDigital certificado,
  String cnpj = '',
  String? cpf,
  String? justificativa,
  DateTime? dataEvento,
}) {
  if (manifestacao == Manifestacao.naoRealizada) _validarJustificativa(justificativa ?? '');
  return montarEvento(
    tipo: manifestacao.tipo,
    detalhe: DetalheEvento(
      descEvento: manifestacao.descricao,
      xJust: manifestacao == Manifestacao.naoRealizada ? justificativa : null,
    ),
    chave: chave,
    cnpj: cnpj,
    cpf: cpf,
    cOrgao: '91',
    ambiente: ambiente,
    certificado: certificado,
    dataEvento: dataEvento,
  );
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

/// Conteúdo do `detEvento` (sem o elemento raiz, que leva `versao="1.00"`).
String _conteudoDetalhe(DetalheEvento d) {
  final x = serializarGrupoXml(d);
  return x.substring(x.indexOf('>') + 1, x.length - '</detEvento>'.length);
}
