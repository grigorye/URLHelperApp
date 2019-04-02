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
import Result

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
            result.analysis(ifSuccess: { (urlsByAppBundleIdentifier) in
                for (appBundleIdentifier, urls) in urlsByAppBundleIdentifier {
                    open(urls, withAppWithBundleIdentifier: appBundleIdentifier)
                }
            }, ifFailure: { error in
                
            })
        }
    }
}

private func resolve(_ urls: [URL], completion: @escaping (Result<[String: [URL]], AnyError>) -> Void) {
    
    var urlsByAppBundleIdentifier: [String: [URL]] = [:]
    let resultGroup = DispatchGroup()
    let queryQueue = DispatchQueue.global()
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
        completion(.success(x$(urlsByAppBundleIdentifier)))
    }
}

private func open(_ urls: [URL], withAppWithBundleIdentifier appBundleIdentifier: String) {
    
    switch defaults.openMethodValue ?? .default {
    case .openURLsWithAppBundleIdentifier:
        workspace.open(urls, withAppBundleIdentifier: appBundleIdentifier, options: .withErrorPresentation, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
    case .openURLsWithApplicationAtURL:
        guard let appURL = resolveAppURL(forBundleIdentifier: appBundleIdentifier) else {
            return
        }
        open(urls: urls, withAppAtURL: appURL)
    }
}

private func open(urls: [URL], withAppAtURL appURL: URL) {
    
    struct OpenURLsWithAppAtURL : Action {
        typealias Input = (urls: [URL], appURL: URL)
        typealias SuccessResult = (NSRunningApplication)
        typealias FailureResult = Error
    }
    let action = OpenURLsWithAppAtURL()
    track(will: action, with: (urls: urls, appURL: appURL))
    do {
        let runningApp = try workspace.open(urls, withApplicationAt: appURL, options: .withErrorPresentation, configuration: [:])
        track(succeeded: action, with: (runningApp))
    } catch {
        track(failed: action, due: error)
    }
}

private func resolveAppURL(forBundleIdentifier bundleIdentifier: String) -> URL? {
    
    struct ResolveAppForBundleIdentifier : Action {
        typealias Input = String
        typealias SuccessResult = URL
        typealias FailureResult = Error
    }
    enum Error: Swift.Error {
        case couldNotLocateApplication(bundleIdentifier: String)
    }
    let action = ResolveAppForBundleIdentifier()
    track(will: action, with: bundleIdentifier)
    guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
        track(failed: action, due: Error.couldNotLocateApplication(bundleIdentifier: bundleIdentifier))
        return nil
    }
    track(succeeded: action, with: appURL)
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
