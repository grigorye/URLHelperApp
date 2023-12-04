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
        log.info("Did finish launching.")
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        log.info("Opening \(urls).")
        let task = Task {
            let urlsByAppBundleIdentifier = try await resolve(urls)
            for (appBundleIdentifier, urls) in urlsByAppBundleIdentifier {
                try await open(urls, withAppWithBundleIdentifier: appBundleIdentifier)
            }
        }
        Task {
            do {
                try await task.result.get()
                log.info("Succeeded with opening \(urls).")
            } catch {
                log.error("Failed to open \(urls): \(error).")
            }
        }
    }
}

private func resolve(_ urls: [URL]) async throws -> [String: [URL]] {
    try await withThrowingTaskGroup(of: (url: URL, appBundleIdentifier: String)?.self) { group in
        for url in urls {
            group.addTask {
                guard let resolution = try await urlResolver.resolveURL(url) else {
                    log.error("Unable to resolve \(url).")
                    return nil
                }
                return (resolution.finalURL, resolution.appBundleIdentifier)
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
    log.info("Using \(appURL) to open \(urls).")
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.promptsUserIfNeeded = true
    do {
        try await workspace.open(urls, withApplicationAt: appURL, configuration: configuration)
        log.info("Succeeded with using \(appURL) to open \(urls).")
    } catch {
        log.error("Failed to use \(appURL) to open \(urls): \(error).")
        throw error
    }
}

private func resolveAppURL(forBundleIdentifier bundleIdentifier: String) -> URL? {
    log.info("Resolving URL for app bundle identifier \(bundleIdentifier).")
    guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
        log.error("Could not get URL for app with bundle identifier \(bundleIdentifier).")
        return nil
    }
    log.info("Resolved app bundle identifier \(bundleIdentifier) into \(appURL).")
    return appURL
}

private let workspace = NSWorkspace()
