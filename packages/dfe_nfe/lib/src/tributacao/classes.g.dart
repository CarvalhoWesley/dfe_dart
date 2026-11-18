// GERADO por tools/extrair_grupos a partir do ZeusFiscal. NÃO EDITE À MÃO.
// ignore_for_file: lines_longer_than_80_chars

import 'grupo.dart';

/// ICMS do item (equivalente ao `ICMSGeral` do Zeus).
///
/// Campos dos grupos ICMS00, ICMS02, ICMS10, ICMS15, ICMS20, ICMS30, ICMS40, ICMS51, ICMS53, ICMS60, ICMS61, ICMS70, ICMS90, ICMSPart, ICMSST, ICMSSN101, ICMSSN102, ICMSSN201, ICMSSN202, ICMSSN500, ICMSSN900 do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class IcmsGeral {
  const IcmsGeral({
    this.orig,
    this.cst,
    this.modBC,
    this.vBC,
    this.pICMS,
    this.vICMS,
    this.pFCP,
    this.vFCP,
    this.qBCMono,
    this.adRemICMS,
    this.vICMSMono,
    this.vBCFCP,
    this.modBCST,
    this.pMVAST,
    this.pRedBCST,
    this.vBCST,
    this.pICMSST,
    this.vICMSST,
    this.vBCFCPST,
    this.pFCPST,
    this.vFCPST,
    this.vICMSSTDeson,
    this.motDesICMSST,
    this.qBCMonoReten,
    this.adRemICMSReten,
    this.vICMSMonoReten,
    this.pRedAdRem,
    this.motRedAdRem,
    this.pRedBC,
    this.vICMSDeson,
    this.motDesICMS,
    this.indDeduzDeson,
    this.cBenefRBC,
    this.vICMSOp,
    this.pDif,
    this.vICMSDif,
    this.pFCPDif,
    this.vFCPDif,
    this.vFCPEfet,
    this.vICMSMonoOp,
    this.vICMSMonoDif,
    this.qBCMonoDif,
    this.adRemICMSDif,
    this.vBCSTRet,
    this.pST,
    this.vICMSSubstituto,
    this.vICMSSTRet,
    this.vBCFCPSTRet,
    this.pFCPSTRet,
    this.vFCPSTRet,
    this.pRedBCEfet,
    this.vBCEfet,
    this.pICMSEfet,
    this.vICMSEfet,
    this.qBCMonoRet,
    this.adRemICMSRet,
    this.vICMSMonoRet,
    this.pBCOp,
    this.ufst,
    this.vBCSTDest,
    this.vICMSSTDest,
    this.csosn,
    this.pCredSN,
    this.vCredICMSSN,
  });

  /// `orig`
  final String? orig;
  /// `CST`
  final String? cst;
  /// `modBC`
  final String? modBC;
  /// `vBC` (2 casas)
  final double? vBC;
  /// `pICMS` (4 casas)
  final double? pICMS;
  /// `vICMS` (2 casas)
  final double? vICMS;
  /// `pFCP` (4 casas)
  final double? pFCP;
  /// `vFCP` (2 casas)
  final double? vFCP;
  /// `qBCMono` (4 casas)
  final double? qBCMono;
  /// `adRemICMS` (4 casas)
  final double? adRemICMS;
  /// `vICMSMono` (2 casas)
  final double? vICMSMono;
  /// `vBCFCP` (2 casas)
  final double? vBCFCP;
  /// `modBCST`
  final String? modBCST;
  /// `pMVAST` (4 casas)
  final double? pMVAST;
  /// `pRedBCST` (4 casas)
  final double? pRedBCST;
  /// `vBCST` (2 casas)
  final double? vBCST;
  /// `pICMSST` (4 casas)
  final double? pICMSST;
  /// `vICMSST` (2 casas)
  final double? vICMSST;
  /// `vBCFCPST` (2 casas)
  final double? vBCFCPST;
  /// `pFCPST` (4 casas)
  final double? pFCPST;
  /// `vFCPST` (2 casas)
  final double? vFCPST;
  /// `vICMSSTDeson` (2 casas)
  final double? vICMSSTDeson;
  /// `motDesICMSST`
  final String? motDesICMSST;
  /// `qBCMonoReten` (4 casas)
  final double? qBCMonoReten;
  /// `adRemICMSReten` (4 casas)
  final double? adRemICMSReten;
  /// `vICMSMonoReten` (2 casas)
  final double? vICMSMonoReten;
  /// `pRedAdRem` (2 casas)
  final double? pRedAdRem;
  /// `motRedAdRem`
  final int? motRedAdRem;
  /// `pRedBC` (4 casas)
  final double? pRedBC;
  /// `vICMSDeson` (2 casas)
  final double? vICMSDeson;
  /// `motDesICMS`
  final String? motDesICMS;
  /// `indDeduzDeson`
  final String? indDeduzDeson;
  /// `cBenefRBC`
  final String? cBenefRBC;
  /// `vICMSOp` (2 casas)
  final double? vICMSOp;
  /// `pDif` (4 casas)
  final double? pDif;
  /// `vICMSDif` (2 casas)
  final double? vICMSDif;
  /// `pFCPDif` (4 casas)
  final double? pFCPDif;
  /// `vFCPDif` (2 casas)
  final double? vFCPDif;
  /// `vFCPEfet` (2 casas)
  final double? vFCPEfet;
  /// `vICMSMonoOp` (2 casas)
  final double? vICMSMonoOp;
  /// `vICMSMonoDif` (2 casas)
  final double? vICMSMonoDif;
  /// `qBCMonoDif` (4 casas)
  final double? qBCMonoDif;
  /// `adRemICMSDif` (4 casas)
  final double? adRemICMSDif;
  /// `vBCSTRet` (2 casas)
  final double? vBCSTRet;
  /// `pST` (4 casas)
  final double? pST;
  /// `vICMSSubstituto` (2 casas)
  final double? vICMSSubstituto;
  /// `vICMSSTRet` (2 casas)
  final double? vICMSSTRet;
  /// `vBCFCPSTRet` (2 casas)
  final double? vBCFCPSTRet;
  /// `pFCPSTRet` (4 casas)
  final double? pFCPSTRet;
  /// `vFCPSTRet` (2 casas)
  final double? vFCPSTRet;
  /// `pRedBCEfet` (4 casas)
  final double? pRedBCEfet;
  /// `vBCEfet` (2 casas)
  final double? vBCEfet;
  /// `pICMSEfet` (4 casas)
  final double? pICMSEfet;
  /// `vICMSEfet` (2 casas)
  final double? vICMSEfet;
  /// `qBCMonoRet` (4 casas)
  final double? qBCMonoRet;
  /// `adRemICMSRet` (4 casas)
  final double? adRemICMSRet;
  /// `vICMSMonoRet` (2 casas)
  final double? vICMSMonoRet;
  /// `pBCOp` (4 casas)
  final double? pBCOp;
  /// `UFST`
  final String? ufst;
  /// `vBCSTDest` (2 casas)
  final double? vBCSTDest;
  /// `vICMSSTDest` (2 casas)
  final double? vICMSSTDest;
  /// `CSOSN`
  final String? csosn;
  /// `pCredSN` (4 casas)
  final double? pCredSN;
  /// `vCredICMSSN` (2 casas)
  final double? vCredICMSSN;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'orig': orig,
        'CST': cst,
        'modBC': modBC,
        'vBC': vBC,
        'pICMS': pICMS,
        'vICMS': vICMS,
        'pFCP': pFCP,
        'vFCP': vFCP,
        'qBCMono': qBCMono,
        'adRemICMS': adRemICMS,
        'vICMSMono': vICMSMono,
        'vBCFCP': vBCFCP,
        'modBCST': modBCST,
        'pMVAST': pMVAST,
        'pRedBCST': pRedBCST,
        'vBCST': vBCST,
        'pICMSST': pICMSST,
        'vICMSST': vICMSST,
        'vBCFCPST': vBCFCPST,
        'pFCPST': pFCPST,
        'vFCPST': vFCPST,
        'vICMSSTDeson': vICMSSTDeson,
        'motDesICMSST': motDesICMSST,
        'qBCMonoReten': qBCMonoReten,
        'adRemICMSReten': adRemICMSReten,
        'vICMSMonoReten': vICMSMonoReten,
        'pRedAdRem': pRedAdRem,
        'motRedAdRem': motRedAdRem,
        'pRedBC': pRedBC,
        'vICMSDeson': vICMSDeson,
        'motDesICMS': motDesICMS,
        'indDeduzDeson': indDeduzDeson,
        'cBenefRBC': cBenefRBC,
        'vICMSOp': vICMSOp,
        'pDif': pDif,
        'vICMSDif': vICMSDif,
        'pFCPDif': pFCPDif,
        'vFCPDif': vFCPDif,
        'vFCPEfet': vFCPEfet,
        'vICMSMonoOp': vICMSMonoOp,
        'vICMSMonoDif': vICMSMonoDif,
        'qBCMonoDif': qBCMonoDif,
        'adRemICMSDif': adRemICMSDif,
        'vBCSTRet': vBCSTRet,
        'pST': pST,
        'vICMSSubstituto': vICMSSubstituto,
        'vICMSSTRet': vICMSSTRet,
        'vBCFCPSTRet': vBCFCPSTRet,
        'pFCPSTRet': pFCPSTRet,
        'vFCPSTRet': vFCPSTRet,
        'pRedBCEfet': pRedBCEfet,
        'vBCEfet': vBCEfet,
        'pICMSEfet': pICMSEfet,
        'vICMSEfet': vICMSEfet,
        'qBCMonoRet': qBCMonoRet,
        'adRemICMSRet': adRemICMSRet,
        'vICMSMonoRet': vICMSMonoRet,
        'pBCOp': pBCOp,
        'UFST': ufst,
        'vBCSTDest': vBCSTDest,
        'vICMSSTDest': vICMSSTDest,
        'CSOSN': csosn,
        'pCredSN': pCredSN,
        'vCredICMSSN': vCredICMSSN,
      };
}

