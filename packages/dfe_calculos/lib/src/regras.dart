// Regras de cálculo de tributos do item. NÃO EXISTEM NO ZEUS: são um extra do
// dfe_dart. Cada regra recebe a base de cálculo e devolve o grupo anêmico do
// dfe_nfe (IcmsGeral, PisGeral...) com os valores já calculados.
import 'package:dfe_nfe/dfe_nfe.dart';

/// Arredonda para [casas] (meio para cima), evitando ruído de ponto flutuante.
double arredondar(double v, [int casas = 2]) {
  var f = 1.0;
  for (var i = 0; i < casas; i++) {
    f *= 10;
  }
  return (v * f + (v >= 0 ? 1e-7 : -1e-7)).round() / f;
}

/// Cálculo do ICMS-ST (MVA ou base informada).
({double vBCST, double vICMSST}) calcularSt({
  required double baseProprio,
  required double icmsProprio,
  required double aliquotaSt,
  double? mva,
  double? reducaoSt,
  double? baseSt,
}) {
  var bc = baseSt ?? baseProprio * (1 + (mva ?? 0) / 100);
  if (baseSt == null && reducaoSt != null) bc = bc * (1 - reducaoSt / 100);
  final vBCST = arredondar(bc);
  final v = arredondar(vBCST * aliquotaSt / 100 - icmsProprio);
  return (vBCST: vBCST, vICMSST: v < 0 ? 0.0 : v);
}

// =============================================================================
// ICMS
// =============================================================================

/// Regra de ICMS: gera o [Icms] do item a partir da base de cálculo
/// (vProd − vDesc + vFrete + vSeg + vOutro).
sealed class RegraIcms {
  const RegraIcms({this.origem = 0});

  /// 0 nacional, 1 estrangeira importação direta, 2 estrangeira mercado interno...
  final int origem;

  Icms gerar(double base);
}

/// CST 00 — tributada integralmente.
class RegraIcms00 extends RegraIcms {
  const RegraIcms00({super.origem, required this.aliquota, this.modBC = 3, this.aliquotaFcp});
  final double aliquota;
  final int modBC;
  final double? aliquotaFcp;

  @override
  Icms gerar(double base) => Icms(IcmsGeral(
        orig: '$origem',
        cst: '00',
        modBC: '$modBC',
        vBC: base,
        pICMS: aliquota,
        vICMS: arredondar(base * aliquota / 100),
        pFCP: aliquotaFcp,
        vFCP: aliquotaFcp == null ? null : arredondar(base * aliquotaFcp! / 100),
      ));
}

/// CST 10 — tributada e com cobrança do ICMS por substituição tributária.
class RegraIcms10 extends RegraIcms {
  const RegraIcms10({
    super.origem,
    required this.aliquota,
    required this.aliquotaSt,
    this.mva,
    this.reducaoSt,
    this.baseSt,
    this.modBC = 3,
    this.modBCST = 4,
  });

  final double aliquota;
  final double aliquotaSt;
  final double? mva;
  final double? reducaoSt;
  final double? baseSt;
  final int modBC;
  final int modBCST;

  @override
  Icms gerar(double base) {
    final vICMS = arredondar(base * aliquota / 100);
    final st = calcularSt(
        baseProprio: base, icmsProprio: vICMS, aliquotaSt: aliquotaSt, mva: mva, reducaoSt: reducaoSt, baseSt: baseSt);
    return Icms(IcmsGeral(
      orig: '$origem',
      cst: '10',
      modBC: '$modBC',
      vBC: base,
      pICMS: aliquota,
      vICMS: vICMS,
      modBCST: '$modBCST',
      pMVAST: mva,
      pRedBCST: reducaoSt,
      vBCST: st.vBCST,
      pICMSST: aliquotaSt,
      vICMSST: st.vICMSST,
    ));
  }
}

/// CST 20 — com redução de base de cálculo.
class RegraIcms20 extends RegraIcms {
  const RegraIcms20({super.origem, required this.aliquota, required this.reducao, this.modBC = 3});
  final double aliquota;
  final double reducao;
  final int modBC;

  @override
  Icms gerar(double base) {
    final bc = arredondar(base * (1 - reducao / 100));
    return Icms(IcmsGeral(
      orig: '$origem',
      cst: '20',
      modBC: '$modBC',
      pRedBC: reducao,
      vBC: bc,
      pICMS: aliquota,
      vICMS: arredondar(bc * aliquota / 100),
    ));
  }
}

