import '../enums.dart';
import 'tributos.dart';

export 'tributos.dart';

/// Modelo de dados simplificado para emissão (venda a consumidor, Simples
/// Nacional). Será substituído pelas classes geradas de `NFe.Classes` na Fase 1.

class Endereco {
  const Endereco({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.codigoMunicipio,
    required this.municipio,
    required this.uf,
    required this.cep,
    this.complemento,
    this.fone,
  });

  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final int codigoMunicipio;
  final String municipio;
  final Uf uf;
  final String cep;
  final String? fone;
}

class Emitente {
  const Emitente({
    required this.cnpj,
    required this.razaoSocial,
    required this.inscricaoEstadual,
    required this.endereco,
    this.nomeFantasia,
    this.crt = 1,
  });

  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String inscricaoEstadual;
  final Endereco endereco;

  /// 1 = Simples Nacional, 2 = SN excesso, 3 = Normal, 4 = MEI.
  /// O exemplo emite ICMS pelo CSOSN 102 (válido para CRT 1 e 4).
  final int crt;
}

class Destinatario {
  const Destinatario({required this.nome, this.cpf, this.cnpj, this.endereco, this.email});

  final String? cpf;
  final String? cnpj;
  final String nome;
  final Endereco? endereco;
  final String? email;
}

class ItemNfe {
  const ItemNfe({
    required this.codigo,
    required this.descricao,
    required this.ncm,
    required this.cfop,
    required this.unidade,
    required this.quantidade,
    required this.valorUnitario,
    this.gtin = 'SEM GTIN',
    this.cest,
    this.codigoBeneficio,
    this.icms = const Csosn102(),
    this.pis = const PisCofins.naoTributado(),
    this.cofins = const PisCofins.naoTributado(),
    this.ipi,
    this.desconto = 0,
    this.frete = 0,
    this.seguro = 0,
    this.outrasDespesas = 0,
    this.valorTributos,
    this.ibsCbs,
  });

  /// IBS/CBS da reforma tributária (NT 2025.002); nulo = grupo não informado.
  final IbsCbs? ibsCbs;

  /// Base do IBS/CBS no período de transição: base do item menos ICMS, FCP,
  /// PIS e COFINS.
  double get baseIbsCbs {
    final b = baseCalculo;
    final t = icms.totais(b);
    return arredondar(b - t.vICMS - t.vFCP - pis.valor(b) - cofins.valor(b));
  }

  final String codigo;
  final String gtin;
  final String descricao;
  final String ncm;
  final String cfop;
  final String unidade;
  final double quantidade;
  final double valorUnitario;

  /// CEST (obrigatório para mercadorias sujeitas a ST).
  final String? cest;

  /// Código de benefício fiscal (cBenef), exigido por algumas UFs.
  final String? codigoBeneficio;

  final Icms icms;
  final PisCofins pis;
  final PisCofins cofins;

  /// Somente NF-e (modelo 55).
  final Ipi? ipi;

  final double desconto;
  final double frete;
  final double seguro;
  final double outrasDespesas;

  /// Valor aproximado dos tributos (Lei 12.741/2012), vTotTrib do item.
  final double? valorTributos;

  double get valorTotal => arredondar(quantidade * valorUnitario);

  /// Base de cálculo: vProd − vDesc + vFrete + vSeg + vOutro.
  double get baseCalculo => arredondar(valorTotal - desconto + frete + seguro + outrasDespesas);
}

/// Dados de cartão (grupo `card`), exigido para crédito, débito e PIX.
class Cartao {
  const Cartao({this.integrado = false, this.cnpjCredenciadora, this.bandeira, this.autorizacao});

  /// tpIntegra: 1 integrado ao sistema (TEF), 2 não integrado (POS).
  final bool integrado;
  final String? cnpjCredenciadora;

  /// tBand: 01 Visa, 02 Mastercard, 03 Amex, 04 Sorocred, 05 Diners, 06 Elo,
  /// 07 Hipercard, 08 Aura, 09 Cabal, 99 outros.
  final String? bandeira;

  /// Número de autorização (cAut).
  final String? autorizacao;
}

class Pagamento {
  const Pagamento({required this.tipo, required this.valor, this.cartao, this.descricao, this.aPrazo = false});

  /// tPag: 01 dinheiro, 03 crédito, 04 débito, 15 boleto, 17 PIX, 90 sem pagamento, 99 outros...
  final String tipo;
  final double valor;

  /// Para 03/04/17 o grupo `card` é gerado mesmo sem dados (tpIntegra = 2).
  final Cartao? cartao;

  /// xPag — obrigatório quando tPag = 99.
  final String? descricao;

  /// indPag: false = à vista (0), true = a prazo (1).
  final bool aPrazo;

  bool get exigeCartao => tipo == '03' || tipo == '04' || tipo == '17';
}

/// Responsável técnico (infRespTec) — exigido por algumas UFs.
class ResponsavelTecnico {
  const ResponsavelTecnico({
    required this.cnpj,
    required this.contato,
    required this.email,
    required this.fone,
  });

  final String cnpj;
  final String contato;
  final String email;
  final String fone;
}

