import 'enums.dart';

const _wsdl = 'http://www.portalfiscal.inf.br/nfe/wsdl';

/// Serviços da NF-e/NFC-e 4.00.
enum ServicoNfe {
  statusServico('$_wsdl/NFeStatusServico4', '$_wsdl/NFeStatusServico4/nfeStatusServicoNF'),
  autorizacao('$_wsdl/NFeAutorizacao4', '$_wsdl/NFeAutorizacao4/nfeAutorizacaoLote'),
  retAutorizacao('$_wsdl/NFeRetAutorizacao4', '$_wsdl/NFeRetAutorizacao4/nfeRetAutorizacaoLote'),
  consultaProtocolo('$_wsdl/NFeConsultaProtocolo4', '$_wsdl/NFeConsultaProtocolo4/nfeConsultaNF'),
  inutilizacao('$_wsdl/NFeInutilizacao4', '$_wsdl/NFeInutilizacao4/nfeInutilizacaoNF'),
  recepcaoEvento('$_wsdl/NFeRecepcaoEvento4', '$_wsdl/NFeRecepcaoEvento4/nfeRecepcaoEvento');

  const ServicoNfe(this.namespaceWsdl, this.action);
  final String namespaceWsdl;
  final String action;
}

typedef _Urls = Map<ServicoNfe, String>;

/// Tabela de URLs (porte parcial de `NFe.Utils/Enderecos/Enderecador.cs`).
///
/// Cobre SP, RS, PR, MG (status), as UFs atendidas pela SVRS e as
/// contingências SVC-AN/SVC-RS. A tabela completa entra na Fase 2.
class Enderecador {
  static _Urls _svrs(String host) => {
        ServicoNfe.statusServico: 'https://$host/ws/NfeStatusServico/NfeStatusServico4.asmx',
        ServicoNfe.autorizacao: 'https://$host/ws/NfeAutorizacao/NFeAutorizacao4.asmx',
        ServicoNfe.retAutorizacao: 'https://$host/ws/NfeRetAutorizacao/NFeRetAutorizacao4.asmx',
        ServicoNfe.consultaProtocolo: 'https://$host/ws/NfeConsulta/NfeConsulta4.asmx',
        ServicoNfe.inutilizacao: 'https://$host/ws/nfeinutilizacao/nfeinutilizacao4.asmx',
        ServicoNfe.recepcaoEvento: 'https://$host/ws/recepcaoevento/recepcaoevento4.asmx',
      };

  static _Urls _svan(String host) => {
        ServicoNfe.statusServico: 'https://$host/NFeStatusServico4/NFeStatusServico4.asmx',
        ServicoNfe.autorizacao: 'https://$host/NFeAutorizacao4/NFeAutorizacao4.asmx',
        ServicoNfe.retAutorizacao: 'https://$host/NFeRetAutorizacao4/NFeRetAutorizacao4.asmx',
        ServicoNfe.consultaProtocolo: 'https://$host/NFeConsultaProtocolo4/NFeConsultaProtocolo4.asmx',
        ServicoNfe.recepcaoEvento: 'https://$host/NFeRecepcaoEvento4/NFeRecepcaoEvento4.asmx',
      };

  static final Map<ModeloDocumento, Map<Ambiente, _Urls>> _svrsTabela = {
    ModeloDocumento.nfe: {
      Ambiente.homologacao: _svrs('nfe-homologacao.svrs.rs.gov.br'),
      Ambiente.producao: _svrs('nfe.svrs.rs.gov.br'),
    },
    ModeloDocumento.nfce: {
      Ambiente.homologacao: _svrs('nfce-homologacao.svrs.rs.gov.br'),
      Ambiente.producao: _svrs('nfce.svrs.rs.gov.br'),
    },
  };

  static final Map<Ambiente, _Urls> _svcAn = {
    Ambiente.homologacao: _svan('hom.sefazvirtual.fazenda.gov.br'),
    Ambiente.producao: _svan('www.sefazvirtual.fazenda.gov.br'),
  };

