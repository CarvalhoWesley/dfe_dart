import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _nfce = '35261112345678000195650010000001231123456785';
const _nfceSubst = '35261112345678000195650010000001241123456781';
const _nfeEpec = '35261112345678000195550010000004564123456782';

List<String> _det(String xml) =>
    XmlDocument.parse(xml).findAllElements('detEvento').single.childElements.map((e) => e.name.local).toList();
String _inf(String xml, String tag) => XmlDocument.parse(xml).findAllElements(tag).first.innerText;

/// Transporte que guarda o envio e devolve evento registrado.
class _Falso implements TransporteSoap {
  final urls = <String>[];
  final corpos = <String>[];

  @override
  Future<RespostaHttp> post(Uri url,
      {required Map<String, String> cabecalhos, required Uint8List corpo, required Duration timeout}) async {
    urls.add('$url');
    corpos.add(utf8.decode(corpo));
    return const RespostaHttp(200,
        '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Body>'
        '<nfeResultMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeRecepcaoEvento4">'
        '<retEnvEvento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><idLote>1</idLote>'
        '<tpAmb>2</tpAmb><cOrgao>91</cOrgao><cStat>128</cStat><xMotivo>ok</xMotivo><retEvento versao="1.00">'
        '<infEvento><tpAmb>2</tpAmb><cOrgao>91</cOrgao><cStat>135</cStat><xMotivo>ok</xMotivo>'
        '<chNFe>$_nfeEpec</chNFe><nProt>191260000000001</nProt></infEvento></retEvento></retEnvEvento>'
        '</nfeResultMsg></soap:Body></soap:Envelope>');
  }

  @override
  void fechar() {}
}

void main() {
  test('cancelamento por substituição (110112): campos na ordem do Zeus', () {
    final e = montarEventoCancelamentoSubstituicao(
      chave: _nfce, protocolo: '135260000000001', justificativa: 'VENDA EMITIDA EM DUPLICIDADE OFFLINE',
      chaveSubstituta: _nfceSubst, cnpj: '12345678000195', ambiente: Ambiente.homologacao, certificado: _cert,
    );
    expect(e.id, 'ID110112${_nfce}01');
    expect(_det(e.xml), ['descEvento', 'cOrgaoAutor', 'tpAutor', 'verAplic', 'nProt', 'xJust', 'chNFeRef']);
    expect(_inf(e.xml, 'descEvento'), 'Cancelamento por substituicao');
    expect(_inf(e.xml, 'cOrgao'), '35');
    expect(_inf(e.xml, 'chNFeRef'), _nfceSubst);
    expect(verificarAssinatura(e.xml).valido, isTrue);
  });

  test('EPEC (110140): Ambiente Nacional, dest e campos na ordem do Zeus', () {
    final e = montarEventoEpec(
      chave: _nfeEpec, cnpj: '12345678000195', inscricaoEstadual: '111111111111',
      dataEmissao: DateTime(2026, 11, 18, 10),
      destinatario: const DestinatarioEpec(uf: 'SP', cpf: '11144477735', vNF: 100, vICMS: 18, vST: 0),
      ambiente: Ambiente.homologacao, certificado: _cert,
    );
    expect(_inf(e.xml, 'cOrgao'), '91');
    expect(_det(e.xml), ['descEvento', 'cOrgaoAutor', 'tpAutor', 'verAplic', 'dhEmi', 'tpNF', 'IE', 'dest']);
    final dest = XmlDocument.parse(e.xml).findAllElements('dest').single;
    expect(dest.childElements.map((c) => c.name.local), ['UF', 'CPF', 'vNF', 'vICMS', 'vST']);
    expect(verificarAssinatura(e.xml).valido, isTrue);
  });

  test('manifestação: Ambiente Nacional, autor por CPF, justificativa só na não realizada', () {
    final ciencia = montarEventoManifestacao(
        chave: _nfeEpec, manifestacao: Manifestacao.ciencia, cpf: '11144477735',
        ambiente: Ambiente.homologacao, certificado: _cert);
    expect(_inf(ciencia.xml, 'cOrgao'), '91');
    expect(XmlDocument.parse(ciencia.xml).findAllElements('CPF'), hasLength(1));
    expect(_det(ciencia.xml), ['descEvento']);
    expect(ciencia.tipo, '210210');

    final nao = montarEventoManifestacao(
        chave: _nfeEpec, manifestacao: Manifestacao.naoRealizada, cnpj: '98765432000198',
        justificativa: 'MERCADORIA NAO FOI ENTREGUE', ambiente: Ambiente.homologacao, certificado: _cert);
    expect(_det(nao.xml), ['descEvento', 'xJust']);
    expect(
        () => montarEventoManifestacao(
            chave: _nfeEpec, manifestacao: Manifestacao.naoRealizada, cnpj: '1',
            ambiente: Ambiente.homologacao, certificado: _cert),
        throwsArgumentError);
  });

  test('evento genérico preserva a CC-e (mesma saída do montador dedicado)', () {
    final dh = DateTime(2026, 11, 18, 10);
    final dedicado = montarEventoCartaCorrecao(
        chave: _nfeEpec, correcao: 'CORRECAO DE TESTE GENERICO', cnpj: '12345678000195',
        ambiente: Ambiente.homologacao, certificado: _cert, dataEvento: dh);
    final generico = montarEvento(
      tipo: '110110',
      detalhe: const DetalheEvento(
          descEvento: 'Carta de Correcao', xCorrecao: 'CORRECAO DE TESTE GENERICO', xCondUso: condicaoUsoCartaCorrecao),
      chave: _nfeEpec, cnpj: '12345678000195', ambiente: Ambiente.homologacao, certificado: _cert, dataEvento: dh,
    );
    expect(generico.xml, dedicado.xml);
  });

  test('ServicosNfe: EPEC e manifestação vão para o Ambiente Nacional', () async {
    final t = _Falso();
    final s = ServicosNfe(
        ConfiguracaoNfe(certificado: _cert, uf: Uf.sp, ambiente: Ambiente.homologacao, modelo: ModeloDocumento.nfe),
        transporte: t);
    final epec = await s.enviarEpec(
      chave: _nfeEpec, inscricaoEstadual: '111', dataEmissao: DateTime(2026, 11, 18), idLote: 1,
      destinatario: const DestinatarioEpec(uf: 'SP', cpf: '11144477735', vNF: 1, vICMS: 0, vST: 0),
    );
    await s.manifestar(chave: _nfeEpec, manifestacao: Manifestacao.confirmacao, cnpj: '98765432000198', idLote: 2);
    expect(t.urls, everyElement('https://hom1.nfe.fazenda.gov.br/NFeRecepcaoEvento4/NFeRecepcaoEvento4.asmx'));
    expect(epec.retEvento!.registrado, isTrue);
    expect(epec.procEventoXml, isNotNull);
  });
}
