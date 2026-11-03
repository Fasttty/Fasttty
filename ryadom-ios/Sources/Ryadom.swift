import SwiftUI
import WebKit

@main
struct RyadomApp: App {
    var body: some Scene {
        WindowGroup { RyadomView() }
    }
}

struct RyadomView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RyadomController { RyadomController() }
    func updateUIViewController(_ controller: RyadomController, context: Context) {}
}

final class RyadomController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private let origin = URL(string: "https://ryadom-duo.daydlo.chatgpt.site")!
    private let routes: Set<String> = ["state", "register", "login", "logout", "profile", "invite", "join", "entry", "remove", "extras", "reward", "cycle", "appreciation"]
    private var web: WKWebView!
    private var root: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        guard let entry = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") else {
            let message = UILabel()
            message.text = "Не удалось загрузить интерфейс «Рядом»."
            message.textAlignment = .center
            message.numberOfLines = 0
            message.frame = view.bounds.insetBy(dx: 24, dy: 0)
            message.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(message)
            return
        }
        root = entry.deletingLastPathComponent()
        let config = WKWebViewConfiguration()
        let js = """
        window.RyadomCloud = {
          request(id, path, payload) {
            window.webkit.messageHandlers.ryadom.postMessage({id, path, payload});
          },
          setBars() {}
        };
        """
        config.userContentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController.add(Bridge(self), name: "ryadom")
        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        let area = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: area.topAnchor),
            web.bottomAnchor.constraint(equalTo: area.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: area.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: area.trailingAnchor)
        ])
        web.loadFileURL(entry, allowingReadAccessTo: root)
    }

    private func isLocal(_ url: URL?) -> Bool {
        guard let url, url.isFileURL else { return false }
        return url.standardizedFileURL.path == root.appendingPathComponent("index.html").standardizedFileURL.path
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(isLocal(action.request.url) ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Рядом", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "Продолжить", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    private func receive(_ message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, isLocal(message.frameInfo.request.url),
              let input = message.body as? [String: Any],
              let id = input["id"] as? Int,
              let path = input["path"] as? String, routes.contains(path) else { return }
        var request = URLRequest(url: origin.appendingPathComponent("api").appendingPathComponent(path))
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let payload = input["payload"] as? String {
            request.httpMethod = "POST"
            request.setValue(origin.absoluteString, forHTTPHeaderField: "Origin")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = Data(payload.utf8)
        }
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            var reply: [String: Any] = ["status": 503, "error": "Не удалось подключиться к серверу. Проверь интернет."]
            if let http = response as? HTTPURLResponse, let data,
               http.url?.host == self?.origin.host,
               var parsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                parsed["status"] = http.statusCode
                reply = parsed
            }
            let finalReply = reply
            DispatchQueue.main.async {
                self?.web.callAsyncJavaScript("window.cloudReply(id, reply)", arguments: ["id": id, "reply": finalReply], in: nil, in: .page) { _ in }
            }
        }.resume()
    }

    private final class Bridge: NSObject, WKScriptMessageHandler {
        weak var owner: RyadomController?
        init(_ owner: RyadomController) { self.owner = owner }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            owner?.receive(message)
        }
    }
}
