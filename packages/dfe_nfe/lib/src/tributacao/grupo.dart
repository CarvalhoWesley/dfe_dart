import '../util/formatacao.dart';
import 'grupos.g.dart';

enum TipoCampo { dec, int, str }

/// Campo de um grupo do XML, conforme a classe correspondente do Zeus.
class CampoGrupo {
  const CampoGrupo(this.nome, this.tipo, {this.casas, this.opcional = false});
  final String nome;
  final TipoCampo tipo;

  /// Casas decimais (os decimais do Zeus arredondam em 2 ou 4 casas).
  final int? casas;

  /// Campo omitido quando nulo; obrigatório quando falso.
  final bool opcional;
}

/// Serializa o grupo [grupo] com os [valores] informados, na ordem e no
/// formato do Zeus. Campos opcionais nulos são omitidos; campo obrigatório
/// nulo gera [ArgumentError].
String serializarGrupo(String grupo, Map<String, Object?> valores) {
  final campos = especificacaoGrupos[grupo];
  if (campos == null) throw ArgumentError('Grupo desconhecido: $grupo');
  final b = StringBuffer('<$grupo>');
  for (final c in campos) {
    final v = valores[c.nome];
    if (v == null) {
      if (c.opcional) continue;
      throw ArgumentError('Campo obrigatório "${c.nome}" não informado no grupo $grupo');
    }
    b.write('<${c.nome}>${escaparXml(formatarCampo(c, v))}</${c.nome}>');
  }
  b.write('</$grupo>');
  return b.toString();
}

String formatarCampo(CampoGrupo c, Object v) => switch (c.tipo) {
      TipoCampo.dec => formatarDecimal((v as num).toDouble(), c.casas ?? 2),
      TipoCampo.int => '${(v as num).toInt()}',
      TipoCampo.str => '$v',
    };
