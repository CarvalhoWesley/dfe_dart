import 'package:dfe_danfe/dfe_danfe.dart';
import 'package:test/test.dart';

const _chave = '35261112345678000195650010000001231123456785';

String _xml({bool comProtocolo = true, String tpEmis = '1', String? dest}) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
    '<NFe><infNFe versao="4.00" Id="NFe$_chave"><ide><cUF>35</cUF><mod>65</mod><serie>1</serie>'
    '<nNF>123</nNF><dhEmi>2026-11-17T10:05:30-03:00</dhEmi><tpEmis>$tpEmis</tpEmis><tpAmb>2</tpAmb></ide>'
    '<emit><CNPJ>12345678000195</CNPJ><xNome>EMPRESA TESTE LTDA</xNome><xFant>LOJA SÃO JOÃO</xFant>'
    '<enderEmit><xLgr>RUA DAS FLORES</xLgr><nro>100</nro><xBairro>CENTRO</xBairro>'
    '<xMun>SAO PAULO</xMun><UF>SP</UF></enderEmit><IE>111111111111</IE></emit>'
    '${dest ?? ''}'
    '<det nItem="1"><prod><cProd>0001</cProd><xProd>PRODUTO COM DESCRIÇÃO BEM LONGA PARA QUEBRAR</xProd>'
    '<qCom>2.0000</qCom><uCom>UN</uCom><vUnCom>5.5000000000</vUnCom><vProd>11.00</vProd></prod></det>'
    '<det nItem="2"><prod><cProd>0002</cProd><xProd>CAFÉ</xProd>'
    '<qCom>1.2500</qCom><uCom>KG</uCom><vUnCom>40.0000000000</vUnCom><vProd>50.00</vProd></prod></det>'
    '<total><ICMSTot><vProd>61.00</vProd><vDesc>1.00</vDesc><vFrete>0.00</vFrete><vSeg>0.00</vSeg>'
    '<vOutro>0.00</vOutro><vNF>60.00</vNF><vTotTrib>8.45</vTotTrib></ICMSTot></total>'
    '<pag><detPag><tPag>17</tPag><vPag>50.00</vPag></detPag><detPag><tPag>01</tPag><vPag>20.00</vPag></detPag>'
    '<vTroco>10.00</vTroco></pag><infAdic><infCpl>Obrigado pela preferência</infCpl></infAdic></infNFe>'
    '<infNFeSupl><qrCode>https://www.homologacao.nfce.fazenda.sp.gov.br/qrcode?p=$_chave|3|2</qrCode>'
    '<urlChave>https://www.homologacao.nfce.fazenda.sp.gov.br/consulta</urlChave></infNFeSupl></NFe>'
    '${comProtocolo ? '<protNFe versao="4.00"><infProt><chNFe>$_chave</chNFe>'
        '<dhRecbto>2026-11-17T10:05:32-03:00</dhRecbto><nProt>135260000000001</nProt>'
        '<cStat>100</cStat></infProt></protNFe>' : ''}'
    '</nfeProc>';

void main() {
  test('leitura do procNFe', () {
    final d = DadosDanfeNfce.deXml(_xml());
    expect(d.itens, hasLength(2));
    expect(d.valorTotal, 60);
    expect(d.troco, 10);
    expect(d.protocolo, '135260000000001');
    expect(d.dataEmissao.hour, 10); // hora local do XML, não UTC
    expect(d.pagamentos.first.descricao, 'PIX');
  });

  test('texto em 48 colunas com as divisões do manual', () {
    final t = DanfeNfce.deXml(_xml()).texto();
    final linhas = t.split('\n').where((l) => l.isNotEmpty);
    expect(linhas.every((l) => l.length <= 48), isTrue, reason: t);
    final corrido = t.replaceAll(RegExp(r'\s+'), ' ');
    for (final trecho in [
      'LOJA SÃO JOÃO',
      'CNPJ: 12.345.678/0001-95',
      'Documento Auxiliar da Nota Fiscal de Consumidor',
      'Valor a Pagar R\$',
      '60,00',
      'Troco R\$',
      'Informação dos Tributos Totais Incidentes',
      '12.741/2012',
      'EMITIDA EM AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL',
      '3526 1112 3456 7800 0195 6500 1000 0001 2311 2345 6785',
      'CONSUMIDOR NÃO IDENTIFICADO',
      'NFC-e nº 000000123 Série 001 17/11/2026 10:05:30',
      'Protocolo de autorização: 135260000000001',
    ]) {
      expect(corrido, contains(trecho), reason: t);
    }
  });

  test('58 mm: 32 colunas e itens em duas linhas', () {
    final t = DanfeNfce.deXml(_xml(), opcoes: OpcoesDanfe.papel58mm).texto(incluirQrCode: false);
    final linhas = t.split('\n').where((l) => l.isNotEmpty);
    expect(linhas.every((l) => l.length <= 32), isTrue, reason: t);
    expect(t, contains('1,25 KG x 40,00'));
  });

  test('contingência sem protocolo e consumidor identificado', () {
    final t = DanfeNfce.deXml(_xml(
      comProtocolo: false,
      tpEmis: '9',
      dest: '<dest><CPF>11144477735</CPF><xNome>FULANO</xNome></dest>',
    )).texto();
    expect(t, contains('EMITIDA EM CONTINGÊNCIA'));
    expect(t, contains('Pendente de autorização'));
    expect(t, contains('CONSUMIDOR - CPF 111.444.777-35'));
    expect(t, isNot(contains('Protocolo de autorização')));
  });

  group('ESC/POS', () {
    final danfe = DanfeNfce.deXml(_xml());

    test('inicialização, página de código, QR nativo e corte parcial', () {
      final b = danfe.escPos();
      expect(b.sublist(0, 5), [0x1B, 0x40, 0x1B, 0x74, 3]);
      expect(_contem(b, [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]), isTrue); // imprime QR
      expect(b.sublist(b.length - 3), [0x1D, 0x56, 0x01]);
      expect(b, contains(0x84)); // "ã" em CP860
    });

    test('QR em imagem raster e sem acentos', () {
      final b = danfe.escPos(const OpcoesEscPos(
          modoQrCode: ModoQrCode.imagem, paginaCodigo: PaginaCodigo.semAcento, corte: Corte.nenhum,
          abrirGaveta: true));
      expect(_contem(b, [0x1D, 0x76, 0x30, 0x00]), isTrue);
      expect(_contem(b, [0x1D, 0x28, 0x6B]), isFalse);
      expect(_contem(b, [0x1B, 0x74]), isFalse);
      expect(_contem(b, 'LOJA SAO JOAO'.codeUnits), isTrue);
      expect(b.sublist(b.length - 5), [0x1B, 0x70, 0x00, 0x19, 0xFA]);
    });
  });

  test('PDF válido', () async {
    final pdf = await DanfeNfce.deXml(_xml()).pdf();
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    expect(pdf.length, greaterThan(1000));
  });

  test('rejeita NF-e modelo 55', () {
    expect(() => DadosDanfeNfce.deXml(_xml().replaceFirst('<mod>65</mod>', '<mod>55</mod>')),
        throwsArgumentError);
  });
}

bool _contem(List<int> b, List<int> seq) {
  for (var i = 0; i <= b.length - seq.length; i++) {
    var ok = true;
    for (var j = 0; j < seq.length; j++) {
      if (b[i + j] != seq[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}
