import 'package:xml/xml.dart';

/// Dados da NF-e (modelo 55) necessários ao DANFE, lidos do `nfeProc`
/// (ou do `<NFe>` assinado ainda sem protocolo).
class DadosDanfeNfe {
  DadosDanfeNfe._(this._inf, this._prot);

  factory DadosDanfeNfe.deXml(String xml) {
    final doc = XmlDocument.parse(xml);
    final inf = doc.findAllElements('infNFe').firstOrNull ??
        (throw ArgumentError('XML sem infNFe'));
    final mod = inf.getElement('ide')?.getElement('mod')?.innerText;
    if (mod != '55') throw ArgumentError('DANFE NF-e exige modelo 55 (recebido: $mod)');
    return DadosDanfeNfe._(inf, doc.findAllElements('infProt').firstOrNull);
  }

  final XmlElement _inf;
  final XmlElement? _prot;

  XmlElement? _el(String caminho) {
    XmlElement? e = _inf;
    for (final p in caminho.split('/')) {
      e = e?.getElement(p);
    }
    return e;
  }

  String _t(String caminho) => _el(caminho)?.innerText ?? '';
  double _d(String caminho) => double.tryParse(_t(caminho)) ?? 0;

  // --- Identificação -----------------------------------------------------------

  String get chave => (_inf.getAttribute('Id') ?? '').replaceFirst('NFe', '');
  String get naturezaOperacao => _t('ide/natOp');
  int get numero => int.tryParse(_t('ide/nNF')) ?? 0;
  int get serie => int.tryParse(_t('ide/serie')) ?? 0;

  /// 0 = entrada, 1 = saída.
  String get tipoOperacao => _t('ide/tpNF');
  DateTime get dataEmissao => _horaLocal(_t('ide/dhEmi'));
  DateTime? get dataSaida => _t('ide/dhSaiEnt').isEmpty ? null : _horaLocal(_t('ide/dhSaiEnt'));
  bool get homologacao => _t('ide/tpAmb') == '2';
  int get tipoEmissao => int.tryParse(_t('ide/tpEmis')) ?? 1;
  bool get contingencia => tipoEmissao != 1;
  String get justificativaContingencia => _t('ide/xJust');

  // --- Protocolo -----------------------------------------------------------------

  String? get protocolo {
    final cStat = _prot?.getElement('cStat')?.innerText;
    if (cStat != '100' && cStat != '150') return null;
    return _prot!.getElement('nProt')?.innerText;
  }

  DateTime? get dataAutorizacao {
    final s = _prot?.getElement('dhRecbto')?.innerText;
    return s == null || s.isEmpty ? null : _horaLocal(s);
  }

  // --- Emitente / destinatário ----------------------------------------------------

  ParteDanfe get emitente => ParteDanfe._(_el('emit')!, 'enderEmit');
  ParteDanfe? get destinatario {
    final d = _el('dest');
    return d == null ? null : ParteDanfe._(d, 'enderDest');
  }

  // --- Faturas -----------------------------------------------------------------

  List<DuplicataDanfe> get duplicatas => (_el('cobr')?.findElements('dup') ?? const <XmlElement>[])
      .map((e) => DuplicataDanfe(
            e.getElement('nDup')?.innerText ?? '',
            e.getElement('dVenc')?.innerText ?? '',
            double.tryParse(e.getElement('vDup')?.innerText ?? '') ?? 0,
          ))
      .toList();

  // --- Totais ------------------------------------------------------------------

  double total(String campo) => _d('total/ICMSTot/$campo');

  // --- Transporte ----------------------------------------------------------------

  String get modalidadeFrete => switch (_t('transp/modFrete')) {
        '0' => '0-Por conta do Rem',
        '1' => '1-Por conta do Dest',
        '2' => '2-Por conta de Terceiros',
        '3' => '3-Próprio Rem',
        '4' => '4-Próprio Dest',
        '9' => '9-Sem Frete',
        final s => s,
      };

  String transporta(String campo) => _t('transp/transporta/$campo');
  String veiculo(String campo) => _t('transp/veicTransp/$campo');
  String volume(String campo) => _t('transp/vol/$campo');

  // --- Itens -----------------------------------------------------------------------

  List<ItemDanfeNfe> get itens => _inf.findElements('det').map(ItemDanfeNfe._).toList();

  // --- Informações adicionais ---------------------------------------------------

  String get informacoesComplementares => _t('infAdic/infCpl');
  String get informacoesFisco => _t('infAdic/infAdFisco');
}

/// Emitente ou destinatário.
class ParteDanfe {
  ParteDanfe._(this._e, this._tagEndereco);
  final XmlElement _e;
  final String _tagEndereco;

  String _t(String n) => _e.getElement(n)?.innerText ?? '';
  String _end(String n) => _e.getElement(_tagEndereco)?.getElement(n)?.innerText ?? '';

  String get nome => _t('xNome');
  String get fantasia => _t('xFant');
  String get documento => _t('CNPJ').isNotEmpty
      ? _t('CNPJ')
      : _t('CPF').isNotEmpty
          ? _t('CPF')
          : _t('idEstrangeiro');
  String get ie => _t('IE');
  String get ieSt => _t('IEST');
  String get logradouro =>
      [_end('xLgr'), _end('nro'), _end('xCpl')].where((s) => s.isNotEmpty).join(', ');
  String get bairro => _end('xBairro');
  String get municipio => _end('xMun');
  String get uf => _end('UF');
  String get cep => _end('CEP');
  String get fone => _end('fone');
}

class DuplicataDanfe {
  const DuplicataDanfe(this.numero, this.vencimento, this.valor);
  final String numero;

  /// AAAA-MM-DD.
  final String vencimento;
  final double valor;
}

class ItemDanfeNfe {
  ItemDanfeNfe._(XmlElement det)
      : _prod = det.getElement('prod')!,
        _icms = det.getElement('imposto')?.getElement('ICMS')?.childElements.firstOrNull,
        _ipi = det.getElement('imposto')?.getElement('IPI')?.getElement('IPITrib');

  final XmlElement _prod;
  final XmlElement? _icms;
  final XmlElement? _ipi;

  String _p(String n) => _prod.getElement(n)?.innerText ?? '';
  double _n(XmlElement? e, String n) => double.tryParse(e?.getElement(n)?.innerText ?? '') ?? 0;

  String get codigo => _p('cProd');
  String get descricao => _p('xProd');
  String get ncm => _p('NCM');
  String get cfop => _p('CFOP');
  String get unidade => _p('uCom');
  double get quantidade => double.tryParse(_p('qCom')) ?? 0;
  double get valorUnitario => double.tryParse(_p('vUnCom')) ?? 0;
  double get valorTotal => double.tryParse(_p('vProd')) ?? 0;

  /// Origem + CST (ou CSOSN), ex.: `000`, `0102`.
  String get cst {
    final e = _icms;
    if (e == null) return '';
    final orig = e.getElement('orig')?.innerText ?? '';
    final cst = e.getElement('CST')?.innerText ?? e.getElement('CSOSN')?.innerText ?? '';
    return '$orig$cst';
  }

  double get baseIcms => _n(_icms, 'vBC');
  double get valorIcms => _n(_icms, 'vICMS');
  double get aliquotaIcms => _n(_icms, 'pICMS');
  double get valorIpi => _n(_ipi, 'vIPI');
  double get aliquotaIpi => _n(_ipi, 'pIPI');
}

DateTime _horaLocal(String s) => DateTime.parse(s.length >= 19 ? s.substring(0, 19) : s);