/// PIS do item (equivalente ao `PISGeral` do Zeus).
///
/// Campos dos grupos PISAliq, PISQtde, PISNT, PISOutr do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class PisGeral {
  const PisGeral({
    this.cst,
    this.vBC,
    this.pPIS,
    this.vPIS,
    this.qBCProd,
    this.vAliqProd,
  });

  /// `CST`
  final String? cst;
  /// `vBC` (2 casas)
  final double? vBC;
  /// `pPIS` (4 casas)
  final double? pPIS;
  /// `vPIS` (2 casas)
  final double? vPIS;
  /// `qBCProd` (4 casas)
  final double? qBCProd;
  /// `vAliqProd` (4 casas)
  final double? vAliqProd;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'CST': cst,
        'vBC': vBC,
        'pPIS': pPIS,
        'vPIS': vPIS,
        'qBCProd': qBCProd,
        'vAliqProd': vAliqProd,
      };
}

/// COFINS do item (equivalente ao `COFINSGeral` do Zeus).
///
/// Campos dos grupos COFINSAliq, COFINSQtde, COFINSNT, COFINSOutr do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class CofinsGeral {
  const CofinsGeral({
    this.cst,
    this.vBC,
    this.pCOFINS,
    this.vCOFINS,
    this.qBCProd,
    this.vAliqProd,
  });

  /// `CST`
  final String? cst;
  /// `vBC` (2 casas)
  final double? vBC;
  /// `pCOFINS` (4 casas)
  final double? pCOFINS;
  /// `vCOFINS` (2 casas)
  final double? vCOFINS;
  /// `qBCProd` (4 casas)
  final double? qBCProd;
  /// `vAliqProd` (4 casas)
  final double? vAliqProd;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'CST': cst,
        'vBC': vBC,
        'pCOFINS': pCOFINS,
        'vCOFINS': vCOFINS,
        'qBCProd': qBCProd,
        'vAliqProd': vAliqProd,
      };
}

/// IPI do item (equivalente ao `IPIGeral` do Zeus). Somente NF-e.
///
/// Campos dos grupos IPI, IPITrib, IPINT do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class IpiGeral {
  const IpiGeral({
    this.clEnq,
    this.cnpjProd,
    this.cSelo,
    this.qSelo,
    this.cEnq,
    this.cst,
    this.vBC,
    this.pIPI,
    this.qUnid,
    this.vUnid,
    this.vIPI,
  });

  /// `clEnq`
  final String? clEnq;
  /// `CNPJProd`
  final String? cnpjProd;
  /// `cSelo`
  final String? cSelo;
  /// `qSelo`
  final int? qSelo;
  /// `cEnq`
  final String? cEnq;
  /// `CST`
  final String? cst;
  /// `vBC` (2 casas)
  final double? vBC;
  /// `pIPI` (4 casas)
  final double? pIPI;
  /// `qUnid` (4 casas)
  final double? qUnid;
  /// `vUnid` (4 casas)
  final double? vUnid;
  /// `vIPI` (2 casas)
  final double? vIPI;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'clEnq': clEnq,
        'CNPJProd': cnpjProd,
        'cSelo': cSelo,
        'qSelo': qSelo,
        'cEnq': cEnq,
        'CST': cst,
        'vBC': vBC,
        'pIPI': pIPI,
        'qUnid': qUnid,
        'vUnid': vUnid,
        'vIPI': vIPI,
      };
}

/// PIS-ST do item (grupo `PISST`).
///
/// Campos dos grupos PISST do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class PisSt {
  const PisSt({
    this.vBC,
    this.pPIS,
    this.qBCProd,
    this.vAliqProd,
    this.vPIS,
    this.indSomaPISST,
  });

  /// `vBC` (2 casas)
  final double? vBC;
  /// `pPIS` (4 casas)
  final double? pPIS;
  /// `qBCProd` (4 casas)
  final double? qBCProd;
  /// `vAliqProd` (4 casas)
  final double? vAliqProd;
  /// `vPIS` (2 casas)
  final double? vPIS;
  /// `indSomaPISST`
  final String? indSomaPISST;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vBC': vBC,
        'pPIS': pPIS,
        'qBCProd': qBCProd,
        'vAliqProd': vAliqProd,
        'vPIS': vPIS,
        'indSomaPISST': indSomaPISST,
      };
}

/// COFINS-ST do item (grupo `COFINSST`).
///
/// Campos dos grupos COFINSST do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class CofinsSt {
  const CofinsSt({
    this.vBC,
    this.pCOFINS,
    this.qBCProd,
    this.vAliqProd,
    this.vCOFINS,
    this.indSomaCOFINSST,
  });

  /// `vBC` (2 casas)
  final double? vBC;
  /// `pCOFINS` (4 casas)
  final double? pCOFINS;
  /// `qBCProd` (4 casas)
  final double? qBCProd;
  /// `vAliqProd` (4 casas)
  final double? vAliqProd;
  /// `vCOFINS` (2 casas)
  final double? vCOFINS;
  /// `indSomaCOFINSST`
  final String? indSomaCOFINSST;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vBC': vBC,
        'pCOFINS': pCOFINS,
        'qBCProd': qBCProd,
        'vAliqProd': vAliqProd,
        'vCOFINS': vCOFINS,
        'indSomaCOFINSST': indSomaCOFINSST,
      };
}

/// Imposto de Importação do item (grupo `II`).
///
/// Campos dos grupos II do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class ImpostoImportacao {
  const ImpostoImportacao({
    this.vBC,
    this.vDespAdu,
    this.vII,
    this.vIOF,
  });

  /// `vBC` (2 casas)
  final double? vBC;
  /// `vDespAdu` (2 casas)
  final double? vDespAdu;
  /// `vII` (2 casas)
  final double? vII;
  /// `vIOF` (2 casas)
  final double? vIOF;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vBC': vBC,
        'vDespAdu': vDespAdu,
        'vII': vII,
        'vIOF': vIOF,
      };
}

/// ICMS interestadual para consumidor final (grupo `ICMSUFDest`, DIFAL).
///
/// Campos dos grupos ICMSUFDest do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class IcmsUfDest {
  const IcmsUfDest({
    this.vBCUFDest,
    this.vBCFCPUFDest,
    this.pFCPUFDest,
    this.pICMSUFDest,
    this.pICMSInter,
    this.pICMSInterPart,
    this.vFCPUFDest,
    this.vICMSUFDest,
    this.vICMSUFRemet,
  });

  /// `vBCUFDest` (2 casas)
  final double? vBCUFDest;
  /// `vBCFCPUFDest` (2 casas)
  final double? vBCFCPUFDest;
  /// `pFCPUFDest` (4 casas)
  final double? pFCPUFDest;
  /// `pICMSUFDest` (4 casas)
  final double? pICMSUFDest;
  /// `pICMSInter` (2 casas)
  final double? pICMSInter;
  /// `pICMSInterPart` (4 casas)
  final double? pICMSInterPart;
  /// `vFCPUFDest` (2 casas)
  final double? vFCPUFDest;
  /// `vICMSUFDest` (2 casas)
  final double? vICMSUFDest;
  /// `vICMSUFRemet` (2 casas)
  final double? vICMSUFRemet;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vBCUFDest': vBCUFDest,
        'vBCFCPUFDest': vBCFCPUFDest,
        'pFCPUFDest': pFCPUFDest,
        'pICMSUFDest': pICMSUFDest,
        'pICMSInter': pICMSInter,
        'pICMSInterPart': pICMSInterPart,
        'vFCPUFDest': vFCPUFDest,
        'vICMSUFDest': vICMSUFDest,
        'vICMSUFRemet': vICMSUFRemet,
      };
}

/// ISSQN do item (grupo `ISSQN`).
///
/// Campos dos grupos ISSQN do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class Issqn {
  const Issqn({
    this.vBC,
    this.vAliq,
    this.vISSQN,
    this.cMunFG,
    this.cListServ,
    this.vDeducao,
    this.vOutro,
    this.vDescIncond,
    this.vDescCond,
    this.vISSRet,
    this.indISS,
    this.cServico,
    this.cMun,
    this.cPais,
    this.nProcesso,
    this.indIncentivo,
  });

  /// `vBC` (2 casas)
  final double? vBC;
  /// `vAliq` (2 casas)
  final double? vAliq;
  /// `vISSQN` (2 casas)
  final double? vISSQN;
  /// `cMunFG`
  final int? cMunFG;
  /// `cListServ`
  final String? cListServ;
  /// `vDeducao` (2 casas)
  final double? vDeducao;
  /// `vOutro` (2 casas)
  final double? vOutro;
  /// `vDescIncond` (2 casas)
  final double? vDescIncond;
  /// `vDescCond` (2 casas)
  final double? vDescCond;
  /// `vISSRet` (2 casas)
  final double? vISSRet;
  /// `indISS`
  final String? indISS;
  /// `cServico`
  final String? cServico;
  /// `cMun`
  final int? cMun;
  /// `cPais`
  final int? cPais;
  /// `nProcesso`
  final String? nProcesso;
  /// `indIncentivo`
  final String? indIncentivo;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vBC': vBC,
        'vAliq': vAliq,
        'vISSQN': vISSQN,
        'cMunFG': cMunFG,
        'cListServ': cListServ,
        'vDeducao': vDeducao,
        'vOutro': vOutro,
        'vDescIncond': vDescIncond,
        'vDescCond': vDescCond,
        'vISSRet': vISSRet,
        'indISS': indISS,
        'cServico': cServico,
        'cMun': cMun,
        'cPais': cPais,
        'nProcesso': nProcesso,
        'indIncentivo': indIncentivo,
      };
}

