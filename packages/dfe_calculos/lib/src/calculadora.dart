// Ferramentas de cálculo e conferência da nota. NÃO EXISTEM NO ZEUS: são um
// extra do dfe_dart, opcional. A emissão (dfe_nfe) não depende delas.
import 'package:dfe_nfe/dfe_nfe.dart';

import 'regras.dart';

/// Monta um [ItemNfe] calculando vProd e os tributos a partir das regras.
///
/// Base de cálculo: vProd − vDesc + vFrete + vSeg + vOutro. A base do IBS/CBS
/// (transição) desconta ainda ICMS, FCP, PIS e COFINS.
ItemNfe calcularItem({
  required String codigo,
  required String descricao,
  required String ncm,
  required String cfop,
  required String unidade,
  required double quantidade,
  required double valorUnitario,
  RegraIcms icms = const RegraCsosn102(),
  RegraPisCofins pis = const RegraPisCofins.naoTributado(),
  RegraPisCofins cofins = const RegraPisCofins.naoTributado(),
  RegraIpi? ipi,
  RegraIbsCbs? ibsCbs,
  double desconto = 0,
  double frete = 0,
  double seguro = 0,
  double outrasDespesas = 0,
  double? valorTributos,
  String gtin = 'SEM GTIN',
  String? cest,
  String? codigoBeneficio,
}) {
  final vProd = arredondar(quantidade * valorUnitario);
  final base = arredondar(vProd - desconto + frete + seguro + outrasDespesas);
  final grupoIcms = icms.gerar(base);
  final grupoPis = pis.pis(base);
  final grupoCofins = cofins.cofins(base);
  final baseIbsCbs = arredondar(base -
      (grupoIcms.dados.vICMS ?? 0) -
      (grupoIcms.dados.vFCP ?? 0) -
      (grupoPis.vPIS ?? 0) -
      (grupoCofins.vCOFINS ?? 0));
  return ItemNfe(
    codigo: codigo,
    descricao: descricao,
    ncm: ncm,
    cfop: cfop,
    unidade: unidade,
    quantidade: quantidade,
    valorUnitario: valorUnitario,
    valorTotal: vProd,
    gtin: gtin,
    cest: cest,
    codigoBeneficio: codigoBeneficio,
    desconto: desconto,
    frete: frete,
    seguro: seguro,
    outrasDespesas: outrasDespesas,
    imposto: ImpostoItem(
      vTotTrib: valorTributos,
      icms: grupoIcms,
      ipi: ipi?.gerar(base),
      pis: grupoPis,
      cofins: grupoCofins,
      ibsCbs: ibsCbs?.gerar(baseIbsCbs),
    ),
  );
}

/// Totaliza a nota a partir dos valores **informados nos itens**.
///
/// vNF = vProd − vDesc − vICMSDeson + vST + vFCPST + vFrete + vSeg + vOutro + vII + vIPI + vIPIDevol.
/// Em 2026 o IBS/CBS não entra no vNF.
TotalNfe calcularTotais(List<ItemNfe> itens) {
  double vBC = 0, vICMS = 0, vICMSDeson = 0, vFCP = 0, vBCST = 0, vST = 0, vFCPST = 0, vFCPSTRet = 0;
  double vProd = 0, vFrete = 0, vSeg = 0, vDesc = 0, vOutro = 0, vII = 0, vIPI = 0, vPIS = 0, vCOFINS = 0;
  double vTotTrib = 0;
  double ibsBase = 0, ibsUf = 0, ibsMun = 0, cbs = 0;
  var temIbsCbs = false;

  for (final it in itens) {
    final imp = it.imposto;
    final icms = imp.icms?.dados;
    if (icms != null) {
      vBC += icms.vBC ?? 0;
      vICMS += icms.vICMS ?? 0;
      vICMSDeson += icms.vICMSDeson ?? 0;
      vFCP += icms.vFCP ?? 0;
      vBCST += icms.vBCST ?? 0;
      vST += icms.vICMSST ?? 0;
      vFCPST += icms.vFCPST ?? 0;
      vFCPSTRet += icms.vFCPSTRet ?? 0;
    }
    if (it.compoeTotal) vProd += it.valorTotal;
    vFrete += it.frete;
    vSeg += it.seguro;
    vDesc += it.desconto;
    vOutro += it.outrasDespesas;
    vII += imp.ii?.vII ?? 0;
    vIPI += imp.ipi?.vIPI ?? 0;
    vPIS += imp.pis?.vPIS ?? 0;
    vCOFINS += imp.cofins?.vCOFINS ?? 0;
    vTotTrib += imp.vTotTrib ?? 0;
    final ibs = imp.ibsCbs;
    if (ibs != null) {
      temIbsCbs = true;
      final g = ibs.gIBSCBS;
      ibsBase += g?.vBC ?? 0;
      ibsUf += g?.gIBSUF?.vIBSUF ?? 0;
      ibsMun += g?.gIBSMun?.vIBSMun ?? 0;
      cbs += g?.gCBS?.vCBS ?? 0;
    }
  }
  final r = arredondar;
  final vNF = r(vProd - vDesc - vICMSDeson + vST + vFCPST + vFrete + vSeg + vOutro + vII + vIPI);
  return TotalNfe(
    icmsTot: IcmsTot(
      vBC: r(vBC),
      vICMS: r(vICMS),
      vICMSDeson: r(vICMSDeson),
      vFCP: r(vFCP),
      vBCST: r(vBCST),
      vST: r(vST),
      vFCPST: r(vFCPST),
      vFCPSTRet: r(vFCPSTRet),
      vProd: r(vProd),
      vFrete: r(vFrete),
      vSeg: r(vSeg),
      vDesc: r(vDesc),
      vII: r(vII),
      vIPI: r(vIPI),
      vIPIDevol: 0,
      vPIS: r(vPIS),
      vCOFINS: r(vCOFINS),
      vOutro: r(vOutro),
      vNF: vNF,
      vTotTrib: vTotTrib > 0 ? r(vTotTrib) : null,
    ),
    ibsCbsTot: temIbsCbs
        ? IBSCBSTot(
            vBCIBSCBS: r(ibsBase),
            gIBS: GIBSTotal(
              gIBSUF: GIBSUFTotal(vDif: 0, vDevTrib: 0, vIBSUF: r(ibsUf)),
              gIBSMun: GIBSMunTotal(vDif: 0, vDevTrib: 0, vIBSMun: r(ibsMun)),
              vIBS: r(ibsUf + ibsMun),
              vCredPres: 0,
              vCredPresCondSus: 0,
            ),
            gCBS: GCBSTotal(vDif: 0, vDevTrib: 0, vCBS: r(cbs), vCredPres: 0, vCredPresCondSus: 0),
          )
        : null,
  );
}

