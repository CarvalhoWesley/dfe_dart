import 'dart:convert';
import 'dart:io';

/// Configuração do app de testes, gravada em JSON (a senha do certificado
/// NÃO é gravada).
class ConfigApp {
  String pfx = '';
  String uf = 'SP';
  String cnpj = '';
  String razaoSocial = '';
  String nomeFantasia = '';
  String ie = '';
  int crt = 1;
  String logradouro = '';
  String numero = '';
  String bairro = '';
  int codigoMunicipio = 3550308;
  String municipio = 'SAO PAULO';
  String cep = '';
  int serieNfe = 1;
  int proximoNfe = 1;
  int serieNfce = 1;
  int proximoNfce = 1;
  String versaoQr = 'v3';
  String idCsc = '';
  String csc = '';
  String pastaXml = '';
  int idLote = 1;

  // DANFE / impressora (a impressão é responsabilidade do app)
  String impressora = '';
  int colunas = 48;
  bool itemDuasLinhas = false;
  String modoQr = 'nativo'; // nativo | imagem
  String paginaCodigo = 'cp860'; // cp860 | cp850 | semAcento
  String corte = 'parcial'; // total | parcial | nenhum
  bool abrirGaveta = false;

  // Cenário de teste da venda
  String tributacao = 'sn102'; // sn102 | sn101 | normal00 | normal40
  String pagamento = 'dinheiro'; // dinheiro | credito | debito | pix | misto
  double desconto = 0;

  // Reforma tributária (IBS/CBS) — alíquotas de teste de 2026
  bool ibsCbs = false;
  String ibsCbsCst = '000';
  String cClassTrib = '000001';

  // Responsável técnico (infRespTec) — vazio = não envia
  String respTecCnpj = '';
  String respTecContato = '';
  String respTecEmail = '';
  String respTecFone = '';

  static Directory get pastaApp {
    final base = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    return Directory('$base${Platform.pathSeparator}Documents${Platform.pathSeparator}dfe_dart');
  }

  static File get _arquivo => File('${pastaApp.path}${Platform.pathSeparator}config.json');

  static ConfigApp carregar() {
    final c = ConfigApp();
    c.pastaXml = '${pastaApp.path}${Platform.pathSeparator}xml';
    try {
      if (_arquivo.existsSync()) c._deJson(jsonDecode(_arquivo.readAsStringSync()) as Map);
    } catch (_) {/* config inválida: usa padrões */}
    return c;
  }

  void salvar() {
    pastaApp.createSync(recursive: true);
    _arquivo.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_paraJson()));
  }

  Map<String, Object> _paraJson() => {
        'pfx': pfx, 'uf': uf, 'cnpj': cnpj, 'razaoSocial': razaoSocial,
        'nomeFantasia': nomeFantasia, 'ie': ie, 'crt': crt, 'logradouro': logradouro,
        'numero': numero, 'bairro': bairro, 'codigoMunicipio': codigoMunicipio,
        'municipio': municipio, 'cep': cep, 'serieNfe': serieNfe, 'proximoNfe': proximoNfe,
        'serieNfce': serieNfce, 'proximoNfce': proximoNfce, 'versaoQr': versaoQr,
        'idCsc': idCsc, 'csc': csc, 'pastaXml': pastaXml, 'idLote': idLote,
        'impressora': impressora, 'colunas': colunas, 'itemDuasLinhas': itemDuasLinhas,
        'modoQr': modoQr, 'paginaCodigo': paginaCodigo, 'corte': corte, 'abrirGaveta': abrirGaveta,
        'tributacao': tributacao, 'pagamento': pagamento, 'desconto': desconto,
        'ibsCbs': ibsCbs, 'ibsCbsCst': ibsCbsCst, 'cClassTrib': cClassTrib,
        'respTecCnpj': respTecCnpj, 'respTecContato': respTecContato,
        'respTecEmail': respTecEmail, 'respTecFone': respTecFone,
      };

  void _deJson(Map j) {
    T v<T>(String k, T padrao) => j[k] is T ? j[k] as T : padrao;
    pfx = v('pfx', pfx);
    uf = v('uf', uf);
    cnpj = v('cnpj', cnpj);
    razaoSocial = v('razaoSocial', razaoSocial);
    nomeFantasia = v('nomeFantasia', nomeFantasia);
    ie = v('ie', ie);
    crt = v('crt', crt);
    logradouro = v('logradouro', logradouro);
    numero = v('numero', numero);
    bairro = v('bairro', bairro);
    codigoMunicipio = v('codigoMunicipio', codigoMunicipio);
    municipio = v('municipio', municipio);
    cep = v('cep', cep);
    serieNfe = v('serieNfe', serieNfe);
    proximoNfe = v('proximoNfe', proximoNfe);
    serieNfce = v('serieNfce', serieNfce);
    proximoNfce = v('proximoNfce', proximoNfce);
    versaoQr = v('versaoQr', versaoQr);
    idCsc = v('idCsc', idCsc);
    csc = v('csc', csc);
    pastaXml = v('pastaXml', pastaXml);
    idLote = v('idLote', idLote);
    impressora = v('impressora', impressora);
    colunas = v('colunas', colunas);
    itemDuasLinhas = v('itemDuasLinhas', itemDuasLinhas);
    modoQr = v('modoQr', modoQr);
    paginaCodigo = v('paginaCodigo', paginaCodigo);
    corte = v('corte', corte);
    abrirGaveta = v('abrirGaveta', abrirGaveta);
    tributacao = v('tributacao', tributacao);
    pagamento = v('pagamento', pagamento);
    desconto = (j['desconto'] as num?)?.toDouble() ?? desconto;
    ibsCbs = v('ibsCbs', ibsCbs);
    ibsCbsCst = v('ibsCbsCst', ibsCbsCst);
    cClassTrib = v('cClassTrib', cClassTrib);
    respTecCnpj = v('respTecCnpj', respTecCnpj);
    respTecContato = v('respTecContato', respTecContato);
    respTecEmail = v('respTecEmail', respTecEmail);
    respTecFone = v('respTecFone', respTecFone);
  }
}