/// Totais de ICMS da nota (grupo `ICMSTot`), informados pelo app.
///
/// Campos dos grupos ICMSTot do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class IcmsTot {
  const IcmsTot({
    this.vBC,
    this.vICMS,
    this.vICMSDeson,
    this.vFCPUFDest,
    this.vICMSUFDest,
    this.vICMSUFRemet,
    this.vFCP,
    this.vBCST,
    this.vST,
    this.vFCPST,
    this.vFCPSTRet,
    this.qBCMono,
    this.vICMSMono,
    this.qBCMonoReten,
    this.vICMSMonoReten,
    this.qBCMonoRet,
    this.vICMSMonoRet,
    this.vProd,
    this.vFrete,
    this.vSeg,
    this.vDesc,
    this.vII,
    this.vIPI,
    this.vIPIDevol,
    this.vPIS,
    this.vCOFINS,
    this.vOutro,
    this.vNF,
    this.vTotTrib,
  });

  /// `vBC` (2 casas)
  final double? vBC;
  /// `vICMS` (2 casas)
  final double? vICMS;
  /// `vICMSDeson` (2 casas)
  final double? vICMSDeson;
  /// `vFCPUFDest` (2 casas)
  final double? vFCPUFDest;
  /// `vICMSUFDest` (2 casas)
  final double? vICMSUFDest;
  /// `vICMSUFRemet` (2 casas)
  final double? vICMSUFRemet;
  /// `vFCP` (2 casas)
  final double? vFCP;
  /// `vBCST` (2 casas)
  final double? vBCST;
  /// `vST` (2 casas)
  final double? vST;
  /// `vFCPST` (2 casas)
  final double? vFCPST;
  /// `vFCPSTRet` (2 casas)
  final double? vFCPSTRet;
  /// `qBCMono` (2 casas)
  final double? qBCMono;
  /// `vICMSMono` (2 casas)
  final double? vICMSMono;
  /// `qBCMonoReten` (2 casas)
  final double? qBCMonoReten;
  /// `vICMSMonoReten` (2 casas)
  final double? vICMSMonoReten;
  /// `qBCMonoRet` (2 casas)
  final double? qBCMonoRet;
  /// `vICMSMonoRet` (2 casas)
  final double? vICMSMonoRet;
  /// `vProd` (2 casas)
  final double? vProd;
  /// `vFrete` (2 casas)
  final double? vFrete;
  /// `vSeg` (2 casas)
  final double? vSeg;
  /// `vDesc` (2 casas)
  final double? vDesc;
  /// `vII` (2 casas)
  final double? vII;
  /// `vIPI` (2 casas)
  final double? vIPI;
  /// `vIPIDevol` (2 casas)
  final double? vIPIDevol;
  /// `vPIS` (2 casas)
  final double? vPIS;
  /// `vCOFINS` (2 casas)
  final double? vCOFINS;
  /// `vOutro` (2 casas)
  final double? vOutro;
  /// `vNF` (2 casas)
  final double? vNF;
  /// `vTotTrib` (2 casas)
  final double? vTotTrib;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vBC': vBC,
        'vICMS': vICMS,
        'vICMSDeson': vICMSDeson,
        'vFCPUFDest': vFCPUFDest,
        'vICMSUFDest': vICMSUFDest,
        'vICMSUFRemet': vICMSUFRemet,
        'vFCP': vFCP,
        'vBCST': vBCST,
        'vST': vST,
        'vFCPST': vFCPST,
        'vFCPSTRet': vFCPSTRet,
        'qBCMono': qBCMono,
        'vICMSMono': vICMSMono,
        'qBCMonoReten': qBCMonoReten,
        'vICMSMonoReten': vICMSMonoReten,
        'qBCMonoRet': qBCMonoRet,
        'vICMSMonoRet': vICMSMonoRet,
        'vProd': vProd,
        'vFrete': vFrete,
        'vSeg': vSeg,
        'vDesc': vDesc,
        'vII': vII,
        'vIPI': vIPI,
        'vIPIDevol': vIPIDevol,
        'vPIS': vPIS,
        'vCOFINS': vCOFINS,
        'vOutro': vOutro,
        'vNF': vNF,
        'vTotTrib': vTotTrib,
      };
}

/// Totais de ISSQN da nota (grupo `ISSQNtot`).
///
/// Campos dos grupos ISSQNtot do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class IssqnTot {
  const IssqnTot({
    this.vServ,
    this.vBC,
    this.vISS,
    this.vPIS,
    this.vCOFINS,
    this.dCompet,
    this.vDeducao,
    this.vOutro,
    this.vDescIncond,
    this.vDescCond,
    this.vISSRet,
    this.cRegTrib,
  });

  /// `vServ` (2 casas)
  final double? vServ;
  /// `vBC` (2 casas)
  final double? vBC;
  /// `vISS` (2 casas)
  final double? vISS;
  /// `vPIS` (2 casas)
  final double? vPIS;
  /// `vCOFINS` (2 casas)
  final double? vCOFINS;
  /// `dCompet`
  final String? dCompet;
  /// `vDeducao` (2 casas)
  final double? vDeducao;
  /// `vOutro` (2 casas)
  final double? vOutro;
  /// `vDescIncond` (2 casas)
  final double? vDescIncond;
  /// `vDescCond` (2 casas)
  final double? vDescCond;
  /// `vISSRet` (2 casas)
  final double? vISSRet;
  /// `cRegTrib`
  final String? cRegTrib;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vServ': vServ,
        'vBC': vBC,
        'vISS': vISS,
        'vPIS': vPIS,
        'vCOFINS': vCOFINS,
        'dCompet': dCompet,
        'vDeducao': vDeducao,
        'vOutro': vOutro,
        'vDescIncond': vDescIncond,
        'vDescCond': vDescCond,
        'vISSRet': vISSRet,
        'cRegTrib': cRegTrib,
      };
}

/// Retenção de tributos (grupo `retTrib`).
///
/// Campos dos grupos retTrib do Zeus. Os valores são
/// **informados pelo app** (nada é calculado na emissão).
class RetTrib {
  const RetTrib({
    this.vRetPIS,
    this.vRetCOFINS,
    this.vRetCSLL,
    this.vBCIRRF,
    this.vIRRF,
    this.vBCRetPrev,
    this.vRetPrev,
  });

  /// `vRetPIS` (2 casas)
  final double? vRetPIS;
  /// `vRetCOFINS` (2 casas)
  final double? vRetCOFINS;
  /// `vRetCSLL` (2 casas)
  final double? vRetCSLL;
  /// `vBCIRRF` (2 casas)
  final double? vBCIRRF;
  /// `vIRRF` (2 casas)
  final double? vIRRF;
  /// `vBCRetPrev` (2 casas)
  final double? vBCRetPrev;
  /// `vRetPrev` (2 casas)
  final double? vRetPrev;

  /// Valores indexados pelo nome do campo no XML.
  Map<String, Object?> get valores => {
        'vRetPIS': vRetPIS,
        'vRetCOFINS': vRetCOFINS,
        'vRetCSLL': vRetCSLL,
        'vBCIRRF': vBCIRRF,
        'vIRRF': vIRRF,
        'vBCRetPrev': vBCRetPrev,
        'vRetPrev': vRetPrev,
      };
}

/// Grupo `IBSCBS` (classe `IBSCBS` do Zeus). Valores informados pelo app.
class IBSCBS implements GrupoXml {
  const IBSCBS({
    required this.cst,
    this.cClassTrib,
    this.indDoacao,
    this.gIBSCBS,
    this.gIBSCBSMono,
    this.gTransfCred,
    this.gAjusteCompet,
    this.gEstornoCred,
    this.gCredPresOper,
    this.gCredPresIBSZFM,
  });

  /// `CST`
  final String cst;
  /// `cClassTrib`
  final String? cClassTrib;
  /// `indDoacao`
  final String? indDoacao;
  /// `gIBSCBS`
  final GIBSCBS? gIBSCBS;
  /// `gIBSCBSMono`
  final GIBSCBSMono? gIBSCBSMono;
  /// `gTransfCred`
  final GTransfCred? gTransfCred;
  /// `gAjusteCompet`
  final GAjusteCompet? gAjusteCompet;
  /// `gEstornoCred`
  final GEstornoCred? gEstornoCred;
  /// `gCredPresOper`
  final GCredPresOper? gCredPresOper;
  /// `gCredPresIBSZFM`
  final GCredPresIBSZFM? gCredPresIBSZFM;

  @override
  String get grupo => 'IBSCBS';

  @override
  Map<String, Object?> get valores => {
        'CST': cst,
        'cClassTrib': cClassTrib,
        'indDoacao': indDoacao,
        'gIBSCBS': gIBSCBS,
        'gIBSCBSMono': gIBSCBSMono,
        'gTransfCred': gTransfCred,
        'gAjusteCompet': gAjusteCompet,
        'gEstornoCred': gEstornoCred,
        'gCredPresOper': gCredPresOper,
        'gCredPresIBSZFM': gCredPresIBSZFM,
      };
}

/// Grupo `gIBSCBS` (classe `gIBSCBS` do Zeus). Valores informados pelo app.
class GIBSCBS implements GrupoXml {
  const GIBSCBS({
    required this.vBC,
    this.gIBSUF,
    this.gIBSMun,
    this.vIBS,
    this.gCBS,
    this.gTribRegular,
    this.gTribCompraGov,
  });

  /// `vBC` (2 casas)
  final double vBC;
  /// `gIBSUF`
  final GIBSUF? gIBSUF;
  /// `gIBSMun`
  final GIBSMun? gIBSMun;
  /// `vIBS` (2 casas)
  final double? vIBS;
  /// `gCBS`
  final GCBS? gCBS;
  /// `gTribRegular`
  final GTribRegular? gTribRegular;
  /// `gTribCompraGov`
  final GTribCompraGov? gTribCompraGov;