/// Distribui [valor] (desconto, frete...) entre os itens, proporcional ao
/// valor de cada um; a diferença de arredondamento vai para o último.
List<double> ratear(double valor, List<double> valoresItens) {
  final total = valoresItens.fold<double>(0, (s, v) => s + v);
  if (total == 0 || valoresItens.isEmpty) return List.filled(valoresItens.length, 0);
  final partes = [for (final v in valoresItens) arredondar(valor * v / total)];
  final diferenca = arredondar(valor - partes.fold<double>(0, (s, p) => s + p));
  partes[partes.length - 1] = arredondar(partes.last + diferenca);
  return partes;
}

/// Troco (vTroco): soma dos pagamentos menos o vNF; nulo se não houver.
double? calcularTroco(List<Pagamento> pagamentos, double vNF) {
  if (pagamentos.every((p) => p.tipo == '90')) return null;
  final troco = arredondar(pagamentos.fold<double>(0, (s, p) => s + p.valor) - vNF);
  return troco > 0 ? troco : null;
}

/// Inclui o grupo `card` (tpIntegra 2, não integrado) nos pagamentos de
/// crédito (03), débito (04) e PIX (17) que não o informaram.
List<Pagamento> comCartaoPadrao(List<Pagamento> pagamentos) => [
      for (final p in pagamentos)
        (p.cartao == null && (p.tipo == '03' || p.tipo == '04' || p.tipo == '17'))
            ? Pagamento(tipo: p.tipo, valor: p.valor, cartao: const Cartao(), descricao: p.descricao, aPrazo: p.aPrazo)
            : p,
    ];

/// Texto exigido pela SEFAZ na descrição do 1º item em homologação.
const textoHomologacaoItem = 'NOTA FISCAL EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL';

/// Texto exigido pela SEFAZ no nome do destinatário em homologação.
const textoHomologacaoDest = 'NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL';

/// Em homologação, troca a descrição do 1º item e o nome do destinatário
/// pelos textos exigidos pela SEFAZ. Em produção devolve [d] sem alterações.
DadosNfe aplicarTextosHomologacao(DadosNfe d) {
  if (d.ambiente != Ambiente.homologacao) return d;
  return d.copiarCom(
    itens: [
      for (var i = 0; i < d.itens.length; i++)
        i == 0 ? d.itens[i].copiarCom(descricao: textoHomologacaoItem) : d.itens[i],
    ],
    destinatario: d.destinatario?.copiarCom(nome: textoHomologacaoDest),
  );
}

/// Conferências de regras de negócio antes do envio (o Zeus só valida o XSD).
/// Retorna a lista de problemas encontrados (vazia = ok).
List<String> validarNfe(DadosNfe d) {
  final erros = <String>[];
  final nfce = d.modelo == ModeloDocumento.nfce;
  if (!nfce && d.destinatario == null) erros.add('NF-e (modelo 55) exige destinatário');
  for (var i = 0; i < d.itens.length; i++) {
    if (nfce && d.itens[i].imposto.ipi != null) erros.add('NFC-e não admite o grupo IPI (item ${i + 1})');
  }
  if (d.pagamentos.isEmpty) erros.add('Informe ao menos um pagamento');
  for (final p in d.pagamentos) {
    if (p.tipo == '99' && (p.descricao ?? '').length < 2) erros.add('Pagamento tipo 99 exige descrição (xPag)');
  }
  final semPagamento = d.pagamentos.every((p) => p.tipo == '90');
  final pago = d.pagamentos.fold<double>(0, (s, p) => s + p.valor);
  if (!semPagamento && pago + 0.004 < d.total.vNF) {
    erros.add('Pagamentos (${pago.toStringAsFixed(2)}) menores que o total da nota '
        '(${d.total.vNF.toStringAsFixed(2)})');
  }
  if (d.tipoEmissao.contingencia && (d.justificativaContingencia ?? '').trim().length < 15) {
    erros.add('Justificativa de contingência deve ter ao menos 15 caracteres');
  }
  return erros;
}
