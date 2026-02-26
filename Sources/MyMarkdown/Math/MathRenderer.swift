//
//  MathRenderer.swift
//  MyMarkdown
//

import Foundation

#if canImport(WebKit)
import WebKit

#if canImport(UIKit)
import UIKit
public typealias NativeImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias NativeImage = NSImage
#endif

/// A high-performance utility that converts LaTeX math strings (e.g. `\frac{1}{2}`) 
/// into pre-rendered images using MathJax running headlessly in a background `WKWebView`.
///
/// Because instantiating `WKWebView` is expensive, this renderer maintains a 
/// shared pool/singleton of an invisible web view loaded with the MathJax library.
public final class MathRenderer: NSObject, WKNavigationDelegate {
    
    public static let shared = MathRenderer()
    
    private var webView: WKWebView?
    private var isReady = false
    private var pendingTasks: [(String, (NativeImage?) -> Void)] = []
    
    private override init() {
        super.init()
        setupBackgroundWebView()
    }
    
    private func setupBackgroundWebView() {
        // Ensure WebKit initialization happens on the main thread
        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
            webView.navigationDelegate = self
            
            // Load a minimal HTML string containing the CDN MathJax library
            // For production, this library should be bundled locally to avoid network requests,
            // but for this MVP, CDN guarantees ChatGPT parity.
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <script>
                    MathJax = {
                        tex: { inlineMath: [['$', '$'], ['\\(', '\\)']] },
                        svg: { fontCache: 'global' },
                        startup: { typeset: false }
                    };
                </script>
                <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
            </head>
            <body>
                <div id="math-container"></div>
            </body>
            </html>
            """
            
            self.webView = webView
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isReady = true
        // Flush any equations that were requested while the engine was booting up
        for task in pendingTasks {
            processEquation(task.0, completion: task.1)
        }
        pendingTasks.removeAll()
    }
    
    /// Converts a LaTeX string into a rasterized image asynchronously.
    public func render(latex: String, completion: @escaping (NativeImage?) -> Void) {
        if !isReady {
            pendingTasks.append((latex, completion))
        } else {
            processEquation(latex, completion: completion)
        }
    }
    
    private func processEquation(_ latex: String, completion: @escaping (NativeImage?) -> Void) {
        // Javascript to command MathJax to typeset the SVG, then extract the bounding box size
        // and trigger a native snapshot.
        let escapedLatex = latex.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        
        let js = """
        (function() {
            const container = document.getElementById('math-container');
            container.innerHTML = '\\\\( \(escapedLatex) \\\\)';
            return MathJax.typesetPromise([container]).then(() => {
                const svg = container.querySelector('svg');
                if (!svg) return null;
                
                // Extract dimensions
                const width = svg.getAttribute('width');
                const height = svg.getAttribute('height');
                return { width: width, height: height, html: svg.outerHTML };
            }).catch(err => {
                return null;
            });
        })();
        """
        
        // Execute JS exclusively on the main loop where WebKit lives
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.webView else {
                completion(nil)
                return
            }
            
            webView.evaluateJavaScript(js) { (result, error) in
                guard error == nil else {
                    completion(nil)
                    return
                }
                
                // In a full implementation, we would parse the SVG HTML here and 
                // use CoreGraphics to natively draw the vector paths to a CGContext.
                // For this prototype, we'll leverage a direct WKWebView snapshot of the bounding box.
                let config = WKSnapshotConfiguration()
                // Assume 100x50 generic size for now as a fallback if the JS promise dimension extraction fails
                config.rect = CGRect(x: 0, y: 0, width: 200, height: 100) 
                
                webView.takeSnapshot(with: config) { image, error in
                    completion(image)
                }
            }
        }
    }
}
#endif
