import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

const _end = Endereco(
  logradouro: 'RUA', numero: '1', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

const _item = ItemNfe(
  codigo: '1', descricao: 'P', ncm: '21069090', cfop: '1202', unidade: 'UN',
  quantidade: 1, valorUnitario: 10, valorTotal: 10,
  imposto: ImpostoItem(
    icms: Icms(IcmsGeral(orig: '0', csosn: '102')),
    pis: PisGeral(cst: '07'),
    cofins: CofinsGeral(cst: '07'),
  ),
);

const _total = TotalNfe(
  icmsTot: IcmsTot(
    vBC: 0, vICMS: 0, vBCST: 0, vST: 0, vProd: 10, vFrete: 0, vSeg: 0, vDesc: 0, vII: 0, vIPI: 0,
    vPIS: 0, vCOFINS: 0, vOutro: 0, vNF: 10,
  ),
);

List<String> _filhos(XmlElement e) => e.childElements.map((c) => c.name.local).toList();

void main() {
  group("grupos complementares", _maisCampos);
  final m = montarNfe(DadosNfe(
    modelo: ModeloDocumento.nfe,
    ambiente: Ambiente.homologacao,
    serie: 1,
    numero: 7,
    codigoNumerico: 12345678,
    dataEmissao: DateTime(2026, 11, 18, 10),
    dataSaidaEntrada: DateTime(2026, 11, 18, 11),
    tipoOperacao: 0,
    finalidade: 4,
    indicadorIntermediador: 1,
    naturezaOperacao: 'DEVOLUCAO DE VENDA',
    referencias: const [
      ReferenciaNfe.chave('35261112345678000195550010000000011123456789'),
      ReferenciaNfe.cupomEcf(modelo: '2D', numeroEcf: 1, coo: 123),
    ],
    emitente: const Emitente(cnpj: '12345678000195', razaoSocial: 'E', inscricaoEstadual: '1', endereco: _end),
    destinatario: const Destinatario(
        nome: 'CLIENTE', cnpj: '98765432000198', endereco: _end, indIEDest: 1, ie: '222', email: 'c@c.com'),
    retirada: const LocalNfe(
        cnpj: '98765432000198', logradouro: 'RUA A', numero: '2', bairro: 'B', codigoMunicipio: 3550308,
        municipio: 'SAO PAULO', uf: 'SP'),
    entrega: const LocalNfe(
        cpf: '11144477735', nome: 'FULANO', logradouro: 'RUA C', numero: '3', bairro: 'D',
        codigoMunicipio: 3550308, municipio: 'SAO PAULO', uf: 'SP', cep: '01002000'),
    autorizadosXml: const ['11111111000191', '11144477735'],
    itens: const [_item],
    total: _total,
    transporte: const Transporte(
      modalidadeFrete: 0,
      transportadora: Transportadora(cnpj: '33333333000191', nome: 'TRANSP', uf: 'SP'),
      veiculo: Veiculo(placa: 'ABC1D23', uf: 'SP'),
      volumes: [Volume(quantidade: 2, especie: 'CAIXA', pesoLiquido: 1.5, pesoBruto: 2)],
    ),
    cobranca: Cobranca(
      fatura: const Fatura(numero: '7', valorOriginal: 10, desconto: 0, valorLiquido: 10),
      duplicatas: [Duplicata(numero: '001', vencimento: DateTime(2026, 12, 18), valor: 10)],
    ),
    pagamentos: const [Pagamento(tipo: '90', valor: 0)],
    intermediador: const Intermediador(cnpj: '44444444000191', identificador: 'LOJA123'),
    informacoesComplementares: 'TESTE',
  ));
  final x = XmlDocument.parse(m.xml);
  final inf = x.findAllElements('infNFe').single;

  test('ordem dos grupos do infNFe (schema/Zeus)', () {
    expect(_filhos(inf), [
      'ide', 'emit', 'dest', 'retirada', 'entrega', 'autXML', 'autXML', 'det', 'total', 'transp', 'cobr',
      'pag', 'infIntermed', 'infAdic',
    ]);
  });

  test('ide: dhSaiEnt, tpNF de entrada, finalidade, indIntermed e NFref ao final', () {
    final ide = inf.getElement('ide')!;
    final f = _filhos(ide);
    expect(f.indexOf('dhSaiEnt'), f.indexOf('dhEmi') + 1);
    expect(ide.getElement('tpNF')!.innerText, '0');
    expect(ide.getElement('finNFe')!.innerText, '4');
    expect(f.indexOf('indIntermed'), f.indexOf('indPres') + 1);
    expect(f.sublist(f.length - 2), ['NFref', 'NFref']);
    expect(ide.findAllElements('refNFe').single.innerText, '35261112345678000195550010000000011123456789');
    expect(_filhos(ide.findAllElements('refECF').single), ['mod', 'nECF', 'nCOO']);
  });

  test('dest com IE e grupos de retirada/entrega/autXML', () {
    expect(_filhos(inf.getElement('dest')!), ['CNPJ', 'xNome', 'enderDest', 'indIEDest', 'IE', 'email']);
    expect(_filhos(inf.getElement('retirada')!).first, 'CNPJ');
    expect(_filhos(inf.getElement('entrega')!),
        ['CPF', 'xNome', 'xLgr', 'nro', 'xBairro', 'cMun', 'xMun', 'UF', 'CEP', 'cPais', 'xPais']);
    expect(inf.findElements('autXML').map((a) => _filhos(a).single), ['CNPJ', 'CPF']);
  });

  test('transporte, cobrança e intermediador', () {
    final transp = inf.getElement('transp')!;
    expect(_filhos(transp), ['modFrete', 'transporta', 'veicTransp', 'vol']);
    expect(transp.findAllElements('pesoL').single.innerText, '1.500');
    final cobr = inf.getElement('cobr')!;
    expect(_filhos(cobr), ['fat', 'dup']);
    expect(cobr.findAllElements('dVenc').single.innerText, '2026-12-18');
    expect(_filhos(inf.getElement('infIntermed')!), ['CNPJ', 'idCadIntTran']);
  });
}

void _maisCampos() {
  final m = montarNfe(DadosNfe(
    modelo: ModeloDocumento.nfe,
    ambiente: Ambiente.homologacao,
    serie: 1,
    numero: 8,
    codigoNumerico: 12345678,
    dataEmissao: DateTime(2026, 11, 18, 10),
    finalidade: 1,
    municipioFatoGeradorIbs: 3550308,
    codigoIndicadorOperacao: '010104',
    compraGovernamental: const GCompraGov(tpEnteGov: '1', pRedutor: 10, tpOperGov: '1'),
    pagamentoAntecipado: const ['35261112345678000195550010000000011123456789'],
    emitente: const Emitente(cnpj: '12345678000195', razaoSocial: 'E', inscricaoEstadual: '1', endereco: _end),
    itens: const [_item],
    total: _total,
    pagamentos: const [Pagamento(tipo: '90', valor: 0)],
    transporte: const Transporte(
      modalidadeFrete: 0,
      retencao: RetTransp(vServ: 100, vBCRet: 100, pICMSRet: 12, vICMSRet: 12, cfop: 5352, cMunFG: 3550308),
      veiculo: Veiculo(placa: 'ABC1D23'),
      reboques: [Reboque(placa: 'XYZ9A87', uf: 'SP')],
      volumes: [Volume(quantidade: 1, lacres: ['L1', 'L2'])],
    ),
    informacoesComplementares: 'X',
    exportacao: const Exporta(ufSaidaPais: 'SP', xLocExporta: 'SANTOS'),
    compra: const Compra(xPed: 'PED1'),
    cana: Cana(
      safra: '2026/2027', ref: '11/2026', qTotMes: 10, qTotAnt: 0, qTotGer: 10, vFor: 100, vTotDed: 0,
      vLiqFor: 100, forDia: const [ForDia(dia: 1, qtde: 10)],
    ),
    agropecuario: const Agropecuario(defensivo: [Defensivo(nReceituario: 'R1', cpfRespTec: '11144477735')]),
  ));
  final inf = XmlDocument.parse(m.xml).findAllElements('infNFe').single;

  test('ide: cMunFGIBS, cIndOp, gCompraGov e gPagAntecipado', () {
    final f = _filhos(inf.getElement('ide')!);
    expect(f.indexOf('cMunFGIBS'), f.indexOf('cMunFG') + 1);
    expect(f.indexOf('cIndOp'), f.indexOf('indPres') + 1);
    expect(f.sublist(f.length - 2), ['gCompraGov', 'gPagAntecipado']);
  });

  test('transp com retTransp, reboque e lacres', () {
    final t = inf.getElement('transp')!;
    expect(_filhos(t), ['modFrete', 'retTransp', 'veicTransp', 'reboque', 'vol']);
    expect(_filhos(t.getElement('vol')!), ['qVol', 'lacres', 'lacres']);
  });

  test('exporta, compra, cana (forDia com atributo) e agropecuário', () {
    expect(_filhos(inf), [
      'ide', 'emit', 'det', 'total', 'transp', 'pag', 'infAdic', 'exporta', 'compra', 'cana', 'agropecuario',
    ]);
    final fd = inf.findAllElements('forDia').single;
    expect(fd.getAttribute('dia'), '1');
    expect(_filhos(fd), ['qtde']);
    expect(_filhos(inf.getElement('agropecuario')!.getElement('defensivo')!), ['nReceituario', 'CPFRespTec']);
  });
}
