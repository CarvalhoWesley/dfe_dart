import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

const _end = Endereco(
  logradouro: 'RUA', numero: '1', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

DadosNfe _dados({TipoEmissao tp = TipoEmissao.normal, ResponsavelTecnico? rt}) => DadosNfe(
      modelo: ModeloDocumento.nfe,
      ambiente: Ambiente.homologacao,
      serie: 1,
      numero: 1,
      codigoNumerico: 12345678,
      dataEmissao: DateTime(2026, 11, 18, 9),
      tipoEmissao: tp,
      justificativaContingencia: tp.contingencia ? 'TESTE DE CONTINGENCIA' : null,
      emitente: const Emitente(cnpj: '12345678000195', razaoSocial: 'E', inscricaoEstadual: '1', endereco: _end),
      destinatario: const Destinatario(nome: 'C', cpf: '11144477735', endereco: _end),
      itens: const [
        ItemNfe(
          codigo: '1', descricao: 'P', ncm: '21069090', cfop: '5102', unidade: 'UN',
          quantidade: 1, valorUnitario: 10, valorTotal: 10,
          imposto: ImpostoItem(
            icms: Icms(IcmsGeral(orig: '0', csosn: '102')),
            pis: PisGeral(cst: '07'),
            cofins: CofinsGeral(cst: '07'),
          ),
        ),
      ],
      total: const TotalNfe(
        icmsTot: IcmsTot(
          vBC: 0, vICMS: 0, vBCST: 0, vST: 0, vProd: 10, vFrete: 0, vSeg: 0, vDesc: 0, vII: 0, vIPI: 0,
          vPIS: 0, vCOFINS: 0, vOutro: 0, vNF: 10,
        ),
      ),
      pagamentos: const [Pagamento(tipo: '01', valor: 10)],
      responsavelTecnico: rt,
    );

void main() {
  group('CSRT', () {
    test('hash do exemplo da NT 2018.005', () {
      expect(hashCsrt('G8063VRTNDMO886SFNK5LDUDEI24XJ22YIPO', '41180678393592000146558900000006041028190697'),
          'aWv6LeEM4X6u4+qBI2OYZ8grigw=');
    });

    test('infRespTec com idCSRT (2 dígitos) e hashCSRT sobre a chave da nota', () {
      final m = montarNfe(_dados(
          rt: const ResponsavelTecnico(
              cnpj: '11111111000191', contato: 'SUPORTE', email: 'a@b.com', fone: '11999999999',
              idCsrt: 1, csrt: 'G8063VRTNDMO886SFNK5LDUDEI24XJ22YIPO')));
      final rt = XmlDocument.parse(m.xml).findAllElements('infRespTec').single;
      expect(rt.childElements.map((e) => e.name.local),
          ['CNPJ', 'xContato', 'email', 'fone', 'idCSRT', 'hashCSRT']);
      expect(rt.getElement('idCSRT')!.innerText, '01');
      expect(rt.getElement('hashCSRT')!.innerText, hashCsrt('G8063VRTNDMO886SFNK5LDUDEI24XJ22YIPO', m.chave.valor));
    });

    test('sem CSRT o grupo não leva idCSRT/hashCSRT', () {
      final m = montarNfe(_dados(
          rt: const ResponsavelTecnico(cnpj: '11111111000191', contato: 'S', email: 'a@b.com', fone: '1')));
      expect(XmlDocument.parse(m.xml).findAllElements('hashCSRT'), isEmpty);
    });
  });

  group('tipos de emissão (paridade com o TipoEmissao do Zeus)', () {
    test('códigos', () {
      expect({for (final t in TipoEmissao.values) t.name: t.codigo},
          {'normal': 1, 'fsIa': 2, 'scan': 3, 'epec': 4, 'fsDa': 5, 'svcAn': 6, 'svcRs': 7, 'offlineNfce': 9});
    });

    test('contingência entra na chave e gera dhCont/xJust', () {
      for (final tp in [TipoEmissao.fsIa, TipoEmissao.epec, TipoEmissao.fsDa]) {
        final m = montarNfe(_dados(tp: tp));
        expect(m.chave.valor[34], '${tp.codigo}');
        final ide = XmlDocument.parse(m.xml).findAllElements('ide').single;
        expect(ide.getElement('tpEmis')!.innerText, '${tp.codigo}');
        expect(ide.getElement('xJust'), isNotNull);
        expect(TipoEmissao.daChave(m.chave.valor), tp);
      }
    });

    test('só SVC usa outros servidores; EPEC/FS-IA/FS-DA/offline usam os normais', () {
      final normal = Enderecador.url(ServicoNfe.autorizacao, Uf.sp, ModeloDocumento.nfe, Ambiente.homologacao);
      for (final tp in [TipoEmissao.fsIa, TipoEmissao.epec, TipoEmissao.fsDa, TipoEmissao.offlineNfce]) {
        expect(tp.usaSvc, isFalse);
        expect(Enderecador.url(ServicoNfe.autorizacao, Uf.sp, ModeloDocumento.nfe, Ambiente.homologacao, tipoEmissao: tp),
            normal);
      }
      expect(TipoEmissao.svcAn.usaSvc, isTrue);
    });
  });
}
