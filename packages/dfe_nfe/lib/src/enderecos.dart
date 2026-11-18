import 'enderecos_tabela.g.dart';
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

/// URLs dos webservices por UF, modelo, ambiente e forma de emissão.
///
/// A tabela (`enderecos_tabela.g.dart`) é gerada a partir do ZeusFiscal por
/// `tools/exportar_urls` — para atualizar, rode a ferramenta em vez de editar.
class Enderecador {
  /// UFs que usam SVC-RS para contingência da NF-e (as demais usam SVC-AN).
  static const _svcRsUfs = {
    Uf.am, Uf.ba, Uf.ce, Uf.go, Uf.ma, Uf.ms, Uf.mt, Uf.pa, Uf.pe, Uf.pr,
  };

  /// Contingência SVC indicada para a UF (NF-e).
  static TipoEmissao contingenciaSvc(Uf uf) =>
      _svcRsUfs.contains(uf) ? TipoEmissao.svcRs : TipoEmissao.svcAn;

  /// URL do [servico]. Só SVC-AN/SVC-RS usam outros servidores; as demais
  /// formas de contingência (offline, EPEC, FS-IA, FS-DA) usam as URLs normais.
  static String url(
    ServicoNfe servico,
    Uf uf,
    ModeloDocumento modelo,
    Ambiente ambiente, {
    TipoEmissao tipoEmissao = TipoEmissao.normal,
  }) {
    final tp = tipoEmissao.usaSvc ? tipoEmissao : TipoEmissao.normal;
    final r = tabelaUrlsServicos['${uf.sigla}|${modelo.name}|${ambiente.name}|${tp.name}|${servico.name}'];
    if (r == null) {
      throw UnsupportedError('Sem URL de ${servico.name} para ${uf.sigla}/${modelo.name}/'
          '${ambiente.name}/${tp.name} na tabela do Zeus.');
    }
    return r;
  }

  static String urlStatus(Uf uf, ModeloDocumento modelo, Ambiente ambiente) =>
      url(ServicoNfe.statusServico, uf, modelo, ambiente);
}
