// Extrai, do código-fonte do ZeusFiscal, a especificação dos grupos de
// tributação (ordem dos campos, tipo, casas decimais e obrigatoriedade) e gera
// packages/dfe_nfe/lib/src/tributacao/grupos.g.dart.
//
// Uso: dart run tools/extrair_grupos/extrair.dart <pasta do zeus_fiscal> <saída .dart>
import 'dart:io';

/// Classes (arquivo → grupo XML) cuja especificação é exportada.
const _classes = <String, String>{
  // ICMS
  'Estadual/ICMS00.cs': 'ICMS00', 'Estadual/ICMS02.cs': 'ICMS02', 'Estadual/ICMS10.cs': 'ICMS10',
  'Estadual/ICMS15.cs': 'ICMS15', 'Estadual/ICMS20.cs': 'ICMS20', 'Estadual/ICMS30.cs': 'ICMS30',
  'Estadual/ICMS40.cs': 'ICMS40', 'Estadual/ICMS51.cs': 'ICMS51', 'Estadual/ICMS53.cs': 'ICMS53',
  'Estadual/ICMS60.cs': 'ICMS60', 'Estadual/ICMS61.cs': 'ICMS61', 'Estadual/ICMS70.cs': 'ICMS70',
  'Estadual/ICMS90.cs': 'ICMS90', 'Estadual/ICMSPart.cs': 'ICMSPart', 'Estadual/ICMSST.cs': 'ICMSST',
  'Estadual/ICMSSN101.cs': 'ICMSSN101', 'Estadual/ICMSSN102.cs': 'ICMSSN102',
  'Estadual/ICMSSN201.cs': 'ICMSSN201', 'Estadual/ICMSSN202.cs': 'ICMSSN202',
  'Estadual/ICMSSN500.cs': 'ICMSSN500', 'Estadual/ICMSSN900.cs': 'ICMSSN900',
  'Estadual/ICMSUFDest.cs': 'ICMSUFDest',
  // PIS / COFINS / IPI / II
  'Federal/PISAliq.cs': 'PISAliq', 'Federal/PISQtde.cs': 'PISQtde', 'Federal/PISNT.cs': 'PISNT',
  'Federal/PISOutr.cs': 'PISOutr', 'Federal/PISST.cs': 'PISST',
  'Federal/COFINSAliq.cs': 'COFINSAliq', 'Federal/COFINSQtde.cs': 'COFINSQtde',
  'Federal/COFINSNT.cs': 'COFINSNT', 'Federal/COFINSOutr.cs': 'COFINSOutr', 'Federal/COFINSST.cs': 'COFINSST',
  'Federal/IPITrib.cs': 'IPITrib', 'Federal/IPINT.cs': 'IPINT', 'Federal/II.cs': 'II',
  // ISSQN
  'Municipal/ISSQN.cs': 'ISSQN',
};

class _Campo {
  _Campo(this.nome, this.ordem, this.tipo, this.casas, this.opcional, {this.tipoCs = '', this.atributo = false});
  final bool atributo;
  final String nome;
  final int ordem;
  String tipo; // dec | int | str | grp
  final int? casas;
  bool opcional;
  final String tipoCs;
  String? classe;
  bool lista = false;
}

/// Raízes dos grupos aninhados (reforma tributária e afins), exportados com
/// todos os subgrupos referenciados.
const _raizesAninhadas = [
  'IBSCBS', 'IS', 'IBSCBSTot', 'ISTot', 'gCompraGov', // reforma tributária
  'exporta', 'compra', 'cana', 'agropecuario', 'retTransp', 'reboque', 'lacres', // NF-e
];

/// Lê todas as classes públicas dos arquivos .cs de [pastas].
Map<String, List<_Campo>> _todasClasses(List<String> pastas) {
  final r = <String, List<_Campo>>{};
  for (final p in pastas) {
    final dir = Directory(p);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.cs'))) {
      final src = f.readAsStringSync();
      final ms = RegExp(r'public\s+(?:partial\s+)?class\s+(\w+)').allMatches(src).toList();
      for (var i = 0; i < ms.length; i++) {
        final corpo = src.substring(ms[i].end, i + 1 < ms.length ? ms[i + 1].start : src.length);
        r.putIfAbsent(ms[i].group(1)!, () => _extrair(corpo, ms[i].group(1)!));
      }
    }
  }
  // Resolve tipos que são classes (subgrupos) e listas.
  for (final campos in r.values) {
    for (final c in campos) {
      var t = c.tipoCs.replaceAll('?', '');
      final lista = RegExp(r'^List<(\w+)>$').firstMatch(t);
      if (lista != null) t = lista.group(1)!;
      if (r.containsKey(t)) {
        c
          ..tipo = 'grp'
          ..classe = t
          ..lista = lista != null
          ..opcional = true;
      }
    }
  }
  return r;
}

