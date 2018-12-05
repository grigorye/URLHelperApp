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
                switch defaults.openMethodValue ?? .default {
                case .openURLsWithAppBundleIdentifier:
                    workspace.open(urls, withAppBundleIdentifier: appBundleIdentifier, options: .withErrorPresentation, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
                case .openURLsWithApplicationAtURL:
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
}

private let workspace = NSWorkspace()

let initializeDefaults: Void = {
	traceEnabledEnforced = true
	sourceLabelsEnabledEnforced = true
	x$(())
}()
