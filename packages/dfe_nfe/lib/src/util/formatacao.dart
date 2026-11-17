/// Formatação de datas e números no padrão do leiaute da NF-e.
library;

/// `AAAA-MM-DDThh:mm:ss±hh:mm` no fuso local (ex.: 2026-11-17T10:00:00-03:00).
String formatarDataHora(DateTime d) {
  final local = d.toLocal();
  final off = local.timeZoneOffset;
  final sinal = off.isNegative ? '-' : '+';
  final abs = off.abs();
  String p(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${p(local.month)}-${p(local.day)}T${p(local.hour)}:'
      '${p(local.minute)}:${p(local.second)}$sinal${p(abs.inHours)}:${p(abs.inMinutes % 60)}';
}

/// Decimal com [casas] casas, ponto como separador (ex.: 10.00).
String formatarDecimal(num v, [int casas = 2]) => v.toStringAsFixed(casas);

/// Escapa texto para conteúdo/atributo XML.
String escaparXml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
