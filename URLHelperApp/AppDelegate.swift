//
//  AppDelegate.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Cocoa

private let urlToAppMapper: URLToAppMapper = ScriptBasedURLToAppMapper()

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {
    
    func application(_ application: NSApplication, open urls: [URL]) {
        dump(urls, name: "urls")
        var urlsByAppBundleIdentifier: [String: [URL]] = [:]
        let queryQueue = DispatchQueue.global()
        let resultGroup = DispatchGroup()
        let resultQueue = DispatchQueue(label: "")
        urls.forEach { url in
            resultGroup.enter()
            queryQueue.async {
                urlToAppMapper.appBundleIdentifierFor(url) { result in
                    resultQueue.async {
                        result.analysis(ifSuccess: { (appBundleIdentifier) in
                            urlsByAppBundleIdentifier[appBundleIdentifier, default: []] += [url]
                        }, ifFailure: { error in
                            dump(error, name: "error")
                            dump(url, name: "failingURL")
                        })
                        resultGroup.leave()
                    }
                }
            }
        }
        resultGroup.notify(queue: .main) {
            for (appBundleIdentifier, urls) in dump(urlsByAppBundleIdentifier, name: "urlsByAppBundleIdentifier") {
                guard let appURL = workspace.urlForApplication(withBundleIdentifier: appBundleIdentifier) else {
                    dump(appBundleIdentifier, name: "appBundleIdentifierMissingApp")
                    continue
                }
                do {
                    let runningApp = try workspace.open(dump(urls, name: "urlsToOpenWithAppAtURL"), withApplicationAt: dump(appURL, name: "appURL"), options: .withErrorPresentation, configuration: [:])
                    dump(runningApp, name: "runningApp")
                } catch {
                    dump(error, name: "openURLsError")
                }
            }
        }
    }
}

private let workspace = NSWorkspace()
