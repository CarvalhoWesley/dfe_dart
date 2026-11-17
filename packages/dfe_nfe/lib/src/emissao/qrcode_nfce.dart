import 'dart:convert';
import 'dart:typed_data';

import 'package:dfe_core/dfe_core.dart';
import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';

import '../enums.dart';
import '../util/formatacao.dart';

/// Versão do QR Code da NFC-e.
enum VersaoQrCode {
  /// v2: usa CSC (idCSC + token).
  v2,

  /// v3 (NT 2025.001): sem CSC; em contingência é assinado com o certificado.
  v3,
}

/// URLs de consulta da NFC-e por UF (porte parcial de `ExtinfNFeSupl.cs`).
class UrlsNfce {
  const UrlsNfce(this.qrCode, this.consulta);
  final String qrCode;
  final String consulta;

  static const _tabela = <Uf, Map<Ambiente, UrlsNfce>>{
    Uf.sp: {
      Ambiente.homologacao: UrlsNfce('https://www.homologacao.nfce.fazenda.sp.gov.br/qrcode',
          'https://www.homologacao.nfce.fazenda.sp.gov.br/consulta'),
      Ambiente.producao: UrlsNfce(
          'https://www.nfce.fazenda.sp.gov.br/qrcode', 'https://www.nfce.fazenda.sp.gov.br/consulta'),
    },
  };

  static UrlsNfce? obter(Uf uf, Ambiente ambiente) => _tabela[uf]?[ambiente];
}

/// Dados do `<NFe>` necessários ao QR Code, lidos do XML assinado.
class _InfoNfe {
  _InfoNfe(XmlDocument doc) {
    final inf = doc.findAllElements('infNFe').first;
    chave = inf.getAttribute('Id')!.substring(3);
    final ide = inf.getElement('ide')!;
    tpAmb = ide.getElement('tpAmb')!.innerText;
    tpEmis = int.parse(ide.getElement('tpEmis')!.innerText);
    dia = ide.getElement('dhEmi')!.innerText.substring(8, 10);
    vNF = double.parse(inf.findAllElements('vNF').first.innerText);
    final dest = inf.getElement('dest');
    if (dest != null) {
      final cnpj = dest.getElement('CNPJ')?.innerText;
      final cpf = dest.getElement('CPF')?.innerText;
      final estr = dest.getElement('idEstrangeiro')?.innerText;
      if (estr != null && estr.isNotEmpty) {
        tpIdDest = '3';
        idDest = estr;
      } else if (cpf != null) {
        tpIdDest = '2';
        idDest = cpf;
      } else if (cnpj != null) {
        tpIdDest = '1';
        idDest = cnpj;
      }
    }
    digestValue = doc.findAllElements('DigestValue').firstOrNull?.innerText;
  }

  late final String chave;
  late final String tpAmb;
  late final int tpEmis;
  late final String dia;
  late final double vNF;
  String tpIdDest = '';
  String idDest = '';
  String? digestValue;

  bool get offline => tpEmis == TipoEmissao.offlineNfce.codigo;
}

/// Gera o conteúdo do QR Code (URL completa) a partir da NFC-e **assinada**.
String gerarQrCode({
  required String nfeAssinada,
  required String urlQrCode,
  required VersaoQrCode versao,
  CertificadoDigital? certificado,
  String? idCsc,
  String? csc,
}) {
  final info = _InfoNfe(XmlDocument.parse(nfeAssinada));
  final url = urlQrCode.contains('?p=') ? urlQrCode : '$urlQrCode?p=';

  switch (versao) {
    case VersaoQrCode.v2:
      if (idCsc == null || csc == null) {
        throw ArgumentError('QR Code v2 exige idCsc e csc');
      }
      final id = int.parse(idCsc).toString();
      final String base;
      if (info.offline) {
        final digVal = _hexDeTexto(info.digestValue ?? '');
        base = '${info.chave}|2|${info.tpAmb}|${info.dia}|${formatarDecimal(info.vNF)}|$digVal|$id';
      } else {
        base = '${info.chave}|2|${info.tpAmb}|$id';
      }
      final hash = _hex(SHA1Digest().process(Uint8List.fromList(utf8.encode('$base$csc'))))
          .toUpperCase();
      return '$url$base|$hash';

    case VersaoQrCode.v3:
      var base = '${info.chave}|3|${info.tpAmb}';
      if (info.offline) {
        if (certificado == null) {
          throw ArgumentError('QR Code v3 em contingência exige o certificado');
        }
        base = '$base|${info.dia}|${formatarDecimal(info.vNF)}|${info.tpIdDest}|${info.idDest}';
        final signer = Signer('SHA-1/RSA')
          ..init(true, PrivateKeyParameter<RSAPrivateKey>(certificado.chavePrivada));
        final ass = signer.generateSignature(Uint8List.fromList(utf8.encode(base)))
            as RSASignature;
        base = '$base|${base64.encode(ass.bytes)}';
      }
      return '$url$base';
  }
}

/// Insere `<infNFeSupl>` entre `</infNFe>` e `<Signature>` (fora da área assinada).
String inserirInfNfeSupl(String nfeAssinada, String qrCode, String urlChave) {
  final doc = XmlDocument.parse(nfeAssinada);
  final inf = doc.findAllElements('infNFe').first;
  final supl = XmlDocumentFragment.parse(
          '<infNFeSupl><qrCode>${escaparXml(qrCode)}</qrCode>'
          '<urlChave>${escaparXml(urlChave)}</urlChave></infNFeSupl>')
      .firstElementChild!
      .copy();
  final pai = inf.parentElement!;
  pai.children.insert(pai.children.indexOf(inf) + 1, supl);
  return doc.toXmlString();
}

String _hex(List<int> b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

/// Hexadecimal dos bytes do texto (usado no digVal).
String _hexDeTexto(String s) => _hex(utf8.encode(s));
