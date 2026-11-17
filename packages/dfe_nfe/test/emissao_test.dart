import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _end = Endereco(
  logradouro: 'RUA TESTE',
  numero: '100',
  bairro: 'CENTRO',
  codigoMunicipio: 3550308,
  municipio: 'SAO PAULO',
  uf: Uf.sp,
  cep: '01001000',
);

DadosNfe _dados(ModeloDocumento m, {TipoEmissao tp = TipoEmissao.normal}) => DadosNfe(
      modelo: m,
      ambiente: Ambiente.homologacao,
      serie: 1,
      numero: 123,
      codigoNumerico: 12345678,
      dataEmissao: DateTime(2026, 11, 17, 10),
      tipoEmissao: tp,
      justificativaContingencia: tp.contingencia ? 'TESTE DE CONTINGENCIA EM HOMOLOGACAO' : null,
      emitente: const Emitente(
        cnpj: '12345678000195',
        razaoSocial: 'EMPRESA TESTE',
        inscricaoEstadual: '111111111111',
        endereco: _end,
      ),
      destinatario: m == ModeloDocumento.nfe
          ? const Destinatario(nome: 'CLIENTE', cpf: '12345678909', endereco: _end)
          : null,
      itens: const [
        ItemNfe(
          codigo: '1', descricao: 'PRODUTO', ncm: '21069090', cfop: '5102',
          unidade: 'UN', quantidade: 2, valorUnitario: 5.5,
        ),
      ],
      pagamentos: const [Pagamento(tipo: '01', valor: 20)],
    );

void main() {
  test('chave de acesso e DV', () {
    final c = ChaveAcesso.gerar(
      uf: Uf.sp, dataEmissao: DateTime(2026, 11, 17), cnpj: '12345678000195',
      modelo: ModeloDocumento.nfce, serie: 1, numero: 123,
      tipoEmissao: TipoEmissao.normal, codigoNumerico: 12345678,
    );
    expect(c.valor, hasLength(44));
    expect(c.valor.substring(0, 6), '352611');
    expect(ChaveAcesso.valida(c.valor), isTrue);
    // Exemplo conhecido do MOC (DV = 5).
    expect(ChaveAcesso.calcularDv('5206043300991100250655012000000780026730161'), 5);
  });

  test('NF-e: estrutura, totais, homologação e assinatura válida', () {
    final doc = EmissorNfe(_cert).gerar(_dados(ModeloDocumento.nfe));
    final x = XmlDocument.parse(doc.xmlAssinado);
    expect(x.rootElement.childElements.map((e) => e.name.local), ['infNFe', 'Signature']);
    expect(x.findAllElements('vNF').single.innerText, '11.00');
    expect(x.findAllElements('vTroco').single.innerText, '9.00');
    expect(x.findAllElements('xProd').single.innerText, textoHomologacaoItem);
    expect(x.findAllElements('dest').single.getElement('xNome')!.innerText, textoHomologacaoDest);
    expect(x.findAllElements('tpImp').single.innerText, '1');
    expect(verificarAssinatura(doc.xmlAssinado).valido, isTrue);
  });

  test('NFC-e online: infNFeSupl entre infNFe e Signature, QR v3', () {
    final doc = EmissorNfe(_cert).gerar(_dados(ModeloDocumento.nfce));
    final raiz = XmlDocument.parse(doc.xmlAssinado).rootElement;
    expect(raiz.childElements.map((e) => e.name.local), ['infNFe', 'infNFeSupl', 'Signature']);
    expect(doc.qrCode,
        'https://www.homologacao.nfce.fazenda.sp.gov.br/qrcode?p=${doc.chave.valor}|3|2');
    expect(verificarAssinatura(doc.xmlAssinado).valido, isTrue);
  });

  test('NFC-e offline: tpEmis 9, dhCont/xJust e QR v3 assinado', () {
    final doc = EmissorNfe(_cert).gerar(_dados(ModeloDocumento.nfce, tp: TipoEmissao.offlineNfce));
    final x = XmlDocument.parse(doc.xmlAssinado);
    expect(x.findAllElements('tpEmis').single.innerText, '9');
    expect(x.findAllElements('xJust'), hasLength(1));
    expect(doc.chave.valor[34], '9');
    final partes = doc.qrCode!.split('?p=')[1].split('|');
    expect(partes.sublist(1, 5), ['3', '2', '17', '11.00']);
    expect(partes.last, isNotEmpty); // assinatura RSA-SHA1 em base64
  });

  test('NFC-e QR v2 online com CSC', () {
    final doc = EmissorNfe(_cert,
            nfce: const ConfiguracaoNfce(versaoQrCode: VersaoQrCode.v2, idCsc: '000001', csc: 'ABC'))
        .gerar(_dados(ModeloDocumento.nfce));
    final p = doc.qrCode!.split('?p=')[1].split('|');
    expect(p.sublist(1, 4), ['2', '2', '1']);
    expect(p.last, matches(RegExp(r'^[0-9A-F]{40}$')));
  });

  test('URLs de autorização e contingência', () {
    expect(Enderecador.url(ServicoNfe.autorizacao, Uf.sp, ModeloDocumento.nfe, Ambiente.homologacao),
        'https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeautorizacao4.asmx');
    expect(Enderecador.contingenciaSvc(Uf.sp), TipoEmissao.svcAn);
    expect(
        Enderecador.url(ServicoNfe.autorizacao, Uf.sp, ModeloDocumento.nfe, Ambiente.homologacao,
            tipoEmissao: TipoEmissao.svcAn),
        'https://hom.sefazvirtual.fazenda.gov.br/NFeAutorizacao4/NFeAutorizacao4.asmx');
  });

  test('retorno síncrono e nfeProc', () {
    final doc = EmissorNfe(_cert).gerar(_dados(ModeloDocumento.nfce));
    final ret = RetornoLote.fromXml(
        '<retEnviNFe xmlns="$nsNfe" versao="4.00"><tpAmb>2</tpAmb><cStat>104</cStat>'
        '<xMotivo>Lote processado</xMotivo><protNFe versao="4.00"><infProt>'
        '<chNFe>${doc.chave.valor}</chNFe><dhRecbto>2026-11-17T10:00:01-03:00</dhRecbto>'
        '<nProt>135260000000001</nProt><cStat>100</cStat><xMotivo>Autorizado</xMotivo>'
        '</infProt></protNFe></retEnviNFe>');
    expect(ret.protocolos.single.autorizado, isTrue);
    final proc = montarNfeProc(doc.xmlAssinado, ret.protocolos.single);
    final raiz = XmlDocument.parse(proc).rootElement;
    expect(raiz.childElements.map((e) => e.name.local), ['NFe', 'protNFe']);
    expect(verificarAssinatura(proc).valido, isTrue);
  });
}
