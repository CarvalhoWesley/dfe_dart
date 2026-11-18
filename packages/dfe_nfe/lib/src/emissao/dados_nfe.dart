import '../enums.dart';
import '../tributacao/imposto.dart';
import 'grupos_nfe.dart';

export '../tributacao/imposto.dart';
export 'grupos_nfe.dart';

/// Modelo de dados da NF-e/NFC-e para emissão.
///
/// **Anêmico, como o Zeus:** todos os valores (tributos e totais) são
/// informados pelo app; a montagem só serializa. Para calcular tributos,
/// totais, rateios e troco, use o pacote opcional `dfe_calculos`.

class Endereco {
  const Endereco({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.codigoMunicipio,
    required this.municipio,
    required this.uf,
    required this.cep,
    this.complemento,
    this.fone,
  });

  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final int codigoMunicipio;
  final String municipio;
  final Uf uf;
  final String cep;
  final String? fone;
}

class Emitente {
  const Emitente({
    required this.cnpj,
    required this.razaoSocial,
    required this.inscricaoEstadual,
    required this.endereco,
    this.nomeFantasia,
    this.crt = 1,
  });

  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String inscricaoEstadual;
  final Endereco endereco;

  /// 1 = Simples Nacional, 2 = SN excesso de sublimite, 3 = Normal, 4 = MEI.
  /// Define o grupo de ICMS (CST × CSOSN).
  final int crt;
}

class Destinatario {
  const Destinatario({
    required this.nome,
    this.cpf,
    this.cnpj,
    this.idEstrangeiro,
    this.endereco,
    this.email,
    this.indIEDest = 9,
    this.ie,
    this.inscricaoSuframa,
    this.inscricaoMunicipal,
  });

  final String? cpf;
  final String? cnpj;

  /// Documento de estrangeiro (idEstrangeiro).
  final String? idEstrangeiro;
  final String nome;
  final Endereco? endereco;
  final String? email;

  /// 1 contribuinte, 2 isento, 9 não contribuinte.
  final int indIEDest;

  /// IE do destinatário (com indIEDest = 1).
  final String? ie;

  /// ISUF.
  final String? inscricaoSuframa;

  /// IM.
  final String? inscricaoMunicipal;

  Destinatario copiarCom({String? nome}) => Destinatario(
        nome: nome ?? this.nome,
        cpf: cpf,
        cnpj: cnpj,
        idEstrangeiro: idEstrangeiro,
        endereco: endereco,
        email: email,
        indIEDest: indIEDest,
        ie: ie,
        inscricaoSuframa: inscricaoSuframa,
        inscricaoMunicipal: inscricaoMunicipal,
      );
}

/// Item da nota (grupos `prod` e `imposto`), com valores informados pelo app.
class ItemNfe {
  const ItemNfe({
    required this.codigo,
    required this.descricao,
    required this.ncm,
    required this.cfop,
    required this.unidade,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
    required this.imposto,
    this.gtin = 'SEM GTIN',
    this.cest,
    this.codigoBeneficio,
    this.unidadeTributavel,
    this.quantidadeTributavel,
    this.valorUnitarioTributavel,
    this.gtinTributavel,
    this.desconto = 0,
    this.frete = 0,
    this.seguro = 0,
    this.outrasDespesas = 0,
    this.compoeTotal = true,
  });

  final String codigo;
  final String gtin;
  final String descricao;
  final String ncm;
  final String cfop;
  final String unidade;
  final double quantidade;
  final double valorUnitario;

  /// vProd (informado pelo app).
  final double valorTotal;

  /// CEST (obrigatório para mercadorias sujeitas a ST).
  final String? cest;

  /// Código de benefício fiscal (cBenef).
  final String? codigoBeneficio;

  /// Unidade/quantidade/valor tributáveis; se nulos, iguais aos comerciais.
  final String? unidadeTributavel;
  final double? quantidadeTributavel;
  final double? valorUnitarioTributavel;
  final String? gtinTributavel;

  final double desconto;
  final double frete;
  final double seguro;
  final double outrasDespesas;

