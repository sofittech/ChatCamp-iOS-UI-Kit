//
//  WebViewController.swift
//  ChatCampUIKit
//
//  Created by Saurabh Gupta on 23/11/18.
//  Copyright © 2018 chatcamp. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {
    
    var webView: WKWebView!
    var urlString: String!
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: view.frame, configuration: webConfiguration)
        webView.isUserInteractionEnabled = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        webView.addSubview(activityIndicator)
        
        if !urlString.starts(with: "http://") && !urlString.starts(with: "https://") {
            urlString = "http://" + urlString
        }
        
        if let url = URL(string: urlString) {
            let request = URLRequest.init(url: url)
            webView.load(request)
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
}
