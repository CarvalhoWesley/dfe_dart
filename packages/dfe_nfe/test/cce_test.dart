import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_nfe/dfe_nfe.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

final _cert = CertificadoDigital.dePfx(
    File('../dfe_core/test/fixtures/moderno.pfx').readAsBytesSync(), 'senha123');

const _chaveNfe = '35261112345678000195550010000004561123456780';
const _chaveNfce = '35261112345678000195650010000001231123456785';

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

}
