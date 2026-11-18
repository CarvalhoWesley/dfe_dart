import 'package:dfe_core/dfe_core.dart';

import 'autorizacao/autorizacao.dart';
import 'enderecos.dart';
import 'enums.dart';
import 'eventos/eventos.dart';
import 'status/cons_stat_serv.dart';

/// Resultado do envio de um evento.
class ResultadoEvento {
  ResultadoEvento({
    required this.envioXml,
    required this.retornoXml,
    required this.lote,
    required this.evento,
    this.retEvento,
    this.procEventoXml,
  });

  final String envioXml;
  final String retornoXml;
  final RetEnvEvento lote;
  final EventoNfe evento;
  final RetEvento? retEvento;

  /// `procEventoNFe`, presente quando o evento foi registrado.
  final String? procEventoXml;
}

/// Resultado de uma inutilização.
class ResultadoInutilizacao {
  ResultadoInutilizacao({
    required this.envioXml,
    required this.retornoXml,
    required this.retorno,
    this.procInutXml,
  });

  final String envioXml;
  final String retornoXml;
  final RetInutNfe retorno;

  /// `ProcInutNFe`, presente quando homologada.
  final String? procInutXml;
}

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

  /// Consulta a situação da NF-e/NFC-e pela chave de acesso.
  ///
  /// Notas emitidas em SVC são consultadas na SVC.
  Future<RetornoNfe<RetConsSitNfe>> consultarProtocolo(String chave) async {
    final envio = montarConsSitNfe(chave, config.ambiente);
    final ret = await _enviar(
        ServicoNfe.consultaProtocolo, _url(ServicoNfe.consultaProtocolo, chave), envio);
    return RetornoNfe(envioXml: envio, retornoXml: ret, retorno: RetConsSitNfe.fromXml(ret));
  }

  /// Cancela uma NF-e/NFC-e autorizada (evento 110111).
  ///
  /// [procEventoXml] do resultado é o XML a guardar quando [RetEvento.registrado].
  Future<ResultadoEvento> cancelar({
    required String chave,
    required String protocolo,
    required String justificativa,
    required int idLote,
    String? cnpj,
    int sequencia = 1,
  }) async {
    return _enviarEvento(
      (data) => montarEventoCancelamento(
        chave: chave,
        protocolo: protocolo,
        justificativa: justificativa,
        cnpj: cnpj ?? chave.substring(6, 20),
        ambiente: config.ambiente,
        certificado: config.certificado,
        sequencia: sequencia,
        dataEvento: data,
      ),
      chave,
      idLote,
    );
  }

  /// Envia uma Carta de Correção (CC-e, evento 110110) — somente NF-e.
  ///
  /// [sequencia] deve ser a próxima da nota (1 para a primeira CC-e).
  Future<ResultadoEvento> cartaCorrecao({
    required String chave,
    required String correcao,
    required int sequencia,
    required int idLote,
    String? cnpj,
  }) {
    return _enviarEvento(
      (data) => montarEventoCartaCorrecao(
        chave: chave,
        correcao: correcao,
        cnpj: cnpj ?? chave.substring(6, 20),
        ambiente: config.ambiente,
        certificado: config.certificado,
        sequencia: sequencia,
        dataEvento: data,
      ),
      chave,
      idLote,
    );
  }

  /// Envia o evento. Se for rejeitado e o `dhEvento` enviado estiver à frente
  /// do `dhRegEvento` da SEFAZ (relógio do servidor de eventos atrasado — visto
  /// na SEFAZ-SP como cStat 999), reassina com o horário da SEFAZ e reenvia uma
  /// vez. A rejeição não consome a sequência do evento.
  Future<ResultadoEvento> _enviarEvento(
      EventoNfe Function(DateTime? dataEvento) montar, String chave, int idLote) async {
    var evento = montar(null);
    var envio = montarEnvEvento([evento], idLote: idLote);
    final url = _url(ServicoNfe.recepcaoEvento, chave);
    var ret = await _enviar(ServicoNfe.recepcaoEvento, url, envio);
    var lote = RetEnvEvento.fromXml(ret);
    var retEvento = lote.eventos.firstOrNull;

    final enviado = _dhEvento(evento.xml);
    final registro = retEvento?.dataRegistro;
    if (retEvento != null &&
        !retEvento.registrado &&
        enviado != null &&
        registro != null &&
        enviado.isAfter(registro)) {
      evento = montar(registro.subtract(const Duration(seconds: 2)));
      envio = montarEnvEvento([evento], idLote: idLote);
      ret = await _enviar(ServicoNfe.recepcaoEvento, url, envio);
      lote = RetEnvEvento.fromXml(ret);
      retEvento = lote.eventos.firstOrNull;
    }

    return ResultadoEvento(
      envioXml: envio,
      retornoXml: ret,
      lote: lote,
      evento: evento,
      retEvento: retEvento,
      procEventoXml: retEvento != null && retEvento.registrado
          ? montarProcEventoNfe(evento, retEvento)
          : null,
    );
  }

  static DateTime? _dhEvento(String xml) {
    final m = RegExp(r'<dhEvento>([^<]+)</dhEvento>').firstMatch(xml);
    return m == null ? null : DateTime.tryParse(m.group(1)!);
  }

  /// Inutiliza uma faixa de numeração ([numeroInicial] a [numeroFinal]).
  Future<ResultadoInutilizacao> inutilizar({
    required String cnpj,
    required int serie,
    required int numeroInicial,
    required int numeroFinal,
    required String justificativa,
    int? ano,
  }) async {
    final inut = montarInutilizacao(
      uf: config.uf,
      ambiente: config.ambiente,
      cnpj: cnpj,
      modelo: config.modelo,
      serie: serie,
      numeroInicial: numeroInicial,
      numeroFinal: numeroFinal,
      justificativa: justificativa,
      certificado: config.certificado,
      ano: ano,
    );
    final url = Enderecador.url(ServicoNfe.inutilizacao, config.uf, config.modelo, config.ambiente);
    final ret = await _enviar(ServicoNfe.inutilizacao, url, inut.xml);
    final r = RetInutNfe.fromXml(ret);
    return ResultadoInutilizacao(
      envioXml: inut.xml,
      retornoXml: ret,
      retorno: r,
      procInutXml: r.homologada ? montarProcInutNfe(inut, r) : null,
    );
  }

  /// URL considerando a forma de emissão da chave (SVC usa o servidor de contingência).
  String _url(ServicoNfe servico, String chave) {
    final tp = TipoEmissao.daChave(chave);
    return Enderecador.url(servico, config.uf, config.modelo, config.ambiente,
        tipoEmissao: tp == TipoEmissao.svcAn || tp == TipoEmissao.svcRs ? tp : TipoEmissao.normal);
  }

  Future<String> _enviar(ServicoNfe servico, String url, String xml) => _soap.enviar(
        url: url,
        namespaceWsdl: servico.namespaceWsdl,
        action: servico.action,
        xmlDados: xml,
      );

  void fechar() => _soap.fechar();
}
