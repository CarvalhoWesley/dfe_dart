import 'package:xml/xml.dart';

import '../enums.dart';

const nsNfe = 'http://www.portalfiscal.inf.br/nfe';

/// Pedido de status do serviço (consStatServ). Escrito à mão na Fase 0;
/// será substituído pelo modelo gerado a partir de `NFe.Classes`.
class ConsStatServ {
  const ConsStatServ({required this.tpAmb, required this.cUF, this.versao = '4.00'});

  final Ambiente tpAmb;
  final Uf cUF;
  final String versao;

  String toXml() => '<consStatServ xmlns="$nsNfe" versao="$versao">'
      '<tpAmb>${tpAmb.codigo}</tpAmb>'
      '<cUF>${cUF.codigo}</cUF>'
      '<xServ>STATUS</xServ>'
      '</consStatServ>';
}

/// Retorno do status do serviço (retConsStatServ).
class RetConsStatServ {
  RetConsStatServ({
    required this.versao,
    required this.tpAmb,
    required this.verAplic,
    required this.cStat,
    required this.xMotivo,
    required this.cUF,
    required this.dhRecbto,
    this.tMed,
    this.dhRetorno,
    this.xObs,
  });

  factory RetConsStatServ.fromXml(String xml) {
    final e = XmlDocument.parse(xml).rootElement;
    String? t(String nome) => e.getElement(nome)?.innerText;
    return RetConsStatServ(
      versao: e.getAttribute('versao') ?? '',
      tpAmb: int.parse(t('tpAmb')!) == 1 ? Ambiente.producao : Ambiente.homologacao,
      verAplic: t('verAplic') ?? '',
      cStat: int.parse(t('cStat')!),
      xMotivo: t('xMotivo') ?? '',
      cUF: int.parse(t('cUF')!),
      dhRecbto: t('dhRecbto') ?? '',
      tMed: int.tryParse(t('tMed') ?? ''),
      dhRetorno: t('dhRetorno'),
      xObs: t('xObs'),
    );
  }

  final String versao;
  final Ambiente tpAmb;
  final String verAplic;
  final int cStat;
  final String xMotivo;
  final int cUF;
  final String dhRecbto;
  final int? tMed;
  final String? dhRetorno;
  final String? xObs;

  /// 107 = Serviço em operação.
  bool get emOperacao => cStat == 107;
}