  @override
  String get grupo => 'gIBSCBS';

  @override
  Map<String, Object?> get valores => {
        'vBC': vBC,
        'gIBSUF': gIBSUF,
        'gIBSMun': gIBSMun,
        'vIBS': vIBS,
        'gCBS': gCBS,
        'gTribRegular': gTribRegular,
        'gTribCompraGov': gTribCompraGov,
      };
}

/// Grupo `gIBSUF` (classe `gIBSUF` do Zeus). Valores informados pelo app.
class GIBSUF implements GrupoXml {
  const GIBSUF({
    required this.pIBSUF,
    this.gDif,
    this.gDevTrib,
    this.gRed,
    required this.vIBSUF,
  });

  /// `pIBSUF` (4 casas)
  final double pIBSUF;
  /// `gDif`
  final GDif? gDif;
  /// `gDevTrib`
  final GDevTrib? gDevTrib;
  /// `gRed`
  final GRed? gRed;
  /// `vIBSUF` (2 casas)
  final double vIBSUF;

  @override
  String get grupo => 'gIBSUF';

  @override
  Map<String, Object?> get valores => {
        'pIBSUF': pIBSUF,
        'gDif': gDif,
        'gDevTrib': gDevTrib,
        'gRed': gRed,
        'vIBSUF': vIBSUF,
      };
}

/// Grupo `gDif` (classe `gDif` do Zeus). Valores informados pelo app.
class GDif implements GrupoXml {
  const GDif({
    required this.pDif,
    required this.vDif,
  });

  /// `pDif` (4 casas)
  final double pDif;
  /// `vDif` (2 casas)
  final double vDif;

  @override
  String get grupo => 'gDif';

  @override
  Map<String, Object?> get valores => {
        'pDif': pDif,
        'vDif': vDif,
      };
}

/// Grupo `gDevTrib` (classe `gDevTrib` do Zeus). Valores informados pelo app.
class GDevTrib implements GrupoXml {
  const GDevTrib({
    required this.vDevTrib,
  });

  /// `vDevTrib` (2 casas)
  final double vDevTrib;

  @override
  String get grupo => 'gDevTrib';

  @override
  Map<String, Object?> get valores => {
        'vDevTrib': vDevTrib,
      };
}

/// Grupo `gRed` (classe `gRed` do Zeus). Valores informados pelo app.
class GRed implements GrupoXml {
  const GRed({
    required this.pRedAliq,
    required this.pAliqEfet,
  });

  /// `pRedAliq` (4 casas)
  final double pRedAliq;
  /// `pAliqEfet` (4 casas)
  final double pAliqEfet;

  @override
  String get grupo => 'gRed';

  @override
  Map<String, Object?> get valores => {
        'pRedAliq': pRedAliq,
        'pAliqEfet': pAliqEfet,
      };
}

/// Grupo `gIBSMun` (classe `gIBSMun` do Zeus). Valores informados pelo app.
class GIBSMun implements GrupoXml {
  const GIBSMun({
    required this.pIBSMun,
    this.gDif,
    this.gDevTrib,
    this.gRed,
    required this.vIBSMun,
  });

  /// `pIBSMun` (4 casas)
  final double pIBSMun;
  /// `gDif`
  final GDif? gDif;
  /// `gDevTrib`
  final GDevTrib? gDevTrib;
  /// `gRed`
  final GRed? gRed;
  /// `vIBSMun` (2 casas)
  final double vIBSMun;

  @override
  String get grupo => 'gIBSMun';

  @override
  Map<String, Object?> get valores => {
        'pIBSMun': pIBSMun,
        'gDif': gDif,
        'gDevTrib': gDevTrib,
        'gRed': gRed,
        'vIBSMun': vIBSMun,
      };
}

/// Grupo `gCBS` (classe `gCBS` do Zeus). Valores informados pelo app.
class GCBS implements GrupoXml {
  const GCBS({
    required this.pCBS,
    this.gDif,
    this.gDevTrib,
    this.gRed,
    required this.vCBS,
  });

  /// `pCBS` (4 casas)
  final double pCBS;
  /// `gDif`
  final GDif? gDif;
  /// `gDevTrib`
  final GDevTrib? gDevTrib;
  /// `gRed`
  final GRed? gRed;
  /// `vCBS` (2 casas)
  final double vCBS;

  @override
  String get grupo => 'gCBS';

  @override
  Map<String, Object?> get valores => {
        'pCBS': pCBS,
        'gDif': gDif,
        'gDevTrib': gDevTrib,
        'gRed': gRed,
        'vCBS': vCBS,
      };
}

/// Grupo `gTribRegular` (classe `gTribRegular` do Zeus). Valores informados pelo app.
class GTribRegular implements GrupoXml {
  const GTribRegular({
    required this.cstReg,
    this.cClassTribReg,
    required this.pAliqEfetRegIBSUF,
    required this.vTribRegIBSUF,
    required this.pAliqEfetRegIBSMun,
    required this.vTribRegIBSMun,
    required this.pAliqEfetRegCBS,
    required this.vTribRegCBS,
  });

  /// `CSTReg`
  final String cstReg;
  /// `cClassTribReg`
  final String? cClassTribReg;
  /// `pAliqEfetRegIBSUF` (4 casas)
  final double pAliqEfetRegIBSUF;
  /// `vTribRegIBSUF` (2 casas)
  final double vTribRegIBSUF;
  /// `pAliqEfetRegIBSMun` (4 casas)
  final double pAliqEfetRegIBSMun;
  /// `vTribRegIBSMun` (2 casas)
  final double vTribRegIBSMun;
  /// `pAliqEfetRegCBS` (4 casas)
  final double pAliqEfetRegCBS;
  /// `vTribRegCBS` (2 casas)
  final double vTribRegCBS;

  @override
  String get grupo => 'gTribRegular';

  @override
  Map<String, Object?> get valores => {
        'CSTReg': cstReg,
        'cClassTribReg': cClassTribReg,
        'pAliqEfetRegIBSUF': pAliqEfetRegIBSUF,
        'vTribRegIBSUF': vTribRegIBSUF,
        'pAliqEfetRegIBSMun': pAliqEfetRegIBSMun,
        'vTribRegIBSMun': vTribRegIBSMun,
        'pAliqEfetRegCBS': pAliqEfetRegCBS,
        'vTribRegCBS': vTribRegCBS,
      };
}

/// Grupo `gTribCompraGov` (classe `gTribCompraGov` do Zeus). Valores informados pelo app.
class GTribCompraGov implements GrupoXml {
  const GTribCompraGov({
    required this.pAliqIBSUF,
    required this.vTribIBSUF,
    required this.pAliqIBSMun,
    required this.vTribIBSMun,
    required this.pAliqCBS,
    required this.vTribCBS,
  });

  /// `pAliqIBSUF` (4 casas)
  final double pAliqIBSUF;
  /// `vTribIBSUF` (2 casas)
  final double vTribIBSUF;
  /// `pAliqIBSMun` (4 casas)
  final double pAliqIBSMun;
  /// `vTribIBSMun` (2 casas)
  final double vTribIBSMun;
  /// `pAliqCBS` (4 casas)
  final double pAliqCBS;
  /// `vTribCBS` (2 casas)
  final double vTribCBS;

  @override
  String get grupo => 'gTribCompraGov';

  @override
  Map<String, Object?> get valores => {
        'pAliqIBSUF': pAliqIBSUF,
        'vTribIBSUF': vTribIBSUF,
        'pAliqIBSMun': pAliqIBSMun,
        'vTribIBSMun': vTribIBSMun,
        'pAliqCBS': pAliqCBS,
        'vTribCBS': vTribCBS,
      };
}

/// Grupo `gIBSCBSMono` (classe `gIBSCBSMono` do Zeus). Valores informados pelo app.
class GIBSCBSMono implements GrupoXml {
  const GIBSCBSMono({
    this.gMonoPadrao,
    this.gMonoReten,
    this.gMonoRet,
    this.gMonoDif,
    this.gIBSMonoAdRem,
    this.gIBSMonoAdValorem,
    this.gCBSMonoAdRem,
    this.gCBSMonoAdValorem,
    required this.vTotIBSMonoItem,
    required this.vTotCBSMonoItem,
  });

  /// `gMonoPadrao`
  final GMonoPadrao? gMonoPadrao;
  /// `gMonoReten`
  final GMonoReten? gMonoReten;
  /// `gMonoRet`
  final GMonoRet? gMonoRet;
  /// `gMonoDif`
  final GMonoDif? gMonoDif;
  /// `gIBSMonoAdRem`
  final GIBSMonoAdRem? gIBSMonoAdRem;
  /// `gIBSMonoAdValorem`
  final GIBSMonoAdValorem? gIBSMonoAdValorem;
  /// `gCBSMonoAdRem`
  final GCBSMonoAdRem? gCBSMonoAdRem;
  /// `gCBSMonoAdValorem`
  final GCBSMonoAdValorem? gCBSMonoAdValorem;
  /// `vTotIBSMonoItem` (2 casas)
  final double vTotIBSMonoItem;
  /// `vTotCBSMonoItem` (2 casas)
  final double vTotCBSMonoItem;

  @override
  String get grupo => 'gIBSCBSMono';

  @override
  Map<String, Object?> get valores => {
        'gMonoPadrao': gMonoPadrao,
        'gMonoReten': gMonoReten,
        'gMonoRet': gMonoRet,
        'gMonoDif': gMonoDif,
        'gIBSMonoAdRem': gIBSMonoAdRem,
        'gIBSMonoAdValorem': gIBSMonoAdValorem,
        'gCBSMonoAdRem': gCBSMonoAdRem,
        'gCBSMonoAdValorem': gCBSMonoAdValorem,
        'vTotIBSMonoItem': vTotIBSMonoItem,
        'vTotCBSMonoItem': vTotCBSMonoItem,
      };
}

