//
//  ContentView.swift
//  TestFairy
//

import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        Webview(url: URL(string: "https://app.testfairy.com")!)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, let scheme = url.scheme {
            print("URL \(url)")
            if scheme.contains("itms-services") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
}

struct Webview: UIViewRepresentable {
    let url: URL
    private let navigationDelegate = WebViewNavigationDelegate()
    
    func makeUIView(context: UIViewRepresentableContext<Webview>) -> WKWebView {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?[ "CFBundleShortVersionString"]
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "TestersApp/\(version ?? 1.0)"
        let webview = WKWebView(frame: .zero, configuration: webConfiguration)
        webview.scrollView.showsHorizontalScrollIndicator = false
        webview.navigationDelegate = navigationDelegate
        
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)

        return webview
    }

    func updateUIView(_ webview: WKWebView, context: UIViewRepresentableContext<Webview>) {
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)
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
