import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';

import '../certificado/certificado_digital.dart';
import 'c14n.dart';

const _c14n = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
const _enveloped = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';

/// Algoritmos de assinatura/digest (mesmos defaults do Zeus: RSA-SHA1/SHA1).
enum AlgoritmoAssinatura {
  sha1(
    'http://www.w3.org/2000/09/xmldsig#rsa-sha1',
    'http://www.w3.org/2000/09/xmldsig#sha1',
    'SHA-1',
  ),
  sha256(
    'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
    'http://www.w3.org/2001/04/xmlenc#sha256',
    'SHA-256',
  );

  const AlgoritmoAssinatura(this.signatureMethod, this.digestMethod, this.digest);

  final String signatureMethod;
  final String digestMethod;
  final String digest;

  static AlgoritmoAssinatura? porSignatureMethod(String uri) {
    for (final a in values) {
      if (a.signatureMethod == uri) return a;
    }
    return null;
  }
}

class AssinaturaException implements Exception {
  AssinaturaException(this.message);
  final String message;
  @override
  String toString() => 'AssinaturaException: $message';
}

/// Assina (XMLDSig envelopado, C14N inclusiva) o elemento com atributo
/// `Id="[id]"` e insere `<Signature>` logo após ele, no mesmo pai
/// (ex.: `infNFe` → `NFe/Signature`, `infEvento` → `evento/Signature`).
///
/// Equivalente a `AssinaturaDigital.AssinaXml` do Zeus.
String assinarXml(
  String xml,
  String id,
  CertificadoDigital certificado, {
  AlgoritmoAssinatura algoritmo = AlgoritmoAssinatura.sha1,
}) {
  final doc = XmlDocument.parse(_normalizarQuebras(xml));
  final alvo = _buscarPorId(doc, id);
  if (alvo == null) {
    throw AssinaturaException('Elemento com Id="$id" não encontrado');
  }
  final pai = alvo.parentElement;
  if (pai == null) {
    throw AssinaturaException('O elemento assinado não pode ser a raiz');
  }

  final digest = base64.encode(_hash(
      algoritmo, utf8.encode(canonicalizar(alvo, removerAssinaturas: true))));

  final signedInfoInterno = '<CanonicalizationMethod Algorithm="$_c14n"></CanonicalizationMethod>'
      '<SignatureMethod Algorithm="${algoritmo.signatureMethod}"></SignatureMethod>'
      '<Reference URI="#$id"><Transforms>'
      '<Transform Algorithm="$_enveloped"></Transform>'
      '<Transform Algorithm="$_c14n"></Transform>'
      '</Transforms>'
      '<DigestMethod Algorithm="${algoritmo.digestMethod}"></DigestMethod>'
      '<DigestValue>$digest</DigestValue></Reference>';

  // Forma canônica do SignedInfo dentro de <Signature xmlns=ds>.
  final signedInfoCanonico =
      '<SignedInfo xmlns="$nsXmlDsig">$signedInfoInterno</SignedInfo>';

  final signer = Signer('${algoritmo.digest}/RSA')
    ..init(true, PrivateKeyParameter<RSAPrivateKey>(certificado.chavePrivada));
  final assinatura = signer.generateSignature(
      Uint8List.fromList(utf8.encode(signedInfoCanonico))) as RSASignature;

  final signatureXml = '<Signature xmlns="$nsXmlDsig">'
      '<SignedInfo>$signedInfoInterno</SignedInfo>'
      '<SignatureValue>${base64.encode(assinatura.bytes)}</SignatureValue>'
      '<KeyInfo><X509Data><X509Certificate>${certificado.certificadoBase64}'
      '</X509Certificate></X509Data></KeyInfo></Signature>';

  final noAssinatura = XmlDocumentFragment.parse(signatureXml).firstElementChild!
      .copy();
  final indice = pai.children.indexOf(alvo);
  pai.children.insert(indice + 1, noAssinatura);
  return doc.toXmlString();
}

/// Resultado da verificação de uma assinatura XMLDSig.
class ResultadoVerificacao {
  ResultadoVerificacao({required this.digestValido, required this.assinaturaValida});
  final bool digestValido;
  final bool assinaturaValida;
  bool get valido => digestValido && assinaturaValida;
}

/// Verifica a primeira `<Signature>` do documento, usando o certificado embutido.
ResultadoVerificacao verificarAssinatura(String xml) {
  final doc = XmlDocument.parse(_normalizarQuebras(xml));
  final sig = doc.descendantElements.firstWhere(
      (e) => e.name.local == 'Signature',
      orElse: () => throw AssinaturaException('Nenhuma Signature encontrada'));

  XmlElement filho(XmlElement e, String nome) =>
      e.descendantElements.firstWhere((x) => x.name.local == nome);

  final signedInfo = filho(sig, 'SignedInfo');
  final reference = filho(signedInfo, 'Reference');
  final uri = reference.getAttribute('URI')!;
  final algoritmo = AlgoritmoAssinatura.porSignatureMethod(
          filho(signedInfo, 'SignatureMethod').getAttribute('Algorithm')!) ??
      (throw AssinaturaException('SignatureMethod não suportado'));

  final alvo = _buscarPorId(doc, uri.substring(1))!;
  final digest = base64.encode(_hash(
      algoritmo, utf8.encode(canonicalizar(alvo, removerAssinaturas: true))));
  final digestValido = digest == filho(reference, 'DigestValue').innerText.trim();

  final certDer = base64.decode(
      filho(sig, 'X509Certificate').innerText.replaceAll(RegExp(r'\s'), ''));
  final valorAssinatura = base64.decode(
      filho(sig, 'SignatureValue').innerText.replaceAll(RegExp(r'\s'), ''));

  final verifier = Signer('${algoritmo.digest}/RSA')
    ..init(false, PublicKeyParameter<RSAPublicKey>(chavePublicaDoCertificado(certDer)));
  final assinaturaValida = verifier.verifySignature(
    Uint8List.fromList(utf8.encode(canonicalizar(signedInfo))),
    RSASignature(valorAssinatura),
  );

  return ResultadoVerificacao(
      digestValido: digestValido, assinaturaValida: assinaturaValida);
}

XmlElement? _buscarPorId(XmlDocument doc, String id) {
  for (final e in doc.descendantElements) {
    if (e.getAttribute('Id') == id) return e;
  }
  return null;
}

Uint8List _hash(AlgoritmoAssinatura alg, List<int> dados) =>
    Digest(alg.digest).process(Uint8List.fromList(dados));

/// Normalização de fim de linha exigida pela especificação XML (§2.11).
String _normalizarQuebras(String s) =>
    s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
