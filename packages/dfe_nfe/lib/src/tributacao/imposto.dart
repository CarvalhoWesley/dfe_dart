import '../util/formatacao.dart';
import 'classes.g.dart';
import 'grupo.dart';

export 'classes.g.dart';

/// Variantes de CST que usam outro grupo (Zeus: `CstPart10/90`, `CstRep41/60`).
enum VarianteIcms {
  normal,

  /// Partilha entre UFs — CST 10 ou 90 no grupo `ICMSPart`.
  partilha,

  /// Repasse de ICMS-ST retido — CST 41 ou 60 no grupo `ICMSST`.
  repasse,
}

/// ICMS do item: valores informados pelo app em [IcmsGeral]; o grupo XML é
/// escolhido pelo CRT do emitente e pelo CST/CSOSN, como no `ICMSGeral` do Zeus.
class Icms {
  const Icms(this.dados, {this.variante = VarianteIcms.normal});

  final IcmsGeral dados;
  final VarianteIcms variante;

  /// Nome do grupo XML para o [crt] do emitente (1 SN, 2 SN excesso, 3 normal, 4 MEI).
  String grupo(int crt) {
    final cst = dados.cst;
    final csosn = dados.csosn;
    if (crt == 1 || crt == 4) {
      // No Simples, o CST 61 (monofásico retido) usa o grupo do regime normal.
      if (cst == '61') return 'ICMS61';
      return switch (csosn) {
        '101' => 'ICMSSN101',
        '102' || '103' || '300' || '400' => 'ICMSSN102',
        '201' => 'ICMSSN201',
        '202' || '203' => 'ICMSSN202',
        '500' => 'ICMSSN500',
        '900' => 'ICMSSN900',
        _ => throw ArgumentError('CSOSN inválido para o Simples Nacional: $csosn'),
      };
    }
    if (crt == 2 || crt == 3) {
      if (variante == VarianteIcms.partilha) {
        if (cst == '10' || cst == '90') return 'ICMSPart';
        throw ArgumentError('Partilha (ICMSPart) só para CST 10 ou 90');
      }
      if (variante == VarianteIcms.repasse) {
        if (cst == '41' || cst == '60') return 'ICMSST';
        throw ArgumentError('Repasse (ICMSST) só para CST 41 ou 60');
      }
      return switch (cst) {
        '00' || '02' || '10' || '15' || '20' || '30' || '51' || '53' || '60' || '61' || '70' || '90' =>
          'ICMS$cst',
        '40' || '41' || '50' => 'ICMS40',
        _ => throw ArgumentError('CST de ICMS inválido para o regime normal: $cst'),
      };
    }
    throw ArgumentError('CRT inválido: $crt');
  }

  String xml(int crt) => '<ICMS>${serializarGrupo(grupo(crt), dados.valores)}</ICMS>';

  /// Origem + CST/CSOSN, como no DANFE.
  String get codigo => '${dados.orig ?? ''}${dados.csosn ?? dados.cst ?? ''}';
}

String _grupoPisCofins(String tributo, String? cst) => switch (cst) {
      '01' || '02' => '${tributo}Aliq',
      '03' => '${tributo}Qtde',
      '04' || '05' || '06' || '07' || '08' || '09' => '${tributo}NT',
      _ when cst != null && int.tryParse(cst) != null && int.parse(cst) >= 49 => '${tributo}Outr',
      _ => throw ArgumentError('CST de $tributo inválido: $cst'),
    };

String _xmlPis(PisGeral p) => '<PIS>${serializarGrupo(_grupoPisCofins('PIS', p.cst), p.valores)}</PIS>';
String _xmlCofins(CofinsGeral c) =>
    '<COFINS>${serializarGrupo(_grupoPisCofins('COFINS', c.cst), c.valores)}</COFINS>';

