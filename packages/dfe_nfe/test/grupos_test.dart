import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

/// Valor de exemplo para qualquer campo da especificação.
Object _exemplo(CampoGrupo c) => switch (c.tipo) {
      TipoCampo.dec => 1.5,
      TipoCampo.int => 2,
      TipoCampo.str => 'X',
    };

List<String> _filhos(String xml) =>
    XmlDocument.parse(xml).rootElement.childElements.map((e) => e.name.local).toList();

void main() {
  group('especificação extraída do Zeus', () {
    test('todos os grupos serializam todos os campos, na ordem do Zeus', () {
      for (final MapEntry(key: grupo, value: campos) in especificacaoGrupos.entries) {
        final valores = {for (final c in campos) c.nome: _exemplo(c)};
        final xml = serializarGrupo(grupo, valores);
        expect(_filhos(xml), campos.map((c) => c.nome).toList(), reason: grupo);
      }
    });

    test('opcionais nulos são omitidos; obrigatório nulo gera erro', () {
      for (final MapEntry(key: grupo, value: campos) in especificacaoGrupos.entries) {
        final obrigatorios = campos.where((c) => !c.opcional).toList();
        final valores = {for (final c in obrigatorios) c.nome: _exemplo(c)};
        expect(_filhos(serializarGrupo(grupo, valores)), obrigatorios.map((c) => c.nome).toList(),
            reason: grupo);
        if (obrigatorios.isNotEmpty) {
          final faltando = Map.of(valores)..remove(obrigatorios.first.nome);
          expect(() => serializarGrupo(grupo, faltando), throwsArgumentError, reason: grupo);
        }
      }
    });

    test('casas decimais: valores em 2, alíquotas em 4 (como o Zeus)', () {
      final xml = serializarGrupo('ICMS00', {
        'orig': '0', 'CST': '00', 'modBC': '3', 'vBC': 100.0, 'pICMS': 18.0, 'vICMS': 18.0, 'pFCP': 2.0,
      });
      expect(xml, contains('<vBC>100.00</vBC>'));
      expect(xml, contains('<pICMS>18.0000</pICMS>'));
      expect(xml, contains('<pFCP>2.0000</pFCP>'));
      expect(xml, isNot(contains('vFCP')));
    });

    test('cobertura: grupos de ICMS, PIS/COFINS, IPI, II, ISSQN e totais', () {
      expect(especificacaoGrupos.keys, containsAll([
        'ICMS00', 'ICMS02', 'ICMS10', 'ICMS15', 'ICMS20', 'ICMS30', 'ICMS40', 'ICMS51', 'ICMS53',
        'ICMS60', 'ICMS61', 'ICMS70', 'ICMS90', 'ICMSPart', 'ICMSST', 'ICMSSN101', 'ICMSSN102',
        'ICMSSN201', 'ICMSSN202', 'ICMSSN500', 'ICMSSN900', 'ICMSUFDest',
        'PISAliq', 'PISQtde', 'PISNT', 'PISOutr', 'PISST',
        'COFINSAliq', 'COFINSQtde', 'COFINSNT', 'COFINSOutr', 'COFINSST',
        'IPI', 'IPITrib', 'IPINT', 'II', 'ISSQN', 'ICMSTot', 'ISSQNtot', 'retTrib',
      ]));
    });
  });

  group('seleção do grupo de ICMS (como o ICMSGeral do Zeus)', () {
    String grupo(int crt, {String? cst, String? csosn, VarianteIcms v = VarianteIcms.normal}) =>
        Icms(IcmsGeral(orig: '0', cst: cst, csosn: csosn), variante: v).grupo(crt);

    test('regime normal (CRT 2 e 3)', () {
      for (final cst in ['00', '02', '10', '15', '20', '30', '51', '53', '60', '61', '70', '90']) {
        expect(grupo(3, cst: cst), 'ICMS$cst');
        expect(grupo(2, cst: cst), 'ICMS$cst');
      }
      for (final cst in ['40', '41', '50']) {
        expect(grupo(3, cst: cst), 'ICMS40');
      }
      expect(grupo(3, cst: '10', v: VarianteIcms.partilha), 'ICMSPart');
      expect(grupo(3, cst: '90', v: VarianteIcms.partilha), 'ICMSPart');
      expect(grupo(3, cst: '41', v: VarianteIcms.repasse), 'ICMSST');
      expect(grupo(3, cst: '60', v: VarianteIcms.repasse), 'ICMSST');
    });

    test('Simples Nacional (CRT 1 e 4)', () {
      const esperado = {
        '101': 'ICMSSN101', '102': 'ICMSSN102', '103': 'ICMSSN102', '300': 'ICMSSN102',
        '400': 'ICMSSN102', '201': 'ICMSSN201', '202': 'ICMSSN202', '203': 'ICMSSN202',
        '500': 'ICMSSN500', '900': 'ICMSSN900',
      };
      esperado.forEach((csosn, g) {
        expect(grupo(1, csosn: csosn), g);
        expect(grupo(4, csosn: csosn), g);
      });
      expect(grupo(1, cst: '61'), 'ICMS61');
    });

    test('combinações inválidas', () {
      expect(() => grupo(3, csosn: '102'), throwsArgumentError);
      expect(() => grupo(1, cst: '00'), throwsArgumentError);
      expect(() => grupo(3, cst: '00', v: VarianteIcms.partilha), throwsArgumentError);
      expect(() => grupo(5, cst: '00'), throwsArgumentError);
    });

    test('ICMS90 com diferimento e FCP: só os campos informados', () {
      final xml = Icms(const IcmsGeral(
        orig: '0', cst: '90', modBC: '3', vBC: 100, pICMS: 18, vICMSOp: 18, pDif: 50, vICMSDif: 9, vICMS: 9,
      )).xml(3);
      expect(_filhos(XmlDocument.parse(xml).rootElement.firstElementChild!.toXmlString()),
          ['orig', 'CST', 'modBC', 'vBC', 'pICMS', 'vICMSOp', 'pDif', 'vICMSDif', 'vICMS']);
    });
  });

  group('imposto do item', () {
    test('PIS/COFINS escolhem o grupo pelo CST', () {
      String pis(String cst) => ImpostoItem(pis: PisGeral(cst: cst, vBC: 1, pPIS: 1, vPIS: 1, qBCProd: 1, vAliqProd: 1))
          .xml(1);
      expect(pis('01'), contains('<PISAliq>'));
      expect(pis('03'), contains('<PISQtde>'));
      expect(pis('07'), contains('<PISNT>'));
      expect(pis('99'), contains('<PISOutr>'));
      expect(() => pis('10'), throwsArgumentError);
    });

    test('IPI: campos do envoltório antes de IPITrib/IPINT', () {
      final xml = const ImpostoItem(ipi: IpiGeral(cEnq: '999', cst: '50', vBC: 100, pIPI: 5, vIPI: 5)).xml(3);
      final ipi = XmlDocument.parse(xml).findAllElements('IPI').single;
      expect(ipi.childElements.map((e) => e.name.local), ['cEnq', 'IPITrib']);
      expect(XmlDocument.parse(const ImpostoItem(ipi: IpiGeral(cEnq: '999', cst: '53')).xml(3))
          .findAllElements('IPINT'), hasLength(1));
    });

    test('ordem do schema com ICMS e com ISSQN', () {
      final comIcms = ImpostoItem(
        vTotTrib: 1,
        icms: Icms(const IcmsGeral(orig: '0', csosn: '102')),
        pis: const PisGeral(cst: '07'),
        pisSt: const PisSt(vBC: 1, pPIS: 1, vPIS: 1),
        cofins: const CofinsGeral(cst: '07'),
        icmsUfDest: const IcmsUfDest(
            vBCUFDest: 1, pICMSUFDest: 1, pICMSInter: 1, pICMSInterPart: 1, vICMSUFDest: 1, vICMSUFRemet: 1),
        ibsCbs: const IbsCbs(cst: '410', classificacao: '410001'),
      ).xml(1);
      expect(_filhos(comIcms), ['vTotTrib', 'ICMS', 'PIS', 'PISST', 'COFINS', 'ICMSUFDest', 'IBSCBS']);

      final comIssqn = const ImpostoItem(
        issqn: Issqn(vBC: 100, vAliq: 5, vISSQN: 5, cMunFG: 3550308, indISS: '1', indIncentivo: '2'),
        pis: PisGeral(cst: '07'),
        cofins: CofinsGeral(cst: '07'),
      ).xml(3);
      expect(_filhos(comIssqn), ['ISSQN', 'PIS', 'COFINS']);
    });
  });

  test('total: ICMSTot obrigatório, IBSCBSTot opcional, vNF informado', () {
    const t = TotalNfe(
      icmsTot: IcmsTot(
        vBC: 0, vICMS: 0, vBCST: 0, vST: 0, vProd: 10, vFrete: 0, vSeg: 0, vDesc: 0, vII: 0, vIPI: 0,
        vPIS: 0, vCOFINS: 0, vOutro: 0, vNF: 10,
      ),
    );
    expect(t.vNF, 10);
    expect(_filhos(t.xml()), ['ICMSTot']);
    expect(() => const TotalNfe(icmsTot: IcmsTot(vBC: 0)).xml(), throwsArgumentError);
  });
}
