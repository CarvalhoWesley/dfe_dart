import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

List<String> _filhos(XmlElement e) => e.childElements.map((c) => c.name.local).toList();
XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  test('IBSCBS com diferimento, redução e devolução nos subgrupos (ordem do Zeus)', () {
    final x = _el(serializarGrupoXml(const IBSCBS(
      cst: '200',
      cClassTrib: '200001',
      gIBSCBS: GIBSCBS(
        vBC: 100,
        gIBSUF: GIBSUF(
          pIBSUF: 0.1,
          gDif: GDif(pDif: 50, vDif: 0.05),
          gDevTrib: GDevTrib(vDevTrib: 0),
          gRed: GRed(pRedAliq: 60, pAliqEfet: 0.04),
          vIBSUF: 0.05,
        ),
        gIBSMun: GIBSMun(pIBSMun: 0, vIBSMun: 0),
        vIBS: 0.05,
        gCBS: GCBS(pCBS: 0.9, gRed: GRed(pRedAliq: 60, pAliqEfet: 0.36), vCBS: 0.36),
        gTribRegular: GTribRegular(
          cstReg: '000', cClassTribReg: '000001', pAliqEfetRegIBSUF: 0.1, vTribRegIBSUF: 0.1,
          pAliqEfetRegIBSMun: 0, vTribRegIBSMun: 0, pAliqEfetRegCBS: 0.9, vTribRegCBS: 0.9),
      ),
    )));
    expect(_filhos(x), ['CST', 'cClassTrib', 'gIBSCBS']);
    final g = x.getElement('gIBSCBS')!;
    expect(_filhos(g), ['vBC', 'gIBSUF', 'gIBSMun', 'vIBS', 'gCBS', 'gTribRegular']);
    expect(_filhos(g.getElement('gIBSUF')!), ['pIBSUF', 'gDif', 'gDevTrib', 'gRed', 'vIBSUF']);
    expect(g.getElement('gIBSUF')!.getElement('pIBSUF')!.innerText, '0.1000');
    expect(_filhos(g.getElement('gCBS')!), ['pCBS', 'gRed', 'vCBS']);
  });

  test('monofásico: subgrupos com nome do elemento do Zeus (gMonoPadrao)', () {
    final x = _el(serializarGrupoXml(const IBSCBS(
      cst: '620',
      cClassTrib: '620001',
      gIBSCBSMono: GIBSCBSMono(
        gMonoPadrao: GMonoPadrao(qBCMono: 10, adRemIBS: 0.1, adRemCBS: 0.9, vIBSMono: 1, vCBSMono: 9),
        vTotIBSMonoItem: 1,
        vTotCBSMonoItem: 9,
      ),
    )));
    final m = x.getElement('gIBSCBSMono')!;
    expect(_filhos(m), ['gMonoPadrao', 'vTotIBSMonoItem', 'vTotCBSMonoItem']);
    expect(_filhos(m.getElement('gMonoPadrao')!), ['qBCMono', 'adRemIBS', 'adRemCBS', 'vIBSMono', 'vCBSMono']);
  });

  test('crédito presumido, IS e campo obrigatório ausente', () {
    final x = _el(serializarGrupoXml(const IBSCBS(
      cst: '000',
      cClassTrib: '000001',
      gCredPresOper: GCredPresOper(
          vBCCredPres: 100, cCredPres: '1', gIBSCredPres: GIBSCredPres(pCredPres: 1, vCredPres: 1)),
    )));
    expect(_filhos(x.getElement('gCredPresOper')!), ['vBCCredPres', 'cCredPres', 'gIBSCredPres']);

    final s = _el(serializarGrupoXml(const IS(cstis: '000', cClassTribIS: '000001', vBCIS: 10, pIS: 5, vIS: 0.5)));
    expect(_filhos(s), ['CSTIS', 'cClassTribIS', 'vBCIS', 'pIS', 'vIS']);

    expect(() => serializarGrupo('gDif', {'pDif': 1}), throwsArgumentError);
  });

  test('total: ICMSTot, ISTot, IBSCBSTot e vNFTot na ordem do Zeus', () {
    const t = TotalNfe(
      icmsTot: IcmsTot(
        vBC: 0, vICMS: 0, vBCST: 0, vST: 0, vProd: 10, vFrete: 0, vSeg: 0, vDesc: 0, vII: 0, vIPI: 0,
        vPIS: 0, vCOFINS: 0, vOutro: 0, vNF: 10,
      ),
      isTot: ISTot(vIS: 0.5),
      ibsCbsTot: IBSCBSTot(
        vBCIBSCBS: 10,
        gIBS: GIBSTotal(
          gIBSUF: GIBSUFTotal(vDif: 0, vDevTrib: 0, vIBSUF: 0.01),
          gIBSMun: GIBSMunTotal(vDif: 0, vDevTrib: 0, vIBSMun: 0),
          vIBS: 0.01, vCredPres: 0, vCredPresCondSus: 0,
        ),
        gCBS: GCBSTotal(vDif: 0, vDevTrib: 0, vCBS: 0.09, vCredPres: 0, vCredPresCondSus: 0),
      ),
      vNFTot: 10.6,
    );
    final x = _el(t.xml());
    expect(_filhos(x), ['ICMSTot', 'ISTot', 'IBSCBSTot', 'vNFTot']);
    expect(x.getElement('vNFTot')!.innerText, '10.60');
  });

  test('gCompraGov gerado do Zeus', () {
    expect(especificacaoGrupos['gCompraGov']!.map((c) => c.nome), ['tpEnteGov', 'pRedutor', 'tpOperGov']);
  });
}
