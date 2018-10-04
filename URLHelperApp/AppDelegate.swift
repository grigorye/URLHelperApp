//
//  AppDelegate.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Cocoa

private let urlToAppMapper: URLToAppMapper = URLToAppMapperImp()

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {
    
    func application(_ application: NSApplication, open urls: [URL]) {
        dump(urls, name: "urls")
        let urlsByAppBundleIdentifier: [String: [URL]] = urls.reduce(into: [:]) { urlsByAppBundleIdentifier, url in
            let appBundleIdentifier = urlToAppMapper.appBundleIdentifierFor(url)
            urlsByAppBundleIdentifier[appBundleIdentifier, default: []] += [url]
        }
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

    private let workspace = NSWorkspace()
}
