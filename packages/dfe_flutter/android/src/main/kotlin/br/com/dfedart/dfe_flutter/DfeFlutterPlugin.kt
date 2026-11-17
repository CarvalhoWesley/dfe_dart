package br.com.dfedart.dfe_flutter

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.URL
import java.net.UnknownHostException
import java.security.KeyFactory
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.spec.PKCS8EncodedKeySpec
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.concurrent.Executors
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLException
import javax.net.ssl.TrustManager
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

/**
 * Transporte HTTPS com certificado de cliente A1 (PKCS#12) usando
 * HttpsURLConnection + JSSE, que aceita a renegociação TLS usada pelas SEFAZ.
 */
class DfeFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var canal: MethodChannel
  private val executor = Executors.newCachedThreadPool()
  private val main = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    canal = MethodChannel(binding.binaryMessenger, "br.com.dfedart/dfe_flutter")
    canal.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    canal.setMethodCallHandler(null)
    executor.shutdown()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method != "post") {
      result.notImplemented()
      return
    }
    executor.execute {
      try {
        val resposta = post(call)
        main.post { result.success(resposta) }
      } catch (e: Exception) {
        val msg = when (e) {
          is SocketTimeoutException -> "Tempo esgotado: ${e.message}"
          is UnknownHostException -> "Servidor não encontrado: ${e.message}"
          is SSLException -> "Falha no TLS: ${e.message}"
          is IOException -> if (e.message?.contains("password", true) == true)
            "Senha do certificado incorreta" else "Falha de conexão: ${e.message}"
          else -> "${e.javaClass.simpleName}: ${e.message}"
        }
        main.post { result.error("TRANSPORTE", msg, null) }
      }
    }
  }

  private fun post(call: MethodCall): Map<String, Any> {
    val url = call.argument<String>("url")!!
    val cabecalhos = call.argument<Map<String, String>>("cabecalhos")!!
    val corpo = call.argument<ByteArray>("corpo")!!
    val timeoutMs = call.argument<Int>("timeoutMs")!!
    val chavePkcs8 = call.argument<ByteArray>("chavePkcs8")!!
    val cadeiaDer = call.argument<List<ByteArray>>("cadeiaDer")!!
    val validarServidor = call.argument<Boolean>("validarServidor")!!

    // Monta o KeyStore em memória com a chave e a cadeia já decifradas no Dart.
    val chave = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(chavePkcs8))
    val cf = CertificateFactory.getInstance("X.509")
    val cadeia = cadeiaDer.map { cf.generateCertificate(ByteArrayInputStream(it)) }.toTypedArray()
    val senhaInterna = CharArray(0)
    val keyStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
      load(null, null)
      setKeyEntry("a1", chave, senhaInterna, cadeia)
    }
    val kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm()).apply {
      init(keyStore, senhaInterna)
    }
    val trustManagers: Array<TrustManager> = if (validarServidor) {
      TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).apply {
        init(null as KeyStore?)
      }.trustManagers
    } else {
      arrayOf(object : X509TrustManager {
        override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {}
        override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {}
        override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
      })
    }
    val ssl = SSLContext.getInstance("TLS").apply {
      init(kmf.keyManagers, trustManagers, SecureRandom())
    }

    val conn = URL(url).openConnection() as HttpsURLConnection
    try {
      conn.sslSocketFactory = ssl.socketFactory
      if (!validarServidor) conn.hostnameVerifier = javax.net.ssl.HostnameVerifier { _, _ -> true }
      conn.connectTimeout = timeoutMs
      conn.readTimeout = timeoutMs
      conn.requestMethod = "POST"
      conn.doOutput = true
      conn.useCaches = false
      cabecalhos.forEach { (k, v) -> conn.setRequestProperty(k, v) }
      conn.setFixedLengthStreamingMode(corpo.size)
      conn.outputStream.use { it.write(corpo) }

      val status = conn.responseCode
      val stream = if (status >= 400) conn.errorStream else conn.inputStream
      val texto = stream?.use { it.readBytes().toString(Charsets.UTF_8) } ?: ""
      return mapOf("status" to status, "corpo" to texto)
    } finally {
      conn.disconnect()
    }
  }
}
