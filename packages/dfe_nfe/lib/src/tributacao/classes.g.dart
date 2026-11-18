// GERADO por tools/extrair_grupos a partir do ZeusFiscal. NÃO EDITE À MÃO.
// ignore_for_file: lines_longer_than_80_chars

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
    this.cNPJProd,
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
  final String? cNPJProd;
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
        'CNPJProd': cNPJProd,
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