  /// indTot: o valor do item compõe o total da nota.
  final bool compoeTotal;

  final ImpostoItem imposto;

  ItemNfe copiarCom({String? descricao, ImpostoItem? imposto}) => ItemNfe(
        codigo: codigo,
        descricao: descricao ?? this.descricao,
        ncm: ncm,
        cfop: cfop,
        unidade: unidade,
        quantidade: quantidade,
        valorUnitario: valorUnitario,
        valorTotal: valorTotal,
        imposto: imposto ?? this.imposto,
        gtin: gtin,
        cest: cest,
        codigoBeneficio: codigoBeneficio,
        unidadeTributavel: unidadeTributavel,
        quantidadeTributavel: quantidadeTributavel,
        valorUnitarioTributavel: valorUnitarioTributavel,
        gtinTributavel: gtinTributavel,
        desconto: desconto,
        frete: frete,
        seguro: seguro,
        outrasDespesas: outrasDespesas,
        compoeTotal: compoeTotal,
      );
}

/// Dados de cartão (grupo `card`).
class Cartao {
  const Cartao({this.integrado = false, this.cnpjCredenciadora, this.bandeira, this.autorizacao});

  /// tpIntegra: 1 integrado ao sistema (TEF), 2 não integrado (POS).
  final bool integrado;
  final String? cnpjCredenciadora;

  /// tBand: 01 Visa, 02 Mastercard, 03 Amex, 04 Sorocred, 05 Diners, 06 Elo,
  /// 07 Hipercard, 08 Aura, 09 Cabal, 99 outros.
  final String? bandeira;

  /// Número de autorização (cAut).
  final String? autorizacao;
}

class Pagamento {
  const Pagamento({required this.tipo, required this.valor, this.cartao, this.descricao, this.aPrazo = false});

  /// tPag: 01 dinheiro, 03 crédito, 04 débito, 15 boleto, 17 PIX, 90 sem pagamento, 99 outros...
  final String tipo;
  final double valor;

  /// Grupo `card` (o app informa; a SEFAZ exige para 03/04/17).
  final Cartao? cartao;

  /// xPag — obrigatório quando tPag = 99.
  final String? descricao;

  /// indPag: false = à vista (0), true = a prazo (1).
  final bool aPrazo;
}

/// Responsável técnico (infRespTec) — exigido por algumas UFs.
class ResponsavelTecnico {
  const ResponsavelTecnico({
    required this.cnpj,
    required this.contato,
    required this.email,
    required this.fone,
    this.idCsrt,
    this.csrt,
  });

  final String cnpj;
  final String contato;
  final String email;
  final String fone;

  /// Identificador do CSRT (idCSRT), fornecido pela SEFAZ.
  final int? idCsrt;

  /// CSRT (código de segurança). Com [idCsrt], a montagem inclui o `hashCSRT`
  /// calculado sobre a chave de acesso.
  final String? csrt;
}

class DadosNfe {
  DadosNfe({
    required this.modelo,
    required this.ambiente,
    required this.serie,
    required this.numero,
    required this.emitente,
    required this.itens,
    required this.total,
    required this.pagamentos,
    this.troco,
    this.destinatario,
    this.naturezaOperacao = 'VENDA',
    this.tipoEmissao = TipoEmissao.normal,
    this.justificativaContingencia,
    DateTime? dataEmissao,
    this.dataContingencia,
    this.informacoesComplementares,
    this.responsavelTecnico,
    this.codigoNumerico,
    this.versaoAplicativo = 'dfe_dart 0.1',
    this.modalidadeFrete = 9,
    this.indicadorPresenca = 1,
    this.consumidorFinal = true,
    this.destinoOperacao = 1,
    this.finalidade = 1,
    this.tipoOperacao = 1,
    this.dataSaidaEntrada,
    this.indicadorIntermediador,
    this.referencias = const [],
    this.retirada,
    this.entrega,
    this.autorizadosXml = const [],
    this.intermediador,
    this.cobranca,
    this.transporte,
  }) : dataEmissao = dataEmissao ?? DateTime.now();

