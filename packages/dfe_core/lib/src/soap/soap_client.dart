import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import 'transporte.dart';

class ComunicacaoException implements Exception {
  ComunicacaoException(this.message, {this.statusCode, this.corpo});
  final String message;
  final int? statusCode;
  final String? corpo;
  @override
  String toString() =>
      'ComunicacaoException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Cliente SOAP 1.2 da SEFAZ. A camada HTTP/TLS é delegada a um [TransporteSoap].
class SoapClient {
  SoapClient(this.transporte, {this.timeout = const Duration(seconds: 30)});

  final TransporteSoap transporte;
  final Duration timeout;

  /// Monta o envelope, envia e devolve o XML do primeiro elemento dentro de
  /// `<nfeResultMsg>` (ou do elemento de resposta indicado).
  Future<String> enviar({
    required String url,
    required String namespaceWsdl,
    required String action,
    required String xmlDados,
    String elementoResposta = 'nfeResultMsg',
  }) async {
    final envelope = montarEnvelope(namespaceWsdl, xmlDados);
    final RespostaHttp resp;
    try {
      resp = await transporte.post(
        Uri.parse(url),
        cabecalhos: {
          'Content-Type': 'application/soap+xml; charset=utf-8; action="$action"',
        },
        corpo: Uint8List.fromList(utf8.encode(envelope)),
        timeout: timeout,
      );
    } on TransporteException catch (e) {
      throw ComunicacaoException(e.message);
    }

    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(resp.corpo);
    } on XmlException {
      throw ComunicacaoException('Resposta não é XML',
          statusCode: resp.status, corpo: resp.corpo);
    }

    final result = doc.descendantElements
        .where((e) => e.name.local == elementoResposta)
        .firstOrNull;
    if (result == null) {
      final fault = doc.descendantElements
          .where((e) => e.name.local == 'Text' || e.name.local == 'faultstring')
          .firstOrNull;
      throw ComunicacaoException(
        fault?.innerText ?? 'Elemento $elementoResposta ausente na resposta',
        statusCode: resp.status,
        corpo: resp.corpo,
      );
    }
    final conteudo = result.firstElementChild;
    if (conteudo == null) {
      throw ComunicacaoException('Resposta vazia',
          statusCode: resp.status, corpo: resp.corpo);
    }
    return conteudo.toXmlString();
  }

  static String montarEnvelope(String namespaceWsdl, String xmlDados) {
    final dados = xmlDados.replaceFirst(RegExp(r'^\s*<\?xml[^>]*\?>\s*'), '');
    return '<?xml version="1.0" encoding="utf-8"?>'
        '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xmlns:xsd="http://www.w3.org/2001/XMLSchema" '
        'xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
        '<soap12:Body><nfeDadosMsg xmlns="$namespaceWsdl">$dados</nfeDadosMsg>'
        '</soap12:Body></soap12:Envelope>';
  }

  void fechar() => transporte.fechar();
}
