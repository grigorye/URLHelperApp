//
//  AppDelegate.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GEAppConfig
import GETracing
import Cocoa

private let urlToAppMapper: URLToAppMapper = ScriptBasedURLToAppMapper()

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {
    
    func application(_ application: NSApplication, open urls: [URL]) {
        x$(urls)
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
                            x$(error)
                            x$(url)
                        })
                        resultGroup.leave()
                    }
                }
            }
        }
        resultGroup.notify(queue: .main) {
            for (appBundleIdentifier, urls) in x$(urlsByAppBundleIdentifier) {
                guard let appURL = workspace.urlForApplication(withBundleIdentifier: appBundleIdentifier) else {
                    x$(appBundleIdentifier)
                    continue
                }
                do {
                    let runningApp = try workspace.open(x$(urls), withApplicationAt: x$(appURL), options: .withErrorPresentation, configuration: [:])
                    x$(runningApp)
                } catch {
                    x$(error)
                }
            }
        }
    }
}

private let workspace = NSWorkspace()
