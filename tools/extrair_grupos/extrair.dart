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
  _Campo(this.nome, this.ordem, this.tipo, this.casas, this.opcional);
  final String nome;
  final int ordem;
  final String tipo; // dec | int | str
  final int? casas;
  final bool opcional;
}

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

  for (final MapEntry(key: arquivo, value: grupo) in _classes.entries) {
    final f = File('$base/$arquivo');
    if (!f.existsSync()) {
      stderr.writeln('ausente: $arquivo');
      continue;
    }
    final campos = _extrair(f.readAsStringSync(), grupo);
    b.writeln("  '$grupo': [");
    for (final c in campos) {
      b.writeln("    CampoGrupo('${c.nome}', TipoCampo.${c.tipo}${c.casas == null ? '' : ', casas: ${c.casas}'}"
          '${c.opcional ? ', opcional: true' : ''}),');
    }
    b.writeln('  ],');
    stdout.writeln('$grupo: ${campos.map((c) => '${c.nome}${c.opcional ? '?' : ''}').join(' ')}');
  }
  b.writeln('};');
  File(saida).writeAsStringSync(b.toString());
}

List<_Campo> _extrair(String src, String grupo) {
  // Remove comentários de documentação.
  final limpo = src.replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '');
  final re = RegExp(
      r'(\[XmlElement\(([^\]]*)\)\]\s*)?public\s+([\w?<>\.]+)\s+(\w+)\s*(\{|$)',
      multiLine: true);
  final campos = <_Campo>[];
  var seq = 0;
  for (final m in re.allMatches(limpo)) {
    final tipoCs = m.group(3)!;
    final nome = m.group(4)!;
    if (tipoCs == 'class' || tipoCs == 'bool' || nome.endsWith('Specified')) continue;
    if (RegExp(r'^(override|static|abstract|virtual)$').hasMatch(tipoCs)) continue;
    if (nome.startsWith('ShouldSerialize') || nome.endsWith('Proxy')) continue;
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
    final opcional = nulo ||
        t == 'string' ||
        src.contains('${nome}Specified') ||
        src.contains('ShouldSerialize$nome()') ||
        (t == 'string' && src.contains('string.IsNullOrEmpty($nome)'));
    campos.add(_Campo(elem, ordem, tipo, tipo == 'dec' ? (casas ?? 2) : null, opcional));
  }
  campos.sort((a, b) => a.ordem.compareTo(b.ordem));
  return campos;
}