/// CST 40 (isenta), 41 (não tributada) ou 50 (suspensão).
class RegraIcms40 extends RegraIcms {
  const RegraIcms40({super.origem, this.cst = '40'}) : assert(cst == '40' || cst == '41' || cst == '50');
  final String cst;

  @override
  Icms gerar(double base) => Icms(IcmsGeral(orig: '$origem', cst: cst));
}

/// CST 60 — ICMS cobrado anteriormente por ST (valores retidos informados).
class RegraIcms60 extends RegraIcms {
  const RegraIcms60(
      {super.origem, this.baseStRetido, this.aliquotaStRetido, this.icmsSubstituto, this.icmsStRetido});
  final double? baseStRetido;
  final double? aliquotaStRetido;
  final double? icmsSubstituto;
  final double? icmsStRetido;

  @override
  Icms gerar(double base) {
    final completo = baseStRetido != null && aliquotaStRetido != null && icmsStRetido != null;
    return Icms(IcmsGeral(
      orig: '$origem',
      cst: '60',
      vBCSTRet: completo ? baseStRetido : null,
      pST: completo ? aliquotaStRetido : null,
      vICMSSubstituto: completo ? icmsSubstituto : null,
      vICMSSTRet: completo ? icmsStRetido : null,
    ));
  }
}

/// CSOSN 101 — tributada com permissão de crédito.
class RegraCsosn101 extends RegraIcms {
  const RegraCsosn101({super.origem, required this.aliquotaCredito});
  final double aliquotaCredito;

  @override
  Icms gerar(double base) => Icms(IcmsGeral(
        orig: '$origem',
        csosn: '101',
        pCredSN: aliquotaCredito,
        vCredICMSSN: arredondar(base * aliquotaCredito / 100),
      ));
}

/// CSOSN 102, 103, 300 ou 400.
class RegraCsosn102 extends RegraIcms {
  const RegraCsosn102({super.origem, this.csosn = '102'})
      : assert(csosn == '102' || csosn == '103' || csosn == '300' || csosn == '400');
  final String csosn;

  @override
  Icms gerar(double base) => Icms(IcmsGeral(orig: '$origem', csosn: csosn));
}

/// CSOSN 201 (com crédito) ou 202/203 (sem crédito) — com cobrança do ICMS-ST.
/// O ST do Simples desconta o ICMS próprio calculado pela [aliquotaInterna].
class RegraCsosn201 extends RegraIcms {
  const RegraCsosn201({
    super.origem,
    this.csosn = '201',
    required this.aliquotaSt,
    required this.aliquotaInterna,
    this.mva,
    this.reducaoSt,
    this.baseSt,
    this.aliquotaCredito,
    this.modBCST = 4,
  }) : assert(csosn == '201' || csosn == '202' || csosn == '203');

  final String csosn;
  final double aliquotaSt;
  final double aliquotaInterna;
  final double? mva;
  final double? reducaoSt;
  final double? baseSt;
  final double? aliquotaCredito;
  final int modBCST;

  @override
  Icms gerar(double base) {
    final st = calcularSt(
      baseProprio: base,
      icmsProprio: arredondar(base * aliquotaInterna / 100),
      aliquotaSt: aliquotaSt,
      mva: mva,
      reducaoSt: reducaoSt,
      baseSt: baseSt,
    );
    final credito = csosn == '201';
    return Icms(IcmsGeral(
      orig: '$origem',
      csosn: csosn,
      modBCST: '$modBCST',
      pMVAST: mva,
      pRedBCST: reducaoSt,
      vBCST: st.vBCST,
      pICMSST: aliquotaSt,
      vICMSST: st.vICMSST,
      pCredSN: credito ? (aliquotaCredito ?? 0) : null,
      vCredICMSSN: credito ? arredondar(base * (aliquotaCredito ?? 0) / 100) : null,
    ));
  }
}

/// CSOSN 500 — ICMS cobrado anteriormente por ST.
class RegraCsosn500 extends RegraIcms {
  const RegraCsosn500(
      {super.origem, this.baseStRetido, this.aliquotaStRetido, this.icmsSubstituto, this.icmsStRetido});
  final double? baseStRetido;
  final double? aliquotaStRetido;
  final double? icmsSubstituto;
  final double? icmsStRetido;

  @override
  Icms gerar(double base) {
    final completo = baseStRetido != null && aliquotaStRetido != null && icmsStRetido != null;
    return Icms(IcmsGeral(
      orig: '$origem',
      csosn: '500',
      vBCSTRet: completo ? baseStRetido : null,
      pST: completo ? aliquotaStRetido : null,
      vICMSSubstituto: completo ? icmsSubstituto : null,
      vICMSSTRet: completo ? icmsStRetido : null,
    ));
  }
}

