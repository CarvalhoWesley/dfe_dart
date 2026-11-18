// Cenários montados com a API ANTERIOR à refatoração (cálculo dentro dos
// grupos). Usados uma única vez para gravar os XMLs de referência em
// test/regressao/esperado/. Depois da refatoração, regressao_test.dart monta os
// mesmos cenários com a API nova + dfe_calculos e exige XML idêntico.
import 'package:dfe_nfe/dfe_nfe.dart';

const enderecoTeste = Endereco(
  logradouro: 'RUA TESTE', numero: '100', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

ItemNfe _item(String cod, double qtd, double unit,
        {Icms icms = const Csosn102(),
        PisCofins pis = const PisCofins.naoTributado(),
        PisCofins cofins = const PisCofins.naoTributado(),
        Ipi? ipi,
        double desconto = 0,
        double frete = 0,
        double? tributos,
        IbsCbs? ibsCbs}) =>
    ItemNfe(
      codigo: cod, descricao: 'PRODUTO $cod', ncm: '21069090', cfop: '5102', unidade: 'UN',
      quantidade: qtd, valorUnitario: unit, icms: icms, pis: pis, cofins: cofins, ipi: ipi,
      desconto: desconto, frete: frete, valorTributos: tributos, ibsCbs: ibsCbs,
    );

DadosNfe _nota(ModeloDocumento m, int crt, List<ItemNfe> itens, List<Pagamento> pag,
        {TipoEmissao tp = TipoEmissao.normal}) =>
    DadosNfe(
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
          endereco: enderecoTeste, crt: crt),
      destinatario: m == ModeloDocumento.nfe
          ? const Destinatario(nome: 'CLIENTE', cpf: '11144477735', endereco: enderecoTeste)
          : null,
      itens: itens,
      pagamentos: pag,
      informacoesComplementares: 'CENARIO DE REGRESSAO',
    );

/// Nome do cenário → dados (API legada).
Map<String, DadosNfe> cenariosLegado() {
  final itensDesc = [_item('1', 1, 10), _item('2', 2, 12.5)];
  final rateio = ratear(5, itensDesc);
  return {
    'nfce_sn102_dinheiro': _nota(ModeloDocumento.nfce, 1, [_item('1', 1, 10), _item('2', 2, 12.5)],
        const [Pagamento(tipo: '01', valor: 40)]),
    'nfce_sn101_pix_offline': _nota(
        ModeloDocumento.nfce, 1, [_item('1', 3, 7.99, icms: const Csosn101(aliquotaCredito: 2.56))],
        const [Pagamento(tipo: '17', valor: 23.97)],
        tp: TipoEmissao.offlineNfce),
    'nfe_cst00_pis_cofins_credito_desconto': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 1, 10,
          icms: const Icms00(aliquota: 18),
          pis: const PisCofins.aliquota(aliquota: 1.65),
          cofins: const PisCofins.aliquota(aliquota: 7.6),
          desconto: rateio[0],
          tributos: 1.35),
      _item('2', 2, 12.5,
          icms: const Icms00(aliquota: 18),
          pis: const PisCofins.aliquota(aliquota: 1.65),
          cofins: const PisCofins.aliquota(aliquota: 7.6),
          desconto: rateio[1],
          tributos: 3.36),
    ], const [
      Pagamento(tipo: '03', valor: 30, cartao: Cartao(bandeira: '01', autorizacao: '123456'))
    ]),
    'nfe_cst10_ipi_frete': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 2, 50,
          icms: const Icms10(aliquota: 18, aliquotaSt: 18, mva: 40),
          ipi: const Ipi.tributado(aliquota: 5),
          frete: 10),
    ], const [
      Pagamento(tipo: '15', valor: 200)
    ]),
    'nfe_cst20_40_60': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 1, 100, icms: const Icms20(aliquota: 18, reducao: 33.33)),
      _item('2', 1, 50, icms: const Icms40(cst: '41')),
      _item('3', 1, 30, icms: const Icms60(baseStRetido: 25, aliquotaStRetido: 18, icmsStRetido: 4.5)),
    ], const [
      Pagamento(tipo: '01', valor: 180)
    ]),
    'nfe_sn201_202_500_900_svc': _nota(
        ModeloDocumento.nfe,
        1,
        [
          _item('1', 1, 100,
              icms: const Csosn201(aliquotaSt: 18, aliquotaInterna: 18, mva: 40, aliquotaCredito: 1.25)),
          _item('2', 1, 100, icms: const Csosn201(csosn: '202', aliquotaSt: 18, aliquotaInterna: 18, mva: 40)),
          _item('3', 1, 20, icms: const Csosn500()),
          _item('4', 1, 20, icms: const Csosn900(), pis: const PisCofins.outros(cst: '49')),
        ],
        const [Pagamento(tipo: '01', valor: 300)],
        tp: TipoEmissao.svcAn),
    'nfe_ibscbs_cst00': _nota(ModeloDocumento.nfe, 3, [
      _item('1', 1, 100,
          icms: const Icms00(aliquota: 18),
          pis: const PisCofins.aliquota(aliquota: 1.65),
          cofins: const PisCofins.aliquota(aliquota: 7.6),
          ibsCbs: const IbsCbs(classificacao: '000001')),
      _item('2', 1, 50, ibsCbs: const IbsCbs.semCalculo(cst: '410', classificacao: '410001')),
    ], const [
      Pagamento(tipo: '17', valor: 150)
    ]),
  };
}
