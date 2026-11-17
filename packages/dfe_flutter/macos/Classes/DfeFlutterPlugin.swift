#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif
import Foundation
import Security

/// Transporte HTTPS com certificado de cliente A1 (PKCS#12) via URLSession.
/// A URLSession responde ao desafio de certificado do cliente inclusive quando
/// o servidor o pede por renegociação TLS (caso das SEFAZ em IIS).
public class DfeFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif
    let canal = FlutterMethodChannel(
      name: "br.com.dfedart/dfe_flutter", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(DfeFlutterPlugin(), channel: canal)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "post", let a = call.arguments as? [String: Any] else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let urlTexto = a["url"] as? String, let url = URL(string: urlTexto),
      let cabecalhos = a["cabecalhos"] as? [String: String],
      let corpo = (a["corpo"] as? FlutterStandardTypedData)?.data,
      let timeoutMs = a["timeoutMs"] as? Int,
      let pfx = (a["pfx"] as? FlutterStandardTypedData)?.data,
      let senha = a["senha"] as? String,
      let validarServidor = a["validarServidor"] as? Bool
    else {
      result(FlutterError(code: "TRANSPORTE", message: "Argumentos inválidos", details: nil))
      return
    }

    let identidade: SecIdentity
    switch importarIdentidade(pfx: pfx, senha: senha) {
    case .success(let i): identidade = i
    case .failure(let msg):
      result(FlutterError(code: "TRANSPORTE", message: msg, details: nil))
      return
    }

    let delegate = DelegateTls(identidade: identidade, validarServidor: validarServidor)
    let cfg = URLSessionConfiguration.ephemeral
    cfg.timeoutIntervalForRequest = Double(timeoutMs) / 1000
    cfg.timeoutIntervalForResource = Double(timeoutMs) / 1000
    let sessao = URLSession(configuration: cfg, delegate: delegate, delegateQueue: nil)

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.httpBody = corpo
    for (k, v) in cabecalhos { req.setValue(v, forHTTPHeaderField: k) }

    sessao.dataTask(with: req) { dados, resposta, erro in
      sessao.finishTasksAndInvalidate()
      DispatchQueue.main.async {
        if let erro = erro as NSError? {
          result(FlutterError(
            code: "TRANSPORTE",
            message: "Falha de conexão/TLS: \(erro.localizedDescription)",
            details: "\(erro.code)"))
          return
        }
        let status = (resposta as? HTTPURLResponse)?.statusCode ?? 0
        let texto = dados.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        result(["status": status, "corpo": texto])
      }
    }.resume()
  }

  private enum Importacao { case success(SecIdentity), failure(String) }

  private func importarIdentidade(pfx: Data, senha: String) -> Importacao {
    var itens: CFArray?
    let opcoes = [kSecImportExportPassphrase as String: senha] as CFDictionary
    let status = SecPKCS12Import(pfx as CFData, opcoes, &itens)
    switch status {
    case errSecSuccess: break
    case errSecAuthFailed: return .failure("Senha do certificado incorreta")
    default: return .failure("Falha ao importar o certificado (OSStatus \(status))")
    }
    guard
      let lista = itens as? [[String: Any]],
      let primeiro = lista.first,
      let ref = primeiro[kSecImportItemIdentity as String]
    else { return .failure("Nenhuma identidade (certificado + chave) no .pfx") }
    return .success(ref as! SecIdentity)
  }
}

private final class DelegateTls: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
  let identidade: SecIdentity
  let validarServidor: Bool

  init(identidade: SecIdentity, validarServidor: Bool) {
    self.identidade = identidade
    self.validarServidor = validarServidor
  }

  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    responder(challenge, completionHandler)
  }

  func urlSession(
    _ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    responder(challenge, completionHandler)
  }

  private func responder(
    _ challenge: URLAuthenticationChallenge,
    _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    switch challenge.protectionSpace.authenticationMethod {
    case NSURLAuthenticationMethodClientCertificate:
      completionHandler(
        .useCredential,
        URLCredential(identity: identidade, certificates: nil, persistence: .forSession))
    case NSURLAuthenticationMethodServerTrust:
      if !validarServidor, let trust = challenge.protectionSpace.serverTrust {
        completionHandler(.useCredential, URLCredential(trust: trust))
      } else {
        completionHandler(.performDefaultHandling, nil)
      }
    default:
      completionHandler(.performDefaultHandling, nil)
    }
  }
}
