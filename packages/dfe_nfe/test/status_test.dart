import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';

void main() {
  test('consStatServ igual ao gerado pelo Zeus', () {
    expect(
      const ConsStatServ(tpAmb: Ambiente.homologacao, cUF: Uf.sp).toXml(),
      '<consStatServ xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
      '<tpAmb>2</tpAmb><cUF>35</cUF><xServ>STATUS</xServ></consStatServ>',
    );
  });

  test('envelope SOAP 1.2 sem declaração XML interna', () {
    final env = SoapClient.montarEnvelope(
        ServicoNfe.statusServico.namespaceWsdl, '<?xml version="1.0"?><x/>');
    expect(env, contains('<soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NFeStatusServico4"><x/></nfeDadosMsg>'));
  });

  test('lê retConsStatServ', () {
    final r = RetConsStatServ.fromXml(
        '<retConsStatServ versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe">'
        '<tpAmb>2</tpAmb><verAplic>SP_NFE_PL009_V4</verAplic><cStat>107</cStat>'
        '<xMotivo>Serviço em Operação</xMotivo><cUF>35</cUF>'
        '<dhRecbto>2024-11-17T10:00:00-03:00</dhRecbto><tMed>1</tMed></retConsStatServ>');
    expect(r.emOperacao, isTrue);
    expect(r.tpAmb, Ambiente.homologacao);
    expect(r.tMed, 1);
  });

  test('URLs de status', () {
    expect(Enderecador.urlStatus(Uf.sc, ModeloDocumento.nfce, Ambiente.homologacao),
        contains('nfce-homologacao.svrs.rs.gov.br'));
    expect(Enderecador.urlStatus(Uf.ba, ModeloDocumento.nfce, Ambiente.producao),
        contains('nfce.svrs.rs.gov.br'));
    expect(Enderecador.urlStatus(Uf.sp, ModeloDocumento.nfe, Ambiente.homologacao),
        'https://homologacao.nfe.fazenda.sp.gov.br/ws/nfestatusservico4.asmx');
    expect(Enderecador.urlStatus(Uf.ce, ModeloDocumento.nfe, Ambiente.producao), startsWith('https://'));
    // Ambiente Nacional não autoriza NF-e: combinação inexistente na tabela.
    expect(() => Enderecador.url(ServicoNfe.autorizacao, Uf.an, ModeloDocumento.nfce, Ambiente.producao),
        throwsUnsupportedError);
  });

  group('tabela completa (gerada do Zeus)', () {
    final ufs = Uf.values.where((u) => u != Uf.an);
    const servicos = [
      ServicoNfe.statusServico,
      ServicoNfe.autorizacao,
      ServicoNfe.retAutorizacao,
      ServicoNfe.consultaProtocolo,
      ServicoNfe.recepcaoEvento,
    ];

    test('todas as 27 UFs têm os serviços de NF-e e NFC-e nos dois ambientes', () {
      final faltando = <String>[];
      for (final uf in ufs) {
        for (final m in ModeloDocumento.values) {
          for (final a in Ambiente.values) {
            for (final s in servicos) {
              try {
                Enderecador.url(s, uf, m, a);
              } on UnsupportedError {
                faltando.add('${uf.sigla}/${m.name}/${a.name}/${s.name}');
              }
            }
          }
        }
      }
      expect(faltando, isEmpty);
    });

    test('contingência SVC da NF-e disponível para todas as UFs', () {
      for (final uf in ufs) {
        final svc = Enderecador.contingenciaSvc(uf);
        expect(Enderecador.url(ServicoNfe.autorizacao, uf, ModeloDocumento.nfe, Ambiente.homologacao,
            tipoEmissao: svc), startsWith('https://'), reason: uf.sigla);
      }
    });

    test('QR Code v3 e consulta para todas as UFs', () {
      for (final uf in ufs) {
        for (final a in Ambiente.values) {
          expect(UrlsNfce.obter(uf, a, VersaoQrCode.v3), isNotNull, reason: '${uf.sigla}/${a.name}');
        }
      }
    });
  });
}