/// Grupo `gMonoPadrao` (classe `gMonoPadrao` do Zeus). Valores informados pelo app.
class GMonoPadrao implements GrupoXml {
  const GMonoPadrao({
    required this.qBCMono,
    required this.adRemIBS,
    required this.adRemCBS,
    required this.vIBSMono,
    required this.vCBSMono,
  });

  /// `qBCMono` (4 casas)
  final double qBCMono;
  /// `adRemIBS` (4 casas)
  final double adRemIBS;
  /// `adRemCBS` (4 casas)
  final double adRemCBS;
  /// `vIBSMono` (2 casas)
  final double vIBSMono;
  /// `vCBSMono` (2 casas)
  final double vCBSMono;

  @override
  String get grupo => 'gMonoPadrao';

  @override
  Map<String, Object?> get valores => {
        'qBCMono': qBCMono,
        'adRemIBS': adRemIBS,
        'adRemCBS': adRemCBS,
        'vIBSMono': vIBSMono,
        'vCBSMono': vCBSMono,
      };
}

/// Grupo `gMonoReten` (classe `gMonoReten` do Zeus). Valores informados pelo app.
class GMonoReten implements GrupoXml {
  const GMonoReten({
    required this.qBCMonoReten,
    required this.adRemIBSReten,
    required this.vIBSMonoReten,
    required this.adRemCBSReten,
    required this.vCBSMonoReten,
  });

  /// `qBCMonoReten` (4 casas)
  final double qBCMonoReten;
  /// `adRemIBSReten` (4 casas)
  final double adRemIBSReten;
  /// `vIBSMonoReten` (2 casas)
  final double vIBSMonoReten;
  /// `adRemCBSReten` (4 casas)
  final double adRemCBSReten;
  /// `vCBSMonoReten` (2 casas)
  final double vCBSMonoReten;

  @override
  String get grupo => 'gMonoReten';

  @override
  Map<String, Object?> get valores => {
        'qBCMonoReten': qBCMonoReten,
        'adRemIBSReten': adRemIBSReten,
        'vIBSMonoReten': vIBSMonoReten,
        'adRemCBSReten': adRemCBSReten,
        'vCBSMonoReten': vCBSMonoReten,
      };
}

/// Grupo `gMonoRet` (classe `gMonoRet` do Zeus). Valores informados pelo app.
class GMonoRet implements GrupoXml {
  const GMonoRet({
    required this.qBCMonoRet,
    required this.adRemIBSRet,
    required this.vIBSMonoRet,
    required this.adRemCBSRet,
    required this.vCBSMonoRet,
  });

  /// `qBCMonoRet` (4 casas)
  final double qBCMonoRet;
  /// `adRemIBSRet` (4 casas)
  final double adRemIBSRet;
  /// `vIBSMonoRet` (2 casas)
  final double vIBSMonoRet;
  /// `adRemCBSRet` (4 casas)
  final double adRemCBSRet;
  /// `vCBSMonoRet` (2 casas)
  final double vCBSMonoRet;

  @override
  String get grupo => 'gMonoRet';

  @override
  Map<String, Object?> get valores => {
        'qBCMonoRet': qBCMonoRet,
        'adRemIBSRet': adRemIBSRet,
        'vIBSMonoRet': vIBSMonoRet,
        'adRemCBSRet': adRemCBSRet,
        'vCBSMonoRet': vCBSMonoRet,
      };
}

/// Grupo `gMonoDif` (classe `gMonoDif` do Zeus). Valores informados pelo app.
class GMonoDif implements GrupoXml {
  const GMonoDif({
    required this.pDifIBS,
    required this.vIBSMonoDif,
    required this.pDifCBS,
    required this.vCBSMonoDif,
  });

  /// `pDifIBS` (4 casas)
  final double pDifIBS;
  /// `vIBSMonoDif` (2 casas)
  final double vIBSMonoDif;
  /// `pDifCBS` (4 casas)
  final double pDifCBS;
  /// `vCBSMonoDif` (2 casas)
  final double vCBSMonoDif;

  @override
  String get grupo => 'gMonoDif';

  @override
  Map<String, Object?> get valores => {
        'pDifIBS': pDifIBS,
        'vIBSMonoDif': vIBSMonoDif,
        'pDifCBS': pDifCBS,
        'vCBSMonoDif': vCBSMonoDif,
      };
}

/// Grupo `gIBSMonoAdRem` (classe `gIBSMonoAdRem` do Zeus). Valores informados pelo app.
class GIBSMonoAdRem implements GrupoXml {
  const GIBSMonoAdRem({
    this.gMonoPadrao,
    this.gMonoReten,
    this.gMonoRet,
    this.gpBioDiferenca,
  });

  /// `gMonoPadrao`
  final GMonoPadraoIBSAdRem? gMonoPadrao;
  /// `gMonoReten`
  final GMonoRetenIBSAdRem? gMonoReten;
  /// `gMonoRet`
  final GMonoRetIBS? gMonoRet;
  /// `gpBioDiferenca`
  final GpBioDiferencaIBS? gpBioDiferenca;

  @override
  String get grupo => 'gIBSMonoAdRem';

  @override
  Map<String, Object?> get valores => {
        'gMonoPadrao': gMonoPadrao,
        'gMonoReten': gMonoReten,
        'gMonoRet': gMonoRet,
        'gpBioDiferenca': gpBioDiferenca,
      };
}

/// Grupo `gMonoPadraoIBSAdRem` (classe `gMonoPadraoIBSAdRem` do Zeus). Valores informados pelo app.
class GMonoPadraoIBSAdRem implements GrupoXml {
  const GMonoPadraoIBSAdRem({
    required this.qBCMono,
    required this.adRemIBS,
    required this.vIBSMono,
  });

  /// `qBCMono` (4 casas)
  final double qBCMono;
  /// `adRemIBS` (4 casas)
  final double adRemIBS;
  /// `vIBSMono` (2 casas)
  final double vIBSMono;

  @override
  String get grupo => 'gMonoPadraoIBSAdRem';

  @override
  Map<String, Object?> get valores => {
        'qBCMono': qBCMono,
        'adRemIBS': adRemIBS,
        'vIBSMono': vIBSMono,
      };
}

/// Grupo `gMonoRetenIBSAdRem` (classe `gMonoRetenIBSAdRem` do Zeus). Valores informados pelo app.
class GMonoRetenIBSAdRem implements GrupoXml {
  const GMonoRetenIBSAdRem({
    required this.qBCMonoReten,
    required this.adRemIBSReten,
    required this.vIBSMonoReten,
  });

  /// `qBCMonoReten` (4 casas)
  final double qBCMonoReten;
  /// `adRemIBSReten` (4 casas)
  final double adRemIBSReten;
  /// `vIBSMonoReten` (2 casas)
  final double vIBSMonoReten;

  @override
  String get grupo => 'gMonoRetenIBSAdRem';

  @override
  Map<String, Object?> get valores => {
        'qBCMonoReten': qBCMonoReten,
        'adRemIBSReten': adRemIBSReten,
        'vIBSMonoReten': vIBSMonoReten,
      };
}

/// Grupo `gMonoRetIBS` (classe `gMonoRetIBS` do Zeus). Valores informados pelo app.
class GMonoRetIBS implements GrupoXml {
  const GMonoRetIBS({
    required this.vIBSMonoRet,
  });

  /// `vIBSMonoRet` (2 casas)
  final double vIBSMonoRet;

  @override
  String get grupo => 'gMonoRetIBS';

  @override
  Map<String, Object?> get valores => {
        'vIBSMonoRet': vIBSMonoRet,
      };
}

/// Grupo `gpBioDiferencaIBS` (classe `gpBioDiferencaIBS` do Zeus). Valores informados pelo app.
class GpBioDiferencaIBS implements GrupoXml {
  const GpBioDiferencaIBS({
    required this.qBCBioComb,
    required this.vIBSDiferenca,
  });

  /// `qBCBioComb` (4 casas)
  final double qBCBioComb;
  /// `vIBSDiferenca` (2 casas)
  final double vIBSDiferenca;

  @override
  String get grupo => 'gpBioDiferencaIBS';

  @override
  Map<String, Object?> get valores => {
        'qBCBioComb': qBCBioComb,
        'vIBSDiferenca': vIBSDiferenca,
      };
}

/// Grupo `gIBSMonoAdValorem` (classe `gIBSMonoAdValorem` do Zeus). Valores informados pelo app.
class GIBSMonoAdValorem implements GrupoXml {
  const GIBSMonoAdValorem({
    this.gMonoPadrao,
    this.gMonoReten,
    this.gMonoRet,
    this.gpBioDiferenca,
  });

  /// `gMonoPadrao`
  final GMonoPadraoIBSAdValorem? gMonoPadrao;
  /// `gMonoReten`
  final GMonoRetenIBSAdValorem? gMonoReten;
  /// `gMonoRet`
  final GMonoRetIBS? gMonoRet;
  /// `gpBioDiferenca`
  final GpBioDiferencaIBS? gpBioDiferenca;

  @override
  String get grupo => 'gIBSMonoAdValorem';

  @override
  Map<String, Object?> get valores => {
        'gMonoPadrao': gMonoPadrao,
        'gMonoReten': gMonoReten,
        'gMonoRet': gMonoRet,
        'gpBioDiferenca': gpBioDiferenca,
      };
}