  final ModeloDocumento modelo;
  final Ambiente ambiente;
  final int serie;
  final int numero;
  final Emitente emitente;
  final Destinatario? destinatario;
  final List<ItemNfe> itens;

  /// Totais da nota (informados pelo app; `dfe_calculos` pode calculá-los).
  final TotalNfe total;
  final List<Pagamento> pagamentos;

  /// vTroco (informado pelo app).
  final double? troco;
  final String naturezaOperacao;
  final TipoEmissao tipoEmissao;

  /// xJust — obrigatório em contingência.
  final String? justificativaContingencia;
  final DateTime dataEmissao;

  /// dhCont — obrigatório em contingência; se nulo, usa [dataEmissao].
  final DateTime? dataContingencia;
  final String? informacoesComplementares;
  final ResponsavelTecnico? responsavelTecnico;

  /// cNF; se nulo, é sorteado.
  final int? codigoNumerico;
  final String versaoAplicativo;

  /// modFrete: 0 emitente, 1 destinatário, 2 terceiros, 3 próprio emitente, 4 próprio destinatário, 9 sem frete.
  final int modalidadeFrete;

  /// indPres: 1 presencial, 2 internet, 3 teleatendimento, 4 entrega a domicílio, 5 presencial fora, 9 outros.
  final int indicadorPresenca;

  /// indFinal.
  final bool consumidorFinal;

  /// idDest: 1 interna, 2 interestadual, 3 exterior.
  final int destinoOperacao;

  /// finNFe: 1 normal, 2 complementar, 3 ajuste, 4 devolução.
  final int finalidade;

  /// tpNF: 0 entrada, 1 saída.
  final int tipoOperacao;

  /// dhSaiEnt (NF-e).
  final DateTime? dataSaidaEntrada;

  /// indIntermed: 0 sem intermediador, 1 em site/plataforma de terceiros.
  final int? indicadorIntermediador;

  /// Documentos referenciados (NFref).
  final List<ReferenciaNfe> referencias;
  final LocalNfe? retirada;
  final LocalNfe? entrega;

  /// CNPJ (14) ou CPF (11) autorizados a baixar o XML (autXML).
  final List<String> autorizadosXml;
  final Intermediador? intermediador;
  final Cobranca? cobranca;

  /// Transporte completo; se nulo, usa só [modalidadeFrete].
  final Transporte? transporte;

  DadosNfe copiarCom({
    List<ItemNfe>? itens,
    Destinatario? destinatario,
    TotalNfe? total,
    List<Pagamento>? pagamentos,
    double? troco,
  }) =>
      DadosNfe(
        modelo: modelo,
        ambiente: ambiente,
        serie: serie,
        numero: numero,
        emitente: emitente,
        itens: itens ?? this.itens,
        total: total ?? this.total,
        pagamentos: pagamentos ?? this.pagamentos,
        troco: troco ?? this.troco,
        destinatario: destinatario ?? this.destinatario,
        naturezaOperacao: naturezaOperacao,
        tipoEmissao: tipoEmissao,
        justificativaContingencia: justificativaContingencia,
        dataEmissao: dataEmissao,
        dataContingencia: dataContingencia,
        informacoesComplementares: informacoesComplementares,
        responsavelTecnico: responsavelTecnico,
        codigoNumerico: codigoNumerico,
        versaoAplicativo: versaoAplicativo,
        modalidadeFrete: modalidadeFrete,
        indicadorPresenca: indicadorPresenca,
        consumidorFinal: consumidorFinal,
        destinoOperacao: destinoOperacao,
        finalidade: finalidade,
        tipoOperacao: tipoOperacao,
        dataSaidaEntrada: dataSaidaEntrada,
        indicadorIntermediador: indicadorIntermediador,
        referencias: referencias,
        retirada: retirada,
        entrega: entrega,
        autorizadosXml: autorizadosXml,
        intermediador: intermediador,
        cobranca: cobranca,
        transporte: transporte,
      );
}
