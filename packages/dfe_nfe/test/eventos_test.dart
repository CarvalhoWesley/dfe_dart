import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _chave = '35261112345678000195650010000001231123456785';
const _just = 'CANCELAMENTO DE TESTE EM HOMOLOGACAO';

void main() {
  test('consSitNFe', () {
    expect(
      montarConsSitNfe(_chave, Ambiente.homologacao),
      '<consSitNFe xmlns="$nsNfe" versao="4.00"><tpAmb>2</tpAmb><xServ>CONSULTAR</xServ>'
      '<chNFe>$_chave</chNFe></consSitNFe>',
    );
  });

  test('retConsSitNFe cancelada com evento', () {
    final r = RetConsSitNfe.fromXml(
        '<retConsSitNFe xmlns="$nsNfe" versao="4.00"><tpAmb>2</tpAmb><cStat>101</cStat>'
        '<xMotivo>Cancelamento de NF-e homologado</xMotivo><cUF>35</cUF><chNFe>$_chave</chNFe>'
        '<protNFe versao="4.00"><infProt><chNFe>$_chave</chNFe><nProt>135260000000001</nProt>'
        '<cStat>100</cStat><xMotivo>Autorizado</xMotivo></infProt></protNFe>'
        '<procEventoNFe versao="1.00"><evento/><retEvento/></procEventoNFe></retConsSitNFe>');
    expect(r.cancelada, isTrue);
    expect(r.protocolo!.nProt, '135260000000001');
    expect(r.eventos, hasLength(1));
  });

  test('evento de cancelamento: Id, campos e assinatura', () {
    final e = montarEventoCancelamento(
      chave: _chave,
      protocolo: '135260000000001',
      justificativa: _just,
      cnpj: '12345678000195',
      ambiente: Ambiente.homologacao,
      certificado: _cert,
    );
    expect(e.id, 'ID110111${_chave}01');
    final x = XmlDocument.parse(e.xml);
    expect(x.rootElement.childElements.map((c) => c.name.local), ['infEvento', 'Signature']);
    expect(x.findAllElements('cOrgao').single.innerText, '35');
    expect(x.findAllElements('descEvento').single.innerText, 'Cancelamento');
    expect(verificarAssinatura(e.xml).valido, isTrue);

    final env = montarEnvEvento([e], idLote: 7);
    expect(XmlDocument.parse(env).findAllElements('evento'), hasLength(1));
  });

  test('justificativa curta é rejeitada', () {
    expect(
      () => montarEventoCancelamento(
        chave: _chave, protocolo: '1', justificativa: 'curta', cnpj: '12345678000195',
        ambiente: Ambiente.homologacao, certificado: _cert),
      throwsArgumentError,
    );
  });

  test('retEnvEvento e procEventoNFe', () {
    final e = montarEventoCancelamento(
      chave: _chave, protocolo: '135260000000001', justificativa: _just,
      cnpj: '12345678000195', ambiente: Ambiente.homologacao, certificado: _cert);
    final ret = RetEnvEvento.fromXml(
        '<retEnvEvento xmlns="$nsNfe" versao="1.00"><idLote>7</idLote><tpAmb>2</tpAmb>'
        '<cOrgao>35</cOrgao><cStat>128</cStat><xMotivo>Lote de Evento Processado</xMotivo>'
        '<retEvento versao="1.00"><infEvento><tpAmb>2</tpAmb><cOrgao>35</cOrgao><cStat>135</cStat>'
        '<xMotivo>Evento registrado e vinculado a NF-e</xMotivo><chNFe>$_chave</chNFe>'
        '<nProt>135260000000002</nProt></infEvento></retEvento></retEnvEvento>');
    expect(ret.eventos.single.registrado, isTrue);
    final proc = montarProcEventoNfe(e, ret.eventos.single);
    expect(XmlDocument.parse(proc).rootElement.childElements.map((c) => c.name.local),
        ['evento', 'retEvento']);
    expect(verificarAssinatura(proc).valido, isTrue);
  });

  test('inutilização: Id de 43 caracteres, assinatura e ProcInutNFe', () {
    final i = montarInutilizacao(
      uf: Uf.sp, ambiente: Ambiente.homologacao, cnpj: '12345678000195',
      modelo: ModeloDocumento.nfce, serie: 1, numeroInicial: 10, numeroFinal: 12,
      justificativa: 'NUMERACAO PULADA POR FALHA DO SISTEMA', certificado: _cert, ano: 2026);
    expect(i.id, 'ID3526123456780001956500100000001000000001' '2');
    expect(i.id.length, 43);
    expect(verificarAssinatura(i.xml).valido, isTrue);

    final r = RetInutNfe.fromXml(
        '<retInutNFe xmlns="$nsNfe" versao="4.00"><infInut><tpAmb>2</tpAmb><cStat>102</cStat>'
        '<xMotivo>Inutilizacao de numero homologado</xMotivo><nProt>135260000000003</nProt>'
        '</infInut></retInutNFe>');
    expect(r.homologada, isTrue);
    final proc = montarProcInutNfe(i, r);
    expect(XmlDocument.parse(proc).rootElement.childElements.map((c) => c.name.local),
        ['inutNFe', 'retInutNFe']);
  });

  test('URLs: SP, SVRS e SVC-AN', () {
    expect(Enderecador.url(ServicoNfe.recepcaoEvento, Uf.sp, ModeloDocumento.nfce, Ambiente.homologacao),
        'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeRecepcaoEvento4.asmx');
    expect(Enderecador.url(ServicoNfe.inutilizacao, Uf.sc, ModeloDocumento.nfe, Ambiente.homologacao),
        'https://nfe-homologacao.svrs.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao4.asmx');
    expect(
        Enderecador.url(ServicoNfe.consultaProtocolo, Uf.sp, ModeloDocumento.nfe, Ambiente.homologacao,
            tipoEmissao: TipoEmissao.svcAn),
        'https://hom.sefazvirtual.fazenda.gov.br/NFeConsultaProtocolo4/NFeConsultaProtocolo4.asmx');
    expect(TipoEmissao.daChave('35261111178691000134550800000000026411661867'), TipoEmissao.svcAn);
  });
}