/// Grupo `gMonoPadraoIBSAdValorem` (classe `gMonoPadraoIBSAdValorem` do Zeus). Valores informados pelo app.
class GMonoPadraoIBSAdValorem implements GrupoXml {
  const GMonoPadraoIBSAdValorem({
    required this.vBCMono,
    required this.pAliqMonoUF,
    required this.vIBSMonoUF,
    required this.pAliqMonoMun,
    required this.vIBSMonoMun,
    required this.vIBSMono,
  });

  /// `vBCMono` (2 casas)
  final double vBCMono;
  /// `pAliqMonoUF` (4 casas)
  final double pAliqMonoUF;
  /// `vIBSMonoUF` (2 casas)
  final double vIBSMonoUF;
  /// `pAliqMonoMun` (4 casas)
  final double pAliqMonoMun;
  /// `vIBSMonoMun` (2 casas)
  final double vIBSMonoMun;
  /// `vIBSMono` (2 casas)
  final double vIBSMono;

  @override
  String get grupo => 'gMonoPadraoIBSAdValorem';

  @override
  Map<String, Object?> get valores => {
        'vBCMono': vBCMono,
        'pAliqMonoUF': pAliqMonoUF,
        'vIBSMonoUF': vIBSMonoUF,
        'pAliqMonoMun': pAliqMonoMun,
        'vIBSMonoMun': vIBSMonoMun,
        'vIBSMono': vIBSMono,
      };
}

/// Grupo `gMonoRetenIBSAdValorem` (classe `gMonoRetenIBSAdValorem` do Zeus). Valores informados pelo app.
class GMonoRetenIBSAdValorem implements GrupoXml {
  const GMonoRetenIBSAdValorem({
    required this.vBCMonoReten,
    required this.pAliqMonoReten,
    required this.vIBSMonoReten,
  });

  /// `vBCMonoReten` (2 casas)
  final double vBCMonoReten;
  /// `pAliqMonoReten` (4 casas)
  final double pAliqMonoReten;
  /// `vIBSMonoReten` (2 casas)
  final double vIBSMonoReten;

  @override
  String get grupo => 'gMonoRetenIBSAdValorem';

  @override
  Map<String, Object?> get valores => {
        'vBCMonoReten': vBCMonoReten,
        'pAliqMonoReten': pAliqMonoReten,
        'vIBSMonoReten': vIBSMonoReten,
      };
}

/// Grupo `gCBSMonoAdRem` (classe `gCBSMonoAdRem` do Zeus). Valores informados pelo app.
class GCBSMonoAdRem implements GrupoXml {
  const GCBSMonoAdRem({
    this.gMonoPadrao,
    this.gMonoReten,
    this.gMonoRet,
    this.gpBioDiferenca,
  });

  /// `gMonoPadrao`
  final GMonoPadraoCBSAdRem? gMonoPadrao;
  /// `gMonoReten`
  final GMonoRetenCBSAdRem? gMonoReten;
  /// `gMonoRet`
  final GMonoRetCBS? gMonoRet;
  /// `gpBioDiferenca`
  final GpBioDiferencaCBS? gpBioDiferenca;

  @override
  String get grupo => 'gCBSMonoAdRem';

  @override
  Map<String, Object?> get valores => {
        'gMonoPadrao': gMonoPadrao,
        'gMonoReten': gMonoReten,
        'gMonoRet': gMonoRet,
        'gpBioDiferenca': gpBioDiferenca,
      };
}

/// Grupo `gMonoPadraoCBSAdRem` (classe `gMonoPadraoCBSAdRem` do Zeus). Valores informados pelo app.
class GMonoPadraoCBSAdRem implements GrupoXml {
  const GMonoPadraoCBSAdRem({
    required this.qBCMono,
    required this.adRemCBS,
    required this.vCBSMono,
  });

  /// `qBCMono` (4 casas)
  final double qBCMono;
  /// `adRemCBS` (4 casas)
  final double adRemCBS;
  /// `vCBSMono` (2 casas)
  final double vCBSMono;

  @override
  String get grupo => 'gMonoPadraoCBSAdRem';

  @override
  Map<String, Object?> get valores => {
        'qBCMono': qBCMono,
        'adRemCBS': adRemCBS,
        'vCBSMono': vCBSMono,
      };
}

/// Grupo `gMonoRetenCBSAdRem` (classe `gMonoRetenCBSAdRem` do Zeus). Valores informados pelo app.
class GMonoRetenCBSAdRem implements GrupoXml {
  const GMonoRetenCBSAdRem({
    required this.qBCMonoReten,
    required this.adRemCBSReten,
    required this.vCBSMonoReten,
  });

  /// `qBCMonoReten` (4 casas)
  final double qBCMonoReten;
  /// `adRemCBSReten` (4 casas)
  final double adRemCBSReten;
  /// `vCBSMonoReten` (2 casas)
  final double vCBSMonoReten;

  @override
  String get grupo => 'gMonoRetenCBSAdRem';

  @override
  Map<String, Object?> get valores => {
        'qBCMonoReten': qBCMonoReten,
        'adRemCBSReten': adRemCBSReten,
        'vCBSMonoReten': vCBSMonoReten,
      };
}

/// Grupo `gMonoRetCBS` (classe `gMonoRetCBS` do Zeus). Valores informados pelo app.
class GMonoRetCBS implements GrupoXml {
  const GMonoRetCBS({
    required this.vCBSMonoRet,
  });

  /// `vCBSMonoRet` (2 casas)
  final double vCBSMonoRet;

  @override
  String get grupo => 'gMonoRetCBS';

  @override
  Map<String, Object?> get valores => {
        'vCBSMonoRet': vCBSMonoRet,
      };
}

/// Grupo `gpBioDiferencaCBS` (classe `gpBioDiferencaCBS` do Zeus). Valores informados pelo app.
class GpBioDiferencaCBS implements GrupoXml {
  const GpBioDiferencaCBS({
    required this.qBCBioComb,
    required this.vCBSDiferenca,
  });

  /// `qBCBioComb` (4 casas)
  final double qBCBioComb;
  /// `vCBSDiferenca` (2 casas)
  final double vCBSDiferenca;

  @override
  String get grupo => 'gpBioDiferencaCBS';

  @override
  Map<String, Object?> get valores => {
        'qBCBioComb': qBCBioComb,
        'vCBSDiferenca': vCBSDiferenca,
      };
}

/// Grupo `gCBSMonoAdValorem` (classe `gCBSMonoAdValorem` do Zeus). Valores informados pelo app.
class GCBSMonoAdValorem implements GrupoXml {
  const GCBSMonoAdValorem({
    this.gMonoPadrao,
    this.gMonoReten,
    this.gMonoRet,
    this.gpBioDiferenca,
  });

  /// `gMonoPadrao`
  final GMonoPadraoCBSAdValorem? gMonoPadrao;
  /// `gMonoReten`
  final GMonoRetenCBSAdValorem? gMonoReten;
  /// `gMonoRet`
  final GMonoRetCBS? gMonoRet;
  /// `gpBioDiferenca`
  final GpBioDiferencaCBS? gpBioDiferenca;

  @override
  String get grupo => 'gCBSMonoAdValorem';

  @override
  Map<String, Object?> get valores => {
        'gMonoPadrao': gMonoPadrao,
        'gMonoReten': gMonoReten,
        'gMonoRet': gMonoRet,
        'gpBioDiferenca': gpBioDiferenca,
      };
}

/// Grupo `gMonoPadraoCBSAdValorem` (classe `gMonoPadraoCBSAdValorem` do Zeus). Valores informados pelo app.
class GMonoPadraoCBSAdValorem implements GrupoXml {
  const GMonoPadraoCBSAdValorem({
    required this.vBCMono,
    required this.pAliqMonoCBS,
    required this.vCBSMono,
  });

  /// `vBCMono` (2 casas)
  final double vBCMono;
  /// `pAliqMonoCBS` (4 casas)
  final double pAliqMonoCBS;
  /// `vCBSMono` (2 casas)
  final double vCBSMono;

  @override
  String get grupo => 'gMonoPadraoCBSAdValorem';

  @override
  Map<String, Object?> get valores => {
        'vBCMono': vBCMono,
        'pAliqMonoCBS': pAliqMonoCBS,
        'vCBSMono': vCBSMono,
      };
}

/// Grupo `gMonoRetenCBSAdValorem` (classe `gMonoRetenCBSAdValorem` do Zeus). Valores informados pelo app.
class GMonoRetenCBSAdValorem implements GrupoXml {
  const GMonoRetenCBSAdValorem({
    required this.vBCMonoReten,
    required this.pAliqMonoReten,
    required this.vCBSMonoReten,
  });

  /// `vBCMonoReten` (2 casas)
  final double vBCMonoReten;
  /// `pAliqMonoReten` (4 casas)
  final double pAliqMonoReten;
  /// `vCBSMonoReten` (2 casas)
  final double vCBSMonoReten;

  @override
  String get grupo => 'gMonoRetenCBSAdValorem';

  @override
  Map<String, Object?> get valores => {
        'vBCMonoReten': vBCMonoReten,
        'pAliqMonoReten': pAliqMonoReten,
        'vCBSMonoReten': vCBSMonoReten,
      };
}

/// Grupo `gTransfCred` (classe `gTransfCred` do Zeus). Valores informados pelo app.
class GTransfCred implements GrupoXml {
  const GTransfCred({
    required this.vIBS,
    required this.vCBS,
  });

  /// `vIBS` (2 casas)
  final double vIBS;
  /// `vCBS` (2 casas)
  final double vCBS;

  @override
  String get grupo => 'gTransfCred';

  @override
  Map<String, Object?> get valores => {
        'vIBS': vIBS,
        'vCBS': vCBS,
      };
}

/// Grupo `gAjusteCompet` (classe `gAjusteCompet` do Zeus). Valores informados pelo app.
class GAjusteCompet implements GrupoXml {
  const GAjusteCompet({
    this.competApur,
    required this.vIBS,
    required this.vCBS,
  });

