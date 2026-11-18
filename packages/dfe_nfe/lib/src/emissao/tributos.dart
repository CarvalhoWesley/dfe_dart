import '../util/formatacao.dart';

/// Arredonda para 2 casas (meio para cima), evitando ruído de ponto flutuante.
double arredondar(double v, [int casas = 2]) {
  final f = _pot(casas);
  return (v * f + (v >= 0 ? 1e-7 : -1e-7)).round() / f;
}

double _pot(int n) {
  var r = 1.0;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

String _t(String tag, String v) => '<$tag>${escaparXml(v)}</$tag>';
String _v(double v) => formatarDecimal(v, 2);
String _p(double v) => formatarDecimal(v, 4);

/// Contribuição de um item para o grupo `ICMSTot`.
class TotaisIcms {
  const TotaisIcms({
    this.vBC = 0,
    this.vICMS = 0,
    this.vICMSDeson = 0,
    this.vFCP = 0,
    this.vBCST = 0,
    this.vST = 0,
    this.vFCPST = 0,
  });

  final double vBC;
  final double vICMS;
  final double vICMSDeson;
  final double vFCP;
  final double vBCST;
  final double vST;
  final double vFCPST;

  TotaisIcms operator +(TotaisIcms o) => TotaisIcms(
        vBC: vBC + o.vBC,
        vICMS: vICMS + o.vICMS,
        vICMSDeson: vICMSDeson + o.vICMSDeson,
        vFCP: vFCP + o.vFCP,
        vBCST: vBCST + o.vBCST,
        vST: vST + o.vST,
        vFCPST: vFCPST + o.vFCPST,
      );
}

/// Cálculo do ICMS-ST (MVA ou base informada).
class _St {
  _St({
    required double baseProprio,
    required double icmsProprio,
    required double aliquotaSt,
    double? mva,
    double? reducaoSt,
    double? baseSt,
  }) {
    var bc = baseSt ?? baseProprio * (1 + (mva ?? 0) / 100);
    if (baseSt == null && reducaoSt != null) bc = bc * (1 - reducaoSt / 100);
    vBCST = arredondar(bc);
    vICMSST = arredondar(vBCST * aliquotaSt / 100 - icmsProprio);
    if (vICMSST < 0) vICMSST = 0;
  }
  late final double vBCST;
  late double vICMSST;
}

// =============================================================================
// ICMS
// =============================================================================

/// Grupo de ICMS do item. [base] é a base de cálculo do item
/// (vProd − vDesc + vFrete + vSeg + vOutro), calculada pelo montador.
sealed class Icms {
  const Icms({this.origem = 0});

  /// 0 nacional, 1 estrangeira importação direta, 2 estrangeira mercado interno...
  final int origem;

  String xml(double base);
  TotaisIcms totais(double base);

  /// Origem + CST/CSOSN, como aparece no DANFE.
  String get codigo;
}

// --- Regime normal (CRT 3) ---------------------------------------------------

/// CST 00 — tributada integralmente.
class Icms00 extends Icms {
  const Icms00({super.origem, required this.aliquota, this.modBC = 3, this.aliquotaFcp});
  final double aliquota;
  final int modBC;
  final double? aliquotaFcp;

  double _icms(double b) => arredondar(b * aliquota / 100);
  double _fcp(double b) => aliquotaFcp == null ? 0 : arredondar(b * aliquotaFcp! / 100);

  @override
  String get codigo => '${origem}00';

  @override
  String xml(double base) => '<ICMS00>${_t('orig', '$origem')}${_t('CST', '00')}${_t('modBC', '$modBC')}'
      '${_t('vBC', _v(base))}${_t('pICMS', _p(aliquota))}${_t('vICMS', _v(_icms(base)))}'
      '${aliquotaFcp == null ? '' : '${_t('pFCP', _p(aliquotaFcp!))}${_t('vFCP', _v(_fcp(base)))}'}'
      '</ICMS00>';

  @override
  TotaisIcms totais(double base) => TotaisIcms(vBC: base, vICMS: _icms(base), vFCP: _fcp(base));
}

/// CST 10 — tributada e com cobrança do ICMS por substituição tributária.
class Icms10 extends Icms {
  const Icms10({
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

  /// Margem de valor agregado (%), quando modBCST = 4.
  final double? mva;
  final double? reducaoSt;

  /// Base do ST informada (ex.: pauta); se nula, é calculada pela MVA.
  final double? baseSt;
  final int modBC;
  final int modBCST;

  double _icms(double b) => arredondar(b * aliquota / 100);
  _St _st(double b) => _St(
      baseProprio: b, icmsProprio: _icms(b), aliquotaSt: aliquotaSt, mva: mva, reducaoSt: reducaoSt, baseSt: baseSt);

  @override
  String get codigo => '${origem}10';

  @override
  String xml(double base) {
    final st = _st(base);
    return '<ICMS10>${_t('orig', '$origem')}${_t('CST', '10')}${_t('modBC', '$modBC')}'
        '${_t('vBC', _v(base))}${_t('pICMS', _p(aliquota))}${_t('vICMS', _v(_icms(base)))}'
        '${_t('modBCST', '$modBCST')}${mva == null ? '' : _t('pMVAST', _p(mva!))}'
        '${reducaoSt == null ? '' : _t('pRedBCST', _p(reducaoSt!))}'
        '${_t('vBCST', _v(st.vBCST))}${_t('pICMSST', _p(aliquotaSt))}${_t('vICMSST', _v(st.vICMSST))}'
        '</ICMS10>';
  }

  @override
  TotaisIcms totais(double base) {
    final st = _st(base);
    return TotaisIcms(vBC: base, vICMS: _icms(base), vBCST: st.vBCST, vST: st.vICMSST);
  }
}

/// CST 20 — com redução de base de cálculo.
class Icms20 extends Icms {
  const Icms20({super.origem, required this.aliquota, required this.reducao, this.modBC = 3});
  final double aliquota;

  /// Percentual de redução da base (pRedBC).
  final double reducao;
  final int modBC;

  double _bc(double b) => arredondar(b * (1 - reducao / 100));
  double _icms(double b) => arredondar(_bc(b) * aliquota / 100);

  @override
  String get codigo => '${origem}20';

  @override
  String xml(double base) => '<ICMS20>${_t('orig', '$origem')}${_t('CST', '20')}${_t('modBC', '$modBC')}'
      '${_t('pRedBC', _p(reducao))}${_t('vBC', _v(_bc(base)))}${_t('pICMS', _p(aliquota))}'
      '${_t('vICMS', _v(_icms(base)))}</ICMS20>';

  @override
  TotaisIcms totais(double base) => TotaisIcms(vBC: _bc(base), vICMS: _icms(base));
}

/// CST 40 (isenta), 41 (não tributada) ou 50 (suspensão).
class Icms40 extends Icms {
  const Icms40({super.origem, this.cst = '40'})
      : assert(cst == '40' || cst == '41' || cst == '50');
  final String cst;

  @override
  String get codigo => '$origem$cst';

  @override
  String xml(double base) => '<ICMS40>${_t('orig', '$origem')}${_t('CST', cst)}</ICMS40>';

  @override
  TotaisIcms totais(double base) => const TotaisIcms();
}

/// CST 60 — ICMS cobrado anteriormente por substituição tributária.
class Icms60 extends Icms {
  const Icms60({super.origem, this.baseStRetido, this.aliquotaStRetido, this.icmsSubstituto, this.icmsStRetido});
  final double? baseStRetido;
  final double? aliquotaStRetido;
  final double? icmsSubstituto;
  final double? icmsStRetido;

  @override
  String get codigo => '${origem}60';

  @override
  String xml(double base) => '<ICMS60>${_t('orig', '$origem')}${_t('CST', '60')}${_retido(
      baseStRetido, aliquotaStRetido, icmsSubstituto, icmsStRetido)}</ICMS60>';

  @override
  TotaisIcms totais(double base) => const TotaisIcms();
}

String _retido(double? vBCSTRet, double? pST, double? vSubst, double? vSTRet) {
  // O grupo de ST retido é "tudo ou nada" no schema.
  if (vBCSTRet == null || pST == null || vSTRet == null) return '';
  return '${_t('vBCSTRet', _v(vBCSTRet))}${_t('pST', _p(pST))}'
      '${vSubst == null ? '' : _t('vICMSSubstituto', _v(vSubst))}${_t('vICMSSTRet', _v(vSTRet))}';
}

// --- Simples Nacional (CRT 1, 2 e 4) ------------------------------------------

/// CSOSN 101 — tributada com permissão de crédito.
class Csosn101 extends Icms {
  const Csosn101({super.origem, required this.aliquotaCredito});
  final double aliquotaCredito;

  @override
  String get codigo => '${origem}101';

  @override
  String xml(double base) => '<ICMSSN101>${_t('orig', '$origem')}${_t('CSOSN', '101')}'
      '${_t('pCredSN', _p(aliquotaCredito))}'
      '${_t('vCredICMSSN', _v(arredondar(base * aliquotaCredito / 100)))}</ICMSSN101>';

  @override
  TotaisIcms totais(double base) => const TotaisIcms();
}

/// CSOSN 102, 103, 300 ou 400 — sem crédito / isenção / imune / não tributada.
class Csosn102 extends Icms {
  const Csosn102({super.origem, this.csosn = '102'})
      : assert(csosn == '102' || csosn == '103' || csosn == '300' || csosn == '400');
  final String csosn;

  @override
  String get codigo => '$origem$csosn';

  @override
  String xml(double base) => '<ICMSSN102>${_t('orig', '$origem')}${_t('CSOSN', csosn)}</ICMSSN102>';

  @override
  TotaisIcms totais(double base) => const TotaisIcms();
}

/// CSOSN 201 (com crédito) ou 202/203 (sem crédito) — com cobrança do ICMS-ST.
///
/// O ST do Simples desconta o ICMS próprio calculado pela [aliquotaInterna].
class Csosn201 extends Icms {
  const Csosn201({
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

  /// Obrigatória no CSOSN 201.
  final double? aliquotaCredito;
  final int modBCST;

  _St _st(double b) => _St(
      baseProprio: b,
      icmsProprio: arredondar(b * aliquotaInterna / 100),
      aliquotaSt: aliquotaSt,
      mva: mva,
      reducaoSt: reducaoSt,
      baseSt: baseSt);

  @override
  String get codigo => '$origem$csosn';

  @override
  String xml(double base) {
    final st = _st(base);
    final grupo = csosn == '201' ? 'ICMSSN201' : 'ICMSSN202';
    final credito = csosn == '201'
        ? '${_t('pCredSN', _p(aliquotaCredito ?? 0))}'
            '${_t('vCredICMSSN', _v(arredondar(base * (aliquotaCredito ?? 0) / 100)))}'
        : '';
    return '<$grupo>${_t('orig', '$origem')}${_t('CSOSN', csosn)}${_t('modBCST', '$modBCST')}'
        '${mva == null ? '' : _t('pMVAST', _p(mva!))}${reducaoSt == null ? '' : _t('pRedBCST', _p(reducaoSt!))}'
        '${_t('vBCST', _v(st.vBCST))}${_t('pICMSST', _p(aliquotaSt))}${_t('vICMSST', _v(st.vICMSST))}'
        '$credito</$grupo>';
  }

  @override
  TotaisIcms totais(double base) {
    final st = _st(base);
    return TotaisIcms(vBCST: st.vBCST, vST: st.vICMSST);
  }
}

/// CSOSN 500 — ICMS cobrado anteriormente por ST.
class Csosn500 extends Icms {
  const Csosn500({super.origem, this.baseStRetido, this.aliquotaStRetido, this.icmsSubstituto, this.icmsStRetido});
  final double? baseStRetido;
  final double? aliquotaStRetido;
  final double? icmsSubstituto;
  final double? icmsStRetido;

  @override
  String get codigo => '${origem}500';

  @override
  String xml(double base) => '<ICMSSN500>${_t('orig', '$origem')}${_t('CSOSN', '500')}${_retido(
      baseStRetido, aliquotaStRetido, icmsSubstituto, icmsStRetido)}</ICMSSN500>';

  @override
  TotaisIcms totais(double base) => const TotaisIcms();
}

/// CSOSN 900 — outros (sem grupos opcionais).
class Csosn900 extends Icms {
  const Csosn900({super.origem});

  @override
  String get codigo => '${origem}900';

  @override
  String xml(double base) => '<ICMSSN900>${_t('orig', '$origem')}${_t('CSOSN', '900')}</ICMSSN900>';

  @override
  TotaisIcms totais(double base) => const TotaisIcms();
}

// =============================================================================
// PIS / COFINS
// =============================================================================

/// PIS ou COFINS do item (mesma estrutura para os dois tributos).
sealed class PisCofins {
  const PisCofins(this.cst);
  final String cst;

  String xml(String tributo, double base);
  double valor(double base);

  /// CST 01/02 — alíquota percentual.
  const factory PisCofins.aliquota({String cst, required double aliquota}) = _PcAliquota;

  /// CST 04 a 09 — não tributado.
  const factory PisCofins.naoTributado([String cst]) = _PcNt;

  /// CST 49 a 99 — outras operações (alíquota 0 por padrão).
  const factory PisCofins.outros({String cst, double aliquota}) = _PcOutros;
}

class _PcAliquota extends PisCofins {
  const _PcAliquota({String cst = '01', required this.aliquota}) : super(cst);
  final double aliquota;

  @override
  double valor(double base) => arredondar(base * aliquota / 100);

  @override
  String xml(String tr, double base) => '<${tr}Aliq>${_t('CST', cst)}${_t('vBC', _v(base))}'
      '${_t('p$tr', _p(aliquota))}${_t('v$tr', _v(valor(base)))}</${tr}Aliq>';
}

class _PcNt extends PisCofins {
  const _PcNt([super.cst = '07']);

  @override
  double valor(double base) => 0;

  @override
  String xml(String tr, double base) => '<${tr}NT>${_t('CST', cst)}</${tr}NT>';
}

class _PcOutros extends PisCofins {
  const _PcOutros({String cst = '99', this.aliquota = 0}) : super(cst);
  final double aliquota;

  @override
  double valor(double base) => arredondar(base * aliquota / 100);

  @override
  String xml(String tr, double base) => '<${tr}Outr>${_t('CST', cst)}${_t('vBC', _v(aliquota == 0 ? 0 : base))}'
      '${_t('p$tr', _p(aliquota))}${_t('v$tr', _v(valor(base)))}</${tr}Outr>';
}

// =============================================================================
// IPI (somente NF-e)
// =============================================================================

sealed class Ipi {
  const Ipi(this.cst, this.enquadramento);
  final String cst;

  /// Código de enquadramento legal (cEnq); 999 = tributação normal.
  final String enquadramento;

  String xml(double base);
  double valor(double base);

  /// CST 00, 49, 50 ou 99 com alíquota.
  const factory Ipi.tributado({String cst, required double aliquota, String enquadramento}) = _IpiTrib;

  /// CST 01–05 ou 51–55.
  const factory Ipi.naoTributado({String cst, String enquadramento}) = _IpiNt;
}

class _IpiTrib extends Ipi {
  const _IpiTrib({String cst = '50', required this.aliquota, String enquadramento = '999'})
      : super(cst, enquadramento);
  final double aliquota;

  @override
  double valor(double base) => arredondar(base * aliquota / 100);

  @override
  String xml(double base) => '<IPI>${_t('cEnq', enquadramento)}<IPITrib>${_t('CST', cst)}'
      '${_t('vBC', _v(base))}${_t('pIPI', _p(aliquota))}${_t('vIPI', _v(valor(base)))}</IPITrib></IPI>';
}

class _IpiNt extends Ipi {
  const _IpiNt({String cst = '53', String enquadramento = '999'}) : super(cst, enquadramento);

  @override
  double valor(double base) => 0;

  @override
  String xml(double base) => '<IPI>${_t('cEnq', enquadramento)}<IPINT>${_t('CST', cst)}</IPINT></IPI>';
}

// =============================================================================
// IBS / CBS (reforma tributária — NT 2025.002)
// =============================================================================

/// Grupo `IBSCBS` do item.
///
/// Em 2026 as alíquotas de teste são CBS 0,9% e IBS 0,1% (UF) / 0% (município)
/// e os valores **não** entram no vNF.
class IbsCbs {
  /// Tributação com cálculo do IBS (UF e município) e da CBS (CST 000, 200...).
  const IbsCbs({
    this.cst = '000',
    required this.classificacao,
    this.aliquotaIbsUf = 0.1,
    this.aliquotaIbsMun = 0,
    this.aliquotaCbs = 0.9,
  }) : calcular = true;

  /// Somente CST e cClassTrib, sem o grupo de valores (ex.: CST 410 — imunidade
  /// e não incidência).
  const IbsCbs.semCalculo({required this.cst, required this.classificacao})
      : calcular = false,
        aliquotaIbsUf = 0,
        aliquotaIbsMun = 0,
        aliquotaCbs = 0;

  /// CST do IBS/CBS (3 dígitos).
  final String cst;

  /// Código de classificação tributária (cClassTrib, 6 dígitos).
  final String classificacao;
  final double aliquotaIbsUf;
  final double aliquotaIbsMun;
  final double aliquotaCbs;
  final bool calcular;

  /// Valores calculados sobre a [base] (vBC do IBS/CBS).
  ValoresIbsCbs valores(double base) => calcular
      ? ValoresIbsCbs(
          base: base,
          ibsUf: arredondar(base * aliquotaIbsUf / 100),
          ibsMun: arredondar(base * aliquotaIbsMun / 100),
          cbs: arredondar(base * aliquotaCbs / 100),
        )
      : const ValoresIbsCbs();

  String xml(double base) {
    final b = StringBuffer('<IBSCBS>${_t('CST', cst)}${_t('cClassTrib', classificacao)}');
    if (calcular) {
      final v = valores(base);
      b
        ..write('<gIBSCBS>${_t('vBC', _v(base))}')
        ..write('<gIBSUF>${_t('pIBSUF', _p(aliquotaIbsUf))}${_t('vIBSUF', _v(v.ibsUf))}</gIBSUF>')
        ..write('<gIBSMun>${_t('pIBSMun', _p(aliquotaIbsMun))}${_t('vIBSMun', _v(v.ibsMun))}</gIBSMun>')
        ..write(_t('vIBS', _v(v.ibs)))
        ..write('<gCBS>${_t('pCBS', _p(aliquotaCbs))}${_t('vCBS', _v(v.cbs))}</gCBS>')
        ..write('</gIBSCBS>');
    }
    b.write('</IBSCBS>');
    return b.toString();
  }
}

/// Valores de IBS/CBS de um item ou da nota.
class ValoresIbsCbs {
  const ValoresIbsCbs({this.base = 0, this.ibsUf = 0, this.ibsMun = 0, this.cbs = 0});
  final double base;
  final double ibsUf;
  final double ibsMun;
  final double cbs;

  double get ibs => arredondar(ibsUf + ibsMun);

  ValoresIbsCbs operator +(ValoresIbsCbs o) =>
      ValoresIbsCbs(base: base + o.base, ibsUf: ibsUf + o.ibsUf, ibsMun: ibsMun + o.ibsMun, cbs: cbs + o.cbs);

  /// Grupo `IBSCBSTot` do total da nota.
  String xmlTotal() => '<IBSCBSTot>${_t('vBCIBSCBS', _v(arredondar(base)))}'
      '<gIBS><gIBSUF>${_t('vDif', _v(0))}${_t('vDevTrib', _v(0))}${_t('vIBSUF', _v(arredondar(ibsUf)))}</gIBSUF>'
      '<gIBSMun>${_t('vDif', _v(0))}${_t('vDevTrib', _v(0))}${_t('vIBSMun', _v(arredondar(ibsMun)))}</gIBSMun>'
      '${_t('vIBS', _v(ibs))}${_t('vCredPres', _v(0))}${_t('vCredPresCondSus', _v(0))}</gIBS>'
      '<gCBS>${_t('vDif', _v(0))}${_t('vDevTrib', _v(0))}${_t('vCBS', _v(arredondar(cbs)))}'
      '${_t('vCredPres', _v(0))}${_t('vCredPresCondSus', _v(0))}</gCBS></IBSCBSTot>';
}
