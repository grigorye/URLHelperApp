//
//  AppDelegate.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Cocoa
import os.log

private let log = Logger(category: "AppDelegate")

private let urlResolver: URLResolver = ScriptBasedURLResolver()

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let leave = Activity("Finish Launching").enter(); defer { leave() }
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        log.info("Bundle version: \(bundleVersion)")
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        let leave = Activity("Open URLs").enter(); defer { leave() }
        log.info("URLs: \(urls)")
        let task = Task {
            let urlsByAppBundleIdentifier = try await resolve(urls)
            for (appBundleIdentifier, urls) in urlsByAppBundleIdentifier {
                try await open(urls, withAppWithBundleIdentifier: appBundleIdentifier)
            }
        }
        Task {
            do {
                try await task.result.get()
                log.info("Open succeeded")
            } catch {
                log.error("Open failed: \(error)")
            }
        }
    }
}

private func resolve(_ urls: [URL]) async throws -> [String: [URL]] {
    let leave = Activity("Get Route For URLs").enter(); defer { leave() }
    return try await withThrowingTaskGroup(of: (url: URL, appBundleIdentifier: String)?.self) { group in
        for url in urls {
            group.addTask {
                guard let resolution = try await urlResolver.resolveURL(url) else {
                    log.error("Unable to resolve \(url)")
                    return nil
                }
                let finalURL = resolution.finalURL
                let appBundleIdentifier = resolution.appBundleIdentifier
                if url != finalURL {
                    log.info("Rewrote \(url) into \(finalURL)")
                }
                log.info("Got \(appBundleIdentifier, privacy: .public) for opening \(finalURL)")
                return (finalURL, appBundleIdentifier)
            }
        }
        return try await group.compactMap { $0 }.reduce([:]) { acc, x in
            var acc = acc
            acc[x.appBundleIdentifier, default: []] += [x.url]
            return acc
        }
    }
}

private func open(_ urls: [URL], withAppWithBundleIdentifier appBundleIdentifier: String) async throws {
    guard let appURL = resolveAppURL(forBundleIdentifier: appBundleIdentifier) else {
        return
    }
    try await open(urls: urls, withAppAtURL: appURL)
}

private func open(urls: [URL], withAppAtURL appURL: URL) async throws {
    let leave = Activity("Open URLs With Single App").enter(); defer { leave() }
    log.info("URLs: \(urls)")
    log.info("App: \(appURL.standardizedFileURL.path)")
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.promptsUserIfNeeded = true
    do {
        do {
            let leave = Activity("Route Open Into Workspace").enter(); defer { leave() }
            try await workspace.open(urls, withApplicationAt: appURL, configuration: configuration)
        }
        log.info("Open succeeded")
    } catch {
        log.error("Open failed: \(error)")
        throw error
    }
}

private func resolveAppURL(forBundleIdentifier bundleIdentifier: String) -> URL? {
    let leave = Activity("Resolve App By Bundle Identifier").enter(); defer { leave() }
    log.info("App bundle identifier: \(bundleIdentifier)")
    guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
        log.error("No app has bundle identifier \(bundleIdentifier)")
        return nil
    }
    log.info("Resolved app: \(appURL.standardizedFileURL.path)")
    return appURL
}

private let workspace = NSWorkspace()