  /// `competApur`
  final String? competApur;
  /// `vIBS` (2 casas)
  final double vIBS;
  /// `vCBS` (2 casas)
  final double vCBS;

  @override
  String get grupo => 'gAjusteCompet';

  @override
  Map<String, Object?> get valores => {
        'competApur': competApur,
        'vIBS': vIBS,
        'vCBS': vCBS,
      };
}

/// Grupo `gEstornoCred` (classe `gEstornoCred` do Zeus). Valores informados pelo app.
class GEstornoCred implements GrupoXml {
  const GEstornoCred({
    required this.vIBSEstCred,
    required this.vCBSEstCred,
  });

  /// `vIBSEstCred` (2 casas)
  final double vIBSEstCred;
  /// `vCBSEstCred` (2 casas)
  final double vCBSEstCred;

  @override
  String get grupo => 'gEstornoCred';

  @override
  Map<String, Object?> get valores => {
        'vIBSEstCred': vIBSEstCred,
        'vCBSEstCred': vCBSEstCred,
      };
}

/// Grupo `gCredPresOper` (classe `gCredPresOper` do Zeus). Valores informados pelo app.
class GCredPresOper implements GrupoXml {
  const GCredPresOper({
    required this.vBCCredPres,
    required this.cCredPres,
    this.gIBSCredPres,
    this.gCBSCredPres,
  });

  /// `vBCCredPres` (2 casas)
  final double vBCCredPres;
  /// `cCredPres`
  final String cCredPres;
  /// `gIBSCredPres`
  final GIBSCredPres? gIBSCredPres;
  /// `gCBSCredPres`
  final GIBSCredPres? gCBSCredPres;

  @override
  String get grupo => 'gCredPresOper';

  @override
  Map<String, Object?> get valores => {
        'vBCCredPres': vBCCredPres,
        'cCredPres': cCredPres,
        'gIBSCredPres': gIBSCredPres,
        'gCBSCredPres': gCBSCredPres,
      };
}

/// Grupo `gIBSCredPres` (classe `gIBSCredPres` do Zeus). Valores informados pelo app.
class GIBSCredPres implements GrupoXml {
  const GIBSCredPres({
    required this.pCredPres,
    required this.vCredPres,
    this.vCredPresCondSus,
  });

  /// `pCredPres` (4 casas)
  final double pCredPres;
  /// `vCredPres` (2 casas)
  final double vCredPres;
  /// `vCredPresCondSus` (2 casas)
  final double? vCredPresCondSus;

  @override
  String get grupo => 'gIBSCredPres';

  @override
  Map<String, Object?> get valores => {
        'pCredPres': pCredPres,
        'vCredPres': vCredPres,
        'vCredPresCondSus': vCredPresCondSus,
      };
}

/// Grupo `gCredPresIBSZFM` (classe `gCredPresIBSZFM` do Zeus). Valores informados pelo app.
class GCredPresIBSZFM implements GrupoXml {
  const GCredPresIBSZFM({
    required this.tpCredPresIBSZFM,
    this.vCredPresIBSZFM,
    this.competApur,
  });

  /// `tpCredPresIBSZFM`
  final String tpCredPresIBSZFM;
  /// `vCredPresIBSZFM` (2 casas)
  final double? vCredPresIBSZFM;
  /// `competApur`
  final String? competApur;

  @override
  String get grupo => 'gCredPresIBSZFM';

  @override
  Map<String, Object?> get valores => {
        'tpCredPresIBSZFM': tpCredPresIBSZFM,
        'vCredPresIBSZFM': vCredPresIBSZFM,
        'competApur': competApur,
      };
}

/// Grupo `IS` (classe `IS` do Zeus). Valores informados pelo app.
class IS implements GrupoXml {
  const IS({
    this.cstis,
    this.cClassTribIS,
    required this.vBCIS,
    required this.pIS,
    this.adRemIS,
    this.uTrib,
    this.qTrib,
    required this.vIS,
  });

  /// `CSTIS`
  final String? cstis;
  /// `cClassTribIS`
  final String? cClassTribIS;
  /// `vBCIS` (2 casas)
  final double vBCIS;
  /// `pIS` (4 casas)
  final double pIS;
  /// `adRemIS` (4 casas)
  final double? adRemIS;
  /// `uTrib`
  final String? uTrib;
  /// `qTrib` (4 casas)
  final double? qTrib;
  /// `vIS` (2 casas)
  final double vIS;

  @override
  String get grupo => 'IS';

  @override
  Map<String, Object?> get valores => {
        'CSTIS': cstis,
        'cClassTribIS': cClassTribIS,
        'vBCIS': vBCIS,
        'pIS': pIS,
        'adRemIS': adRemIS,
        'uTrib': uTrib,
        'qTrib': qTrib,
        'vIS': vIS,
      };
}

/// Grupo `IBSCBSTot` (classe `IBSCBSTot` do Zeus). Valores informados pelo app.
class IBSCBSTot implements GrupoXml {
  const IBSCBSTot({
    required this.vBCIBSCBS,
    this.gIBS,
    this.gCBS,
    this.gMono,
    this.gEstornoCred,
  });

  /// `vBCIBSCBS` (2 casas)
  final double vBCIBSCBS;
  /// `gIBS`
  final GIBSTotal? gIBS;
  /// `gCBS`
  final GCBSTotal? gCBS;
  /// `gMono`
  final GMonoTotal? gMono;
  /// `gEstornoCred`
  final GEstornoCredTotal? gEstornoCred;

  @override
  String get grupo => 'IBSCBSTot';

  @override
  Map<String, Object?> get valores => {
        'vBCIBSCBS': vBCIBSCBS,
        'gIBS': gIBS,
        'gCBS': gCBS,
        'gMono': gMono,
        'gEstornoCred': gEstornoCred,
      };
}

/// Grupo `gIBSTotal` (classe `gIBSTotal` do Zeus). Valores informados pelo app.
class GIBSTotal implements GrupoXml {
  const GIBSTotal({
    this.gIBSUF,
    this.gIBSMun,
    required this.vIBS,
    required this.vCredPres,
    required this.vCredPresCondSus,
  });

  /// `gIBSUF`
  final GIBSUFTotal? gIBSUF;
  /// `gIBSMun`
  final GIBSMunTotal? gIBSMun;
  /// `vIBS` (2 casas)
  final double vIBS;
  /// `vCredPres` (2 casas)
  final double vCredPres;
  /// `vCredPresCondSus` (2 casas)
  final double vCredPresCondSus;

  @override
  String get grupo => 'gIBSTotal';

  @override
  Map<String, Object?> get valores => {
        'gIBSUF': gIBSUF,
        'gIBSMun': gIBSMun,
        'vIBS': vIBS,
        'vCredPres': vCredPres,
        'vCredPresCondSus': vCredPresCondSus,
      };
}

/// Grupo `gIBSUFTotal` (classe `gIBSUFTotal` do Zeus). Valores informados pelo app.
class GIBSUFTotal implements GrupoXml {
  const GIBSUFTotal({
    required this.vDif,
    required this.vDevTrib,
    required this.vIBSUF,
  });

  /// `vDif` (2 casas)
  final double vDif;
  /// `vDevTrib` (2 casas)
  final double vDevTrib;
  /// `vIBSUF` (2 casas)
  final double vIBSUF;

  @override
  String get grupo => 'gIBSUFTotal';

  @override
  Map<String, Object?> get valores => {
        'vDif': vDif,
        'vDevTrib': vDevTrib,
        'vIBSUF': vIBSUF,
      };
}

/// Grupo `gIBSMunTotal` (classe `gIBSMunTotal` do Zeus). Valores informados pelo app.
class GIBSMunTotal implements GrupoXml {
  const GIBSMunTotal({
    required this.vDif,
    required this.vDevTrib,
    required this.vIBSMun,
  });

  /// `vDif` (2 casas)
  final double vDif;
  /// `vDevTrib` (2 casas)
  final double vDevTrib;
  /// `vIBSMun` (2 casas)
  final double vIBSMun;

  @override
  String get grupo => 'gIBSMunTotal';

  @override
  Map<String, Object?> get valores => {
        'vDif': vDif,
        'vDevTrib': vDevTrib,
        'vIBSMun': vIBSMun,
      };
}

/// Grupo `gCBSTotal` (classe `gCBSTotal` do Zeus). Valores informados pelo app.
class GCBSTotal implements GrupoXml {
  const GCBSTotal({
    required this.vDif,
    required this.vDevTrib,
    required this.vCBS,
    required this.vCredPres,
    required this.vCredPresCondSus,
  });

  /// `vDif` (2 casas)
  final double vDif;
  /// `vDevTrib` (2 casas)
  final double vDevTrib;
  /// `vCBS` (2 casas)
  final double vCBS;
  /// `vCredPres` (2 casas)
  final double vCredPres;
  /// `vCredPresCondSus` (2 casas)
  final double vCredPresCondSus;

  @override
  String get grupo => 'gCBSTotal';

  @override
  Map<String, Object?> get valores => {
        'vDif': vDif,
        'vDevTrib': vDevTrib,
        'vCBS': vCBS,
        'vCredPres': vCredPres,
        'vCredPresCondSus': vCredPresCondSus,
      };
}

/// Grupo `gMonoTotal` (classe `gMonoTotal` do Zeus). Valores informados pelo app.
class GMonoTotal implements GrupoXml {
  const GMonoTotal({
    required this.vIBSMono,
    required this.vCBSMono,
    required this.vIBSMonoReten,
    required this.vCBSMonoReten,
    required this.vIBSMonoRet,
    required this.vCBSMonoRet,
  });

