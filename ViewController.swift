//
//  ViewController.swift
//  TestFairy
//

import UIKit
import WebKit

let TESTFAIRY_URL = "https://app.testfairy.com"

class ViewController: UIViewController {
    private lazy var navigationDelegate: WebViewNavigationDelegate = { [unowned self] in
        return WebViewNavigationDelegate(controller: self)
    }()
    private lazy var uiDelegate: WebViewUIDelegate = { [unowned self] in
        return WebViewUIDelegate(controller: self)
    }()
    private lazy var webView: WKWebView = { [unowned self] in
        let bundle = Bundle.main
        let version = bundle.infoDictionary?[ "CFBundleShortVersionString"]
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "TestersApp/\(version ?? 1.0)"
        let view = WKWebView(frame: .zero, configuration: webConfiguration)
        view.scrollView.showsHorizontalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.navigationDelegate = self.navigationDelegate
        view.uiDelegate = self.uiDelegate
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                webView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                webView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
                webView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: self.view.topAnchor),
                webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                webView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                webView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            ])
        }
        
        let request = URLRequest(url: URL(string: TESTFAIRY_URL)!, cachePolicy: .reloadIgnoringLocalCacheData)
        webView.load(request)
    }
}

class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var controller: UIViewController?
    init(controller: UIViewController) {
        self.controller = controller
        super.init()
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url {
            print("URL \(url)")
            if self.canOpenUrl(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    private func canOpenUrl(_ url: URL) -> Bool {
        if let scheme = url.scheme, scheme.contains("itms-services") {
            return true
        }
        
        return false
    }
}

class WebViewUIDelegate: NSObject, WKUIDelegate {
    weak var controller: UIViewController?
    init(controller: UIViewController) {
        self.controller = controller
        super.init()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))

        self.controller?.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        self.controller?.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }

        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in

            completionHandler(nil)
        }))

        self.controller?.present(alertController, animated: true, completion: nil)
    }
}

extension WKWebView {
    func load(_ request: URLRequest, with cookies: [HTTPCookie]) {
        var request = request
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        for (name, value) in headers {
            request.addValue(value, forHTTPHeaderField: name)
        }

        load(request)
    }
}
