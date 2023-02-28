//
//  AppDelegate.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GEFoundation
import GETracing
import Cocoa

extension TypedUserDefaults {
    
    @NSManaged var openMethod: String?
    
    enum OpenMethod : String {
        case openURLsWithAppBundleIdentifier
        case openURLsWithApplicationAtURL
    }
	
    var openMethodValue: OpenMethod? {
        guard let rawValue = defaults.openMethod else {
            return nil
        }
        return OpenMethod(rawValue: rawValue)
    }
}

extension TypedUserDefaults.OpenMethod {
	static let `default`: TypedUserDefaults.OpenMethod = .openURLsWithApplicationAtURL
}

private let urlToAppMapper: URLToAppMapper = ScriptBasedURLToAppMapper()

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {
    
    override init() {
        _ = initializeDefaults
        super.init()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        x$(urls)
        let task = Task {
            let urlsByAppBundleIdentifier = try await resolve(urls)
            for (appBundleIdentifier, urls) in urlsByAppBundleIdentifier {
                try open(urls, withAppWithBundleIdentifier: appBundleIdentifier)
            }
        }
        Task {
            let result = await task.result
            x$(result)
        }
    }
}

private func resolve(_ urls: [URL]) async throws -> [String: [URL]] {
    try await withThrowingTaskGroup(of: (url: URL, appBundleIdentifier: String).self) { group in
        for url in urls {
            group.addTask {
                try await (url, urlToAppMapper.appBundleIdentifierFor(url))
            }
        }
        return try await group.reduce([:]) { acc, x in
            var acc = acc
            acc[x.appBundleIdentifier, default: []] += [x.url]
            return acc
        }
    }
}

private func open(_ urls: [URL], withAppWithBundleIdentifier appBundleIdentifier: String) throws {
    
    switch defaults.openMethodValue ?? .default {
    case .openURLsWithAppBundleIdentifier:
        open(urls: urls, withAppWithBundleIdentifier: appBundleIdentifier)
    case .openURLsWithApplicationAtURL:
        try open(urls: urls, resolvingAppWithBundleIdentifier: appBundleIdentifier)
    }
}

struct OpenURLsWithAppWithBundleIdentifier : Action {
    typealias Input = (urls: [URL], appBundleIdentifier: String)
    typealias SuccessResult = ()
    typealias FailureResult = Error

    enum Error: Swift.Error {
        case workspaceFailedToOpenApp
    }
}

private func open(urls: [URL], withAppWithBundleIdentifier appBundleIdentifier: String) {
    
    let action = OpenURLsWithAppWithBundleIdentifier()
    track(will: action, with: (urls: urls, appBundleIdentifier: appBundleIdentifier))
    let succeeded = workspace.open(urls, withAppBundleIdentifier: appBundleIdentifier, options: .withErrorPresentation, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
    if succeeded {
        track(succeeded: action, with: ())
    } else {
        track(failed: action, due: .workspaceFailedToOpenApp)
    }
}

private func open(urls: [URL], resolvingAppWithBundleIdentifier appBundleIdentifier: String) throws {
    
    let appURL = try resolveAppURL(forBundleIdentifier: appBundleIdentifier)
    open(urls: urls, withAppAtURL: appURL)
}

struct OpenURLsWithAppAtURL : Action {
    typealias Input = (urls: [URL], appURL: URL)
    typealias SuccessResult = (NSRunningApplication)
    typealias FailureResult = Error
}

private func open(urls: [URL], withAppAtURL appURL: URL) {
    
    let action = OpenURLsWithAppAtURL()
    track(will: action, with: (urls: urls, appURL: appURL))
    do {
        let runningApp = try workspace.open(urls, withApplicationAt: appURL, options: .withErrorPresentation, configuration: [:])
        track(succeeded: action, with: (runningApp))
    } catch {
        track(failed: action, due: error)
    }
}

struct ResolveAppForBundleIdentifier : Action {
    typealias Input = String
    typealias SuccessResult = URL
    typealias FailureResult = Error
}

private func resolveAppURL(forBundleIdentifier bundleIdentifier: String) throws -> URL {
    
    let action = ResolveAppForBundleIdentifier()
    track(will: action, with: bundleIdentifier)
    do {
        let appURL = try resolveAppURLWithWorkspace(forBundleIdentifier: bundleIdentifier)
        track(succeeded: action, with: appURL)
        return appURL
    } catch {
        track(failed: action, due: error)
        throw error
    }
}

private func resolveAppURLWithWorkspace(forBundleIdentifier bundleIdentifier: String) throws -> URL {
    
    enum Error: Swift.Error {
        case couldNotLocateApplication(bundleIdentifier: String)
    }
    
    guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
        throw Error.couldNotLocateApplication(bundleIdentifier: bundleIdentifier)
    }
    return appURL
}

private let workspace = NSWorkspace()

private let initializeDefaults: Void = {
#if false
    traceEnabledEnforced = true
    sourceLabelsEnabledEnforced = true
#endif
    x$(())
}()