  /// `vIBSMono` (2 casas)
  final double vIBSMono;
  /// `vCBSMono` (2 casas)
  final double vCBSMono;
  /// `vIBSMonoReten` (2 casas)
  final double vIBSMonoReten;
  /// `vCBSMonoReten` (2 casas)
  final double vCBSMonoReten;
  /// `vIBSMonoRet` (2 casas)
  final double vIBSMonoRet;
  /// `vCBSMonoRet` (2 casas)
  final double vCBSMonoRet;

  @override
  String get grupo => 'gMonoTotal';

  @override
  Map<String, Object?> get valores => {
        'vIBSMono': vIBSMono,
        'vCBSMono': vCBSMono,
        'vIBSMonoReten': vIBSMonoReten,
        'vCBSMonoReten': vCBSMonoReten,
        'vIBSMonoRet': vIBSMonoRet,
        'vCBSMonoRet': vCBSMonoRet,
      };
}

/// Grupo `gEstornoCredTotal` (classe `gEstornoCredTotal` do Zeus). Valores informados pelo app.
class GEstornoCredTotal implements GrupoXml {
  const GEstornoCredTotal({
    required this.vIBSEstCred,
    required this.vCBSEstCred,
  });

  /// `vIBSEstCred` (2 casas)
  final double vIBSEstCred;
  /// `vCBSEstCred` (2 casas)
  final double vCBSEstCred;

  @override
  String get grupo => 'gEstornoCredTotal';

  @override
  Map<String, Object?> get valores => {
        'vIBSEstCred': vIBSEstCred,
        'vCBSEstCred': vCBSEstCred,
      };
}

/// Grupo `ISTot` (classe `ISTot` do Zeus). Valores informados pelo app.
class ISTot implements GrupoXml {
  const ISTot({
    required this.vIS,
  });

  /// `vIS` (2 casas)
  final double vIS;

  @override
  String get grupo => 'ISTot';

  @override
  Map<String, Object?> get valores => {
        'vIS': vIS,
      };
}

/// Grupo `gCompraGov` (classe `gCompraGov` do Zeus). Valores informados pelo app.
class GCompraGov implements GrupoXml {
  const GCompraGov({
    required this.tpEnteGov,
    required this.pRedutor,
    required this.tpOperGov,
  });

  /// `tpEnteGov`
  final String tpEnteGov;
  /// `pRedutor` (4 casas)
  final double pRedutor;
  /// `tpOperGov`
  final String tpOperGov;

  @override
  String get grupo => 'gCompraGov';

  @override
  Map<String, Object?> get valores => {
        'tpEnteGov': tpEnteGov,
        'pRedutor': pRedutor,
        'tpOperGov': tpOperGov,
      };
}

/// Grupo `exporta` (classe `exporta` do Zeus). Valores informados pelo app.
class Exporta implements GrupoXml {
  const Exporta({
    this.ufSaidaPais,
    this.xLocExporta,
    this.xLocDespacho,
  });

  /// `UFSaidaPais`
  final String? ufSaidaPais;
  /// `xLocExporta`
  final String? xLocExporta;
  /// `xLocDespacho`
  final String? xLocDespacho;

  @override
  String get grupo => 'exporta';

  @override
  Map<String, Object?> get valores => {
        'UFSaidaPais': ufSaidaPais,
        'xLocExporta': xLocExporta,
        'xLocDespacho': xLocDespacho,
      };
}

/// Grupo `compra` (classe `compra` do Zeus). Valores informados pelo app.
class Compra implements GrupoXml {
  const Compra({
    this.xNEmp,
    this.xPed,
    this.xCont,
  });

  /// `xNEmp`
  final String? xNEmp;
  /// `xPed`
  final String? xPed;
  /// `xCont`
  final String? xCont;

  @override
  String get grupo => 'compra';

  @override
  Map<String, Object?> get valores => {
        'xNEmp': xNEmp,
        'xPed': xPed,
        'xCont': xCont,
      };
}

/// Grupo `cana` (classe `cana` do Zeus). Valores informados pelo app.
class Cana implements GrupoXml {
  const Cana({
    this.safra,
    this.ref,
    this.forDia,
    required this.qTotMes,
    required this.qTotAnt,
    required this.qTotGer,
    this.deduc,
    required this.vFor,
    required this.vTotDed,
    required this.vLiqFor,
  });

  /// `safra`
  final String? safra;
  /// `ref`
  final String? ref;
  /// `forDia`
  final List<ForDia>? forDia;
  /// `qTotMes` (2 casas)
  final double qTotMes;
  /// `qTotAnt` (2 casas)
  final double qTotAnt;
  /// `qTotGer` (2 casas)
  final double qTotGer;
  /// `deduc`
  final List<Deduc>? deduc;
  /// `vFor` (2 casas)
  final double vFor;
  /// `vTotDed` (2 casas)
  final double vTotDed;
  /// `vLiqFor` (2 casas)
  final double vLiqFor;

  @override
  String get grupo => 'cana';

  @override
  Map<String, Object?> get valores => {
        'safra': safra,
        'ref': ref,
        'forDia': forDia,
        'qTotMes': qTotMes,
        'qTotAnt': qTotAnt,
        'qTotGer': qTotGer,
        'deduc': deduc,
        'vFor': vFor,
        'vTotDed': vTotDed,
        'vLiqFor': vLiqFor,
      };
}

/// Grupo `forDia` (classe `forDia` do Zeus). Valores informados pelo app.
class ForDia implements GrupoXml {
  const ForDia({
    required this.dia,
    required this.qtde,
  });

  /// `dia`
  final int dia;
  /// `qtde` (2 casas)
  final double qtde;

  @override
  String get grupo => 'forDia';

  @override
  Map<String, Object?> get valores => {
        'dia': dia,
        'qtde': qtde,
      };
}

/// Grupo `deduc` (classe `deduc` do Zeus). Valores informados pelo app.
class Deduc implements GrupoXml {
  const Deduc({
    this.xDed,
    required this.vDed,
  });

  /// `xDed`
  final String? xDed;
  /// `vDed` (2 casas)
  final double vDed;

  @override
  String get grupo => 'deduc';

  @override
  Map<String, Object?> get valores => {
        'xDed': xDed,
        'vDed': vDed,
      };
}

/// Grupo `agropecuario` (classe `agropecuario` do Zeus). Valores informados pelo app.
class Agropecuario implements GrupoXml {
  const Agropecuario({
    this.defensivo,
    this.guiaTransito,
  });

  /// `defensivo`
  final List<Defensivo>? defensivo;
  /// `guiaTransito`
  final GuiaTransito? guiaTransito;

  @override
  String get grupo => 'agropecuario';

  @override
  Map<String, Object?> get valores => {
        'defensivo': defensivo,
        'guiaTransito': guiaTransito,
      };
}

/// Grupo `defensivo` (classe `defensivo` do Zeus). Valores informados pelo app.
class Defensivo implements GrupoXml {
  const Defensivo({
    this.nReceituario,
    this.cpfRespTec,
  });

  /// `nReceituario`
  final String? nReceituario;
  /// `CPFRespTec`
  final String? cpfRespTec;

  @override
  String get grupo => 'defensivo';

  @override
  Map<String, Object?> get valores => {
        'nReceituario': nReceituario,
        'CPFRespTec': cpfRespTec,
      };
}

/// Grupo `guiaTransito` (classe `guiaTransito` do Zeus). Valores informados pelo app.
class GuiaTransito implements GrupoXml {
  const GuiaTransito({
    required this.tpGuia,
    this.ufGuia,
    this.serieGuia,
    this.nGuia,
  });

  /// `tpGuia`
  final String tpGuia;
  /// `UFGuia`
  final String? ufGuia;
  /// `serieGuia`
  final String? serieGuia;
  /// `nGuia`
  final String? nGuia;

  @override
  String get grupo => 'guiaTransito';

  @override
  Map<String, Object?> get valores => {
        'tpGuia': tpGuia,
        'UFGuia': ufGuia,
        'serieGuia': serieGuia,
        'nGuia': nGuia,
      };
}

/// Grupo `retTransp` (classe `retTransp` do Zeus). Valores informados pelo app.
class RetTransp implements GrupoXml {
  const RetTransp({
    required this.vServ,
    required this.vBCRet,
    required this.pICMSRet,
    required this.vICMSRet,
    required this.cfop,
    required this.cMunFG,
  });

  /// `vServ` (2 casas)
  final double vServ;
  /// `vBCRet` (2 casas)
  final double vBCRet;
  /// `pICMSRet` (4 casas)
  final double pICMSRet;
  /// `vICMSRet` (2 casas)
  final double vICMSRet;
  /// `CFOP`
  final int cfop;
  /// `cMunFG`
  final int cMunFG;

  @override
  String get grupo => 'retTransp';

  @override
  Map<String, Object?> get valores => {
        'vServ': vServ,
        'vBCRet': vBCRet,
        'pICMSRet': pICMSRet,
        'vICMSRet': vICMSRet,
        'CFOP': cfop,
        'cMunFG': cMunFG,
      };
}

/// Grupo `reboque` (classe `reboque` do Zeus). Valores informados pelo app.
class Reboque implements GrupoXml {
  const Reboque({
    this.placa,
    this.uf,
    this.rntc,
  });

  /// `placa`
  final String? placa;
  /// `UF`
  final String? uf;
  /// `RNTC`
  final String? rntc;

  @override
  String get grupo => 'reboque';

  @override
  Map<String, Object?> get valores => {
        'placa': placa,
        'UF': uf,
        'RNTC': rntc,
      };
}

/// Grupo `lacres` (classe `lacres` do Zeus). Valores informados pelo app.
class Lacres implements GrupoXml {
  const Lacres({
    this.nLacre,
  });

  /// `nLacre`
  final String? nLacre;

  @override
  String get grupo => 'lacres';

  @override
  Map<String, Object?> get valores => {
        'nLacre': nLacre,
      };
}