  /// Autorizadores próprios.
  static final Map<Uf, Map<ModeloDocumento, Map<Ambiente, _Urls>>> _proprios = {
    Uf.sp: {
      ModeloDocumento.nfe: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://homologacao.nfe.fazenda.sp.gov.br/ws/nfestatusservico4.asmx',
          ServicoNfe.autorizacao: 'https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeautorizacao4.asmx',
          ServicoNfe.retAutorizacao: 'https://homologacao.nfe.fazenda.sp.gov.br/ws/nferetautorizacao4.asmx',
          ServicoNfe.consultaProtocolo: 'https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeconsultaprotocolo4.asmx',
          ServicoNfe.inutilizacao: 'https://homologacao.nfe.fazenda.sp.gov.br/ws/nfeinutilizacao4.asmx',
          ServicoNfe.recepcaoEvento: 'https://homologacao.nfe.fazenda.sp.gov.br/ws/nferecepcaoevento4.asmx',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfe.fazenda.sp.gov.br/ws/nfestatusservico4.asmx',
          ServicoNfe.autorizacao: 'https://nfe.fazenda.sp.gov.br/ws/nfeautorizacao4.asmx',
          ServicoNfe.retAutorizacao: 'https://nfe.fazenda.sp.gov.br/ws/nferetautorizacao4.asmx',
          ServicoNfe.consultaProtocolo: 'https://nfe.fazenda.sp.gov.br/ws/nfeconsultaprotocolo4.asmx',
          ServicoNfe.inutilizacao: 'https://nfe.fazenda.sp.gov.br/ws/nfeinutilizacao4.asmx',
          ServicoNfe.recepcaoEvento: 'https://nfe.fazenda.sp.gov.br/ws/nferecepcaoevento4.asmx',
        },
      },
      ModeloDocumento.nfce: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeStatusServico4.asmx',
          ServicoNfe.autorizacao: 'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeAutorizacao4.asmx',
          ServicoNfe.retAutorizacao: 'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeRetAutorizacao4.asmx',
          ServicoNfe.consultaProtocolo: 'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeConsultaProtocolo4.asmx',
          ServicoNfe.inutilizacao: 'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeInutilizacao4.asmx',
          ServicoNfe.recepcaoEvento: 'https://homologacao.nfce.fazenda.sp.gov.br/ws/NFeRecepcaoEvento4.asmx',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfce.fazenda.sp.gov.br/ws/NFeStatusServico4.asmx',
          ServicoNfe.autorizacao: 'https://nfce.fazenda.sp.gov.br/ws/NFeAutorizacao4.asmx',
          ServicoNfe.retAutorizacao: 'https://nfce.fazenda.sp.gov.br/ws/NFeRetAutorizacao4.asmx',
          ServicoNfe.consultaProtocolo: 'https://nfce.fazenda.sp.gov.br/ws/NFeConsultaProtocolo4.asmx',
          ServicoNfe.inutilizacao: 'https://nfce.fazenda.sp.gov.br/ws/NFeInutilizacao4.asmx',
          ServicoNfe.recepcaoEvento: 'https://nfce.fazenda.sp.gov.br/ws/NFeRecepcaoEvento4.asmx',
        },
      },
    },
    Uf.rs: {
      ModeloDocumento.nfe: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://nfe-homologacao.sefazrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico4.asmx',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfe.sefazrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico4.asmx',
        },
      },
      ModeloDocumento.nfce: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://nfce-homologacao.sefazrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico4.asmx',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfce.sefazrs.rs.gov.br/ws/NfeStatusServico/NfeStatusServico4.asmx',
        },
      },
    },
    Uf.pr: {
      ModeloDocumento.nfe: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://homologacao.nfe.sefa.pr.gov.br/nfe/NFeStatusServico4?wsdl',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfe.sefa.pr.gov.br/nfe/NFeStatusServico4?wsdl',
        },
      },
      ModeloDocumento.nfce: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://homologacao.nfce.sefa.pr.gov.br/nfce/NFeStatusServico4',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfce.sefa.pr.gov.br/nfce/NFeStatusServico4',
        },
      },
    },
    Uf.mg: {
      ModeloDocumento.nfe: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NFeStatusServico4',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfe.fazenda.mg.gov.br/nfe2/services/NFeStatusServico4',
        },
      },
      ModeloDocumento.nfce: {
        Ambiente.homologacao: {
          ServicoNfe.statusServico: 'https://hnfce.fazenda.mg.gov.br/nfce/services/NFeStatusServico4',
        },
        Ambiente.producao: {
          ServicoNfe.statusServico: 'https://nfce.fazenda.mg.gov.br/nfce/services/NFeStatusServico4',
        },
      },
    },
  };

  /// UFs que usam SVRS para NF-e e NFC-e.
  static const _svrsUfs = {
    Uf.ac, Uf.al, Uf.ap, Uf.df, Uf.es, Uf.pa, Uf.pb, Uf.pi, Uf.rj, Uf.rn,
    Uf.ro, Uf.rr, Uf.sc, Uf.se, Uf.to,
  };

  /// UFs que usam SVC-RS (as demais usam SVC-AN) para contingência da NF-e.
  static const _svcRsUfs = {
    Uf.am, Uf.ba, Uf.ce, Uf.go, Uf.ma, Uf.ms, Uf.mt, Uf.pa, Uf.pe, Uf.pr,
  };

  /// Contingência SVC indicada para a UF (NF-e).
  static TipoEmissao contingenciaSvc(Uf uf) =>
      _svcRsUfs.contains(uf) ? TipoEmissao.svcRs : TipoEmissao.svcAn;

  static String url(
    ServicoNfe servico,
    Uf uf,
    ModeloDocumento modelo,
    Ambiente ambiente, {
    TipoEmissao tipoEmissao = TipoEmissao.normal,
  }) {
    String? r;
    switch (tipoEmissao) {
      case TipoEmissao.svcAn:
        r = _svcAn[ambiente]![servico];
      case TipoEmissao.svcRs:
        r = _svrsTabela[ModeloDocumento.nfe]![ambiente]![servico];
      case TipoEmissao.normal:
      case TipoEmissao.offlineNfce:
        r = _proprios[uf]?[modelo]?[ambiente]?[servico];
        // BA, MA e PE usam SVRS somente para NFC-e.
        final svrsNfce = modelo == ModeloDocumento.nfce && {Uf.ba, Uf.ma, Uf.pe}.contains(uf);
        if (r == null && (_svrsUfs.contains(uf) || svrsNfce)) {
          r = _svrsTabela[modelo]![ambiente]![servico];
        }
    }
    if (r == null) {
      throw UnsupportedError('URL de ${servico.name} para ${uf.sigla}/${modelo.name}/'
          '${tipoEmissao.name} ainda não mapeada (Fase 2).');
    }
    return r;
  }

  /// Mantido por compatibilidade com a Fase 0.
  static String urlStatus(Uf uf, ModeloDocumento modelo, Ambiente ambiente) =>
      url(ServicoNfe.statusServico, uf, modelo, ambiente);
}
