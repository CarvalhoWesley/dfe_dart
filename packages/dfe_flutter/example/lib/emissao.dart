import 'dart:io';

import 'package:dfe_core/dfe_core.dart';
import 'package:dfe_flutter/dfe_flutter.dart';
import 'package:dfe_nfe/dfe_nfe.dart';

import 'config.dart';

typedef Log = void Function(String msg);

/// Fluxos de teste em homologação: emissão normal, contingência e gravação dos XMLs.
class EmissaoTeste {
  EmissaoTeste(this.cfg, this.certificado, this.log);

  final ConfigApp cfg;
  final CertificadoDigital certificado;
  final Log log;

  static const _justificativa = 'TESTE DE EMISSAO EM CONTINGENCIA EM AMBIENTE DE HOMOLOGACAO';

  Uf get _uf => Uf.porSigla(cfg.uf);

  ServicosNfe _servicos(ModeloDocumento modelo) => ServicosNfe(
        ConfiguracaoNfe(
          certificado: certificado,
          uf: _uf,
          ambiente: Ambiente.homologacao,
          modelo: modelo,
        ),
        transporte: criarTransporteNativo(ConfiguracaoTransporte(certificado: certificado)),
      );

  EmissorNfe get _emissor => EmissorNfe(
        certificado,
        nfce: ConfiguracaoNfce(
          versaoQrCode: cfg.versaoQr == 'v2' ? VersaoQrCode.v2 : VersaoQrCode.v3,
          idCsc: cfg.idCsc.isEmpty ? null : cfg.idCsc,
          csc: cfg.csc.isEmpty ? null : cfg.csc,
        ),
      );

  Endereco get _endereco => Endereco(
        logradouro: cfg.logradouro,
        numero: cfg.numero,
        bairro: cfg.bairro,
        codigoMunicipio: cfg.codigoMunicipio,
        municipio: cfg.municipio,
        uf: _uf,
        cep: cfg.cep,
      );

  DadosNfe _dados(ModeloDocumento modelo, TipoEmissao tp) {
    final nfe = modelo == ModeloDocumento.nfe;
    return DadosNfe(
      modelo: modelo,
      ambiente: Ambiente.homologacao,
      serie: nfe ? cfg.serieNfe : cfg.serieNfce,
      numero: nfe ? cfg.proximoNfe : cfg.proximoNfce,
      tipoEmissao: tp,
      justificativaContingencia: tp.contingencia ? _justificativa : null,
      emitente: Emitente(
        cnpj: cfg.cnpj,
        razaoSocial: cfg.razaoSocial,
        nomeFantasia: cfg.nomeFantasia,
        inscricaoEstadual: cfg.ie,
        crt: cfg.crt,
        endereco: _endereco,
      ),
      // CPF de teste válido; em homologação o nome é trocado pelo texto padrão.
      destinatario: nfe
          ? Destinatario(nome: 'CONSUMIDOR TESTE', cpf: '11144477735', endereco: _endereco)
          : null,
      itens: const [
        ItemNfe(
          codigo: '0001',
          descricao: 'PRODUTO DE TESTE',
          ncm: '21069090',
          cfop: '5102',
          unidade: 'UN',
          quantidade: 1,
          valorUnitario: 10,
        ),
      ],
      pagamentos: const [Pagamento(tipo: '01', valor: 10)],
      informacoesComplementares: 'Documento emitido pelo app de testes do dfe_dart',
    );
  }

  // --- Arquivos -------------------------------------------------------------

  Directory _pasta(ModeloDocumento m, [String sub = '']) {
    final s = Platform.pathSeparator;
    final d = Directory('${cfg.pastaXml}$s${m == ModeloDocumento.nfe ? 'nfe' : 'nfce'}'
        '${sub.isEmpty ? '' : '$s$sub'}');
    d.createSync(recursive: true);
    return d;
  }

  String _gravar(Directory d, String nome, String xml) {
    final f = File('${d.path}${Platform.pathSeparator}$nome');
    f.writeAsStringSync(xml);
    return f.path;
  }

  // --- Fluxos ---------------------------------------------------------------

  Future<void> status(ModeloDocumento modelo, {TipoEmissao tp = TipoEmissao.normal}) async {
    final s = _servicos(modelo);
    try {
      final r = await s.statusServico(tipoEmissao: tp);
      log('Status ${modelo.name.toUpperCase()} (${tp.name}): cStat ${r.retorno.cStat} - ${r.retorno.xMotivo}');
    } finally {
      s.fechar();
    }
  }

