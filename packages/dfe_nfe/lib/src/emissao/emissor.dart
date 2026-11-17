import 'package:dfe_core/dfe_core.dart';

import '../enums.dart';
import '../util/chave_acesso.dart';
import 'dados_nfe.dart';
import 'montador_nfe.dart';
import 'qrcode_nfce.dart';

/// Configuração da NFC-e (QR Code).
class ConfiguracaoNfce {
  const ConfiguracaoNfce({
    this.versaoQrCode = VersaoQrCode.v3,
    this.idCsc,
    this.csc,
    this.urlQrCode,
    this.urlConsulta,
  });

  final VersaoQrCode versaoQrCode;
  final String? idCsc;
  final String? csc;

  /// Sobrescrevem a tabela [UrlsNfce] (necessário para UFs ainda não mapeadas).
  final String? urlQrCode;
  final String? urlConsulta;
}

/// NF-e/NFC-e pronta para transmissão.
class DocumentoNfe {
  DocumentoNfe(this.chave, this.xmlAssinado, this.qrCode);
  final ChaveAcesso chave;

  /// `<NFe>` assinado (com `infNFeSupl` na NFC-e).
  final String xmlAssinado;

  /// Conteúdo do QR Code (somente NFC-e).
  final String? qrCode;
}

/// Gera e assina NF-e/NFC-e: montagem → assinatura → QR Code (NFC-e).
class EmissorNfe {
  EmissorNfe(this.certificado, {this.nfce = const ConfiguracaoNfce()});

  final CertificadoDigital certificado;
  final ConfiguracaoNfce nfce;

  DocumentoNfe gerar(DadosNfe dados) {
    final montada = montarNfe(dados);
    var xml = assinarXml(montada.xml, montada.chave.id, certificado);

    String? qr;
    if (dados.modelo == ModeloDocumento.nfce) {
      final uf = dados.emitente.endereco.uf;
      final urls = UrlsNfce.obter(uf, dados.ambiente);
      final urlQr = nfce.urlQrCode ?? urls?.qrCode;
      final urlConsulta = nfce.urlConsulta ?? urls?.consulta;
      if (urlQr == null || urlConsulta == null) {
        throw UnsupportedError(
            'URLs de QR Code da NFC-e para ${uf.sigla} não mapeadas: informe-as em ConfiguracaoNfce.');
      }
      qr = gerarQrCode(
        nfeAssinada: xml,
        urlQrCode: urlQr,
        versao: nfce.versaoQrCode,
        certificado: certificado,
        idCsc: nfce.idCsc,
        csc: nfce.csc,
      );
      xml = inserirInfNfeSupl(xml, qr, urlConsulta);
    }
    return DocumentoNfe(montada.chave, xml, qr);
  }
}