class DadosNfe {
  DadosNfe({
    required this.modelo,
    required this.ambiente,
    required this.serie,
    required this.numero,
    required this.emitente,
    required this.itens,
    required this.pagamentos,
    this.destinatario,
    this.naturezaOperacao = 'VENDA',
    this.tipoEmissao = TipoEmissao.normal,
    this.justificativaContingencia,
    DateTime? dataEmissao,
    DateTime? dataContingencia,
    this.informacoesComplementares,
    this.responsavelTecnico,
    this.codigoNumerico,
    this.versaoAplicativo = 'dfe_dart 0.1',
  })  : dataEmissao = dataEmissao ?? DateTime.now(),
        dataContingencia = dataContingencia ??
            (tipoEmissao.contingencia ? (dataEmissao ?? DateTime.now()) : null);

  final ModeloDocumento modelo;
  final Ambiente ambiente;
  final int serie;
  final int numero;
  final Emitente emitente;
  final Destinatario? destinatario;
  final List<ItemNfe> itens;
  final List<Pagamento> pagamentos;
  final String naturezaOperacao;
  final TipoEmissao tipoEmissao;
  final String? justificativaContingencia;
  final DateTime dataEmissao;
  final DateTime? dataContingencia;
  final String? informacoesComplementares;
  final ResponsavelTecnico? responsavelTecnico;

  /// cNF; se nulo, é sorteado.
  final int? codigoNumerico;
  final String versaoAplicativo;

  double get valorProdutos => arredondar(itens.fold<double>(0, (s, i) => s + i.valorTotal));

  /// Totais da nota (grupo `ICMSTot`) calculados a partir dos itens.
  TotaisNfe get totais => TotaisNfe.calcular(itens);
}

/// Totais da nota (ICMSTot).
class TotaisNfe {
  TotaisNfe._(this.icms, this.vProd, this.vFrete, this.vSeg, this.vDesc, this.vOutro, this.vIPI,
      this.vPIS, this.vCOFINS, this.vTotTrib, this.ibsCbs);

  /// Soma do IBS/CBS dos itens; nulo se nenhum item informa o grupo.
  final ValoresIbsCbs? ibsCbs;

  factory TotaisNfe.calcular(List<ItemNfe> itens) {
    var icms = const TotaisIcms();
    double vProd = 0, vFrete = 0, vSeg = 0, vDesc = 0, vOutro = 0, vIPI = 0, vPIS = 0, vCOFINS = 0, vTrib = 0;
    ValoresIbsCbs? ibsCbs;
    for (final i in itens) {
      final b = i.baseCalculo;
      if (i.ibsCbs != null) {
        final base = i.baseIbsCbs;
        final v = i.ibsCbs!.valores(base);
        ibsCbs = (ibsCbs ?? const ValoresIbsCbs()) + v;
      }
      icms = icms + i.icms.totais(b);
      vProd += i.valorTotal;
      vFrete += i.frete;
      vSeg += i.seguro;
      vDesc += i.desconto;
      vOutro += i.outrasDespesas;
      vIPI += i.ipi?.valor(b) ?? 0;
      vPIS += i.pis.valor(b);
      vCOFINS += i.cofins.valor(b);
      vTrib += i.valorTributos ?? 0;
    }
    final r = arredondar;
    return TotaisNfe._(
      TotaisIcms(
        vBC: r(icms.vBC),
        vICMS: r(icms.vICMS),
        vICMSDeson: r(icms.vICMSDeson),
        vFCP: r(icms.vFCP),
        vBCST: r(icms.vBCST),
        vST: r(icms.vST),
        vFCPST: r(icms.vFCPST),
      ),
      r(vProd), r(vFrete), r(vSeg), r(vDesc), r(vOutro), r(vIPI), r(vPIS), r(vCOFINS), r(vTrib),
      ibsCbs,
    );
  }

  final TotaisIcms icms;
  final double vProd;
  final double vFrete;
  final double vSeg;
  final double vDesc;
  final double vOutro;
  final double vIPI;
  final double vPIS;
  final double vCOFINS;
  final double vTotTrib;

  /// vNF = vProd − vDesc − vICMSDeson + vST + vFCPST + vFrete + vSeg + vOutro + vIPI.
  double get vNF => arredondar(
      vProd - vDesc - icms.vICMSDeson + icms.vST + icms.vFCPST + vFrete + vSeg + vOutro + vIPI);
}

/// Distribui um desconto (ou acréscimo) no total da venda entre os itens,
/// proporcional ao valor de cada um; a diferença de arredondamento vai para o
/// último item.
List<double> ratear(double valor, List<ItemNfe> itens) {
  final total = itens.fold<double>(0, (s, i) => s + i.valorTotal);
  if (total == 0 || itens.isEmpty) return List.filled(itens.length, 0);
  final partes = [for (final i in itens) arredondar(valor * i.valorTotal / total)];
  final diferenca = arredondar(valor - partes.fold<double>(0, (s, p) => s + p));
  partes[partes.length - 1] = arredondar(partes.last + diferenca);
  return partes;
}