/// Nome da classe no Dart: `gIBSUF` → `GIBSUF`.
String _classeDart(String zeus) => zeus[0].toUpperCase() + zeus.substring(1);

void main(List<String> args) {
  final zeus = args[0];
  final saida = args[1];
  final base = '$zeus/NFe.Classes/Informacoes/Detalhe/Tributacao';
  final b = StringBuffer()
    ..writeln('// GERADO por tools/extrair_grupos a partir do ZeusFiscal. NÃO EDITE À MÃO.')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln("import 'grupo.dart';")
    ..writeln()
    ..writeln('/// Especificação dos grupos de tributação (ordem dos campos, tipo, casas')
    ..writeln('/// decimais e obrigatoriedade), extraída das classes do Zeus.')
    ..writeln('const especificacaoGrupos = <String, List<CampoGrupo>>{');

  final todos = <String, List<_Campo>>{};
  for (final MapEntry(key: arquivo, value: grupo) in _classes.entries) {
    final f = File('$base/$arquivo');
    if (!f.existsSync()) {
      stderr.writeln('ausente: $arquivo');
      continue;
    }
    todos[grupo] = _extrair(f.readAsStringSync(), grupo);
  }
  // Totais da nota.
  final baseTotal = '$zeus/NFe.Classes/Informacoes/Total';
  for (final MapEntry(key: arquivo, value: grupo)
      in const {'ICMSTot.cs': 'ICMSTot', 'ISSQNtot.cs': 'ISSQNtot', 'retTrib.cs': 'retTrib'}.entries) {
    todos[grupo] = _extrair(File('$baseTotal/$arquivo').readAsStringSync(), grupo);
  }
  // Grupo IPI (envolve IPITrib/IPINT): definido conforme IPI.cs do Zeus.
  todos['IPI'] = [
    _Campo('clEnq', 1, 'str', null, true),
    _Campo('CNPJProd', 2, 'str', null, true),
    _Campo('cSelo', 3, 'str', null, true),
    _Campo('qSelo', 4, 'int', null, true),
    _Campo('cEnq', 5, 'str', null, false),
  ];

  final inf = '$zeus/NFe.Classes/Informacoes';
  final todasZeus = _todasClasses(
      [base, baseTotal, '$inf/Identificacao', inf, '$inf/Cana', '$inf/Agropecuario', '$inf/Transporte']);
  final aninhadas = <String>[];
  void visitar(String c) {
    if (aninhadas.contains(c) || todos.containsKey(c)) return;
    aninhadas.add(c);
    todos[c] = todasZeus[c]!;
    for (final f in todasZeus[c]!) {
      if (f.classe != null) visitar(f.classe!);
    }
  }

  _raizesAninhadas.forEach(visitar);

  for (final MapEntry(key: grupo, value: campos) in todos.entries) {
    b.writeln("  '$grupo': [");
    for (final c in campos) {
      b.writeln("    CampoGrupo('${c.nome}', TipoCampo.${c.tipo}${c.casas == null ? '' : ', casas: ${c.casas}'}"
          "${c.classe == null ? '' : ", classe: '${c.classe}'"}${c.lista ? ', lista: true' : ''}${c.atributo ? ', atributo: true' : ''}"
          '${c.opcional ? ', opcional: true' : ''}),');
    }
    b.writeln('  ],');
    stdout.writeln('$grupo: ${campos.map((c) => '${c.nome}${c.opcional ? '?' : ''}').join(' ')}');
  }
  b.writeln('};');
  File(saida).writeAsStringSync(b.toString());

  // Classes tipadas (equivalentes a ICMSGeral, PISGeral... do Zeus).
  final classes = StringBuffer()
    ..writeln('// GERADO por tools/extrair_grupos a partir do ZeusFiscal. NÃO EDITE À MÃO.')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln("import 'grupo.dart';")
    ..writeln();
  void classe(String nome, String doc, List<String> grupos, {List<String> ignorar = const []}) {
    final campos = <String, _Campo>{};
    for (final g in grupos) {
      for (final c in todos[g]!) {
        if (!ignorar.contains(c.nome)) campos.putIfAbsent(c.nome, () => c);
      }
    }
    classes
      ..writeln('/// $doc')
      ..writeln('///')
      ..writeln('/// Campos dos grupos ${grupos.join(', ')} do Zeus. Os valores são')
      ..writeln('/// **informados pelo app** (nada é calculado na emissão).')
      ..writeln('class $nome {')
      ..writeln('  const $nome({');
    for (final c in campos.values) {
      classes.writeln('    this.${_dart(c.nome)},');
    }
    classes
      ..writeln('  });')
      ..writeln();
    for (final c in campos.values) {
      final t = switch (c.tipo) { 'dec' => 'double', 'int' => 'int', _ => 'String' };
      classes
        ..writeln('  /// `${c.nome}`${c.casas == null ? '' : ' (${c.casas} casas)'}')
        ..writeln('  final $t? ${_dart(c.nome)};');
    }
    classes
      ..writeln()
      ..writeln('  /// Valores indexados pelo nome do campo no XML.')
      ..writeln('  Map<String, Object?> get valores => {');
    for (final c in campos.values) {
      classes.writeln("        '${c.nome}': ${_dart(c.nome)},");
    }
    classes
      ..writeln('      };')
      ..writeln('}')
      ..writeln();
  }

  classe('IcmsGeral', 'ICMS do item (equivalente ao `ICMSGeral` do Zeus).', [
    'ICMS00', 'ICMS02', 'ICMS10', 'ICMS15', 'ICMS20', 'ICMS30', 'ICMS40', 'ICMS51', 'ICMS53',
    'ICMS60', 'ICMS61', 'ICMS70', 'ICMS90', 'ICMSPart', 'ICMSST', 'ICMSSN101', 'ICMSSN102',
    'ICMSSN201', 'ICMSSN202', 'ICMSSN500', 'ICMSSN900',
  ]);
  classe('PisGeral', 'PIS do item (equivalente ao `PISGeral` do Zeus).',
      ['PISAliq', 'PISQtde', 'PISNT', 'PISOutr']);
  classe('CofinsGeral', 'COFINS do item (equivalente ao `COFINSGeral` do Zeus).',
      ['COFINSAliq', 'COFINSQtde', 'COFINSNT', 'COFINSOutr']);
  classe('IpiGeral', 'IPI do item (equivalente ao `IPIGeral` do Zeus). Somente NF-e.',
      ['IPI', 'IPITrib', 'IPINT']);
  classe('PisSt', 'PIS-ST do item (grupo `PISST`).', ['PISST']);
  classe('CofinsSt', 'COFINS-ST do item (grupo `COFINSST`).', ['COFINSST']);
  classe('ImpostoImportacao', 'Imposto de Importação do item (grupo `II`).', ['II']);
  classe('IcmsUfDest', 'ICMS interestadual para consumidor final (grupo `ICMSUFDest`, DIFAL).',
      ['ICMSUFDest']);
  classe('Issqn', 'ISSQN do item (grupo `ISSQN`).', ['ISSQN']);

  classe('IcmsTot', 'Totais de ICMS da nota (grupo `ICMSTot`), informados pelo app.', ['ICMSTot']);
  classe('IssqnTot', 'Totais de ISSQN da nota (grupo `ISSQNtot`).', ['ISSQNtot']);
  classe('RetTrib', 'Retenção de tributos (grupo `retTrib`).', ['retTrib']);

  // Classes aninhadas (uma por classe do Zeus), serializáveis por si.
  for (final nome in aninhadas) {
    final dartNome = _classeDart(nome);
    final campos = todos[nome]!;
    classes
      ..writeln('/// Grupo `$nome` (classe `$nome` do Zeus). Valores informados pelo app.')
      ..writeln('class $dartNome implements GrupoXml {')
      ..writeln(campos.isEmpty ? '  const $dartNome();' : '  const $dartNome({');
    for (final c in campos) {
      classes.writeln('    ${c.opcional ? '' : 'required '}this.${_dart(c.nome)},');
    }
    if (campos.isNotEmpty) classes.writeln('  });');
    classes.writeln();
    for (final c in campos) {
      var t = switch (c.tipo) {
        'dec' => 'double',
        'int' => 'int',
        'grp' => _classeDart(c.classe!),
        _ => 'String',
      };
      if (c.lista) t = 'List<$t>';
      classes
        ..writeln('  /// `${c.nome}`${c.casas == null ? '' : ' (${c.casas} casas)'}')
        ..writeln('  final $t${c.opcional ? '?' : ''} ${_dart(c.nome)};');
    }
    classes
      ..writeln()
      ..writeln('  @override')
      ..writeln("  String get grupo => '$nome';")
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Map<String, Object?> get valores => {');
    for (final c in campos) {
      classes.writeln("        '${c.nome}': ${_dart(c.nome)},");
    }
    classes
      ..writeln('      };')
      ..writeln('}')
      ..writeln();
  }

  final arqClasses = saida.replaceFirst('grupos.g.dart', 'classes.g.dart');
  File(arqClasses).writeAsStringSync(classes.toString());
  stdout.writeln('classes: $arqClasses');
}

/// Nome do campo no Dart: siglas todas em maiúsculas viram minúsculas
/// (CST → cst, UFST → ufst); os demais mantêm o nome do XML (vICMS, pFCP...).
String _dart(String xml) {
  if (xml == xml.toUpperCase()) return xml.toLowerCase();
  // Sigla inicial seguida de palavra: CSTReg → cstReg, CNPJProd → cnpjProd.
  final sigla = RegExp(r'^([A-Z]{2,})([A-Z][a-z])').firstMatch(xml);
  if (sigla != null) return sigla.group(1)!.toLowerCase() + xml.substring(sigla.group(1)!.length);
  return xml[0].toLowerCase() + xml.substring(1);
}

List<_Campo> _extrair(String src, String grupo) {
  // Remove comentários de documentação e mantém o ramo #else das diretivas.
  final limpo = src
      .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
      .replaceAll(RegExp(r'#if[^\n]*\n[\s\S]*?#else[^\n]*\n'), '')
      .replaceAll(RegExp(r'^\s*#(if|endif)[^\n]*$', multiLine: true), '');
  final re = RegExp(
      r'(\[XmlElement\(([^\]]*)\)\]\s*)?public\s+([\w?<>\.]+)\s+@?(\w+)\s*(\{|$)',
      multiLine: true);
  final campos = <_Campo>[];
  var seq = 0;
  for (final m in re.allMatches(limpo)) {
    final tipoCs = m.group(3)!;
    final nome = m.group(4)!;
    if (tipoCs == 'class' || tipoCs == 'bool' || nome.endsWith('Specified')) continue;
    if (RegExp(r'^(override|static|abstract|virtual)$').hasMatch(tipoCs)) continue;
    if (nome.startsWith('ShouldSerialize') || nome.endsWith('Proxy')) continue;
    if (RegExp('ShouldSerialize$nome\\(\\)\\s*=>\\s*false').hasMatch(src)) continue;
    if (RegExp(r'^(void|string\s*ToString)$').hasMatch(tipoCs)) continue;
    if (RegExp(r'\[XmlIgnore\]\s*$').hasMatch(limpo.substring(0, m.start).trimRight().split('\n').last)) {
      continue;
    }
    final attr = m.group(2) ?? '';
    // Nome do elemento XML pode diferir da propriedade (ElementName).
    final elem = RegExp(r'ElementName\s*=\s*"(\w+)"').firstMatch(attr)?.group(1) ?? nome;
    final ordem = int.tryParse(RegExp(r'Order\s*=\s*(\d+)').firstMatch(attr)?.group(1) ?? '') ?? (1000 + seq);
    seq++;

    // Corpo da propriedade (até o próximo "public").
    final fim = limpo.indexOf(RegExp(r'\n\s*(\[Xml|public )'), m.end);
    final corpo = limpo.substring(m.end, fim < 0 ? limpo.length : fim);
    final casas = int.tryParse(RegExp(r'Arredondar\((\d)\)').firstMatch(corpo)?.group(1) ?? '');

    final nulo = tipoCs.endsWith('?');
    final t = tipoCs.replaceAll('?', '');
    final tipo = switch (t) {
      'decimal' => 'dec',
      'int' || 'short' || 'long' => 'int',
      _ => 'str', // string e enums (o app informa o código)
    };
    final atributo = RegExp(r'\[XmlAttribute[^\]]*\]\s*$').hasMatch(limpo.substring(0, m.start));
    final opcional = nulo ||
        t == 'string' ||
        src.contains('${nome}Specified') ||
        src.contains('ShouldSerialize$nome()') ||
        (t == 'string' && src.contains('string.IsNullOrEmpty($nome)'));
    campos.add(_Campo(elem, ordem, tipo, tipo == 'dec' ? (casas ?? 2) : null, opcional, tipoCs: tipoCs, atributo: atributo));
  }
  campos.sort((a, b) => a.ordem.compareTo(b.ordem));
  return campos;
}
