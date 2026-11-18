import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _end = Endereco(
  logradouro: 'RUA TESTE', numero: '1', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

ItemNfe _item({
  Icms icms = const Csosn102(),
  PisCofins pis = const PisCofins.naoTributado(),
  PisCofins cofins = const PisCofins.naoTributado(),
  Ipi? ipi,
  double qtd = 2,
  double unit = 50,
  double desconto = 0,
  double frete = 0,
  double? tributos,
}) =>
    ItemNfe(
      codigo: '1', descricao: 'PRODUTO', ncm: '21069090', cfop: '5102', unidade: 'UN',
      quantidade: qtd, valorUnitario: unit, icms: icms, pis: pis, cofins: cofins, ipi: ipi,
      desconto: desconto, frete: frete, valorTributos: tributos,
    );

XmlDocument _nota(List<ItemNfe> itens, {List<Pagamento>? pag, ModeloDocumento m = ModeloDocumento.nfe, int crt = 3}) {
  final d = DadosNfe(
    modelo: m,
    ambiente: Ambiente.homologacao,
    serie: 1,
    numero: 1,
    codigoNumerico: 12345678,
    emitente: Emitente(
        cnpj: '12345678000195', razaoSocial: 'EMPRESA', inscricaoEstadual: '111', endereco: _end, crt: crt),
    destinatario: m == ModeloDocumento.nfe
        ? const Destinatario(nome: 'CLIENTE', cpf: '11144477735', endereco: _end)
        : null,
    itens: itens,
    pagamentos: pag ?? [Pagamento(tipo: '01', valor: TotaisNfe.calcular(itens).vNF)],
  );
  return XmlDocument.parse(EmissorNfe(_cert).gerar(d).xmlAssinado);
}

List<String> _filhos(XmlDocument x, String grupo) =>
    x.findAllElements(grupo).single.childElements.map((e) => e.name.local).toList();
String _tot(XmlDocument x, String campo) =>
    x.findAllElements('ICMSTot').single.getElement(campo)!.innerText;

void main() {
  group('ICMS regime normal', () {
    test('CST 00: ordem dos campos, valores e totais', () {
      final x = _nota([_item(icms: const Icms00(aliquota: 18))]);
      expect(_filhos(x, 'ICMS00'), ['orig', 'CST', 'modBC', 'vBC', 'pICMS', 'vICMS']);
      expect(x.findAllElements('vICMS').first.innerText, '18.00');
      expect(_tot(x, 'vBC'), '100.00');
      expect(_tot(x, 'vICMS'), '18.00');
    });

    test('CST 10 com MVA: ST = base×(1+MVA)×alíq. ST − ICMS próprio, soma no vNF', () {
      final x = _nota([_item(icms: const Icms10(aliquota: 18, aliquotaSt: 18, mva: 40))]);
      expect(_filhos(x, 'ICMS10'), [
        'orig', 'CST', 'modBC', 'vBC', 'pICMS', 'vICMS', 'modBCST', 'pMVAST', 'vBCST', 'pICMSST', 'vICMSST'
      ]);
      // base ST = 140,00; ST = 25,20 − 18,00 = 7,20
      expect(_tot(x, 'vBCST'), '140.00');
      expect(_tot(x, 'vST'), '7.20');
      expect(_tot(x, 'vNF'), '107.20');
    });

    test('CST 20 reduz a base', () {
      final x = _nota([_item(icms: const Icms20(aliquota: 18, reducao: 33.33))]);
      expect(_filhos(x, 'ICMS20'), ['orig', 'CST', 'modBC', 'pRedBC', 'vBC', 'pICMS', 'vICMS']);
      expect(_tot(x, 'vBC'), '66.67');
      expect(_tot(x, 'vICMS'), '12.00');
    });

    test('CST 41 e 60 não somam ICMS', () {
      final x = _nota([
        _item(icms: const Icms40(cst: '41')),
        _item(icms: const Icms60(baseStRetido: 80, aliquotaStRetido: 18, icmsStRetido: 14.4)),
      ]);
      expect(x.findAllElements('ICMS40').single.getElement('CST')!.innerText, '41');
      expect(_filhos(x, 'ICMS60'), ['orig', 'CST', 'vBCSTRet', 'pST', 'vICMSSTRet']);
      expect(_tot(x, 'vICMS'), '0.00');
      expect(_tot(x, 'vNF'), '200.00');
    });
  });

  group('Simples Nacional', () {
    test('CSOSN 101 com crédito', () {
      final x = _nota([_item(icms: const Csosn101(aliquotaCredito: 2.56))], crt: 1);
      expect(_filhos(x, 'ICMSSN101'), ['orig', 'CSOSN', 'pCredSN', 'vCredICMSSN']);
      expect(x.findAllElements('vCredICMSSN').single.innerText, '2.56');
    });

    test('CSOSN 201 desconta o ICMS próprio pela alíquota interna', () {
      final x = _nota([_item(icms: const Csosn201(aliquotaSt: 18, aliquotaInterna: 18, mva: 40, aliquotaCredito: 1.25))],
          crt: 1);
      expect(_filhos(x, 'ICMSSN201'),
          ['orig', 'CSOSN', 'modBCST', 'pMVAST', 'vBCST', 'pICMSST', 'vICMSST', 'pCredSN', 'vCredICMSSN']);
      expect(_tot(x, 'vST'), '7.20');
      expect(_tot(x, 'vNF'), '107.20');
    });

    test('CSOSN 202 usa o grupo ICMSSN202, 500 e 900', () {
      final x = _nota([
        _item(icms: const Csosn201(csosn: '202', aliquotaSt: 18, aliquotaInterna: 18, mva: 40)),
        _item(icms: const Csosn500()),
        _item(icms: const Csosn900()),
      ], crt: 1);
      expect(x.findAllElements('ICMSSN202').single.getElement('CSOSN')!.innerText, '202');
      expect(_filhos(x, 'ICMSSN500'), ['orig', 'CSOSN']);
      expect(_filhos(x, 'ICMSSN900'), ['orig', 'CSOSN']);
    });
  });

  group('PIS, COFINS e IPI', () {
    test('alíquota (CST 01) e totais', () {
      final x = _nota([
        _item(
          pis: const PisCofins.aliquota(aliquota: 1.65),
          cofins: const PisCofins.aliquota(aliquota: 7.6),
          ipi: const Ipi.tributado(aliquota: 10),
        ),
      ]);
      expect(_filhos(x, 'PISAliq'), ['CST', 'vBC', 'pPIS', 'vPIS']);
      expect(_filhos(x, 'COFINSAliq'), ['CST', 'vBC', 'pCOFINS', 'vCOFINS']);
      expect(_tot(x, 'vPIS'), '1.65');
      expect(_tot(x, 'vCOFINS'), '7.60');
      expect(_tot(x, 'vIPI'), '10.00');
      expect(_tot(x, 'vNF'), '110.00');
      // ordem dentro de imposto: ICMS, IPI, PIS, COFINS
      final imposto = x.findAllElements('imposto').single.childElements.map((e) => e.name.local);
      expect(imposto, ['ICMS', 'IPI', 'PIS', 'COFINS']);
    });

    test('outros (CST 99) sem alíquota e IPI não tributado', () {
      final x = _nota([_item(pis: const PisCofins.outros(), ipi: const Ipi.naoTributado())]);
      expect(_filhos(x, 'PISOutr'), ['CST', 'vBC', 'pPIS', 'vPIS']);
      expect(x.findAllElements('IPINT').single.getElement('CST')!.innerText, '53');
    });

    test('NFC-e não aceita IPI', () {
      expect(() => _nota([_item(ipi: const Ipi.tributado(aliquota: 5))], m: ModeloDocumento.nfce),
          throwsArgumentError);
    });
  });

  group('Valores do item e totais', () {
    test('desconto e frete entram na base e no vNF; vTotTrib somado', () {
      final x = _nota([
        _item(icms: const Icms00(aliquota: 18), desconto: 10, frete: 5, tributos: 12.34),
        _item(icms: const Icms00(aliquota: 18), tributos: 1),
      ]);
      final prod = x.findAllElements('prod').first.childElements.map((e) => e.name.local).toList();
      expect(prod.sublist(prod.indexOf('vUnTrib')), ['vUnTrib', 'vFrete', 'vDesc', 'indTot']);
      expect(_tot(x, 'vDesc'), '10.00');
      expect(_tot(x, 'vFrete'), '5.00');
      expect(_tot(x, 'vBC'), '195.00');
      expect(_tot(x, 'vNF'), '195.00');
      expect(_tot(x, 'vTotTrib'), '13.34');
      expect(x.findAllElements('imposto').first.firstElementChild!.name.local, 'vTotTrib');
    });

    test('rateio de desconto fecha o valor exato', () {
      final itens = [_item(unit: 10, qtd: 1), _item(unit: 20, qtd: 1), _item(unit: 3.33, qtd: 1)];
      final partes = ratear(5, itens);
      expect(partes.fold<double>(0, (s, p) => s + p), closeTo(5, 1e-9));
      expect(partes.first, closeTo(1.50, 1e-9));
    });
  });

  group('Pagamentos', () {
    test('cartão gera card (tpIntegra 2 sem dados) e troco sobre o vNF', () {
      final x = _nota([_item()], pag: const [
        Pagamento(tipo: '03', valor: 60, cartao: Cartao(bandeira: '01', autorizacao: '123456')),
        Pagamento(tipo: '17', valor: 30),
        Pagamento(tipo: '01', valor: 20),
      ]);
      final cards = x.findAllElements('card').toList();
      expect(cards, hasLength(2));
      expect(cards.first.childElements.map((e) => e.name.local), ['tpIntegra', 'tBand', 'cAut']);
      expect(cards.last.getElement('tpIntegra')!.innerText, '2');
      expect(x.findAllElements('vTroco').single.innerText, '10.00');
    });

    test('pagamento insuficiente e tPag 99 sem descrição são rejeitados', () {
      expect(() => _nota([_item()], pag: const [Pagamento(tipo: '01', valor: 50)]), throwsArgumentError);
      expect(() => _nota([_item()], pag: const [Pagamento(tipo: '99', valor: 100)]), throwsArgumentError);
      final x = _nota([_item()], pag: const [Pagamento(tipo: '99', valor: 100, descricao: 'VALE')]);
      expect(x.findAllElements('xPag').single.innerText, 'VALE');
    });
  });

  test('assinatura continua válida com tributação completa', () {
    final d = DadosNfe(
      modelo: ModeloDocumento.nfe,
      ambiente: Ambiente.homologacao,
      serie: 1,
      numero: 1,
      emitente: const Emitente(cnpj: '12345678000195', razaoSocial: 'E', inscricaoEstadual: '1', endereco: _end, crt: 3),
      destinatario: const Destinatario(nome: 'C', cpf: '11144477735', endereco: _end),
      itens: [_item(icms: const Icms10(aliquota: 18, aliquotaSt: 18, mva: 40), ipi: const Ipi.tributado(aliquota: 5))],
      pagamentos: const [Pagamento(tipo: '15', valor: 112.20)],
    );
    expect(verificarAssinatura(EmissorNfe(_cert).gerar(d).xmlAssinado).valido, isTrue);
  });
}
