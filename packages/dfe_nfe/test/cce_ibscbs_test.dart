import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _chaveNfe = '35261112345678000195550010000004561123456780';
const _chaveNfce = '35261112345678000195650010000001231123456785';
const _end = Endereco(
  logradouro: 'RUA', numero: '1', bairro: 'CENTRO', codigoMunicipio: 3550308,
  municipio: 'SAO PAULO', uf: Uf.sp, cep: '01001000',
);

List<String> _filhos(XmlElement e) => e.childElements.map((c) => c.name.local).toList();

void main() {
  group('CC-e', () {
    test('evento 110110: Id com sequência, detEvento e assinatura', () {
      final e = montarEventoCartaCorrecao(
        chave: _chaveNfe,
        correcao: 'CORRIGIR O ENDERECO DO DESTINATARIO PARA RUA B, 20',
        cnpj: '12345678000195',
        ambiente: Ambiente.homologacao,
        certificado: _cert,
        sequencia: 3,
      );
      expect(e.id, 'ID110110${_chaveNfe}03');
      final x = XmlDocument.parse(e.xml);
      expect(x.findAllElements('tpEvento').single.innerText, '110110');
      expect(x.findAllElements('nSeqEvento').single.innerText, '3');
      expect(_filhos(x.findAllElements('detEvento').single), ['descEvento', 'xCorrecao', 'xCondUso']);
      expect(x.findAllElements('descEvento').single.innerText, 'Carta de Correcao');
      expect(x.findAllElements('xCondUso').single.innerText, condicaoUsoCartaCorrecao);
      expect(verificarAssinatura(e.xml).valido, isTrue);
    });

    test('validações: NFC-e, texto curto e sequência', () {
      CertificadoDigital c() => _cert;
      expect(
          () => montarEventoCartaCorrecao(chave: _chaveNfce, correcao: 'CORRECAO VALIDA DE TESTE', cnpj: '1',
              ambiente: Ambiente.homologacao, certificado: c()),
          throwsArgumentError);
      expect(
          () => montarEventoCartaCorrecao(chave: _chaveNfe, correcao: 'curta', cnpj: '1',
              ambiente: Ambiente.homologacao, certificado: c()),
          throwsArgumentError);
      expect(
          () => montarEventoCartaCorrecao(chave: _chaveNfe, correcao: 'CORRECAO VALIDA DE TESTE', cnpj: '1',
              ambiente: Ambiente.homologacao, certificado: c(), sequencia: 21),
          throwsArgumentError);
    });
  });

  group('IBS/CBS', () {
    XmlDocument nota(List<ItemNfe> itens) {
      final d = DadosNfe(
        modelo: ModeloDocumento.nfe,
        ambiente: Ambiente.homologacao,
        serie: 1,
        numero: 1,
        codigoNumerico: 12345678,
        emitente: const Emitente(
            cnpj: '12345678000195', razaoSocial: 'E', inscricaoEstadual: '1', endereco: _end, crt: 3),
        destinatario: const Destinatario(nome: 'C', cpf: '11144477735', endereco: _end),
        itens: itens,
        pagamentos: [Pagamento(tipo: '01', valor: TotaisNfe.calcular(itens).vNF)],
      );
      return XmlDocument.parse(EmissorNfe(_cert).gerar(d).xmlAssinado);
    }

    ItemNfe item({IbsCbs? ibsCbs, Icms icms = const Csosn102(), PisCofins pc = const PisCofins.naoTributado()}) =>
        ItemNfe(
          codigo: '1', descricao: 'P', ncm: '21069090', cfop: '5102', unidade: 'UN',
          quantidade: 1, valorUnitario: 100, icms: icms, pis: pc, cofins: pc, ibsCbs: ibsCbs,
        );

    test('grupo do item na ordem do schema e por último no imposto', () {
      final x = nota([item(ibsCbs: const IbsCbs(classificacao: '000001'))]);
      final imposto = x.findAllElements('imposto').single;
      expect(_filhos(imposto).last, 'IBSCBS');
      final g = imposto.getElement('IBSCBS')!;
      expect(_filhos(g), ['CST', 'cClassTrib', 'gIBSCBS']);
      expect(_filhos(g.getElement('gIBSCBS')!), ['vBC', 'gIBSUF', 'gIBSMun', 'vIBS', 'gCBS']);
      expect(g.findAllElements('vIBSUF').single.innerText, '0.10');
      expect(g.findAllElements('vCBS').single.innerText, '0.90');
    });

    test('base desconta ICMS, PIS e COFINS; valores não entram no vNF', () {
      final x = nota([
        item(
          icms: const Icms00(aliquota: 18),
          pc: const PisCofins.aliquota(aliquota: 1),
          ibsCbs: const IbsCbs(classificacao: '000001'),
        ),
      ]);
      // 100 − 18 (ICMS) − 1 (PIS) − 1 (COFINS) = 80
      expect(x.findAllElements('gIBSCBS').single.getElement('vBC')!.innerText, '80.00');
      final tot = x.findAllElements('IBSCBSTot').single;
      expect(_filhos(tot), ['vBCIBSCBS', 'gIBS', 'gCBS']);
      expect(tot.getElement('vBCIBSCBS')!.innerText, '80.00');
      expect(tot.findAllElements('vCBS').single.innerText, '0.72');
      expect(x.findAllElements('vNF').single.innerText, '100.00');
      final total = x.findAllElements('total').single;
      expect(_filhos(total), ['ICMSTot', 'IBSCBSTot']);
    });

    test('CST sem cálculo só leva CST e cClassTrib; sem grupo nos itens não há IBSCBSTot', () {
      final x = nota([item(ibsCbs: const IbsCbs.semCalculo(cst: '410', classificacao: '410001'))]);
      expect(_filhos(x.findAllElements('IBSCBS').single), ['CST', 'cClassTrib']);
      expect(nota([item()]).findAllElements('IBSCBSTot'), isEmpty);
    });
  });
}
