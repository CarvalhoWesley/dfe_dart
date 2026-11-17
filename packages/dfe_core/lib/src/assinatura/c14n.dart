import 'package:xml/xml.dart';

const nsXmlDsig = 'http://www.w3.org/2000/09/xmldsig#';
const _nsXml = 'http://www.w3.org/XML/1998/namespace';

/// Canonical XML 1.0 inclusiva, sem comentários
/// (`http://www.w3.org/TR/2001/REC-xml-c14n-20010315`), aplicada à subárvore
/// de [elemento] — equivalente ao XmlDsigC14NTransform do .NET.
///
/// Se [removerAssinaturas] for verdadeiro, aplica também o transform
/// enveloped-signature (descarta elementos `ds:Signature` descendentes).
String canonicalizar(XmlElement elemento, {bool removerAssinaturas = false}) {
  final sb = StringBuffer();
  final escopoPai = _escopoNamespaces(elemento.parentElement);
  // No ápice, nada foi renderizado ainda: o default "vazio" é o ponto de partida.
  _renderizar(elemento, sb, const {'': ''}, escopoPai, removerAssinaturas,
      apice: true);
  return sb.toString();
}

/// Namespaces em escopo (prefixo -> URI) declarados em [e] e seus ancestrais.
Map<String, String> _escopoNamespaces(XmlElement? e) {
  final cadeia = <XmlElement>[];
  for (var atual = e; atual != null; atual = atual.parentElement) {
    cadeia.add(atual);
  }
  final r = <String, String>{};
  for (final el in cadeia.reversed) {
    _aplicarDeclaracoes(el, r);
  }
  return r;
}

void _aplicarDeclaracoes(XmlElement el, Map<String, String> escopo) {
  for (final a in el.attributes) {
    final n = a.name;
    if (n.prefix == null && n.local == 'xmlns') {
      escopo[''] = a.value;
    } else if (n.prefix == 'xmlns') {
      escopo[n.local] = a.value;
    }
  }
}

bool _ehDeclaracaoNs(XmlAttribute a) =>
    (a.name.prefix == null && a.name.local == 'xmlns') ||
    a.name.prefix == 'xmlns';

void _renderizar(
  XmlElement el,
  StringBuffer sb,
  Map<String, String> renderizadosPai,
  Map<String, String> escopoPai,
  bool removerAssinaturas, {
  bool apice = false,
}) {
  final escopo = Map<String, String>.of(escopoPai);
  _aplicarDeclaracoes(el, escopo);

  // Namespaces a emitir: os em escopo que diferem do que o ancestral de saída emitiu.
  final nsEmitir = <String, String>{};
  for (final MapEntry(key: prefixo, value: uri) in escopo.entries) {
    if (prefixo == 'xml') continue;
    final anterior = renderizadosPai[prefixo];
    if (prefixo.isEmpty) {
      if ((anterior ?? '') != uri) nsEmitir[prefixo] = uri;
    } else if (anterior != uri) {
      nsEmitir[prefixo] = uri;
    }
  }

  final renderizados = Map<String, String>.of(renderizadosPai)..addAll(nsEmitir);

  // Atributos comuns (+ xml:* herdados quando ápice).
  final atributos = <_Atributo>[];
  final locaisXml = <String>{};
  for (final a in el.attributes) {
    if (_ehDeclaracaoNs(a)) continue;
    final prefixo = a.name.prefix;
    final uri = prefixo == null
        ? ''
        : prefixo == 'xml'
            ? _nsXml
            : (escopo[prefixo] ?? '');
    if (prefixo == 'xml') locaisXml.add(a.name.local);
    atributos.add(_Atributo(a.name.qualified, a.name.local, uri, a.value));
  }
  if (apice) {
    for (var anc = el.parentElement; anc != null; anc = anc.parentElement) {
      for (final a in anc.attributes) {
        if (a.name.prefix == 'xml' && locaisXml.add(a.name.local)) {
          atributos.add(_Atributo(a.name.qualified, a.name.local, _nsXml, a.value));
        }
      }
    }
  }
  atributos.sort((x, y) {
    final c = x.uri.compareTo(y.uri);
    return c != 0 ? c : x.local.compareTo(y.local);
  });

  final prefixosOrdenados = nsEmitir.keys.toList()..sort();

  sb.write('<${el.name.qualified}');
  for (final p in prefixosOrdenados) {
    sb
      ..write(p.isEmpty ? ' xmlns="' : ' xmlns:$p="')
      ..write(_escaparAtributo(nsEmitir[p]!))
      ..write('"');
  }
  for (final a in atributos) {
    sb.write(' ${a.qualificado}="${_escaparAtributo(a.valor)}"');
  }
  sb.write('>');

  for (final filho in el.children) {
    switch (filho) {
      case XmlElement():
        if (removerAssinaturas && _ehAssinatura(filho, escopo)) continue;
        _renderizar(filho, sb, renderizados, escopo, removerAssinaturas);
      case XmlCDATA():
        sb.write(_escaparTexto(filho.value));
      case XmlText():
        sb.write(_escaparTexto(filho.value));
      case XmlProcessing():
        sb.write('<?${filho.target}${filho.value.isEmpty ? '' : ' ${filho.value}'}?>');
      default:
        break; // comentários e demais nós são descartados
    }
  }

  sb.write('</${el.name.qualified}>');
}

bool _ehAssinatura(XmlElement el, Map<String, String> escopoPai) {
  if (el.name.local != 'Signature') return false;
  final escopo = Map<String, String>.of(escopoPai);
  _aplicarDeclaracoes(el, escopo);
  return escopo[el.name.prefix ?? ''] == nsXmlDsig;
}

class _Atributo {
  _Atributo(this.qualificado, this.local, this.uri, this.valor);
  final String qualificado;
  final String local;
  final String uri;
  final String valor;
}

String _escaparTexto(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x26:
        sb.write('&amp;');
      case 0x3C:
        sb.write('&lt;');
      case 0x3E:
        sb.write('&gt;');
      case 0x0D:
        sb.write('&#xD;');
      default:
        sb.writeCharCode(r);
    }
  }
  return sb.toString();
}

String _escaparAtributo(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x26:
        sb.write('&amp;');
      case 0x3C:
        sb.write('&lt;');
      case 0x22:
        sb.write('&quot;');
      case 0x09:
        sb.write('&#x9;');
      case 0x0A:
        sb.write('&#xA;');
      case 0x0D:
        sb.write('&#xD;');
      default:
        sb.writeCharCode(r);
    }
  }
  return sb.toString();
}