  /// Emite e transmite. [tp] normal ou SVC (NF-e).
  Future<void> emitir(ModeloDocumento modelo, {TipoEmissao tp = TipoEmissao.normal}) async {
    final doc = _emissor.gerar(_dados(modelo, tp));
    final pasta = _pasta(modelo);
    log('${modelo.name.toUpperCase()} nº ${_numero(modelo)} (${tp.name}) gerada: ${doc.chave}');
    _gravar(pasta, '${doc.chave}-nfe.xml', doc.xmlAssinado);
    await _transmitir(modelo, doc.chave.valor, doc.xmlAssinado, tp, pasta);
  }

  /// NFC-e em contingência offline: gera, assina e guarda em `pendentes/`.
  void emitirNfceOffline() {
    const modelo = ModeloDocumento.nfce;
    final doc = _emissor.gerar(_dados(modelo, TipoEmissao.offlineNfce));
    final caminho = _gravar(_pasta(modelo, 'pendentes'), '${doc.chave}-nfe.xml', doc.xmlAssinado);
    log('NFC-e nº ${cfg.proximoNfce} OFFLINE gerada (tpEmis 9): ${doc.chave}');
    log('  QR Code: ${doc.qrCode}');
    log('  Pendente de transmissão: $caminho');
    cfg.proximoNfce++;
    cfg.salvar();
  }

