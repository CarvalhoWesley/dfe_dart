import '../util/formatacao.dart';
import 'grupos.g.dart';

enum TipoCampo { dec, int, str, grp }

/// Grupo do XML com especificação gerada a partir de uma classe do Zeus.
abstract interface class GrupoXml {
  /// Nome da classe no Zeus (chave da especificação).
  String get grupo;

  /// Valores indexados pelo nome do elemento no XML.
  Map<String, Object?> get valores;
}

/// Serializa um [GrupoXml]; [tag] substitui o nome do elemento raiz.
String serializarGrupoXml(GrupoXml g, {String? tag}) => serializarGrupo(g.grupo, g.valores, tag: tag);

/// Campo de um grupo do XML, conforme a classe correspondente do Zeus.
class CampoGrupo {
  const CampoGrupo(this.nome, this.tipo, {this.casas, this.opcional = false, this.classe, this.lista = false, this.atributo = false});

  /// Serializado como atributo XML do grupo (XmlAttribute no Zeus).
  final bool atributo;
  final String nome;
  final TipoCampo tipo;

  /// Classe do subgrupo (quando [tipo] é [TipoCampo.grp]).
  final String? classe;

  /// Subgrupo repetível (List no Zeus).
  final bool lista;

  /// Casas decimais (os decimais do Zeus arredondam em 2 ou 4 casas).
  final int? casas;

  /// Campo omitido quando nulo; obrigatório quando falso.
  final bool opcional;
}

/// Serializa o grupo [grupo] com os [valores] informados, na ordem e no
/// formato do Zeus. Campos opcionais nulos são omitidos; campo obrigatório
/// nulo gera [ArgumentError].
String serializarGrupo(String grupo, Map<String, Object?> valores, {String? tag}) {
  final campos = especificacaoGrupos[grupo];
  if (campos == null) throw ArgumentError('Grupo desconhecido: $grupo');
  final raiz = tag ?? grupo;
  final atributos = StringBuffer();
  final b = StringBuffer();
  for (final c in campos) {
    final v = valores[c.nome];
    if (v == null) {
      if (c.opcional) continue;
      throw ArgumentError('Campo obrigatório "${c.nome}" não informado no grupo $grupo');
    }
    if (c.atributo) {
      atributos.write(' ${c.nome}="${escaparXml(formatarCampo(c, v))}"');
      continue;
    }
    if (c.tipo == TipoCampo.grp) {
      for (final g in v is List ? v.cast<GrupoXml>() : [v as GrupoXml]) {
        b.write(serializarGrupo(c.classe ?? g.grupo, g.valores, tag: c.nome));
      }
      continue;
    }
    b.write('<${c.nome}>${escaparXml(formatarCampo(c, v))}</${c.nome}>');
  }
  return '<$raiz$atributos>$b</$raiz>';
}

String formatarCampo(CampoGrupo c, Object v) => switch (c.tipo) {
      TipoCampo.dec => formatarDecimal((v as num).toDouble(), c.casas ?? 2),
      TipoCampo.int => '${(v as num).toInt()}',
      TipoCampo.str || TipoCampo.grp => '$v',
    };
