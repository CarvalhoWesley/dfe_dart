import 'package:dfe_core/dfe_core.dart';

import 'autorizacao/autorizacao.dart';
import 'enderecos.dart';
import 'enums.dart';
import 'status/cons_stat_serv.dart';

/// Configuração imutável dos serviços (substitui o singleton `ConfiguracaoServico` do Zeus).
class ConfiguracaoNfe {
  const ConfiguracaoNfe({
    required this.certificado,
    required this.uf,
    required this.ambiente,
    required this.modelo,
    this.timeout = const Duration(seconds: 30),
    this.urlStatus,
  });

  final CertificadoDigital certificado;
  final Uf uf;
  final Ambiente ambiente;
  final ModeloDocumento modelo;
  final Duration timeout;

  /// Sobrescreve a URL do serviço de status.
  final String? urlStatus;

  ConfiguracaoNfe copiarCom({ModeloDocumento? modelo}) => ConfiguracaoNfe(
        certificado: certificado,
        uf: uf,
        ambiente: ambiente,
        modelo: modelo ?? this.modelo,
        timeout: timeout,
        urlStatus: urlStatus,
      );
}

/// Retorno com os XMLs trocados, como o `RetornoBasico` do Zeus.
class RetornoNfe<T> {
  RetornoNfe({required this.envioXml, required this.retornoXml, required this.retorno});
  final String envioXml;
  final String retornoXml;
  final T retorno;
}

/// Resultado de uma autorização.
class ResultadoAutorizacao {
  ResultadoAutorizacao({
    required this.envioXml,
    required this.retornoXml,
    required this.lote,
    this.reciboXml,
    this.consultaReciboXml,
  });

  /// `enviNFe` enviado.
  final String envioXml;

  /// `retEnviNFe` recebido.
  final String retornoXml;

  /// Último retorno de lote (do `retEnviNFe` ou do `retConsReciNFe`).
  final RetornoLote lote;

  /// `consReciNFe` enviado e `retConsReciNFe` recebido (modo assíncrono).
  final String? reciboXml;
  final String? consultaReciboXml;

  ProtNfe? get protocolo => lote.protocolos.firstOrNull;
}

/// Porte de `NFe.Servicos/ServicosNFe.cs`.
///
/// [transporte] deve ser nativo para falar com a SEFAZ (ver `dfe_transporte_ffi`
/// e `dfe_flutter`); o `TransporteDartIo` não aceita renegociação TLS.
class ServicosNfe {
  ServicosNfe(this.config, {required TransporteSoap transporte})
      : _soap = SoapClient(transporte, timeout: config.timeout);

  final ConfiguracaoNfe config;
  final SoapClient _soap;

  Future<RetornoNfe<RetConsStatServ>> statusServico({
    TipoEmissao tipoEmissao = TipoEmissao.normal,
  }) async {
    final envio = ConsStatServ(tpAmb: config.ambiente, cUF: config.uf).toXml();
    final url = config.urlStatus ??
        Enderecador.url(ServicoNfe.statusServico, config.uf, config.modelo, config.ambiente,
            tipoEmissao: tipoEmissao);
    final retornoXml = await _enviar(ServicoNfe.statusServico, url, envio);
    return RetornoNfe(
      envioXml: envio,
      retornoXml: retornoXml,
      retorno: RetConsStatServ.fromXml(retornoXml),
    );
  }

  /// Envia uma NF-e/NFC-e assinada para autorização.
  ///
  /// Tenta o modo síncrono; se a SEFAZ responder 103 (lote recebido), consulta
  /// o recibo até obter o protocolo.
  Future<ResultadoAutorizacao> autorizar(
    String nfeAssinada, {
    required int idLote,
    TipoEmissao tipoEmissao = TipoEmissao.normal,
    bool sincrono = true,
    int tentativasRecibo = 5,
  }) async {
    final envio = montarEnviNfe([nfeAssinada], idLote: idLote, sincrono: sincrono);
    final urlAut = Enderecador.url(
        ServicoNfe.autorizacao, config.uf, config.modelo, config.ambiente,
        tipoEmissao: tipoEmissao);
    final retornoXml = await _enviar(ServicoNfe.autorizacao, urlAut, envio);
    var lote = RetornoLote.fromXml(retornoXml);

    String? reciboXml;
    String? consultaXml;
    if (lote.cStat == 103 && lote.recibo != null) {
      final urlRet = Enderecador.url(
          ServicoNfe.retAutorizacao, config.uf, config.modelo, config.ambiente,
          tipoEmissao: tipoEmissao);
      reciboXml = montarConsReciNfe(lote.recibo!, config.ambiente);
      var espera = Duration(seconds: (lote.tMed ?? 1).clamp(1, 10));
      for (var i = 0; i < tentativasRecibo; i++) {
        await Future<void>.delayed(espera);
        consultaXml = await _enviar(ServicoNfe.retAutorizacao, urlRet, reciboXml);
        lote = RetornoLote.fromXml(consultaXml);
        if (lote.cStat != 105) break;
        espera = espera * 2;
      }
    }

    return ResultadoAutorizacao(
      envioXml: envio,
      retornoXml: retornoXml,
      lote: lote,
      reciboXml: reciboXml,
      consultaReciboXml: consultaXml,
    );
  }

  Future<String> _enviar(ServicoNfe servico, String url, String xml) => _soap.enviar(
        url: url,
        namespaceWsdl: servico.namespaceWsdl,
        action: servico.action,
        xmlDados: xml,
      );

  void fechar() => _soap.fechar();
}