/// CSOSN 900 — outros (sem grupos opcionais).
class RegraCsosn900 extends RegraIcms {
  const RegraCsosn900({super.origem});

  @override
  Icms gerar(double base) => Icms(IcmsGeral(orig: '$origem', csosn: '900'));
}

// =============================================================================
// PIS / COFINS
// =============================================================================

/// Regra de PIS ou COFINS (mesma estrutura para os dois tributos).
class RegraPisCofins {
  /// CST 01/02 — alíquota percentual.
  const RegraPisCofins.aliquota({this.cst = '01', required double this.aliquota}) : _tipo = 0;

  /// CST 04 a 09 — não tributado.
  const RegraPisCofins.naoTributado([this.cst = '07'])
      : aliquota = null,
        _tipo = 1;

  /// CST 49 a 99 — outras operações (alíquota 0 por padrão).
  const RegraPisCofins.outros({this.cst = '99', double this.aliquota = 0}) : _tipo = 2;

  final String cst;
  final double? aliquota;
  final int _tipo;

  double valor(double base) => _tipo == 1 ? 0 : arredondar(base * aliquota! / 100);

  ({double? vBC, double? p, double? v}) _campos(double base) => switch (_tipo) {
        1 => (vBC: null, p: null, v: null),
        2 => (vBC: aliquota == 0 ? 0.0 : base, p: aliquota, v: valor(base)),
        _ => (vBC: base, p: aliquota, v: valor(base)),
      };

  PisGeral pis(double base) {
    final c = _campos(base);
    return PisGeral(cst: cst, vBC: c.vBC, pPIS: c.p, vPIS: c.v);
  }

  CofinsGeral cofins(double base) {
    final c = _campos(base);
    return CofinsGeral(cst: cst, vBC: c.vBC, pCOFINS: c.p, vCOFINS: c.v);
  }
}

// =============================================================================
// IPI (somente NF-e)
// =============================================================================

class RegraIpi {
  /// CST 00, 49, 50 ou 99 com alíquota.
  const RegraIpi.tributado({this.cst = '50', required double this.aliquota, this.enquadramento = '999'});

  /// CST 01–05 ou 51–55.
  const RegraIpi.naoTributado({this.cst = '53', this.enquadramento = '999'}) : aliquota = null;

  final String cst;
  final double? aliquota;

  /// cEnq; 999 = tributação normal.
  final String enquadramento;

  double valor(double base) => aliquota == null ? 0 : arredondar(base * aliquota! / 100);

  IpiGeral gerar(double base) => aliquota == null
      ? IpiGeral(cEnq: enquadramento, cst: cst)
      : IpiGeral(cEnq: enquadramento, cst: cst, vBC: base, pIPI: aliquota, vIPI: valor(base));
}

// =============================================================================
// IBS / CBS (reforma tributária)
// =============================================================================

/// Regra de IBS/CBS. Em 2026 as alíquotas de teste são CBS 0,9% e IBS 0,1% (UF).
class RegraIbsCbs {
  const RegraIbsCbs({
    this.cst = '000',
    required this.classificacao,
    this.aliquotaIbsUf = 0.1,
    this.aliquotaIbsMun = 0,
    this.aliquotaCbs = 0.9,
  }) : calcular = true;

  /// Somente CST e cClassTrib (ex.: CST 410).
  const RegraIbsCbs.semCalculo({required this.cst, required this.classificacao})
      : calcular = false,
        aliquotaIbsUf = 0,
        aliquotaIbsMun = 0,
        aliquotaCbs = 0;

  final String cst;
  final String classificacao;
  final double aliquotaIbsUf;
  final double aliquotaIbsMun;
  final double aliquotaCbs;
  final bool calcular;

  /// [base]: base da transição (base do item − ICMS − FCP − PIS − COFINS).
  IbsCbs gerar(double base) {
    if (!calcular) return IbsCbs(cst: cst, classificacao: classificacao);
    final uf = arredondar(base * aliquotaIbsUf / 100);
    final mun = arredondar(base * aliquotaIbsMun / 100);
    return IbsCbs(
      cst: cst,
      classificacao: classificacao,
      vBC: base,
      pIBSUF: aliquotaIbsUf,
      vIBSUF: uf,
      pIBSMun: aliquotaIbsMun,
      vIBSMun: mun,
      vIBS: arredondar(uf + mun),
      pCBS: aliquotaCbs,
      vCBS: arredondar(base * aliquotaCbs / 100),
    );
  }
}
