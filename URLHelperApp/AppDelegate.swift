//
//  AppDelegate.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GEAppConfig
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

	private let appDelegateBase: AppDelegateBase = {
		_ = initializeDefaults
		return AppDelegateBase()
	}()

    func application(_ application: NSApplication, open urls: [URL]) {
        x$(urls)
        resolve(urls) { result in
            do {
                let urlsByAppBundleIdentifier = try result.get()
                for (appBundleIdentifier, urls) in urlsByAppBundleIdentifier {
                    try open(urls, withAppWithBundleIdentifier: appBundleIdentifier)
                }
            } catch {
                x$(error)
            }
        }
    }
}

private func resolve(_ urls: [URL], completion: @escaping (Result<[String: [URL]], Error>) -> Void) {
    
    var urlsByAppBundleIdentifier: [String: [URL]] = [:]
    let resultGroup = DispatchGroup()
    let queryQueue = DispatchQueue.global()
    let resultQueue = DispatchQueue(label: "")
    urls.forEach { url in
        resultGroup.enter()
        queryQueue.async {
            urlToAppMapper.appBundleIdentifierFor(url) { result in
                resultQueue.async {
                    do {
                        let appBundleIdentifier = try result.get()
                        urlsByAppBundleIdentifier[appBundleIdentifier, default: []] += [url]
                    } catch {
                        x$(error)
                        x$(url)
                    }
                    resultGroup.leave()
                }
            }
        }
    }
    resultGroup.notify(queue: .main) {
        completion(.success(x$(urlsByAppBundleIdentifier)))
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

let initializeDefaults: Void = {
    #if false
	traceEnabledEnforced = true
	sourceLabelsEnabledEnforced = true
    #endif
	x$(())
}()