String _xmlIpi(IpiGeral i) {
  final grupo = switch (i.cst) {
    '00' || '49' || '50' || '99' => 'IPITrib',
    '01' || '02' || '03' || '04' || '05' || '51' || '52' || '53' || '54' || '55' => 'IPINT',
    _ => throw ArgumentError('CST de IPI inválido: ${i.cst}'),
  };
  final envoltorio = serializarGrupo('IPI', i.valores);
  // Insere o grupo IPITrib/IPINT antes de </IPI>.
  return '${envoltorio.substring(0, envoltorio.length - 6)}${serializarGrupo(grupo, i.valores)}</IPI>';
}

/// Grupo `IBSCBS` do item (reforma tributária, NT 2025.002). Valores
/// informados pelo app; sem [vBC] o grupo leva apenas CST e cClassTrib.
class IbsCbs {
  const IbsCbs({
    required this.cst,
    required this.classificacao,
    this.vBC,
    this.pIBSUF = 0,
    this.vIBSUF = 0,
    this.pIBSMun = 0,
    this.vIBSMun = 0,
    this.vIBS,
    this.pCBS = 0,
    this.vCBS = 0,
  });

  final String cst;

  /// cClassTrib (6 dígitos).
  final String classificacao;
  final double? vBC;
  final double pIBSUF;
  final double vIBSUF;
  final double pIBSMun;
  final double vIBSMun;

  /// Se nulo, vIBSUF + vIBSMun.
  final double? vIBS;
  final double pCBS;
  final double vCBS;

  String xml() {
    String t(String tag, String v) => '<$tag>${escaparXml(v)}</$tag>';
    String v2(double v) => formatarDecimal(v, 2);
    String p4(double v) => formatarDecimal(v, 4);
    final b = StringBuffer('<IBSCBS>${t('CST', cst)}${t('cClassTrib', classificacao)}');
    if (vBC != null) {
      b
        ..write('<gIBSCBS>${t('vBC', v2(vBC!))}')
        ..write('<gIBSUF>${t('pIBSUF', p4(pIBSUF))}${t('vIBSUF', v2(vIBSUF))}</gIBSUF>')
        ..write('<gIBSMun>${t('pIBSMun', p4(pIBSMun))}${t('vIBSMun', v2(vIBSMun))}</gIBSMun>')
        ..write(t('vIBS', v2(vIBS ?? (vIBSUF + vIBSMun))))
        ..write('<gCBS>${t('pCBS', p4(pCBS))}${t('vCBS', v2(vCBS))}</gCBS>')
        ..write('</gIBSCBS>');
    }
    b.write('</IBSCBS>');
    return b.toString();
  }
}

/// Totais do IBS/CBS (grupo `IBSCBSTot`), informados pelo app.
class IbsCbsTot {
  const IbsCbsTot({
    required this.vBCIBSCBS,
    this.vIBSUF = 0,
    this.vIBSMun = 0,
    this.vIBS,
    this.vCBS = 0,
    this.vDifUF = 0,
    this.vDevTribUF = 0,
    this.vDifMun = 0,
    this.vDevTribMun = 0,
    this.vCredPresIBS = 0,
    this.vCredPresCondSusIBS = 0,
    this.vDifCBS = 0,
    this.vDevTribCBS = 0,
    this.vCredPresCBS = 0,
    this.vCredPresCondSusCBS = 0,
  });

  final double vBCIBSCBS;
  final double vIBSUF;
  final double vIBSMun;
  final double? vIBS;
  final double vCBS;
  final double vDifUF;
  final double vDevTribUF;
  final double vDifMun;
  final double vDevTribMun;
  final double vCredPresIBS;
  final double vCredPresCondSusIBS;
  final double vDifCBS;
  final double vDevTribCBS;
  final double vCredPresCBS;
  final double vCredPresCondSusCBS;

