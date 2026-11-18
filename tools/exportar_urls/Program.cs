// Exporta as URLs de webservice (NF-e/NFC-e 4.00) e de consulta pública da
// NFC-e do ZeusFiscal para uma tabela Dart.
using System.Text;
using DFe.Classes.Entidades;
using DFe.Classes.Flags;
using NFe.Classes.Informacoes.Identificacao.Tipos;
using NFe.Classes;
using NFe.Utils;
using NFe.Classes.Servicos.Tipos;
using NFe.Utils.Enderecos;
using NFe.Utils.InformacoesSuplementares;

var saida = args.Length > 0 ? args[0] : "enderecos_tabela.g.dart";

// Serviço do Zeus -> nome do enum ServicoNfe no dfe_nfe.
var servicos = new Dictionary<ServicoNFe, string>
{
    [ServicoNFe.NfeStatusServico] = "statusServico",
    [ServicoNFe.NFeAutorizacao] = "autorizacao",
    [ServicoNFe.NFeRetAutorizacao] = "retAutorizacao",
    [ServicoNFe.NfeConsultaProtocolo] = "consultaProtocolo",
    [ServicoNFe.NfeInutilizacao] = "inutilizacao",
    [ServicoNFe.RecepcaoEventoCancelmento] = "recepcaoEvento",
    [ServicoNFe.RecepcaoEventoEpec] = "recepcaoEventoEpec",
    [ServicoNFe.RecepcaoEventoManifestacaoDestinatario] = "manifestacaoDestinatario",
};
var emissoes = new Dictionary<TipoEmissao, string>
{
    [TipoEmissao.teNormal] = "normal",
    [TipoEmissao.teSVCAN] = "svcAn",
    [TipoEmissao.teSVCRS] = "svcRs",
    [TipoEmissao.teEPEC] = "epec",
};
var modelos = new Dictionary<ModeloDocumento, string> { [ModeloDocumento.NFe] = "nfe", [ModeloDocumento.NFCe] = "nfce" };
var ambientes = new Dictionary<TipoAmbiente, string> { [TipoAmbiente.Producao] = "producao", [TipoAmbiente.Homologacao] = "homologacao" };
var estados = Enum.GetValues<Estado>().Where(e => e != Estado.EX).ToList();

var linhas = new SortedDictionary<string, string>(StringComparer.Ordinal);
foreach (var uf in estados)
foreach (var (mod, nomeMod) in modelos)
foreach (var (amb, nomeAmb) in ambientes)
foreach (var (tp, nomeTp) in emissoes)
{
    // Mesma regra do Zeus: para cada serviço, a versão mais recente <= 4.00.
    foreach (var e in Enderecador.ObterEnderecoServicosMaisRecentes(VersaoServico.Versao400, uf, amb, mod, tp))
    {
        if (!servicos.TryGetValue(e.ServicoNFe, out var nomeServ)) continue;
        if (e.VersaoServico != VersaoServico.Versao400) continue;
        linhas[$"{uf}|{nomeMod}|{nomeAmb}|{nomeTp}|{nomeServ}"] = e.Url;
    }
}

var supl = new infNFeSupl();
var qr = new SortedDictionary<string, string>(StringComparer.Ordinal);
foreach (var uf in estados)
foreach (var (amb, nomeAmb) in ambientes)
foreach (var (versao, nomeVersao) in new[] { (VersaoQrCode.QrCodeVersao2, "v2"), (VersaoQrCode.QrCodeVersao3, "v3") })
foreach (var (tipo, nomeTipo) in new[] { (TipoUrlConsultaPublica.UrlQrCode, "qrCode"), (TipoUrlConsultaPublica.UrlConsulta, "consulta") })
{
    try
    {
        var url = supl.ObterUrl(amb, uf, tipo, VersaoServico.Versao400, versao);
        if (!string.IsNullOrWhiteSpace(url)) qr[$"{uf}|{nomeAmb}|{nomeVersao}|{nomeTipo}"] = url.Trim();
    }
    catch
    {
        // UF sem URL para essa combinação.
    }
}

static string Esc(string s) => s.Replace("\\", "\\\\").Replace("'", "\\'").Replace("$", "\\$");

var b = new StringBuilder();
b.AppendLine("// GERADO por tools/exportar_urls a partir do ZeusFiscal. NÃO EDITE À MÃO.");
b.AppendLine($"// Gerado em {DateTime.Now:yyyy-MM-dd}.");
b.AppendLine("// ignore_for_file: lines_longer_than_80_chars");
b.AppendLine();
b.AppendLine("/// Chave: `UF|modelo|ambiente|tipoEmissao|servico` (UF em maiúsculas).");
b.AppendLine("const Map<String, String> tabelaUrlsServicos = {");
foreach (var (k, v) in linhas) b.AppendLine($"  '{k}': '{Esc(v)}',");
b.AppendLine("};");
b.AppendLine();
b.AppendLine("/// Chave: `UF|ambiente|versaoQrCode|qrCode|consulta`.");
b.AppendLine("const Map<String, String> tabelaUrlsNfce = {");
foreach (var (k, v) in qr) b.AppendLine($"  '{k}': '{Esc(v)}',");
b.AppendLine("};");

File.WriteAllText(saida, b.ToString(), new UTF8Encoding(false));
Console.WriteLine($"{linhas.Count} URLs de serviço e {qr.Count} URLs de NFC-e gravadas em {saida}");
