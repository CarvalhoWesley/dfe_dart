import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

const _id = 'NFe35241112345678000195650010000000011000000019';

String _fx(String nome) => File('test/fixtures/$nome').readAsStringSync();

CertificadoDigital _cert([String arquivo = 'moderno.pfx']) =>
    CertificadoDigital.dePfx(File('test/fixtures/$arquivo').readAsBytesSync(), 'senha123');

String _valor(String xml, String tag) => XmlDocument.parse(xml)
    .descendantElements
    .firstWhere((e) => e.name.local == tag)
    .innerText;

void main() {
  group('PKCS#12', () {
    for (final arquivo in ['moderno.pfx', 'legado.pfx', 'tresdes.pfx']) {
      test('carrega $arquivo', () {
        final c = _cert(arquivo);
        expect(c.nomeComum, 'EMPRESA TESTE LTDA:12345678000195');
        expect(c.documento, '12345678000195');
        expect(c.validoAte.isAfter(c.validoDe), isTrue);
        expect(c.chavePrivada.modulus, c.chavePublica.modulus);
      });
    }

    test('senha incorreta', () {
      expect(
        () => CertificadoDigital.dePfx(
            File('test/fixtures/moderno.pfx').readAsBytesSync(), 'errada'),
        throwsA(isA<Pkcs12Exception>()),
      );
    });

    test('PEM aceito pelo SecurityContext do dart:io', () {
      final c = _cert('legado.pfx');
      SecurityContext()
        ..useCertificateChainBytes(c.cadeiaPem)
        ..usePrivateKeyBytes(c.chavePem);
    });
  });

  group('Golden contra .NET SignedXml (lógica do Zeus)', () {
    for (final (alg, arquivo) in [
      (AlgoritmoAssinatura.sha1, 'nfe.signature.sha1.xml'),
      (AlgoritmoAssinatura.sha256, 'nfe.signature.sha256.xml'),
    ]) {
      test('${alg.name}: DigestValue e SignatureValue idênticos', () {
        final esperado = _fx(arquivo);
        final assinado = assinarXml(_fx('nfe.xml'), _id, _cert(), algoritmo: alg);

        expect(_valor(assinado, 'DigestValue'), _valor(esperado, 'DigestValue'));
        expect(_valor(assinado, 'SignatureValue'), _valor(esperado, 'SignatureValue'));
        expect(_valor(assinado, 'X509Certificate'), _valor(esperado, 'X509Certificate'));
      });
    }

    test('certificado legado produz a mesma assinatura (mesma chave)', () {
      final a = assinarXml(_fx('nfe.xml'), _id, _cert('legado.pfx'));
      expect(_valor(a, 'SignatureValue'),
          _valor(_fx('nfe.signature.sha1.xml'), 'SignatureValue'));
    });
  });

  group('XMLDSig', () {
    test('Signature inserida após infNFe e verificável', () {
      final assinado = assinarXml(_fx('nfe.xml'), _id, _cert());
      final nfe = XmlDocument.parse(assinado).rootElement;
      expect(nfe.childElements.map((e) => e.name.local), ['infNFe', 'Signature']);
      expect(verificarAssinatura(assinado).valido, isTrue);
    });

    test('alteração no conteúdo invalida o digest', () {
      final assinado = assinarXml(_fx('nfe.xml'), _id, _cert())
          .replaceFirst('<vNF>10.00</vNF>', '<vNF>11.00</vNF>');
      final r = verificarAssinatura(assinado);
      expect(r.digestValido, isFalse);
      expect(r.assinaturaValida, isTrue);
    });

    test('Id inexistente', () {
      expect(() => assinarXml(_fx('nfe.xml'), 'NFe0', _cert()),
          throwsA(isA<AssinaturaException>()));
    });
  });

  group('C14N', () {
    String c14n(String xml, String local) => canonicalizar(XmlDocument.parse(xml)
        .descendantElements
        .firstWhere((e) => e.name.local == local));

    test('herda namespace default do ancestral', () {
      expect(c14n('<a xmlns="urn:x"><b Id="1"/></a>', 'b'),
          '<b xmlns="urn:x" Id="1"></b>');
    });

    test('ordena namespaces e atributos e não repete declarações', () {
      expect(
        c14n('<r xmlns:z="urn:z" xmlns:a="urn:a"><e z:k="1" b="2" a="3" a:k="4"><f xmlns:a="urn:a"/></e></r>', 'e'),
        '<e xmlns:a="urn:a" xmlns:z="urn:z" a="3" b="2" a:k="4" z:k="1"><f></f></e>',
      );
    });

    test('escapes de texto e atributo, remove comentários', () {
      expect(c14n('<a t="&quot;&lt;&#9;">x &gt; y &amp; "z"<!-- c --></a>', 'a'),
          '<a t="&quot;&lt;&#x9;">x &gt; y &amp; "z"</a>');
    });

    test('xmlns="" emitido somente quando necessário', () {
      expect(c14n('<a xmlns="urn:x"><b xmlns=""><c/></b></a>', 'a'),
          '<a xmlns="urn:x"><b xmlns=""><c></c></b></a>');
    });
  });
}
