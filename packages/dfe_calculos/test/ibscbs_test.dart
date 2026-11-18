import 'dart:io';

import 'package:dfe_calculos/dfe_calculos.dart';
import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _end = Endereco(
  logradouro: 'RUA', numero: '1', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

List<String> _filhos(XmlElement e) => e.childElements.map((c) => c.name.local).toList();

XmlDocument _nota(List<ItemNfe> itens) {
  final total = calcularTotais(itens);
  final crt = itens.any((i) => i.imposto.icms?.dados.csosn != null) ? 1 : 3;
  final d = DadosNfe(
    modelo: ModeloDocumento.nfe,
    ambiente: Ambiente.homologacao,
    serie: 1,
    numero: 1,
    codigoNumerico: 12345678,
    emitente: Emitente(cnpj: '12345678000195', razaoSocial: 'E', inscricaoEstadual: '1', endereco: _end, crt: crt),
    destinatario: const Destinatario(nome: 'C', cpf: '11144477735', endereco: _end),
    itens: itens,
    total: total,
    pagamentos: [Pagamento(tipo: '01', valor: total.vNF)],
  );
  return XmlDocument.parse(EmissorNfe(_cert).gerar(d).xmlAssinado);
}

ItemNfe _item(
        {RegraIbsCbs? ibsCbs,
        RegraIcms icms = const RegraCsosn102(),
        RegraPisCofins pc = const RegraPisCofins.naoTributado()}) =>
    calcularItem(
      codigo: '1', descricao: 'P', ncm: '21069090', cfop: '5102', unidade: 'UN',
      quantidade: 1, valorUnitario: 100, icms: icms, pis: pc, cofins: pc, ibsCbs: ibsCbs,
    );

void main() {
  test('grupo do item na ordem do schema e por último no imposto', () {
    final x = _nota([_item(ibsCbs: const RegraIbsCbs(classificacao: '000001'))]);
    final imposto = x.findAllElements('imposto').single;
    expect(_filhos(imposto).last, 'IBSCBS');
    final g = imposto.getElement('IBSCBS')!;
    expect(_filhos(g), ['CST', 'cClassTrib', 'gIBSCBS']);
    expect(_filhos(g.getElement('gIBSCBS')!), ['vBC', 'gIBSUF', 'gIBSMun', 'vIBS', 'gCBS']);
    expect(g.findAllElements('vIBSUF').single.innerText, '0.10');
    expect(g.findAllElements('vCBS').single.innerText, '0.90');
  });

  test('base desconta ICMS, PIS e COFINS; valores não entram no vNF', () {
    final x = _nota([
      _item(
        icms: const RegraIcms00(aliquota: 18),
        pc: const RegraPisCofins.aliquota(aliquota: 1),
        ibsCbs: const RegraIbsCbs(classificacao: '000001'),
      ),
    ]);
    // 100 − 18 (ICMS) − 1 (PIS) − 1 (COFINS) = 80
    expect(x.findAllElements('gIBSCBS').single.getElement('vBC')!.innerText, '80.00');
    final tot = x.findAllElements('IBSCBSTot').single;
    expect(_filhos(tot), ['vBCIBSCBS', 'gIBS', 'gCBS']);
    expect(tot.getElement('vBCIBSCBS')!.innerText, '80.00');
    expect(tot.findAllElements('vCBS').single.innerText, '0.72');
    expect(x.findAllElements('vNF').single.innerText, '100.00');
    expect(_filhos(x.findAllElements('total').single), ['ICMSTot', 'IBSCBSTot']);
  });

  test('CST sem cálculo só leva CST e cClassTrib; sem grupo nos itens não há IBSCBSTot', () {
    final x = _nota([_item(ibsCbs: const RegraIbsCbs.semCalculo(cst: '410', classificacao: '410001'))]);
    expect(_filhos(x.findAllElements('IBSCBS').single), ['CST', 'cClassTrib']);
    expect(_nota([_item()]).findAllElements('IBSCBSTot'), isEmpty);
  });
}