  /// Transmite as NFC-e offline pendentes.
  Future<void> transmitirPendentes() async {
    const modelo = ModeloDocumento.nfce;
    final pendentes = _pasta(modelo, 'pendentes')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('-nfe.xml'))
        .toList();
    if (pendentes.isEmpty) {
      log('Nenhuma NFC-e pendente.');
      return;
    }
    for (final f in pendentes) {
      final nome = f.uri.pathSegments.last;
      final chave = nome.substring(0, 44);
      log('Transmitindo pendente $chave');
      final ok = await _transmitir(modelo, chave, f.readAsStringSync(), TipoEmissao.offlineNfce,
          _pasta(modelo), contarNumero: false);
      if (ok) {
        f.renameSync('${_pasta(modelo).path}${Platform.pathSeparator}$nome');
        log('  Movida para a pasta de autorizadas.');
      }
    }
  }

  int _numero(ModeloDocumento m) => m == ModeloDocumento.nfe ? cfg.proximoNfe : cfg.proximoNfce;

  Future<bool> _transmitir(ModeloDocumento modelo, String chave, String xml, TipoEmissao tp,
      Directory pasta, {bool contarNumero = true}) async {
    final s = _servicos(modelo);
    try {
      final r = await s.autorizar(xml, idLote: cfg.idLote++, tipoEmissao: tp);
      cfg.salvar();
      _gravar(pasta, '$chave-env-lot.xml', r.envioXml);
      _gravar(pasta, '$chave-rec.xml', r.retornoXml);
      if (r.reciboXml != null) _gravar(pasta, '$chave-ped-rec.xml', r.reciboXml!);
      if (r.consultaReciboXml != null) _gravar(pasta, '$chave-pro-rec.xml', r.consultaReciboXml!);

      log('  Lote: cStat ${r.lote.cStat} - ${r.lote.xMotivo}');
      final prot = r.protocolo;
      if (prot == null) return false;
      log('  NF: cStat ${prot.cStat} - ${prot.xMotivo}');

      // Número consumido: autorizada, denegada ou duplicidade (204/539).
      final consumido = prot.autorizado || prot.denegado || const {204, 539}.contains(prot.cStat);
      if (contarNumero && consumido) {
        if (modelo == ModeloDocumento.nfe) {
          cfg.proximoNfe++;
        } else {
          cfg.proximoNfce++;
        }
        cfg.salvar();
      }
      if (prot.autorizado) {
        final proc = _gravar(pasta, '$chave-procNFe.xml', montarNfeProc(xml, prot));
        log('  Protocolo ${prot.nProt}. XML autorizado: $proc');
        return true;
      }
      return false;
    } finally {
      s.fechar();
    }
  }

  // --- Consulta, cancelamento e inutilização ---------------------------------

  /// Última nota autorizada (pelo `-procNFe.xml` mais recente) ainda não cancelada.
  ({String chave, String protocolo})? _ultimaAutorizada(ModeloDocumento modelo,
      {bool ignorarCanceladas = true}) {
    final pasta = _pasta(modelo);
    final procs = pasta
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('-procNFe.xml'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final f in procs) {
      final chave = f.uri.pathSegments.last.substring(0, 44);
      final cancelada = File('${pasta.path}${Platform.pathSeparator}$chave-110111-01-procEventoNFe.xml')
          .existsSync();
      if (ignorarCanceladas && cancelada) continue;
      final prot = RegExp(r'<nProt>(\d+)</nProt>').firstMatch(f.readAsStringSync())?.group(1);
      if (prot != null) return (chave: chave, protocolo: prot);
    }
    return null;
  }

  /// Consulta a situação da [chave] (ou da última autorizada).
  Future<void> consultar(ModeloDocumento modelo, {String? chave}) async {
    final alvo = chave ?? _ultimaAutorizada(modelo, ignorarCanceladas: false)?.chave;
    if (alvo == null) {
      log('Nenhuma ${modelo.name.toUpperCase()} autorizada para consultar.');
      return;
    }
    final s = _servicos(modelo);
    try {
      final r = await s.consultarProtocolo(alvo);
      final pasta = _pasta(modelo);
      _gravar(pasta, '$alvo-ped-sit.xml', r.envioXml);
      _gravar(pasta, '$alvo-sit.xml', r.retornoXml);
      log('Consulta $alvo: cStat ${r.retorno.cStat} - ${r.retorno.xMotivo}');
      if (r.retorno.protocolo != null) log('  Protocolo ${r.retorno.protocolo!.nProt}');
      if (r.retorno.eventos.isNotEmpty) log('  ${r.retorno.eventos.length} evento(s) vinculado(s)');
    } finally {
      s.fechar();
    }
  }

  /// Cancela a última nota autorizada do [modelo].
  Future<void> cancelarUltima(ModeloDocumento modelo) async {
    final alvo = _ultimaAutorizada(modelo);
    if (alvo == null) {
      log('Nenhuma ${modelo.name.toUpperCase()} autorizada e não cancelada.');
      return;
    }
    log('Cancelando ${alvo.chave} (protocolo ${alvo.protocolo})');
    final s = _servicos(modelo);
    try {
      final r = await s.cancelar(
        chave: alvo.chave,
        protocolo: alvo.protocolo,
        justificativa: 'CANCELAMENTO DE TESTE EM AMBIENTE DE HOMOLOGACAO',
        idLote: cfg.idLote++,
      );
      cfg.salvar();
      final pasta = _pasta(modelo);
      _gravar(pasta, '${alvo.chave}-ped-can.xml', r.envioXml);
      _gravar(pasta, '${alvo.chave}-can.xml', r.retornoXml);
      log('  Lote: cStat ${r.lote.cStat} - ${r.lote.xMotivo}');
      final ev = r.retEvento;
      if (ev != null) log('  Evento: cStat ${ev.cStat} - ${ev.xMotivo}');
      if (r.procEventoXml != null) {
        final p = _gravar(pasta, '${alvo.chave}-110111-01-procEventoNFe.xml', r.procEventoXml!);
        log('  Cancelamento registrado (protocolo ${ev!.nProt}): $p');
      }
    } finally {
      s.fechar();
    }
  }

  /// Inutiliza o próximo número do [modelo] e avança a numeração.
  Future<void> inutilizarProximo(ModeloDocumento modelo) async {
    final nfe = modelo == ModeloDocumento.nfe;
    final serie = nfe ? cfg.serieNfe : cfg.serieNfce;
    final numero = nfe ? cfg.proximoNfe : cfg.proximoNfce;
    log('Inutilizando ${modelo.name.toUpperCase()} série $serie nº $numero');
    final s = _servicos(modelo);
    try {
      final r = await s.inutilizar(
        cnpj: cfg.cnpj,
        serie: serie,
        numeroInicial: numero,
        numeroFinal: numero,
        justificativa: 'INUTILIZACAO DE TESTE EM AMBIENTE DE HOMOLOGACAO',
      );
      final pasta = _pasta(modelo, 'inutilizacoes');
      final nome = 'serie$serie-$numero-$numero';
      _gravar(pasta, '$nome-ped-inu.xml', r.envioXml);
      _gravar(pasta, '$nome-inu.xml', r.retornoXml);
      log('  cStat ${r.retorno.cStat} - ${r.retorno.xMotivo}');
      if (r.retorno.servicoDesativado) {
        log('  A SEFAZ desativou a inutilização para esta UF/modelo; o número não foi inutilizado.');
      }
      if (r.procInutXml != null) {
        final p = _gravar(pasta, '$nome-procInutNFe.xml', r.procInutXml!);
        log('  Inutilização homologada (protocolo ${r.retorno.nProt}): $p');
        if (nfe) {
          cfg.proximoNfe++;
        } else {
          cfg.proximoNfce++;
        }
        cfg.salvar();
      }
    } finally {
      s.fechar();
    }
  }
}