  String xml() {
    String t(String tag, double v) => '<$tag>${formatarDecimal(v, 2)}</$tag>';
    return '<IBSCBSTot>${t('vBCIBSCBS', vBCIBSCBS)}'
        '<gIBS><gIBSUF>${t('vDif', vDifUF)}${t('vDevTrib', vDevTribUF)}${t('vIBSUF', vIBSUF)}</gIBSUF>'
        '<gIBSMun>${t('vDif', vDifMun)}${t('vDevTrib', vDevTribMun)}${t('vIBSMun', vIBSMun)}</gIBSMun>'
        '${t('vIBS', vIBS ?? (vIBSUF + vIBSMun))}${t('vCredPres', vCredPresIBS)}'
        '${t('vCredPresCondSus', vCredPresCondSusIBS)}</gIBS>'
        '<gCBS>${t('vDif', vDifCBS)}${t('vDevTrib', vDevTribCBS)}${t('vCBS', vCBS)}'
        '${t('vCredPres', vCredPresCBS)}${t('vCredPresCondSus', vCredPresCondSusCBS)}</gCBS></IBSCBSTot>';
  }
}

/// Grupo `imposto` do item, com todos os valores informados pelo app.
///
/// Ordem do schema: vTotTrib, (ICMS, IPI, II) ou (IPI, ISSQN), PIS, PISST,
/// COFINS, COFINSST, ICMSUFDest, IBSCBS.
class ImpostoItem {
  const ImpostoItem({
    this.vTotTrib,
    this.icms,
    this.ipi,
    this.ii,
    this.issqn,
    this.pis,
    this.pisSt,
    this.cofins,
    this.cofinsSt,
    this.icmsUfDest,
    this.ibsCbs,
  });

  /// Valor aproximado dos tributos (Lei 12.741/2012).
  final double? vTotTrib;
  final Icms? icms;
  final IpiGeral? ipi;
  final ImpostoImportacao? ii;

  /// Serviço (NF-e conjugada): exclui ICMS e II.
  final Issqn? issqn;
  final PisGeral? pis;
  final PisSt? pisSt;
  final CofinsGeral? cofins;
  final CofinsSt? cofinsSt;
  final IcmsUfDest? icmsUfDest;
  final IbsCbs? ibsCbs;

  String xml(int crt) {
    final b = StringBuffer('<imposto>');
    if (vTotTrib != null) b.write('<vTotTrib>${formatarDecimal(vTotTrib!, 2)}</vTotTrib>');
    if (issqn != null) {
      if (ipi != null) b.write(_xmlIpi(ipi!));
      b.write(serializarGrupo('ISSQN', issqn!.valores));
    } else {
      if (icms != null) b.write(icms!.xml(crt));
      if (ipi != null) b.write(_xmlIpi(ipi!));
      if (ii != null) b.write(serializarGrupo('II', ii!.valores));
    }
    if (pis != null) b.write(_xmlPis(pis!));
    if (pisSt != null) b.write(serializarGrupo('PISST', pisSt!.valores));
    if (cofins != null) b.write(_xmlCofins(cofins!));
    if (cofinsSt != null) b.write(serializarGrupo('COFINSST', cofinsSt!.valores));
    if (icmsUfDest != null) b.write(serializarGrupo('ICMSUFDest', icmsUfDest!.valores));
    if (ibsCbs != null) b.write(ibsCbs!.xml());
    b.write('</imposto>');
    return b.toString();
  }
}

/// Totais da nota (grupo `total`), informados pelo app.
class TotalNfe {
  const TotalNfe({required this.icmsTot, this.issqnTot, this.retTrib, this.ibsCbsTot});

  final IcmsTot icmsTot;
  final IssqnTot? issqnTot;
  final RetTrib? retTrib;
  final IbsCbsTot? ibsCbsTot;

  /// Valor total da nota (vNF) informado.
  double get vNF => icmsTot.vNF ?? 0;

  String xml() {
    final b = StringBuffer('<total>${serializarGrupo('ICMSTot', icmsTot.valores)}');
    if (issqnTot != null) b.write(serializarGrupo('ISSQNtot', issqnTot!.valores));
    if (retTrib != null) b.write(serializarGrupo('retTrib', retTrib!.valores));
    if (ibsCbsTot != null) b.write(ibsCbsTot!.xml());
    b.write('</total>');
    return b.toString();
  }
}
