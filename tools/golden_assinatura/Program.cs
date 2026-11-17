// Gera a <Signature> de referência usando exatamente a lógica de
// DFe.Utils/Assinatura/AssinaturaDigital.AssinaXml do ZeusFiscal.
// Uso: dotnet run -- <xml> <id> <pfx> <senha> [sha256]
using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography.Xml;
using System.Xml;

var xml = File.ReadAllText(args[0]);
var id = args[1];
var cert = X509CertificateLoader.LoadPkcs12FromFile(args[2], args[3]);
var sha256 = args.Length > 4 && args[4] == "sha256";

var documento = new XmlDocument { PreserveWhitespace = true };
documento.LoadXml(xml);

var docXml = new SignedXml(documento) { SigningKey = cert.GetRSAPrivateKey() };
docXml.SignedInfo.SignatureMethod = sha256
    ? "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    : "http://www.w3.org/2000/09/xmldsig#rsa-sha1";
var reference = new Reference
{
    Uri = "#" + id,
    DigestMethod = sha256 ? "http://www.w3.org/2001/04/xmlenc#sha256" : "http://www.w3.org/2000/09/xmldsig#sha1",
};
reference.AddTransform(new XmlDsigEnvelopedSignatureTransform());
reference.AddTransform(new XmlDsigC14NTransform());
docXml.AddReference(reference);

var keyInfo = new KeyInfo();
keyInfo.AddClause(new KeyInfoX509Data(cert));
docXml.KeyInfo = keyInfo;
docXml.ComputeSignature();

Console.Out.Write(docXml.GetXml().OuterXml);
