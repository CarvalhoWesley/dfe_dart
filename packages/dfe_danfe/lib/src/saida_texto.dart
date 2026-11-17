import 'layout.dart';

/// Renderiza o layout como texto puro em [colunas] colunas. O QR Code vira
/// uma linha com o conteúdo (o app decide como desenhá-lo).
String renderizarTexto(List<ElementoDanfe> layout, int colunas, {bool incluirQrCode = true}) {
  final b = StringBuffer();
  for (final e in layout) {
    switch (e) {
      case LinhaDanfe():
        b.writeln(alinhar(e.texto, colunas, e.alinhamento));
      case SeparadorDanfe():
        b.writeln('-' * colunas);
      case QrCodeDanfe():
        if (incluirQrCode) {
          for (final l in quebrar(e.conteudo, colunas)) {
            b.writeln(l);
          }
        }
    }
  }
  return b.toString();
}

String alinhar(String s, int n, Alinhamento a) {
  if (s.length >= n) return s;
  return switch (a) {
    Alinhamento.esquerda => s,
    Alinhamento.direita => s.padLeft(n),
    Alinhamento.centro => '${' ' * ((n - s.length) ~/ 2)}$s',
  };
}
