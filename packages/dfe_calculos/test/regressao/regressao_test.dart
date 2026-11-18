// Regressão da refatoração "emissão anêmica + dfe_calculos".
//
// Os XMLs em esperado/ foram gerados ANTES da refatoração (commit 3032a99),
// quando os cálculos ficavam dentro da emissão. Aqui os mesmos cenários são
// montados com a API nova (valores informados) + dfe_calculos, e o XML tem
// que sair idêntico.
import 'dart:io';

import 'package:dfe_calculos/dfe_calculos.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';

const _end = Endereco(
  logradouro: 'RUA TESTE', numero: '100', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

ItemNfe _item(String cod, double qtd, double unit,
        {RegraIcms icms = const RegraCsosn102(),
        RegraPisCofins pis = const RegraPisCofins.naoTributado(),
        RegraPisCofins cofins = const RegraPisCofins.naoTributado(),
        RegraIpi? ipi,
        double desconto = 0,
        double frete = 0,
        double? tributos,
        RegraIbsCbs? ibsCbs}) =>
    calcularItem(
      codigo: cod, descricao: 'PRODUTO $cod', ncm: '21069090', cfop: '5102', unidade: 'UN',
      quantidade: qtd, valorUnitario: unit, icms: icms, pis: pis, cofins: cofins, ipi: ipi,
      desconto: desconto, frete: frete, valorTributos: tributos, ibsCbs: ibsCbs,
    );

/// Mesmo fluxo que a emissão fazia sozinha antes: totais, card padrão, troco
/// e textos de homologação — agora explícitos, via dfe_calculos.
DadosNfe _nota(ModeloDocumento m, int crt, List<ItemNfe> itens, List<Pagamento> pag,
    {TipoEmissao tp = TipoEmissao.normal}) {
  final total = calcularTotais(itens);
  final d = DadosNfe(
    modelo: m,
    ambiente: Ambiente.homologacao,
    serie: 1,
    numero: 10,
    codigoNumerico: 12345678,
    dataEmissao: DateTime(2026, 11, 17, 10, 30),
    tipoEmissao: tp,
    justificativaContingencia: tp.contingencia ? 'TESTE DE CONTINGENCIA EM HOMOLOGACAO' : null,
    emitente: Emitente(
        cnpj: '12345678000195', razaoSocial: 'EMPRESA TESTE', inscricaoEstadual: '111111111111',
        endereco: _end, crt: crt),
    destinatario: m == ModeloDocumento.nfe
        ? const Destinatario(nome: 'CLIENTE', cpf: '11144477735', endereco: _end)
        : null,
    itens: itens,
    total: total,
    pagamentos: comCartaoPadrao(pag),
    troco: calcularTroco(pag, total.vNF),
    informacoesComplementares: 'CENARIO DE REGRESSAO',
  );
  return aplicarTextosHomologacao(d);
}

Map<String, DadosNfe> _cenarios() {
  final rateio = ratear(5, [10, 25]);
  return {
    'nfce_sn102_dinheiro': _nota(ModeloDocumento.nfce, 1, [_item('1', 1, 10), _item('2', 2, 12.5)],
        const [Pagamento(tipo: '01', valor: 40)]),
    'nfce_sn101_pix_offline': _nota(
        ModeloDocumento.nfce, 1, [_item('1', 3, 7.99, icms: const RegraCsosn101(aliquotaCredito: 2.56))],
        const [Pagamento(tipo: '17', valor: 23.97)],
        tp: TipoEmissao.offlineNfce),
    'nfe_cst00_pis_cofins_credito_desconto': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 1, 10,
          icms: const RegraIcms00(aliquota: 18),
          pis: const RegraPisCofins.aliquota(aliquota: 1.65),
          cofins: const RegraPisCofins.aliquota(aliquota: 7.6),
          desconto: rateio[0],
          tributos: 1.35),
      _item('2', 2, 12.5,
          icms: const RegraIcms00(aliquota: 18),
          pis: const RegraPisCofins.aliquota(aliquota: 1.65),
          cofins: const RegraPisCofins.aliquota(aliquota: 7.6),
          desconto: rateio[1],
          tributos: 3.36),
    ], const [
      Pagamento(tipo: '03', valor: 30, cartao: Cartao(bandeira: '01', autorizacao: '123456'))
    ]),
    'nfe_cst10_ipi_frete': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 2, 50,
          icms: const RegraIcms10(aliquota: 18, aliquotaSt: 18, mva: 40),
          ipi: const RegraIpi.tributado(aliquota: 5),
          frete: 10),
    ], const [
      Pagamento(tipo: '15', valor: 200)
    ]),
    'nfe_cst20_40_60': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 1, 100, icms: const RegraIcms20(aliquota: 18, reducao: 33.33)),
      _item('2', 1, 50, icms: const RegraIcms40(cst: '41')),
      _item('3', 1, 30, icms: const RegraIcms60(baseStRetido: 25, aliquotaStRetido: 18, icmsStRetido: 4.5)),
    ], const [
      Pagamento(tipo: '01', valor: 180)
    ]),
    'nfe_sn201_202_500_900_svc': _nota(
        ModeloDocumento.nfe,
        1,
        [
          _item('1', 1, 100,
              icms: const RegraCsosn201(aliquotaSt: 18, aliquotaInterna: 18, mva: 40, aliquotaCredito: 1.25)),
          _item('2', 1, 100,
              icms: const RegraCsosn201(csosn: '202', aliquotaSt: 18, aliquotaInterna: 18, mva: 40)),
          _item('3', 1, 20, icms: const RegraCsosn500()),
          _item('4', 1, 20, icms: const RegraCsosn900(), pis: const RegraPisCofins.outros(cst: '49')),
        ],
        const [Pagamento(tipo: '01', valor: 300)],
        tp: TipoEmissao.svcAn),
    'nfe_ibscbs_cst00': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 1, 100,
          icms: const RegraIcms00(aliquota: 18),
          pis: const RegraPisCofins.aliquota(aliquota: 1.65),
          cofins: const RegraPisCofins.aliquota(aliquota: 7.6),
          ibsCbs: const RegraIbsCbs(classificacao: '000001')),
      // Corrigido: o cenário antigo usava CSOSN 102 com CRT 3 (combinação que o Zeus recusa).
      _item('2', 1, 50,
          icms: const RegraIcms40(cst: '41'),
          ibsCbs: const RegraIbsCbs.semCalculo(cst: '410', classificacao: '410001')),
    ], const [
      Pagamento(tipo: '17', valor: 150)
    ]),
  };
}

void main() {
  for (final MapEntry(key: nome, value: dados) in _cenarios().entries) {
    test('XML idêntico ao anterior à refatoração: $nome', () {
      expect(validarNfe(dados), isEmpty);
      final esperado = File('test/regressao/esperado/$nome.xml').readAsStringSync();
      expect(montarNfe(dados).xml, esperado);
    });
  }
}
