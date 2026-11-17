import 'dart:io';

import 'package:dfe_danfe/dfe_danfe.dart';
import 'package:test/test.dart';

const _chave = '35261112345678000195550010000004561123456780';

String _item(int i) => '<det nItem="$i"><prod><cProd>${i.toString().padLeft(5, '0')}</cProd>'
    '<xProd>PRODUTO DE TESTE NÚMERO $i COM DESCRIÇÃO LONGA PARA OCUPAR DUAS LINHAS NA TABELA DO DANFE</xProd>'
    '<NCM>21069090</NCM><CFOP>5102</CFOP><uCom>UN</uCom><qCom>2.0000</qCom>'
    '<vUnCom>10.5000000000</vUnCom><vProd>21.00</vProd></prod><imposto><ICMS><ICMS00>'
    '<orig>0</orig><CST>00</CST><modBC>3</modBC><vBC>21.00</vBC><pICMS>18.00</pICMS><vICMS>3.78</vICMS>'
    '</ICMS00></ICMS><IPI><cEnq>999</cEnq><IPITrib><CST>50</CST><vBC>21.00</vBC><pIPI>5.00</pIPI>'
    '<vIPI>1.05</vIPI></IPITrib></IPI></imposto></det>';

String nfeXml({int itens = 3, bool protocolo = true, String tpEmis = '1', bool duplicatas = true}) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00"><NFe>'
    '<infNFe versao="4.00" Id="NFe$_chave"><ide><cUF>35</cUF><natOp>VENDA DE MERCADORIA</natOp>'
    '<mod>55</mod><serie>1</serie><nNF>456</nNF><dhEmi>2026-11-17T14:20:00-03:00</dhEmi>'
    '<dhSaiEnt>2026-11-17T15:00:00-03:00</dhSaiEnt><tpNF>1</tpNF><tpEmis>$tpEmis</tpEmis><tpAmb>2</tpAmb>'
    '${tpEmis != '1' ? '<dhCont>2026-11-17T14:19:00-03:00</dhCont><xJust>SEFAZ FORA DO AR PARA TESTE</xJust>' : ''}'
    '</ide><emit><CNPJ>12345678000195</CNPJ><xNome>EMPRESA DE TESTE COMÉRCIO LTDA</xNome>'
    '<enderEmit><xLgr>AVENIDA PAULISTA</xLgr><nro>1000</nro><xBairro>BELA VISTA</xBairro>'
    '<xMun>SAO PAULO</xMun><UF>SP</UF><CEP>01310100</CEP><fone>1133334444</fone></enderEmit>'
    '<IE>111111111111</IE><CRT>3</CRT></emit>'
    '<dest><CPF>11144477735</CPF><xNome>NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL</xNome>'
    '<enderDest><xLgr>RUA TESTE</xLgr><nro>10</nro><xBairro>CENTRO</xBairro><xMun>CAMPINAS</xMun>'
    '<UF>SP</UF><CEP>13010000</CEP></enderDest><indIEDest>9</indIEDest></dest>'
    '${List.generate(itens, (i) => _item(i + 1)).join()}'
    '<total><ICMSTot><vBC>${(21 * itens).toStringAsFixed(2)}</vBC><vICMS>${(3.78 * itens).toStringAsFixed(2)}</vICMS>'
    '<vProd>${(21 * itens).toStringAsFixed(2)}</vProd><vFrete>0.00</vFrete><vIPI>${(1.05 * itens).toStringAsFixed(2)}</vIPI>'
    '<vNF>${(22.05 * itens).toStringAsFixed(2)}</vNF><vTotTrib>5.00</vTotTrib></ICMSTot></total>'
    '<transp><modFrete>0</modFrete><transporta><CNPJ>98765432000198</CNPJ><xNome>TRANSPORTADORA TESTE</xNome>'
    '<IE>222222222222</IE><xEnder>RUA DO FRETE, 5</xEnder><xMun>SAO PAULO</xMun><UF>SP</UF></transporta>'
    '<vol><qVol>2</qVol><esp>CAIXA</esp><pesoL>10.500</pesoL><pesoB>11.000</pesoB></vol></transp>'
    '${duplicatas ? '<cobr><fat><nFat>456</nFat></fat><dup><nDup>001</nDup><dVenc>2026-12-17</dVenc><vDup>30.00</vDup></dup>'
        '<dup><nDup>002</nDup><dVenc>2027-01-17</dVenc><vDup>36.15</vDup></dup></cobr>' : ''}'
    '<pag><detPag><tPag>15</tPag><vPag>66.15</vPag></detPag></pag>'
    '<infAdic><infCpl>Pedido 123. Obrigado pela preferência.</infCpl></infAdic></infNFe></NFe>'
    '${protocolo ? '<protNFe versao="4.00"><infProt><chNFe>$_chave</chNFe>'
        '<dhRecbto>2026-11-17T14:20:05-03:00</dhRecbto><nProt>135260000000999</nProt><cStat>100</cStat>'
        '</infProt></protNFe>' : ''}</nfeProc>';

int _paginas(List<int> pdf) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(String.fromCharCodes(pdf)).length;

void main() {
  test('leitura dos dados', () {
    final d = DadosDanfeNfe.deXml(nfeXml());
    expect(d.numero, 456);
    expect(d.protocolo, '135260000000999');
    expect(d.emitente.nome, 'EMPRESA DE TESTE COMÉRCIO LTDA');
    expect(d.destinatario!.documento, '11144477735');
    expect(d.itens.first.cst, '000');
    expect(d.itens.first.valorIcms, 3.78);
    expect(d.itens.first.aliquotaIpi, 5);
    expect(d.duplicatas, hasLength(2));
    expect(d.total('vNF'), closeTo(66.15, 0.001));
    expect(d.modalidadeFrete, '0-Por conta do Rem');
    expect(d.dataEmissao.hour, 14);
  });

  test('PDF de uma folha', () async {
    final pdf = await DanfeNfe.deXml(nfeXml()).pdf();
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    expect(_paginas(pdf), 1);
  });

  test('muitos itens geram várias folhas', () async {
    final pdf = await DanfeNfe.deXml(nfeXml(itens: 80)).pdf();
    expect(_paginas(pdf), greaterThan(2));
  });

  test('contingência sem protocolo e cancelada geram PDF', () async {
    final a = await DanfeNfe.deXml(nfeXml(protocolo: false, tpEmis: '6', duplicatas: false)).pdf();
    final b = await DanfeNfe.deXml(nfeXml()).pdf(const OpcoesDanfeNfe(cancelada: true));
    expect(a.length, greaterThan(1000));
    expect(b.length, greaterThan(1000));
  });

  test('rejeita NFC-e', () {
    expect(() => DadosDanfeNfe.deXml(nfeXml().replaceFirst('<mod>55</mod>', '<mod>65</mod>')),
        throwsArgumentError);
  });

  // Gera amostras para conferência visual quando DFE_AMOSTRAS aponta para uma pasta.
  test('amostras', () async {
    final pasta = Platform.environment['DFE_AMOSTRAS'];
    if (pasta == null) return;
    File('$pasta/danfe_nfe_1folha.pdf').writeAsBytesSync(await DanfeNfe.deXml(nfeXml()).pdf());
    File('$pasta/danfe_nfe_varias.pdf').writeAsBytesSync(await DanfeNfe.deXml(nfeXml(itens: 45)).pdf());
  });
}
